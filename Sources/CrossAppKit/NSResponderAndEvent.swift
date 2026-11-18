import Foundation
#if !os(macOS)
  import NativeAPI
#endif
#if os(Windows)
  import CAppKitWindows
#endif

@MainActor
open class NSResponder: NSObject {
  public weak var nextResponder: NSResponder?

  public override init() {
    super.init()
  }

  public init?(coder: NSCoder) {
    super.init()
  }

  open var acceptsFirstResponder: Bool { false }
  open func becomeFirstResponder() -> Bool { true }
  open func resignFirstResponder() -> Bool { true }
  open var undoManager: UndoManager? { nextResponder?.undoManager }

  open func keyDown(with event: NSEvent) { nextResponder?.keyDown(with: event) }
  open func keyUp(with event: NSEvent) { nextResponder?.keyUp(with: event) }
  open func flagsChanged(with event: NSEvent) { nextResponder?.flagsChanged(with: event) }
  open func performKeyEquivalent(with event: NSEvent) -> Bool {
    for sub in (self as? NSView)?.subviews ?? [] {
      if sub.performKeyEquivalent(with: event) { return true }
    }
    return false
  }
  open func mouseDown(with event: NSEvent) { nextResponder?.mouseDown(with: event) }
  open func mouseUp(with event: NSEvent) { nextResponder?.mouseUp(with: event) }
  open func mouseDragged(with event: NSEvent) { nextResponder?.mouseDragged(with: event) }
  open func rightMouseDown(with event: NSEvent) { nextResponder?.rightMouseDown(with: event) }
  open func rightMouseUp(with event: NSEvent) { nextResponder?.rightMouseUp(with: event) }
  open func mouseMoved(with event: NSEvent) { nextResponder?.mouseMoved(with: event) }
  open func mouseEntered(with event: NSEvent) { nextResponder?.mouseEntered(with: event) }
  open func mouseExited(with event: NSEvent) { nextResponder?.mouseExited(with: event) }
  open func scrollWheel(with event: NSEvent) { nextResponder?.scrollWheel(with: event) }
  open func cursorUpdate(with event: NSEvent) { nextResponder?.cursorUpdate(with: event) }

  open func doCommand(by selector: Selector) {}
  open func insertText(_ insertString: Any) {}
  open func insertNewline(_ sender: Any?) {}
  open func insertLineBreak(_ sender: Any?) {}
  open func insertNewlineIgnoringFieldEditor(_ sender: Any?) {}
  open func insertParagraphSeparator(_ sender: Any?) {}
  open func insertTab(_ sender: Any?) {}
  open func insertBacktab(_ sender: Any?) {}
  open func insertTabIgnoringFieldEditor(_ sender: Any?) {}
  open func deleteBackward(_ sender: Any?) {}
  open func deleteForward(_ sender: Any?) {}
  open func cancelOperation(_ sender: Any?) {}
}

open class NSEvent: NSObject, @unchecked Sendable {
  public enum EventType: UInt, Sendable {
    case leftMouseDown = 1
    case leftMouseUp = 2
    case rightMouseDown = 3
    case rightMouseUp = 4
    case mouseMoved = 5
    case leftMouseDragged = 6
    case rightMouseDragged = 7
    case mouseEntered = 8
    case mouseExited = 9
    case keyDown = 10
    case keyUp = 11
    case flagsChanged = 12
    case appKitDefined = 13
    case systemDefined = 14
    case applicationDefined = 15
    case periodic = 16
    case cursorUpdate = 17
    case scrollWheel = 22
    case otherMouseDown = 25
    case otherMouseUp = 26
    case otherMouseDragged = 27
  }

  public static let foreverDuration: TimeInterval = .greatestFiniteMagnitude

  public struct EventTypeMask: OptionSet, Sendable {
    public let rawValue: UInt64
    public init(rawValue: UInt64) { self.rawValue = rawValue }
    public init(type: EventType) { self.rawValue = 1 << UInt64(type.rawValue) }

    public static let leftMouseDown = EventTypeMask(type: .leftMouseDown)
    public static let leftMouseUp = EventTypeMask(type: .leftMouseUp)
    public static let rightMouseDown = EventTypeMask(type: .rightMouseDown)
    public static let rightMouseUp = EventTypeMask(type: .rightMouseUp)
    public static let mouseMoved = EventTypeMask(type: .mouseMoved)
    public static let leftMouseDragged = EventTypeMask(type: .leftMouseDragged)
    public static let rightMouseDragged = EventTypeMask(type: .rightMouseDragged)
    public static let mouseEntered = EventTypeMask(type: .mouseEntered)
    public static let mouseExited = EventTypeMask(type: .mouseExited)
    public static let keyDown = EventTypeMask(type: .keyDown)
    public static let keyUp = EventTypeMask(type: .keyUp)
    public static let flagsChanged = EventTypeMask(type: .flagsChanged)
    public static let cursorUpdate = EventTypeMask(type: .cursorUpdate)
    public static let scrollWheel = EventTypeMask(type: .scrollWheel)
    public static let otherMouseDown = EventTypeMask(type: .otherMouseDown)
    public static let otherMouseUp = EventTypeMask(type: .otherMouseUp)
    public static let otherMouseDragged = EventTypeMask(type: .otherMouseDragged)
    public static let any = EventTypeMask(rawValue: UInt64.max)

    public func matches(_ type: EventType) -> Bool {
      contains(EventTypeMask(type: type))
    }
  }

  public struct ModifierFlags: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }

    public static let capsLock = ModifierFlags(rawValue: 1 << 16)
    public static let shift = ModifierFlags(rawValue: 1 << 17)
    public static let control = ModifierFlags(rawValue: 1 << 18)
    public static let option = ModifierFlags(rawValue: 1 << 19)
    public static let command = ModifierFlags(rawValue: 1 << 20)
    public static let numericPad = ModifierFlags(rawValue: 1 << 21)
    public static let help = ModifierFlags(rawValue: 1 << 22)
    public static let function = ModifierFlags(rawValue: 1 << 23)
    public static let deviceIndependentFlagsMask = ModifierFlags(rawValue: 0xffff0000)
  }

  public struct SpecialKey: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }
    public var unicodeScalar: UnicodeScalar { UnicodeScalar(rawValue) ?? UnicodeScalar(0)! }

    public static let upArrow = SpecialKey(rawValue: 0xF700)
    public static let downArrow = SpecialKey(rawValue: 0xF701)
    public static let leftArrow = SpecialKey(rawValue: 0xF702)
    public static let rightArrow = SpecialKey(rawValue: 0xF703)
    public static let delete = SpecialKey(rawValue: 0x007F)
    public static let deleteForward = SpecialKey(rawValue: 0xF728)
    public static let home = SpecialKey(rawValue: 0xF729)
    public static let end = SpecialKey(rawValue: 0xF72B)
    public static let pageUp = SpecialKey(rawValue: 0xF72C)
    public static let pageDown = SpecialKey(rawValue: 0xF72D)
    public static let carriageReturn = SpecialKey(rawValue: 0x000D)
    public static let enter = SpecialKey(rawValue: 0x0003)
    public static let tab = SpecialKey(rawValue: 0x0009)
    public static let backTab = SpecialKey(rawValue: 0x0019)
  }

  public let type: EventType
  public let locationInWindow: NSPoint
  public let modifierFlags: ModifierFlags
  public let timestamp: TimeInterval
  public let windowNumber: Int
  public weak var window: NSWindow?
  public let characters: String?
  public let charactersIgnoringModifiers: String?
  public let isARepeat: Bool
  public let keyCode: UInt16
  public let buttonNumber: Int
  public let clickCount: Int
  public let scrollingDeltaX: CGFloat
  public let scrollingDeltaY: CGFloat
  public let data1: Int
  public let data2: Int

  public var specialKey: SpecialKey? {
    guard let scalar = charactersIgnoringModifiers?.unicodeScalars.first else { return nil }
    let v = Int(scalar.value)
    if (0xF700...0xF8FF).contains(v) || v == 0x7F || v == 0x0D || v == 0x03 || v == 0x09 || v == 0x19 {
      return SpecialKey(rawValue: v)
    }
    return nil
  }

  public init(
    type: EventType,
    locationInWindow: NSPoint = .zero,
    modifierFlags: ModifierFlags = [],
    timestamp: TimeInterval = ProcessInfo.processInfo.systemUptime,
    windowNumber: Int = 0,
    window: NSWindow? = nil,
    characters: String? = nil,
    charactersIgnoringModifiers: String? = nil,
    isARepeat: Bool = false,
    keyCode: UInt16 = 0,
    buttonNumber: Int = 0,
    clickCount: Int = 1,
    scrollingDeltaX: CGFloat = 0,
    scrollingDeltaY: CGFloat = 0,
    data1: Int = 0,
    data2: Int = 0
  ) {
    self.type = type
    self.locationInWindow = locationInWindow
    self.modifierFlags = modifierFlags
    self.timestamp = timestamp
    self.windowNumber = windowNumber
    self.window = window
    self.characters = characters
    self.charactersIgnoringModifiers = charactersIgnoringModifiers
    self.isARepeat = isARepeat
    self.keyCode = keyCode
    self.buttonNumber = buttonNumber
    self.clickCount = clickCount
    self.scrollingDeltaX = scrollingDeltaX
    self.scrollingDeltaY = scrollingDeltaY
    self.data1 = data1
    self.data2 = data2
    super.init()
  }

  public static func keyEvent(
    with type: EventType,
    location: NSPoint,
    modifierFlags flags: ModifierFlags,
    timestamp time: TimeInterval,
    windowNumber wNum: Int,
    context unusedPassNil: NSGraphicsContext?,
    characters keys: String,
    charactersIgnoringModifiers ukeys: String,
    isARepeat flag: Bool,
    keyCode code: UInt16
  ) -> NSEvent? {
    NSEvent(
      type: type,
      locationInWindow: location,
      modifierFlags: flags,
      timestamp: time,
      windowNumber: wNum,
      characters: keys,
      charactersIgnoringModifiers: ukeys,
      isARepeat: flag,
      keyCode: code
    )
  }

  public static func otherEvent(
    with type: EventType,
    location: NSPoint,
    modifierFlags flags: ModifierFlags,
    timestamp time: TimeInterval,
    windowNumber wNum: Int,
    context unusedPassNil: NSGraphicsContext?,
    subtype: Int16,
    data1 d1: Int,
    data2 d2: Int
  ) -> NSEvent? {
    NSEvent(
      type: type,
      locationInWindow: location,
      modifierFlags: flags,
      timestamp: time,
      windowNumber: wNum,
      data1: d1,
      data2: d2
    )
  }

  public static var mouseLocation: NSPoint {
    #if !os(macOS)
      let pt = NativeAPI.DisplayManager.shared.getCursorPosition()
      return CrossAppKitCoordinates.pointFromNativeTopLeft(x: pt.x, y: pt.y)
    #else
      return .zero
    #endif
  }

  public static var modifierFlags: ModifierFlags {
    #if os(Windows)
      return ModifierFlags(rawValue: UInt(cak_modifier_flags()))
    #else
      return []
    #endif
  }

  public static var doubleClickInterval: TimeInterval { 0.5 }

  private final class MonitorToken {
    let id = UUID()
    let isGlobal: Bool
    init(isGlobal: Bool) { self.isGlobal = isGlobal }
  }

  nonisolated(unsafe) private static var localMonitors: [(id: UUID, mask: EventTypeMask, handler: (NSEvent) -> NSEvent?)] = []
  nonisolated(unsafe) private static var globalMonitors: [(id: UUID, mask: EventTypeMask, handler: (NSEvent) -> Void)] = []

  public static func addLocalMonitorForEvents(
    matching mask: EventTypeMask,
    handler block: @escaping (NSEvent) -> NSEvent?
  ) -> Any? {
    let token = MonitorToken(isGlobal: false)
    localMonitors.append((token.id, mask, block))
    return token
  }

  public static func addGlobalMonitorForEvents(
    matching mask: EventTypeMask,
    handler block: @escaping (NSEvent) -> Void
  ) -> Any? {
    let token = MonitorToken(isGlobal: true)
    globalMonitors.append((token.id, mask, block))
    return token
  }

  public static func removeMonitor(_ eventMonitor: Any) {
    guard let token = eventMonitor as? MonitorToken else { return }
    if token.isGlobal {
      globalMonitors.removeAll { $0.id == token.id }
    } else {
      localMonitors.removeAll { $0.id == token.id }
    }
  }

  public static func dispatchLocalMonitors(_ event: NSEvent) -> NSEvent? {
    var current: NSEvent? = event
    for entry in localMonitors where entry.mask.matches(event.type) {
      guard let ev = current else { return nil }
      current = entry.handler(ev)
    }
    return current
  }

  public static func dispatchGlobalMonitors(_ event: NSEvent) {
    for entry in globalMonitors where entry.mask.matches(event.type) {
      entry.handler(event)
    }
  }

  /// Translates a Win32 virtual keycode (`VK_*`) into macOS HIToolbox `kVK_*`.
  public static func carbonKeyCode(fromWin32VK vk: Int) -> UInt16 {
    switch vk {
    case 0x0D: return 0x24 // Return
    case 0x09: return 0x30 // Tab
    case 0x20: return 0x31 // Space
    case 0x08: return 0x33 // Backspace -> kVK_Delete
    case 0x1B: return 0x35 // Escape
    case 0x2E: return 0x75 // Delete -> kVK_ForwardDelete
    case 0x25: return 0x7B // Left
    case 0x27: return 0x7C // Right
    case 0x28: return 0x7D // Down
    case 0x26: return 0x7E // Up
    case 0x24: return 0x73 // Home
    case 0x23: return 0x77 // End
    case 0x21: return 0x74 // PageUp
    case 0x22: return 0x79 // PageDown
    case 0x41: return 0x00 // A
    case 0x42: return 0x0B // B
    case 0x43: return 0x08 // C
    case 0x44: return 0x02 // D
    case 0x45: return 0x0E // E
    case 0x46: return 0x03 // F
    case 0x47: return 0x05 // G
    case 0x48: return 0x04 // H
    case 0x49: return 0x22 // I
    case 0x4A: return 0x26 // J
    case 0x4B: return 0x28 // K
    case 0x4C: return 0x25 // L
    case 0x4D: return 0x2E // M
    case 0x4E: return 0x2D // N
    case 0x4F: return 0x1F // O
    case 0x50: return 0x23 // P
    case 0x51: return 0x0C // Q
    case 0x52: return 0x0F // R
    case 0x53: return 0x01 // S
    case 0x54: return 0x11 // T
    case 0x55: return 0x20 // U
    case 0x56: return 0x09 // V
    case 0x57: return 0x0D // W
    case 0x58: return 0x07 // X
    case 0x59: return 0x10 // Y
    case 0x5A: return 0x06 // Z
    case 0x30: return 0x1D // 0
    case 0x31: return 0x12 // 1
    case 0x32: return 0x13 // 2
    case 0x33: return 0x14 // 3
    case 0x34: return 0x15 // 4
    case 0x35: return 0x17 // 5
    case 0x36: return 0x16 // 6
    case 0x37: return 0x1A // 7
    case 0x38: return 0x1C // 8
    case 0x39: return 0x19 // 9
    case 0xBC: return 0x2B // ,
    case 0xBE: return 0x2F // .
    case 0xBD: return 0x1B // -
    case 0xBB: return 0x18 // =
    case 0x70: return 0x7A // F1
    case 0x71: return 0x78 // F2
    case 0x72: return 0x63 // F3
    case 0x73: return 0x76 // F4
    case 0x74: return 0x60 // F5
    case 0x75: return 0x61 // F6
    case 0x76: return 0x62 // F7
    case 0x77: return 0x64 // F8
    case 0x78: return 0x65 // F9
    case 0x79: return 0x6D // F10
    case 0x7A: return 0x67 // F11
    case 0x7B: return 0x6F // F12
    default: return UInt16(vk & 0xFF)
    }
  }
}

open class NSCursor: NSObject, @unchecked Sendable {
  private let kind: Int
  nonisolated(unsafe) public private(set) static var current: NSCursor = .arrow

  private init(kind: Int) {
    self.kind = kind
    super.init()
  }

  public static let arrow = NSCursor(kind: 0)
  public static let iBeam = NSCursor(kind: 1)
  public static let pointingHand = NSCursor(kind: 2)
  public static let crosshair = NSCursor(kind: 3)
  public static let resizeLeftRight = NSCursor(kind: 4)
  public static let resizeUpDown = NSCursor(kind: 5)
  public static let openHand = NSCursor(kind: 2)
  public static let closedHand = NSCursor(kind: 2)

  public func set() {
    Self.current = self
    #if os(Windows)
      cak_set_cursor(Int32(kind))
    #endif
  }

  public func push() { set() }
  public static func pop() { arrow.set() }
}

public protocol NSHapticFeedbackPerformer {
  func perform(_ pattern: NSHapticFeedbackManager.FeedbackPattern, performanceTime: NSHapticFeedbackManager.PerformanceTime)
}

public final class NSHapticFeedbackManager: NSObject, @unchecked Sendable {
  public enum FeedbackPattern: Int, Sendable {
    case generic = 0
    case alignment = 1
    case levelChange = 2
  }

  public enum PerformanceTime: UInt, Sendable {
    case `default` = 0
    case now = 1
    case drawCompleted = 2
  }

  private struct DefaultPerformer: NSHapticFeedbackPerformer {
    func perform(_ pattern: FeedbackPattern, performanceTime: PerformanceTime) {}
  }

  public static var defaultPerformer: any NSHapticFeedbackPerformer { DefaultPerformer() }
}
