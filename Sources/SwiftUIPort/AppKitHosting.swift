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
}

private final class HostedMountInstance<R: NSViewRepresentable>: _HostedViewMount {
  let typedView: R.NSViewType
  let coordinator: R.Coordinator
  var nsView: NSView { typedView }

  init(typedView: R.NSViewType, coordinator: R.Coordinator) {
    self.typedView = typedView
    self.coordinator = coordinator
  }

  func dismantle() {
    MainActor.assumeIsolated {
      R.dismantleNSView(typedView, coordinator: coordinator)
      typedView.removeFromSuperview()
    }
  }
}

private final class HostedViewBridge<R: NSViewRepresentable>: _HostedViewBackendBridge {
  let representable: R
  let environment: EnvironmentValues
  weak var hostContainer: NSView?

  init(representable: R, environment: EnvironmentValues, hostContainer: NSView?) {
    self.representable = representable
    self.environment = environment
    self.hostContainer = hostContainer
  }

  func createMount(frame: CGRect) -> (mount: any _HostedViewMount, nativeView: NativeAPI.View?) {
    MainActor.assumeIsolated {
      let coordinator = representable.makeCoordinator()
      let ctx = NSViewRepresentableContext<R>(coordinator: coordinator, environment: environment)
      let view = representable.makeNSView(context: ctx)
      view.frame = frame
      if let container = hostContainer {
        container.addSubview(view)
      }
      representable.updateNSView(view, context: ctx)
      return (HostedMountInstance<R>(typedView: view, coordinator: coordinator), view.ownedNativeView)
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
    return _HostedViewPrimitive(adapter: bridge) { proposal in
      MainActor.assumeIsolated {
        let coordinator = self.makeCoordinator()
        let ctx = NSViewRepresentableContext<Self>(coordinator: coordinator, environment: env)
        let probe = self.makeNSView(context: ctx)
        if let custom = self.sizeThatFits(proposal, nsView: probe, context: ctx) {
          return SwiftUIRuntime.Size(width: Double(custom.width), height: Double(custom.height))
        }
        let intrinsic = probe.intrinsicContentSize
        let w = intrinsic.width >= 0 ? Double(intrinsic.width) : Double(proposal.width ?? 0)
        let h = intrinsic.height >= 0 ? Double(intrinsic.height) : Double(proposal.height ?? 0)
        return SwiftUIRuntime.Size(width: max(0, w), height: max(0, h))
      }
    }
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
      if bg.a < 0.05 {
        // Transparent/scrim panels paint over dark/light acrylic backdrop
        let base = isDark
          ? SwiftUIRuntime.Color(red: 0.10, green: 0.10, blue: 0.11, opacity: 1.0)
          : SwiftUIRuntime.Color(red: 0.95, green: 0.95, blue: 0.96, opacity: 1.0)
        backend?.setBackgroundColor(base)
        win.applyWindowsBackdrop(.acrylic)
      } else {
        backend?.setBackgroundColor(SwiftUIRuntime.Color(
          red: Double(bg.r), green: Double(bg.g), blue: Double(bg.b), opacity: Double(bg.a)
        ))
      }
    #endif
  }

  private func attachIfPossible() {
    guard renderer == nil, let win = window, let nativeWin = win.nativeWindow else { return }
    let targetView: NativeAPI.View
    if win.contentView === self, let cv = nativeWin.contentView {
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
      syncAppearanceAndBackground()

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

      createdBackend.onResize = { [weak createdRenderer] newSize in
        createdRenderer?.resize(to: newSize)
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
      flags.insert(.control)
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
  SwiftUIRuntime.Image.assetPathResolver = { name in
    CrossAppKit.NSImage.resolveAssetPath(named: name)
  }
  CrossAppKit.NSImage.symbolLookupHandler = { symbolName in
    VectorImage.hasSymbol(symbolName)
  }
}

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
