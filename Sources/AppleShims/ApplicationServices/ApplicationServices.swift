import Foundation
import CoreFoundation
import CoreGraphics

#if !os(macOS)
  public final class AXUIElement: @unchecked Sendable {
    public let pid: Int32
    public let hwnd: Int64
    public init(pid: Int32 = 0, hwnd: Int64 = 0) {
      self.pid = pid
      self.hwnd = hwnd
    }
  }
  public final class AXValue: @unchecked Sendable {}
  public func AXValueGetTypeID() -> CFTypeID { 0 }

  public enum AXError: Int32, Sendable, Equatable {
    case success = 0
    case failure = -25200
    case illegalArgument = -25201
    case invalidUIElement = -25202
    case invalidUIElementObserver = -25203
    case cannotComplete = -25204
    case attributeUnsupported = -25205
    case actionUnsupported = -25206
    case notificationUnsupported = -25207
    case notImplemented = -25208
    case notificationAlreadyRegistered = -25209
    case notificationNotRegistered = -25210
    case apiDisabled = -25211
    case noValue = -25212
    case parameterizedAttributeUnsupported = -25213
    case notEnoughPrecision = -25214
  }

  public enum AXValueType: UInt32, Sendable {
    case illegal = 0
    case cgPoint = 1
    case cgSize = 2
    case cgRect = 3
    case cfRange = 4
    case axError = 5
  }

  public let kAXTrustedCheckOptionPrompt: Unmanaged<CFString> = Unmanaged.passUnretained("AXTrustedCheckOptionPrompt" as CFString)
  public let kAXWindowsAttribute = "AXWindows"
  public let kAXFrontmostAttribute = "AXFrontmost"
  public let kAXHiddenAttribute = "AXHidden"
  public let kAXMinimizeButtonAttribute = "AXMinimizeButton"
  public let kAXSelectedTextMarkerRangeAttribute = "AXSelectedTextMarkerRange"
  public let kAXStringForTextMarkerRangeParameterizedAttribute = "AXStringForTextMarkerRange"
  public let kAXFocusedWindowAttribute = "AXFocusedWindow"
  public let kAXMainWindowAttribute = "AXMainWindow"
  public let kAXFocusedUIElementAttribute = "AXFocusedUIElement"
  public let kAXPositionAttribute = "AXPosition"
  public let kAXSizeAttribute = "AXSize"
  public let kAXTitleAttribute = "AXTitle"
  public let kAXRoleAttribute = "AXRole"
  public let kAXSubroleAttribute = "AXSubrole"
  public let kAXMinimizedAttribute = "AXMinimized"
  public let kAXChildrenAttribute = "AXChildren"
  public let kAXMenuBarAttribute = "AXMenuBar"
  public let kAXEnabledAttribute = "AXEnabled"
  public let kAXValueAttribute = "AXValue"
  public let kAXSelectedTextAttribute = "AXSelectedText"
  public let kAXSelectedTextRangeAttribute = "AXSelectedTextRange"
  public let kAXNumberOfCharactersAttribute = "AXNumberOfCharacters"
  public let kAXCloseButtonAttribute = "AXCloseButton"
  public let kAXFullScreenButtonAttribute = "AXFullScreenButton"
  public let kAXRaiseAction = "AXRaise"
  public let kAXPressAction = "AXPress"
  public let kAXStandardWindowSubrole = "AXStandardWindow"
  public let kAXDialogSubrole = "AXDialog"
  public let kAXWindowRole = "AXWindow"
  public let kAXMenuBarItemRole = "AXMenuBarItem"
  public let kAXMenuItemRole = "AXMenuItem"
  public let kAXMenuRole = "AXMenu"
  public let kAXMenuItemCmdCharAttribute = "AXMenuItemCmdChar"
  public let kAXMenuItemCmdModifiersAttribute = "AXMenuItemCmdModifiers"
  public let kAXMenuItemCmdVirtualKeyAttribute = "AXMenuItemCmdVirtualKey"
  public let kAXMenuItemMarkCharAttribute = "AXMenuItemMarkChar"

  public func AXIsProcessTrusted() -> Bool { true }
  public func AXIsProcessTrustedWithOptions(_ options: CFDictionary?) -> Bool { true }
  public func AXUIElementCreateApplication(_ pid: Int32) -> AXUIElement { AXUIElement() }
  public func AXUIElementCreateSystemWide() -> AXUIElement { AXUIElement() }
  public func AXUIElementCopyAttributeValue(_ element: AXUIElement, _ attribute: CFString, _ value: UnsafeMutablePointer<CFTypeRef?>) -> AXError {
    value.pointee = nil
    return .notImplemented
  }
  public func AXUIElementCopyAttributeNames(_ element: AXUIElement, _ names: UnsafeMutablePointer<CFArray?>) -> AXError {
    names.pointee = nil
    return .notImplemented
  }
  public struct AXCopyMultipleAttributeOptions: OptionSet, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let stopOnError = AXCopyMultipleAttributeOptions(rawValue: 1 << 0)
  }
  public func AXUIElementCopyMultipleAttributeValues(
    _ element: AXUIElement,
    _ attributes: CFArray,
    _ options: AXCopyMultipleAttributeOptions,
    _ values: UnsafeMutablePointer<CFArray?>
  ) -> AXError {
    values.pointee = nil
    return .notImplemented
  }
  public func AXUIElementCopyParameterizedAttributeValue(
    _ element: AXUIElement,
    _ parameterizedAttribute: CFString,
    _ parameter: CFTypeRef,
    _ result: UnsafeMutablePointer<CFTypeRef?>
  ) -> AXError {
    result.pointee = nil
    return .notImplemented
  }
  public func AXUIElementCopyActionNames(_ element: AXUIElement, _ names: UnsafeMutablePointer<CFArray?>) -> AXError {
    names.pointee = nil
    return .notImplemented
  }
  public func AXUIElementIsAttributeSettable(
    _ element: AXUIElement,
    _ attribute: CFString,
    _ settable: UnsafeMutablePointer<DarwinBoolean>
  ) -> AXError {
    settable.pointee = DarwinBoolean(false)
    return .notImplemented
  }
  public func AXUIElementGetTypeID() -> CFTypeID { 0 }
  public func AXTextMarkerRangeGetTypeID() -> CFTypeID { 0 }
  public func AXUIElementSetAttributeValue(_ element: AXUIElement, _ attribute: CFString, _ value: CFTypeRef) -> AXError { .notImplemented }
  public func AXUIElementPerformAction(_ element: AXUIElement, _ action: CFString) -> AXError { .notImplemented }
  public func AXUIElementGetPid(_ element: AXUIElement, _ pid: UnsafeMutablePointer<Int32>) -> AXError {
    pid.pointee = 0
    return .notImplemented
  }
  public func AXUIElementSetMessagingTimeout(_ element: AXUIElement, _ timeoutInSeconds: Float) -> AXError { .success }
  public func AXValueCreate(_ theType: AXValueType, _ valuePtr: UnsafeRawPointer) -> AXValue? { AXValue() }
  public func AXValueGetValue(_ value: AXValue, _ theType: AXValueType, _ valuePtr: UnsafeMutableRawPointer) -> Bool { false }
  public func AXValueGetType(_ value: AXValue) -> AXValueType { .illegal }

  // Carbon HIToolbox Text Input Sources (TIS) shims
  public final class TISInputSource: NSObject, @unchecked Sendable {}
  public let kTISNotifyEnabledKeyboardInputSourcesChanged: CFString = "com.apple.Carbon.TISNotifyEnabledKeyboardInputSourcesChanged" as NSString
  public let kTISPropertyInputSourceIsASCIICapable: CFString = "TISPropertyInputSourceIsASCIICapable" as NSString
  public let kTISPropertyInputModeID: CFString = "TISPropertyInputModeID" as NSString
  public let kTISPropertyLocalizedName: CFString = "TISPropertyLocalizedName" as NSString
  public let kTISPropertyInputSourceID: CFString = "TISPropertyInputSourceID" as NSString
  public let kTISPropertyInputSourceCategory: CFString = "TISPropertyInputSourceCategory" as NSString
  public let kTISCategoryKeyboardInputSource: CFString = "TISCategoryKeyboardInputSource" as NSString
  public let kTISPropertyInputSourceIsSelectCapable: CFString = "TISPropertyInputSourceIsSelectCapable" as NSString

  @discardableResult
  public func TISSelectInputSource(_ inputSource: TISInputSource) -> Int32 { 0 }
  public func TISCopyCurrentASCIICapableKeyboardInputSource() -> Unmanaged<TISInputSource>? { nil }
  public func TISCopyCurrentKeyboardInputSource() -> Unmanaged<TISInputSource>? { nil }
  public func TISCreateInputSourceList(_ properties: CFDictionary?, _ includeAllInstalled: Bool) -> Unmanaged<CFArray>? { nil }
  public func TISGetInputSourceProperty(_ inputSource: TISInputSource, _ propertyKey: CFString) -> UnsafeMutableRawPointer? { nil }
#endif
