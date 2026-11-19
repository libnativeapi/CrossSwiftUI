import Foundation

#if !os(macOS)
  public typealias CFTypeRef = AnyObject
  public typealias CFTypeID = UInt
  public typealias CFString = NSString
  public typealias CFNumber = NSNumber
  public typealias CFBoolean = NSNumber
  public typealias CFDictionary = NSDictionary
  public typealias CFArray = NSArray
  public typealias CFData = NSData
  public typealias CFURL = NSURL
  public typealias CFAllocator = AnyObject
  public typealias CFTimeInterval = Double
  public typealias CFIndex = Int

  public struct CFRange: Equatable, Hashable, Sendable {
    public var location: CFIndex
    public var length: CFIndex
    public init(location: CFIndex = 0, length: CFIndex = 0) {
      self.location = location
      self.length = length
    }
  }

  public struct DarwinBoolean: Equatable, Hashable, ExpressibleByBooleanLiteral, Sendable {
    public var boolValue: Bool
    public init(_ value: Bool) { self.boolValue = value }
    public init(booleanLiteral value: Bool) { self.boolValue = value }
  }

  public let kCFAllocatorDefault: CFAllocator? = nil
  public let kCFBooleanTrue: CFBoolean = NSNumber(value: true)
  public let kCFBooleanFalse: CFBoolean = NSNumber(value: false)

  private let _cfBooleanTypeID: CFTypeID = 21
  private let _cfNumberTypeID: CFTypeID = 22
  private let _cfStringTypeID: CFTypeID = 7
  private let _cfOtherTypeID: CFTypeID = 1

  public func CFBooleanGetTypeID() -> CFTypeID { _cfBooleanTypeID }
  public func CFNumberGetTypeID() -> CFTypeID { _cfNumberTypeID }
  public func CFStringGetTypeID() -> CFTypeID { _cfStringTypeID }
  public func CFEqual(_ cf1: CFTypeRef?, _ cf2: CFTypeRef?) -> Bool {
    guard let cf1, let cf2 else { return cf1 == nil && cf2 == nil }
    if let o1 = cf1 as? NSObject, let o2 = cf2 as? NSObject { return o1.isEqual(o2) }
    return cf1 === cf2
  }
  public func CFHash(_ cf: CFTypeRef?) -> UInt {
    guard let cf else { return 0 }
    if let o = cf as? NSObject { return UInt(bitPattern: o.hash) }
    return UInt(bitPattern: ObjectIdentifier(cf))
  }

  public func CFGetTypeID(_ cf: CFTypeRef?) -> CFTypeID {
    guard let cf else { return 0 }
    if let num = cf as? NSNumber {
      // Distinguish Bool-backed NSNumber from numeric NSNumber via objCType / Swift Bool bridge
      if type(of: num) == type(of: kCFBooleanTrue) && (num === kCFBooleanTrue || num === kCFBooleanFalse) {
        return _cfBooleanTypeID
      }
      if let s = String(validatingUTF8: num.objCType), s == "B" || s == "c" {
        return _cfBooleanTypeID
      }
      return _cfNumberTypeID
    }
    if cf is NSString || cf is String { return _cfStringTypeID }
    return _cfOtherTypeID
  }

  public final class CFMachPort: @unchecked Sendable {}
  public final class CFRunLoopSource: @unchecked Sendable {}
  public final class CFRunLoop: @unchecked Sendable {}
  public struct CFRunLoopMode: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let commonModes = CFRunLoopMode(rawValue: "kCFRunLoopCommonModes")
    public static let defaultMode = CFRunLoopMode(rawValue: "kCFRunLoopDefaultMode")
  }

  public func CFRunLoopGetCurrent() -> CFRunLoop? { CFRunLoop() }
  public func CFRunLoopGetMain() -> CFRunLoop? { CFRunLoop() }
  public func CFRunLoopRun() {}
  public func CFRunLoopStop(_ rl: CFRunLoop?) {}
  public func CFRunLoopWakeUp(_ rl: CFRunLoop?) {}
  public func CFRunLoopPerformBlock(_ rl: CFRunLoop?, _ mode: Any?, _ block: @escaping () -> Void) {}
  public func CFRunLoopAddSource(_ rl: CFRunLoop?, _ source: CFRunLoopSource?, _ mode: CFRunLoopMode?) {}
  public func CFRunLoopRemoveSource(_ rl: CFRunLoop?, _ source: CFRunLoopSource?, _ mode: CFRunLoopMode?) {}
  public func CFMachPortCreateRunLoopSource(_ allocator: CFAllocator?, _ port: CFMachPort?, _ order: CFIndex) -> CFRunLoopSource? { nil }
  public func CFMachPortInvalidate(_ port: CFMachPort?) {}
  public func CFRunLoopSourceIsValid(_ source: CFRunLoopSource?) -> Bool { false }

  public final class CFNotificationCenter: @unchecked Sendable {}
  public struct CFNotificationName: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
  }
  public enum CFNotificationSuspensionBehavior: CFIndex, Sendable {
    case drop = 1
    case coalesce = 2
    case hold = 3
    case deliverImmediately = 4
  }
  public func CFNotificationCenterGetDarwinNotifyCenter() -> CFNotificationCenter? { CFNotificationCenter() }
  public func CFNotificationCenterGetDistributedCenter() -> CFNotificationCenter? { CFNotificationCenter() }
  public func CFNotificationCenterAddObserver(
    _ center: CFNotificationCenter?,
    _ observer: UnsafeRawPointer?,
    _ callBack: (@Sendable (CFNotificationCenter?, UnsafeMutableRawPointer?, CFNotificationName?, UnsafeRawPointer?, CFDictionary?) -> Void)?,
    _ name: CFString?,
    _ object: UnsafeRawPointer?,
    _ suspensionBehavior: CFNotificationSuspensionBehavior
  ) {}
  public func CFNotificationCenterRemoveObserver(
    _ center: CFNotificationCenter?,
    _ observer: UnsafeRawPointer?,
    _ name: CFNotificationName?,
    _ object: UnsafeRawPointer?
  ) {}
  public func CFNotificationCenterRemoveEveryObserver(_ center: CFNotificationCenter?, _ observer: UnsafeRawPointer?) {}

  public let kCFPreferencesCurrentApplication: CFString = "kCFPreferencesCurrentApplication"
  public let kCFPreferencesAnyApplication: CFString = "kCFPreferencesAnyApplication"
  public let kCFPreferencesCurrentUser: CFString = "kCFPreferencesCurrentUser"
  public let kCFPreferencesAnyHost: CFString = "kCFPreferencesAnyHost"
  public let kCFPreferencesCurrentHost: CFString = "kCFPreferencesCurrentHost"
  public func CFPreferencesCopyAppValue(_ key: CFString, _ applicationID: CFString) -> CFTypeRef? { nil }
  public func CFPreferencesCopyKeyList(_ applicationID: CFString, _ userName: CFString, _ hostName: CFString) -> CFArray? { nil }
  public func CFPreferencesCopyValue(_ key: CFString, _ applicationID: CFString, _ userName: CFString, _ hostName: CFString) -> CFTypeRef? { nil }
  public final class CFUUID: @unchecked Sendable {
    public let uuidString: String
    public init(_ uuidString: String = UUID().uuidString) { self.uuidString = uuidString }
  }

  public func CFUUIDCreateString(_ alloc: CFAllocator?, _ uuid: CFUUID?) -> CFString? {
    guard let uuid else { return nil }
    return uuid.uuidString as NSString
  }

  public func CFPreferencesAppSynchronize(_ applicationID: CFString) -> Bool { true }
#endif
