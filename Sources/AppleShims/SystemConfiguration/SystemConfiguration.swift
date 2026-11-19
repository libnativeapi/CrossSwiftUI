import Foundation
import CoreFoundation

#if !os(macOS)
  public func SCDynamicStoreCopyComputerName(_ store: AnyObject?, _ nameEncoding: UnsafeMutablePointer<UInt32>?) -> CFString? {
    ProcessInfo.processInfo.hostName as NSString
  }
#endif
