import Foundation
import CoreFoundation

#if !os(macOS)
  public typealias OSStatus = Int32
  public let errSecSuccess: OSStatus = 0
  public let errSecItemNotFound: OSStatus = -25300
  public let errSecDuplicateItem: OSStatus = -25299
  public let errSecUnimplemented: OSStatus = -4
  public let errSecParam: OSStatus = -50

  public let kSecClass: CFString = "class"
  public let kSecClassGenericPassword: CFString = "genp"
  public let kSecAttrService: CFString = "svce"
  public let kSecAttrAccount: CFString = "acct"
  public let kSecAttrAccessible: CFString = "pdmn"
  public let kSecAttrAccessibleAfterFirstUnlock: CFString = "ck"
  public let kSecAttrAccessibleWhenUnlocked: CFString = "ak"
  public let kSecValueData: CFString = "v_Data"
  public let kSecReturnData: CFString = "r_Data"
  public let kSecMatchLimit: CFString = "m_Limit"
  public let kSecMatchLimitOne: CFString = "m_LimitOne"
  public let kSecMatchLimitAll: CFString = "m_LimitAll"
  public let kSecReturnAttributes: CFString = "r_Attributes"
  public let kSecUseDataProtectionKeychain: CFString = "nleg"

  public func SecItemCopyMatching(_ query: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
    result?.pointee = nil
    return errSecItemNotFound
  }
  public func SecItemAdd(_ attributes: CFDictionary, _ result: UnsafeMutablePointer<CFTypeRef?>?) -> OSStatus {
    errSecUnimplemented
  }
  public func SecItemUpdate(_ query: CFDictionary, _ attributesToUpdate: CFDictionary) -> OSStatus {
    errSecUnimplemented
  }
  public func SecItemDelete(_ query: CFDictionary) -> OSStatus {
    errSecItemNotFound
  }

  public final class SecRandom: @unchecked Sendable {}
  public let kSecRandomDefault: SecRandom? = nil
  public func SecRandomCopyBytes(_ rnd: SecRandom?, _ count: Int, _ bytes: UnsafeMutableRawPointer) -> Int32 {
    let ptr = bytes.assumingMemoryBound(to: UInt8.self)
    for i in 0..<count { ptr[i] = UInt8.random(in: 0...255) }
    return errSecSuccess
  }

  public final class SecStaticCode: @unchecked Sendable {}
  public final class SecCode: @unchecked Sendable {}
  public final class SecRequirement: @unchecked Sendable {}
  public struct SecCSFlags: OptionSet, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let defaultFlags = SecCSFlags([])
    public static let strictValidate = SecCSFlags(rawValue: 1 << 4)
    public static let checkAllArchitectures = SecCSFlags(rawValue: 1 << 0)
    public static let doNotValidateExecutable = SecCSFlags(rawValue: 1 << 1)
    public static let doNotValidateResources = SecCSFlags(rawValue: 1 << 2)
    public static let signingInformation = SecCSFlags(rawValue: 1 << 1)
  }
  public let kSecCSCheckAllArchitectures: UInt32 = 1 << 0
  public let kSecCSCheckNestedCode: UInt32 = 1 << 3
  public let kSecCSStrictValidate: UInt32 = 1 << 4
  public let kSecCSSigningInformation: UInt32 = 1 << 1
  public let kSecCodeInfoTeamIdentifier: CFString = "teamid"
  public let kSecCodeInfoIdentifier: CFString = "identifier"
  public let kSecCodeInfoUnique: CFString = "unique"
  public func SecStaticCodeCreateWithPath(_ path: URL, _ flags: SecCSFlags, _ staticCode: UnsafeMutablePointer<SecStaticCode?>) -> OSStatus {
    staticCode.pointee = nil
    return errSecUnimplemented
  }
  public func SecStaticCodeCreateWithPath(_ path: CFURL, _ flags: SecCSFlags, _ staticCode: UnsafeMutablePointer<SecStaticCode?>) -> OSStatus {
    staticCode.pointee = nil
    return errSecUnimplemented
  }
  public func SecRequirementCreateWithString(_ text: CFString, _ flags: SecCSFlags, _ requirement: UnsafeMutablePointer<SecRequirement?>) -> OSStatus {
    requirement.pointee = nil
    return errSecUnimplemented
  }
  public func SecCodeCopyStaticCode(_ code: SecCode, _ flags: SecCSFlags, _ staticCode: UnsafeMutablePointer<SecStaticCode?>) -> OSStatus {
    staticCode.pointee = nil
    return errSecUnimplemented
  }
  public func SecCodeCopyDesignatedRequirement(_ code: SecStaticCode, _ flags: SecCSFlags, _ requirement: UnsafeMutablePointer<SecRequirement?>) -> OSStatus {
    requirement.pointee = nil
    return errSecUnimplemented
  }
  public func SecStaticCodeCheckValidity(_ staticCode: SecStaticCode, _ flags: SecCSFlags, _ requirement: SecRequirement?) -> OSStatus {
    errSecUnimplemented
  }
  public func SecCodeCopySigningInformation(_ code: SecStaticCode, _ flags: SecCSFlags, _ information: UnsafeMutablePointer<CFDictionary?>) -> OSStatus {
    information.pointee = nil
    return errSecUnimplemented
  }
  public func SecCodeCopySelf(_ flags: SecCSFlags, _ selfCode: UnsafeMutablePointer<SecCode?>) -> OSStatus {
    selfCode.pointee = nil
    return errSecUnimplemented
  }
  public func SecCodeCopySigningInformation(_ code: SecCode, _ flags: SecCSFlags, _ information: UnsafeMutablePointer<CFDictionary?>) -> OSStatus {
    information.pointee = nil
    return errSecUnimplemented
  }

  public final class SecTask: @unchecked Sendable {}
  public func SecTaskCreateFromSelf(_ allocator: CFAllocator?) -> SecTask? { nil }
  public func SecTaskCopyValueForEntitlement(_ task: SecTask, _ entitlement: CFString, _ error: UnsafeMutablePointer<AnyObject?>?) -> CFTypeRef? { nil }
#endif
