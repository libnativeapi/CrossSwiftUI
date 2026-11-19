import Foundation
#if !os(macOS)
  import NativeAPI
#endif
#if os(Windows)
  import CAppKitWindows
#endif

@MainActor
public protocol NSApplicationDelegate: AnyObject {
  init()
  func applicationWillFinishLaunching(_ notification: Notification)
  func applicationDidFinishLaunching(_ notification: Notification)
  func applicationWillTerminate(_ notification: Notification)
  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply
  func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool
  func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool
  func application(_ application: NSApplication, open urls: [URL])
  func applicationDidBecomeActive(_ notification: Notification)
  func applicationDidResignActive(_ notification: Notification)
}

extension NSApplicationDelegate {
  public func applicationWillFinishLaunching(_ notification: Notification) {}
  public func applicationDidFinishLaunching(_ notification: Notification) {}
  public func applicationWillTerminate(_ notification: Notification) {}
  public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply { .terminateNow }
  public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { true }
  public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
  public func application(_ application: NSApplication, open urls: [URL]) {}
  public func applicationDidBecomeActive(_ notification: Notification) {}
  public func applicationDidResignActive(_ notification: Notification) {}
}

@MainActor
public var NSApp: NSApplication! {
  get { NSApplication.shared }
  set {}
}

@MainActor
open class NSApplication: NSResponder, @unchecked Sendable {
  public enum ActivationPolicy: Int, Sendable {
    case regular = 0
    case accessory = 1
    case prohibited = 2
  }

  public enum TerminateReply: UInt, Sendable {
    case terminateCancel = 0
    case terminateNow = 1
    case terminateLater = 2
  }

  public typealias ModalResponse = NSModalResponse

  public static let willFinishLaunchingNotification = Notification.Name("NSApplicationWillFinishLaunchingNotification")
  public static let didFinishLaunchingNotification = Notification.Name("NSApplicationDidFinishLaunchingNotification")
  public static let willTerminateNotification = Notification.Name("NSApplicationWillTerminateNotification")
  public static let didBecomeActiveNotification = Notification.Name("NSApplicationDidBecomeActiveNotification")
  public static let didResignActiveNotification = Notification.Name("NSApplicationDidResignActiveNotification")
  public static let didChangeScreenParametersNotification = Notification.Name("NSApplicationDidChangeScreenParametersNotification")

  public static let shared = NSApplication()

  public weak var delegate: (any NSApplicationDelegate)?
  private var currentActivationPolicy: ActivationPolicy = .regular
  public var mainMenu: NSMenu?
  public var applicationIconImage: NSImage = NSImage(size: NSSize(width: 64, height: 64))
  public private(set) var isActive: Bool = false
  public private(set) var isRunning: Bool = false
  public var currentEvent: NSEvent?
  public var modalWindow: NSWindow?

  public var appearance: NSAppearance? {
    didSet {
      NSAppearance._appAppearanceOverride = appearance
      #if !os(macOS)
        if let app = appearance {
          let dark = app.bestMatch(from: [.aqua, .darkAqua]) == .darkAqua
          _ = NativeAPI.Application.shared.setBrightness(dark ? .dark : .light)
        } else {
          _ = NativeAPI.Application.shared.setBrightness(.system)
        }
      #endif
      notifyAppearanceObservers()
      for win in windows { win.contentView?.viewDidChangeEffectiveAppearance() }
    }
  }

  public var effectiveAppearance: NSAppearance {
    appearance ?? NSAppearance.systemAppearance
  }

  private struct WeakWindow {
    weak var window: NSWindow?
  }
  private var trackedWindows: [WeakWindow] = []
  private var appearanceObservers: [UUID: () -> Void] = [:]

  public var windows: [NSWindow] {
    trackedWindows.compactMap(\.window)
  }

  public var keyWindow: NSWindow? {
    windows.first { $0.isKeyWindow && $0.isVisible }
  }

  public var mainWindow: NSWindow? {
    windows.first { $0.isMainWindow && $0.isVisible } ?? keyWindow
  }

  private override init() {
    #if os(Windows)
      cak_enable_per_monitor_dpi()
    #endif
    #if !os(macOS)
      CarbonHotKeyBridge.install()
    #endif
    super.init()
  }

  public override init?(coder: NSCoder) {
    super.init(coder: coder)
  }

  internal func registerWindow(_ window: NSWindow) {
    trackedWindows.removeAll { $0.window == nil || $0.window === window }
    trackedWindows.append(WeakWindow(window: window))
  }

  internal func unregisterWindow(_ window: NSWindow) {
    trackedWindows.removeAll { $0.window == nil || $0.window === window }
  }

  #if !os(macOS)
    public func observeEffectiveAppearance(
      initial: Bool = true,
      _ changeHandler: @escaping () -> Void
    ) -> NSKeyValueObservation {
      let id = UUID()
      appearanceObservers[id] = changeHandler
      if initial { changeHandler() }
      return NSKeyValueObservation { [weak self] in
        self?.appearanceObservers.removeValue(forKey: id)
      }
    }

    public func observe<Value>(
      _ keyPath: KeyPath<NSApplication, Value>,
      options: NSKeyValueObservingOptions = [],
      changeHandler: @escaping @Sendable (NSApplication, NSKeyValueObservedChange<Value>) -> Void
    ) -> NSKeyValueObservation {
      let fireInitial = options.contains(.initial)
      return observeEffectiveAppearance(initial: fireInitial) { [weak self] in
        guard let self else { return }
        changeHandler(self, NSKeyValueObservedChange<Value>())
      }
    }
  #endif

  private func notifyAppearanceObservers() {
    for handler in Array(appearanceObservers.values) {
      handler()
    }
  }

  @discardableResult
  public func setActivationPolicy(_ activationPolicy: ActivationPolicy) -> Bool {
    currentActivationPolicy = activationPolicy
    #if !os(macOS)
      _ = NativeAPI.Application.shared.setDockIconVisible(activationPolicy == .regular)
    #endif
    return true
  }

  public func activationPolicy() -> ActivationPolicy {
    currentActivationPolicy
  }

  public func activate(ignoringOtherApps flag: Bool = true) {
    isActive = true
    #if !os(macOS)
      _ = NativeAPI.Application.shared.show()
    #endif
    keyWindow?.makeKeyAndOrderFront(nil)
  }

  public func activate() {
    activate(ignoringOtherApps: true)
  }

  public func hide(_ sender: Any?) {
    isActive = false
    #if !os(macOS)
      _ = NativeAPI.Application.shared.hide()
    #endif
  }

  public func registerForRemoteNotifications() {}
  public func unregisterForRemoteNotifications() {}

  public func finishLaunching() {
    let willNote = Notification(name: Self.willFinishLaunchingNotification, object: self)
    NotificationCenter.default.post(willNote)
    delegate?.applicationWillFinishLaunching(willNote)

    let didNote = Notification(name: Self.didFinishLaunchingNotification, object: self)
    NotificationCenter.default.post(didNote)
    delegate?.applicationDidFinishLaunching(didNote)
  }

  public func run() {
    guard !isRunning else { return }
    isRunning = true
    #if !os(macOS)
      NativeAPI.Application.shared.installMainQueue()
    #endif
    finishLaunching()
    #if !os(macOS)
      _ = NativeAPI.Application.shared.run()
    #endif
    isRunning = false
  }

  public func terminate(_ sender: Any?) {
    if let reply = delegate?.applicationShouldTerminate(self) {
      switch reply {
      case .terminateCancel:
        return
      case .terminateLater:
        return
      case .terminateNow:
        break
      }
    }
    performFinalTermination()
  }

  public func reply(toApplicationShouldTerminate shouldTerminate: Bool) {
    guard shouldTerminate else { return }
    performFinalTermination()
  }

  private func performFinalTermination() {
    let termNote = Notification(name: Self.willTerminateNotification, object: self)
    NotificationCenter.default.post(termNote)
    delegate?.applicationWillTerminate(termNote)
    #if !os(macOS)
      NativeAPI.Application.shared.quit(0)
    #endif
  }
}

// Apple Event minimal shims used by AppDelegate launch-cause checks
public let kCoreEventClass: UInt32 = 0x61657674
public let kAEOpenApplication: UInt32 = 0x6F617070
public let kAEQuitApplication: UInt32 = 0x71756974
public let keySenderPIDAttr: UInt32 = 0x73706964
public let keyAEPropData: UInt32 = 0x70726474
public let keyAELaunchedAsLogInItem: UInt32 = 0x6C636E74

open class NSAppleEventDescriptor: NSObject {
  public var eventClass: UInt32 = 0
  public var eventID: UInt32 = 0
  public var int32Value: Int32 = 0
  public var enumCodeValue: UInt32 = 0
  public var stringValue: String?
  public func attributeDescriptor(forKeyword keyword: UInt32) -> NSAppleEventDescriptor? { nil }
  public func paramDescriptor(forKeyword keyword: UInt32) -> NSAppleEventDescriptor? { nil }
}

open class NSAppleEventManager: NSObject, @unchecked Sendable {
  private static let sharedInstance = NSAppleEventManager()
  public static func shared() -> NSAppleEventManager { sharedInstance }
  public var currentAppleEvent: NSAppleEventDescriptor? {
    #if !os(macOS)
      if CommandLine.arguments.contains("--background") { return nil }
      let desc = NSAppleEventDescriptor()
      desc.eventClass = kCoreEventClass
      desc.eventID = kAEOpenApplication
      return desc
    #else
      return nil
    #endif
  }
}

open class NSAppleScript: NSObject {
  public static let errorMessage = "NSAppleScriptErrorMessage"
  public static let errorNumber = "NSAppleScriptErrorNumber"
  public let source: String?

  public init?(source: String) {
    self.source = source
    super.init()
  }

  @discardableResult
  public func executeAndReturnError(_ errorInfo: UnsafeMutablePointer<NSDictionary?>?) -> NSAppleEventDescriptor {
    errorInfo?.pointee = nil
    return NSAppleEventDescriptor()
  }
}

#if !os(macOS)
  public struct AutoreleasingUnsafeMutablePointer<Pointee> {
    public var pointee: Pointee
    public init(_ pointee: Pointee) { self.pointee = pointee }
  }
#endif
