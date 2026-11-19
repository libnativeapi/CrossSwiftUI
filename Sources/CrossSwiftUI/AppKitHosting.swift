import CrossAppKit
import Foundation
import NativeAPI
import Observation
import SwiftUIRuntime
#if !os(macOS)
  import Combine
#endif

// MARK: - Hosted NSView Bridge Protocols

protocol _HostedViewMount: AnyObject {
  var nsView: NSView { get }
  func dismantle()
}

protocol _HostedViewBackendBridge: AnyObject {
  func createMount(frame: CGRect) -> (mount: any _HostedViewMount, nativeView: NativeAPI.View?)
  func updateMount(_ mount: any _HostedViewMount, frame: CGRect)
}

// MARK: - Color / Font / Image AppKit Interop

extension SwiftUIRuntime.Color {
  public init(nsColor: CrossAppKit.NSColor) {
    if nsColor.isDynamic {
      self.init { scheme in
        let app = CrossAppKit.NSAppearance(named: scheme == .dark ? .darkAqua : .aqua)
        let c = nsColor.resolved(for: app)
        return (Double(c.r), Double(c.g), Double(c.b), Double(c.a))
      }
    } else {
      let c = nsColor.resolved()
      self.init(red: Double(c.r), green: Double(c.g), blue: Double(c.b), opacity: Double(c.a))
    }
  }

  public init(_ nsColor: CrossAppKit.NSColor) {
    self.init(nsColor: nsColor)
  }
}

extension CrossAppKit.NSColor {
  public convenience init(_ color: SwiftUIRuntime.Color) {
    self.init(name: nil) { appearance in
      let isDark = appearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
      let resolved = color.resolved(in: isDark ? .dark : .light)
      return CrossAppKit.NSColor(
        srgbRed: CGFloat(resolved.red),
        green: CGFloat(resolved.green),
        blue: CGFloat(resolved.blue),
        alpha: CGFloat(resolved.opacity)
      )
    }
  }
}

extension SwiftUIRuntime.Font {
  public init(_ font: CrossAppKit.NSFont) {
    self.init(
      size: font.pointSize,
      weight: Weight(font.fontDescriptor.weight.cssWeight),
      family: font.fontName
    )
  }
}

extension SwiftUIRuntime.Image {
  public init(nsImage: CrossAppKit.NSImage) {
    if let sym = nsImage.symbolName {
      self.init(systemName: sym)
    } else {
      let path = nsImage.ensureTemporaryFilePath() ?? ""
      let sz = SwiftUIRuntime.Size(width: Double(nsImage.size.width), height: Double(nsImage.size.height))
      self.init(filePath: path, size: sz, isTemplate: nsImage.isTemplate)
    }
  }
}

// MARK: - NSViewRepresentable

public struct NSViewRepresentableContext<Representable: NSViewRepresentable> {
  public let coordinator: Representable.Coordinator
  public let environment: EnvironmentValues
}

@MainActor @preconcurrency
public protocol NSViewRepresentable: SwiftUIRuntime.View where Body == _HostedViewPrimitive {
  associatedtype NSViewType: CrossAppKit.NSView
  associatedtype Coordinator = Void
  typealias Context = NSViewRepresentableContext<Self>

  func makeCoordinator() -> Coordinator
  func makeNSView(context: NSViewRepresentableContext<Self>) -> NSViewType
  func updateNSView(_ nsView: NSViewType, context: NSViewRepresentableContext<Self>)
  static func dismantleNSView(_ nsView: NSViewType, coordinator: Coordinator)
  func sizeThatFits(
    _ proposal: ProposedViewSize,
    nsView: NSViewType,
    context: NSViewRepresentableContext<Self>
  ) -> CGSize?
}

extension NSViewRepresentable where Coordinator == Void {
  public func makeCoordinator() -> Void { () }
}

extension NSViewRepresentable {
  public static func dismantleNSView(_ nsView: NSViewType, coordinator: Coordinator) {}

  public func sizeThatFits(
    _ proposal: ProposedViewSize,
    nsView: NSViewType,
    context: NSViewRepresentableContext<Self>
  ) -> CGSize? {
    nil
  }
}

private enum ActiveHostingContext {
  nonisolated(unsafe) static weak var currentHostingView: NSView?
  @MainActor static var mountsByHost: [ObjectIdentifier: [AnyHashable: any _HostedViewMount]] = [:]

  @MainActor static func mount(for host: NSView?, key: AnyHashable?) -> (any _HostedViewMount)? {
    guard let host, let key else { return nil }
    return mountsByHost[ObjectIdentifier(host)]?[key]
  }

  @MainActor static func setMount(_ mount: any _HostedViewMount, for host: NSView?, key: AnyHashable?) {
    guard let host, let key else { return }
    mountsByHost[ObjectIdentifier(host), default: [:]][key] = mount
  }

  @MainActor static func removeMount(for host: NSView?, key: AnyHashable?) {
    guard let host, let key else { return }
    let id = ObjectIdentifier(host)
    mountsByHost[id]?.removeValue(forKey: key)
    if mountsByHost[id]?.isEmpty == true {
      mountsByHost.removeValue(forKey: id)
    }
  }
}

private final class HostedMountInstance<R: NSViewRepresentable>: _HostedViewMount {
  let typedView: R.NSViewType
  let coordinator: R.Coordinator
  weak var hostContainer: NSView?
  let key: AnyHashable?
  var nsView: NSView { typedView }

  init(typedView: R.NSViewType, coordinator: R.Coordinator, hostContainer: NSView?, key: AnyHashable?) {
    self.typedView = typedView
    self.coordinator = coordinator
    self.hostContainer = hostContainer
    self.key = key
  }

  func dismantle() {
    MainActor.assumeIsolated {
      ActiveHostingContext.removeMount(for: hostContainer, key: key)
      R.dismantleNSView(typedView, coordinator: coordinator)
      typedView.removeFromSuperview()
    }
  }
}

private final class HostedViewBridge<R: NSViewRepresentable>: _HostedViewBackendBridge {
  let representable: R
  let environment: EnvironmentValues
  weak var hostContainer: NSView?
  var viewKey: AnyHashable?

  init(representable: R, environment: EnvironmentValues, hostContainer: NSView?) {
    self.representable = representable
    self.environment = environment
    self.hostContainer = hostContainer
  }

  @MainActor
  private func ensureInstance(key: AnyHashable?) -> HostedMountInstance<R> {
    let resolvedKey = key ?? viewKey
    if let existing = ActiveHostingContext.mount(for: hostContainer, key: resolvedKey) as? HostedMountInstance<R> {
      if let container = hostContainer, existing.typedView.superview !== container {
        container.addSubview(existing.typedView)
      }
      return existing
    }
    let coordinator = representable.makeCoordinator()
    let ctx = NSViewRepresentableContext<R>(coordinator: coordinator, environment: environment)
    let view = representable.makeNSView(context: ctx)
    if let container = hostContainer {
      container.addSubview(view)
    }
    let instance = HostedMountInstance<R>(
      typedView: view, coordinator: coordinator, hostContainer: hostContainer, key: resolvedKey
    )
    ActiveHostingContext.setMount(instance, for: hostContainer, key: resolvedKey)
    return instance
  }

  func measure(key: AnyHashable, proposal: ProposedViewSize) -> SwiftUIRuntime.Size {
    MainActor.assumeIsolated {
      let instance = ensureInstance(key: key)
      let ctx = NSViewRepresentableContext<R>(coordinator: instance.coordinator, environment: environment)
      if let custom = representable.sizeThatFits(proposal, nsView: instance.typedView, context: ctx) {
        return SwiftUIRuntime.Size(width: Double(custom.width), height: Double(custom.height))
      }
      let intrinsic = instance.typedView.intrinsicContentSize
      let w = intrinsic.width >= 0 ? Double(intrinsic.width) : Double(proposal.width ?? 0)
      let h = intrinsic.height >= 0 ? Double(intrinsic.height) : Double(proposal.height ?? 0)
      return SwiftUIRuntime.Size(width: max(0, w), height: max(0, h))
    }
  }

  func createMount(frame: CGRect) -> (mount: any _HostedViewMount, nativeView: NativeAPI.View?) {
    MainActor.assumeIsolated {
      let instance = ensureInstance(key: viewKey)
      instance.typedView.frame = frame
      let ctx = NSViewRepresentableContext<R>(coordinator: instance.coordinator, environment: environment)
      representable.updateNSView(instance.typedView, context: ctx)
      return (instance, instance.typedView.ownedNativeView)
    }
  }

  func updateMount(_ mount: any _HostedViewMount, frame: CGRect) {
    MainActor.assumeIsolated {
      guard let typed = mount as? HostedMountInstance<R> else { return }
      if typed.typedView.frame != frame {
        typed.typedView.frame = frame
      }
      if let container = hostContainer, typed.typedView.superview !== container {
        container.addSubview(typed.typedView)
      }
      let ctx = NSViewRepresentableContext<R>(coordinator: typed.coordinator, environment: environment)
      representable.updateNSView(typed.typedView, context: ctx)
    }
  }
}

extension NSViewRepresentable {
  public var body: _HostedViewPrimitive {
    let env = EnvironmentValues.current
    let host = ActiveHostingContext.currentHostingView
    let bridge = HostedViewBridge(representable: self, environment: env, hostContainer: host)
    return _HostedViewPrimitive(
      adapter: bridge,
      bindPath: { key in bridge.viewKey = key },
      measure: { key, proposal in bridge.measure(key: key, proposal: proposal) }
    )
  }
}

internal final class _HeadlessRenderBackend: RenderBackend {
  var tapHandler: ((NodeID) -> Void)?
  var transactionHandler: ((() -> Void) -> Void)?
  var animationTickHandler: (() -> Bool)?
  var environment = EnvironmentValues()
  var needsRenderCommands: Bool { false }
  func perform(_ commands: [RenderCommand]) {}
  func didRender(_ root: Element) {}
}

// MARK: - NSHostingView & NSHostingController

public struct NSHostingSizingOptions: OptionSet, Sendable {
  public let rawValue: Int
  public init(rawValue: Int) { self.rawValue = rawValue }
  public static let minSize = NSHostingSizingOptions(rawValue: 1 << 0)
  public static let intrinsicContentSize = NSHostingSizingOptions(rawValue: 1 << 1)
  public static let maxSize = NSHostingSizingOptions(rawValue: 1 << 2)
  public static let preferredContentSize = NSHostingSizingOptions(rawValue: 1 << 3)
  public static let standardBounds: NSHostingSizingOptions = [.minSize, .intrinsicContentSize, .maxSize]
}

@MainActor
open class NSHostingView<Content: SwiftUIRuntime.View>: NSView {
  public typealias SizingOptions = NSHostingSizingOptions

  public var sizingOptions: SizingOptions = .standardBounds
  public var rootView: Content {
    didSet {
      rebuildOrUpdateRenderer(forceRemount: true)
    }
  }

  #if os(Windows)
    private var backend: WindowsDrawingBackend?
    private var isApplyingWindowResize = false
    private var isCommittingPendingWindowBounds = false
    private var pendingWindowBoundsCommit: (() -> Void)?
    private var surfaceContentOffset: NSPoint = .zero
    private var usesEnvelopeSizing = false
  #elseif os(Linux)
    private var backend: LinuxDrawingBackend?
  #else
    private var backend: NativeViewBackend?
  #endif
  public private(set) var renderer: Renderer?

  public init(rootView: Content) {
    self.rootView = rootView
    super.init(frame: .zero)
    installAssetResolversOnce()
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  open override var intrinsicContentSize: NSSize {
    if let renderer {
      let measured = renderer.sizeThatFits(
        ProposedViewSize(
          width: frame.width > 0 ? frame.width : nil,
          height: nil
        )
      )
      return NSSize(width: CGFloat(measured.width), height: CGFloat(measured.height))
    }
    return measureDetached(proposal: ProposedViewSize(width: frame.width > 0 ? frame.width : nil, height: nil))
  }

  private func measureDetached(proposal: ProposedViewSize) -> NSSize {
    #if os(Windows)
      let engine = LayoutEngine(textMeasurer: WindowsDrawingBackend.measureText)
    #else
      let engine = LayoutEngine()
    #endif
    let dummy = _HeadlessRenderBackend()
    let isDark = effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    dummy.environment.colorScheme = isDark ? SwiftUIRuntime.ColorScheme.dark : SwiftUIRuntime.ColorScheme.light
    let temp = Renderer(backend: dummy, root: AnyView(rootView), size: SwiftUIRuntime.Size(width: Double(proposal.width ?? 420), height: Double(proposal.height ?? 800)), layoutEngine: engine)
    let sz = temp.sizeThatFits(proposal)
    return NSSize(width: CGFloat(sz.width), height: CGFloat(sz.height))
  }

  open override func viewDidMoveToWindow() {
    super.viewDidMoveToWindow()
    if window != nil {
      attachIfPossible()
    } else {
      teardownRenderer()
    }
  }

  private var isFlushingLayout = false

  open override func layout() {
    super.layout()
    guard !isFlushingLayout else { return }
    if renderer?.isRendering == true { return }
    isFlushingLayout = true
    defer { isFlushingLayout = false }
    renderer?.renderIfNeeded()
    #if os(Windows)
      if !isApplyingWindowResize && pendingWindowBoundsCommit == nil {
        backend?.flushSyncPaint()
      }
    #endif
  }

  open override func applySurfaceContentOffset(x: Double, y: Double) {
    #if os(Windows)
      surfaceContentOffset = NSPoint(x: x, y: y)
      if x != 0 || y != 0 {
        usesEnvelopeSizing = true
      }
      backend?.setContentOffset(x: x, y: y)
    #endif
  }

  open override func applyWindowFrameChange(
    contentSize: NSSize,
    envelopeSize: NSSize? = nil,
    contentOffset: NSPoint = .zero,
    display: Bool,
    commitNativeBounds: @escaping () -> Void
  ) -> Bool {
    #if os(Windows)
      guard let renderer, let backend, ownedNativeView != nil else { return false }
      let w = Double(max(1, contentSize.width))
      let h = Double(max(1, contentSize.height))
      let envSize = envelopeSize ?? contentSize
      let surfW = Double(max(1, envSize.width))
      let surfH = Double(max(1, envSize.height))
      let hasEnv = envelopeSize != nil
      if hasEnv {
        usesEnvelopeSizing = true
      }
      let offsetChanged =
        abs(Double(surfaceContentOffset.x) - Double(contentOffset.x)) > 1e-4
        || abs(Double(surfaceContentOffset.y) - Double(contentOffset.y)) > 1e-4
      surfaceContentOffset = contentOffset
      let sizeChanged =
        abs(Double(frame.width) - w) > 0.5 || abs(Double(frame.height) - h) > 0.5 || offsetChanged

      if renderer.isRendering || isApplyingWindowResize {
        pendingWindowBoundsCommit = commitNativeBounds
        if sizeChanged || pendingWindowBoundsCommit != nil {
          backend.beginPendingResize(width: surfW, height: surfH)
          if hasEnv || offsetChanged {
            backend.setPendingContentOffset(x: Double(contentOffset.x), y: Double(contentOffset.y))
          }
        }
        if superview === window?.contentView, superview !== self {
          superview?.frame = NSRect(origin: .zero, size: contentSize)
        }
        self.frame = NSRect(origin: .zero, size: contentSize)
        renderer.resize(to: SwiftUIRuntime.Size(width: w, height: h))
        return true
      }

      guard sizeChanged else {
        commitNativeBounds()
        if display {
          renderer.renderIfNeeded()
          backend.flushSyncPaint()
        }
        return true
      }

      isApplyingWindowResize = true
      defer { isApplyingWindowResize = false }
      pendingWindowBoundsCommit = commitNativeBounds

      backend.beginPendingResize(width: surfW, height: surfH)
      if hasEnv || offsetChanged {
        backend.setPendingContentOffset(x: Double(contentOffset.x), y: Double(contentOffset.y))
      }
      if superview === window?.contentView, superview !== self {
        superview?.frame = NSRect(origin: .zero, size: contentSize)
      }
      self.frame = NSRect(origin: .zero, size: contentSize)
      renderer.resize(to: SwiftUIRuntime.Size(width: w, height: h))
      renderer.renderIfNeeded()

      let finalCommit = pendingWindowBoundsCommit ?? commitNativeBounds
      pendingWindowBoundsCommit = nil
      backend.prerenderPendingResize()
      isCommittingPendingWindowBounds = true
      finalCommit()
      isCommittingPendingWindowBounds = false
      backend.commitPendingResize()
      return true
    #else
      return false
    #endif
  }

  open override func viewDidChangeFrameSize(from oldSize: NSSize) {
    super.viewDidChangeFrameSize(from: oldSize)
    guard frame.width > 0 && frame.height > 0 else { return }
    renderer?.resize(to: SwiftUIRuntime.Size(width: Double(frame.width), height: Double(frame.height)))
  }

  open override func viewDidChangeEffectiveAppearance() {
    super.viewDidChangeEffectiveAppearance()
    syncAppearanceAndBackground()
    renderer?.setNeedsRender()
  }

  private func syncAppearanceAndBackground() {
    guard let win = window else { return }
    let isDark = win.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
    #if os(Windows)
      backend?.environmentTransform = { env in
        env.colorScheme = isDark ? SwiftUIRuntime.ColorScheme.dark : SwiftUIRuntime.ColorScheme.light
      }
      let bg = win.backgroundColor.resolved(for: win.effectiveAppearance)
      let isFrameless = !win.styleMask.contains(.titled)
      if !win.isOpaque || bg.a < 0.05 {
        // Transparent borderless panels clear to per-pixel alpha=0 so outer margins stay hollow
        backend?.setBackgroundColor(.clear)
        backend?.setWindowShadow(enabled: isFrameless && win.hasShadow, isDark: isDark)
        win.syncBackgroundToNative()
      } else {
        backend?.setWindowShadow(enabled: false, isDark: isDark)
        backend?.setBackgroundColor(SwiftUIRuntime.Color(
          red: Double(bg.r), green: Double(bg.g), blue: Double(bg.b), opacity: Double(bg.a)
        ))
      }
    #endif
  }

  private func attachIfPossible() {
    guard renderer == nil, let win = window, let nativeWin = win.nativeWindow else { return }
    let targetView: NativeAPI.View
    let isWindowRootHost = (win.contentView === self)
      || (superview === win.contentView && superview?.ownedNativeView == nil && superview?.subviews.count == 1)
    if isWindowRootHost, let cv = nativeWin.contentView {
      self.ownedNativeView = cv
      targetView = cv
    } else if let subNV = ensureNativeView() {
      if let parentNV = superview?.ownedNativeView ?? nativeWin.contentView {
        parentNV.addSubview(subNV)
      }
      targetView = subNV
    } else {
      return
    }

    let initialSize = frame.width > 0 && frame.height > 0 ? frame.size : win.contentLayoutRect.size
    let w = Double(max(1, initialSize.width))
    let h = Double(max(1, initialSize.height))

    #if os(Windows)
      WindowsDrawingBackend.prepareApplication()
      guard let createdBackend = WindowsDrawingBackend(view: targetView, window: nativeWin, schedulesUpdates: true) else {
        return
      }
      self.backend = createdBackend
      let initOffset = win.nativeContentOffset
      if initOffset.x != 0 || initOffset.y != 0 {
        surfaceContentOffset = initOffset
        usesEnvelopeSizing = true
        createdBackend.setContentOffset(x: Double(initOffset.x), y: Double(initOffset.y))
      }
      syncAppearanceAndBackground()

      createdBackend.onTextSelectionOrCompositionChanged = { [weak self] in
        guard let responder = self?.window?.firstResponder else { return }
        NotificationCenter.default.post(
          name: NSTextView.didChangeSelectionNotification,
          object: responder
        )
      }

      createdBackend.onPreInput = { [weak self] event, point, value, modifiers in
        guard let self, let nsWin = self.window else { return false }
        return self.forwardToNSWindowIfIntercepted(
          nsWin: nsWin, event: event, point: point, value: value, modifiers: modifiers
        )
      }

      let layout = LayoutEngine(textMeasurer: WindowsDrawingBackend.measureText)
      ActiveHostingContext.currentHostingView = self
      let createdRenderer = Renderer(
        backend: createdBackend,
        root: AnyView(HostingScopeView(host: self, content: rootView)),
        size: SwiftUIRuntime.Size(width: w, height: h),
        layoutEngine: layout
      )
      self.renderer = createdRenderer

      createdRenderer.onDidFinishRenderPasses = { [weak self] in
        guard let self, !self.isApplyingWindowResize, !self.isCommittingPendingWindowBounds,
          let commit = self.pendingWindowBoundsCommit
        else {
          return
        }
        self.pendingWindowBoundsCommit = nil
        self.backend?.prerenderPendingResize()
        self.isCommittingPendingWindowBounds = true
        commit()
        self.isCommittingPendingWindowBounds = false
        self.backend?.commitPendingResize()
      }
      createdBackend.onResize = { [weak self, weak createdRenderer] newSize in
        guard let self, let createdRenderer else { return }
        if self.usesEnvelopeSizing {
          return
        }
        if self.isCommittingPendingWindowBounds || self.isApplyingWindowResize || self.pendingWindowBoundsCommit != nil {
          if abs(Double(self.frame.width) - newSize.width) < 1.0
            && abs(Double(self.frame.height) - newSize.height) < 1.0
          {
            return
          }
        }
        createdRenderer.resize(to: newSize)
      }
      createdBackend.inputHandler = { [weak self, weak createdRenderer] id, event, point, value, modifiers, text in
        ActiveHostingContext.currentHostingView = self
        return createdRenderer?.input(
          id: id, event: event, point: point, value: value, modifiers: modifiers, text: text,
          updatesPressedState: false
        ) ?? false
      }
      createdBackend.interactionHandler = { [weak createdRenderer] id, interaction in
        createdRenderer?.interact(id, interaction)
      }
      createdRenderer.mount()
      ActiveHostingContext.currentHostingView = nil
    #elseif os(Linux)
      guard let createdBackend = LinuxDrawingBackend(window: nativeWin) else { return }
      self.backend = createdBackend
      let layout = LayoutEngine(textMeasurer: createdBackend.measureText)
      let createdRenderer = Renderer(
        backend: createdBackend,
        root: AnyView(HostingScopeView(host: self, content: rootView)),
        size: SwiftUIRuntime.Size(width: w, height: h),
        layoutEngine: layout
      )
      self.renderer = createdRenderer
      createdBackend.onResize = { [weak createdRenderer] newSize in
        createdRenderer?.resize(to: newSize)
      }
      createdBackend.inputHandler = { [weak createdRenderer] id, event, point, value, modifiers, text in
        createdRenderer?.input(
          id: id, event: event, point: point, value: value, modifiers: modifiers, text: text,
          updatesPressedState: true
        ) ?? false
      }
      createdBackend.interactionHandler = { [weak createdRenderer] id, interaction in
        createdRenderer?.interact(id, interaction)
      }
      createdRenderer.mount()
    #endif
  }

  private func rebuildOrUpdateRenderer(forceRemount: Bool) {
    guard renderer != nil else {
      attachIfPossible()
      return
    }
    if forceRemount {
      teardownRenderer()
      attachIfPossible()
    } else {
      renderer?.setNeedsRender()
    }
  }

  private func teardownRenderer() {
    ActiveHostingContext.mountsByHost.removeValue(forKey: ObjectIdentifier(self))
    renderer = nil
    backend = nil
  }

  /// Translates low-level surface key/mouse events into `CrossAppKit.NSEvent` and lets
  /// subclasses like `PalettePanel` or `DialogPanel` run their `sendEvent` hooks!
  private func forwardToNSWindowIfIntercepted(
    nsWin: NSWindow, event: Int, point: CGPoint, value: Int, modifiers: EventModifiers
  ) -> Bool {
    var flags: NSEvent.ModifierFlags = []
    if modifiers.contains(.shift) { flags.insert(.shift) }
    if modifiers.contains(.control) {
      // On Windows, Ctrl acts as Command for app shortcuts (Ctrl+K, Ctrl+W, Ctrl+,)
      flags.insert(.command)
    }
    if modifiers.contains(.option) { flags.insert(.option) }
    if modifiers.contains(.command) { flags.insert(.command) }

    let winHeight = nsWin.contentLayoutRect.height
    let appKitLoc = NSPoint(x: point.x, y: max(0, winHeight - point.y))

    if event == 6 {
      // KeyDown: value is Win32 VK code
      let carbonCode = NSEvent.carbonKeyCode(fromWin32VK: value)
      let ch: String
      if (0x30...0x5A).contains(value), let scalar = UnicodeScalar(value) {
        ch = String(scalar).lowercased()
      } else if value == 0xBC {
        ch = ","
      } else if value == 0xBE {
        ch = "."
      } else if value == 0xBD {
        ch = "-"
      } else if value == 0xBB {
        ch = "="
      } else if value == 0x1B {
        ch = "\u{1B}"
      } else if value == 0x0D {
        ch = "\r"
      } else if value == 0x08 {
        ch = "\u{7F}"
      } else if value == 0x09 {
        ch = "\t"
      } else {
        ch = ""
      }
      let nsEv = NSEvent(
        type: .keyDown,
        locationInWindow: appKitLoc,
        modifierFlags: flags,
        windowNumber: nsWin.windowNumber,
        window: nsWin,
        characters: ch,
        charactersIgnoringModifiers: ch,
        keyCode: carbonCode
      )
      guard NSEvent.dispatchLocalMonitors(nsEv) != nil else {
        return true // Swallowed by local monitor (e.g., Paste monitor)!
      }
      nsWin._eventReachedBaseSendEvent = false
      nsWin._suppressLocalMonitorInSendEvent = true
      nsWin.sendEvent(nsEv)
      nsWin._suppressLocalMonitorInSendEvent = false
      if !nsWin._eventReachedBaseSendEvent {
        return true // Swallowed by NSWindow subclass (PalettePanel, MenuPanel, DialogPanel)!
      }
    }
    return false
  }
}

private struct HostingScopeView<Content: SwiftUIRuntime.View>: SwiftUIRuntime.View {
  weak var host: NSView?
  let content: Content

  var body: some SwiftUIRuntime.View {
    let _ = { ActiveHostingContext.currentHostingView = host }()
    content
  }
}

public struct NSHostingSceneBridgingOptions: OptionSet, Sendable {
  public let rawValue: Int
  public init(rawValue: Int) { self.rawValue = rawValue }
  public static let toolbars = NSHostingSceneBridgingOptions(rawValue: 1 << 0)
  public static let title = NSHostingSceneBridgingOptions(rawValue: 1 << 1)
  public static let all: NSHostingSceneBridgingOptions = [.toolbars, .title]
}

@MainActor
open class NSHostingController<Content: SwiftUIRuntime.View>: NSViewController {
  public typealias SizingOptions = NSHostingSizingOptions

  public var sizingOptions: SizingOptions = .standardBounds {
    didSet { hostingView.sizingOptions = sizingOptions }
  }
  public var sceneBridgingOptions: NSHostingSceneBridgingOptions = .all

  public var rootView: Content {
    get { hostingView.rootView }
    set { hostingView.rootView = newValue }
  }

  private let hostingView: NSHostingView<Content>

  public init(rootView: Content) {
    self.hostingView = NSHostingView(rootView: rootView)
    super.init(nibName: nil, bundle: nil)
    self.view = hostingView
  }

  @available(*, unavailable)
  public required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }
}

// MARK: - @NSApplicationDelegateAdaptor

public protocol _ApplicationDelegateProvider {
  @MainActor func _installDelegate()
}

@MainActor
@propertyWrapper
public struct NSApplicationDelegateAdaptor<DelegateType: NSObject & NSApplicationDelegate>: _ApplicationDelegateProvider {
  public let wrappedValue: DelegateType

  public init(_ delegateType: DelegateType.Type = DelegateType.self) {
    self.wrappedValue = delegateType.init()
  }

  public init(_ makeDelegate: @autoclosure @escaping () -> DelegateType) {
    self.wrappedValue = makeDelegate()
  }

  public func _installDelegate() {
    NSApplication.shared.delegate = wrappedValue
  }
}

nonisolated(unsafe) private var didInstallAssetResolvers = false

internal func installAssetResolversOnce() {
  guard !didInstallAssetResolvers else { return }
  didInstallAssetResolvers = true
  #if !os(macOS)
    bootstrapAppResources()
  #endif
  SwiftUIRuntime.Image.assetPathResolver = { name in
    CrossAppKit.NSImage.resolveAssetPath(named: name)
  }
  CrossAppKit.NSImage.symbolLookupHandler = { symbolName in
    VectorImage.hasSymbol(symbolName)
  }
}

#if !os(macOS)
  private func bootstrapAppResources() {
    let fm = FileManager.default
    let exeDir = URL(fileURLWithPath: CommandLine.arguments.first ?? ".").deletingLastPathComponent()
    let cwd = URL(fileURLWithPath: fm.currentDirectoryPath)
    var candidates: [URL] = [exeDir, cwd]
    var cursor = exeDir
    for _ in 0..<5 {
      cursor = cursor.deletingLastPathComponent()
      candidates.append(cursor)
    }
    var searchPaths = CrossAppKit.NSImage.resourceSearchPaths
    for root in candidates {
      var bases: [URL] = [root]
      if let children = try? fm.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey], options: [.skipsHiddenFiles]) {
        for child in children {
          if (try? child.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true {
            bases.append(child)
          }
        }
      }
      for base in bases {
        let assets = base.appendingPathComponent("Assets.xcassets")
        if fm.fileExists(atPath: assets.path), !searchPaths.contains(base.path) {
          searchPaths.append(base.path)
        }
        let xcstrings = base.appendingPathComponent("Resources/Localizable.xcstrings")
        if fm.fileExists(atPath: xcstrings.path) {
          XCStringsCatalog.shared.load(from: xcstrings)
        }
      }
    }
    CrossAppKit.NSImage.resourceSearchPaths = searchPaths
  }
#endif

#if !os(macOS)
  private final class _WinCombineCancellableBox {
    var cancellable: AnyCancellable?
  }

  private struct _WinOnReceiveView<Content: SwiftUIRuntime.View, P: Combine.Publisher>: SwiftUIRuntime.View
  where P.Failure == Never {
    let content: Content
    let publisher: P
    let action: (P.Output) -> Void
    @State private var box = _WinCombineCancellableBox()

    var body: some SwiftUIRuntime.View {
      content
        .onAppear {
          box.cancellable = publisher.sink(receiveValue: action)
        }
        .onDisappear {
          box.cancellable?.cancel()
          box.cancellable = nil
        }
    }
  }

  extension SwiftUIRuntime.View {
    public func onReceive<P: Combine.Publisher>(
      _ publisher: P,
      perform action: @escaping (P.Output) -> Void
    ) -> some SwiftUIRuntime.View where P.Failure == Never {
      _WinOnReceiveView(content: self, publisher: publisher, action: action)
    }
  }
#endif
