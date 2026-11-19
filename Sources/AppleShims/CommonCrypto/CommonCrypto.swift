import Foundation

#if !os(macOS)
  public let kCCSuccess: Int32 = 0
  public let kCCAlgorithmAES: UInt32 = 0
  public let kCCOptionPKCS7Padding: UInt32 = 1
  public let kCCEncrypt: UInt32 = 0
  public let kCCDecrypt: UInt32 = 1
#endif
