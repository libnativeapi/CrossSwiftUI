import Foundation
#if os(Windows)
  import CAppKitWindows
#endif

#if !os(macOS)
  public typealias CCPBKDFAlgorithm = UInt32
  public typealias CCPseudoRandomAlgorithm = UInt32
  public typealias CCOperation = UInt32
  public typealias CCAlgorithm = UInt32
  public typealias CCOptions = UInt32
  public typealias CCCryptorStatus = Int32

  public let kCCSuccess: Int32 = 0
  public let kCCAlignmentError: Int = -4303
  public let kCCAlgorithmAES: UInt32 = 0
  public let kCCBlockSizeAES128: Int = 16
  public let kCCOptionPKCS7Padding: UInt32 = 1
  public let kCCOptionECBMode: UInt32 = 2
  public let kCCEncrypt: UInt32 = 0
  public let kCCDecrypt: UInt32 = 1

  public let kCCPBKDF2: UInt32 = 2
  public let kCCPRFHmacAlgSHA1: Int = 1
  public let kCCPRFHmacAlgSHA224: Int = 2
  public let kCCPRFHmacAlgSHA256: Int = 3
  public let kCCPRFHmacAlgSHA384: Int = 4
  public let kCCPRFHmacAlgSHA512: Int = 5

  public func CCKeyDerivationPBKDF(
    _ algorithm: CCPBKDFAlgorithm,
    _ password: UnsafePointer<CChar>?,
    _ passwordLen: Int,
    _ salt: UnsafePointer<UInt8>?,
    _ saltLen: Int,
    _ prf: CCPseudoRandomAlgorithm,
    _ rounds: UInt32,
    _ derivedKey: UnsafeMutablePointer<UInt8>?,
    _ derivedKeyLen: Int
  ) -> Int32 {
    guard algorithm == kCCPBKDF2, let derivedKey, derivedKeyLen > 0 else {
      return derivedKeyLen == 0 ? kCCSuccess : -4300
    }
    #if os(Windows)
      let pwPtr = password.map { UnsafeRawPointer($0).assumingMemoryBound(to: UInt8.self) }
      let ok = cak_pbkdf2(
        Int32(prf), pwPtr, passwordLen, salt, saltLen, rounds, derivedKey, derivedKeyLen)
      return ok != 0 ? kCCSuccess : -4300
    #else
      return -4300
    #endif
  }

  public func CCCrypt(
    _ op: CCOperation,
    _ alg: CCAlgorithm,
    _ options: CCOptions,
    _ key: UnsafeRawPointer?,
    _ keyLength: Int,
    _ iv: UnsafeRawPointer?,
    _ dataIn: UnsafeRawPointer?,
    _ dataInLength: Int,
    _ dataOut: UnsafeMutableRawPointer?,
    _ dataOutAvailable: Int,
    _ dataOutMoved: UnsafeMutablePointer<Int>?
  ) -> CCCryptorStatus {
    dataOutMoved?.pointee = 0
    guard alg == kCCAlgorithmAES, let key, let dataOut else { return -4300 }
    let decrypt = op == kCCDecrypt
    let ecb = (options & kCCOptionECBMode) != 0
    let pad = (options & kCCOptionPKCS7Padding) != 0
    if !pad && (dataInLength % kCCBlockSizeAES128) != 0 {
      return CCCryptorStatus(kCCAlignmentError)
    }
    #if os(Windows)
      var written = 0
      let ok = cak_aes_crypt(
        decrypt ? 1 : 0,
        ecb ? 1 : 0,
        pad ? 1 : 0,
        key.assumingMemoryBound(to: UInt8.self), keyLength,
        iv?.assumingMemoryBound(to: UInt8.self),
        dataIn?.assumingMemoryBound(to: UInt8.self), dataInLength,
        dataOut.assumingMemoryBound(to: UInt8.self), dataOutAvailable,
        &written)
      guard ok != 0 else { return -4300 }
      dataOutMoved?.pointee = written
      return kCCSuccess
    #else
      return -4300
    #endif
  }
#endif
