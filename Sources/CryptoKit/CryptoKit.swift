import Foundation
#if os(Windows)
  import CAppKitWindows
#endif

public enum CryptoKitError: Error, Sendable {
  case incorrectKeySize
  case incorrectParameterSize
  case authenticationFailure
  case underlyingCoreCryptoError(error: Int32)
}

public protocol ContiguousBytes {
  func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R
}

extension Data: ContiguousBytes {}
extension Array: ContiguousBytes where Element == UInt8 {}
extension ArraySlice: ContiguousBytes where Element == UInt8 {}
extension ContiguousArray: ContiguousBytes where Element == UInt8 {}

public protocol Digest: ContiguousBytes, Sequence, Equatable, Hashable, Sendable
where Element == UInt8 {
  static var byteCount: Int { get }
}

public struct DigestBytes: Digest {
  public static var byteCount: Int { 0 }
  private let bytes: [UInt8]
  public init(_ bytes: [UInt8]) { self.bytes = bytes }
  public func makeIterator() -> IndexingIterator<[UInt8]> { bytes.makeIterator() }
  public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    try bytes.withUnsafeBytes(body)
  }
}

public struct SHA256Digest: Digest {
  public static let byteCount = 32
  private let bytes: [UInt8]
  public init(_ bytes: [UInt8]) { self.bytes = bytes }
  public func makeIterator() -> IndexingIterator<[UInt8]> { bytes.makeIterator() }
  public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    try bytes.withUnsafeBytes(body)
  }
}

public struct SHA512Digest: Digest {
  public static let byteCount = 64
  private let bytes: [UInt8]
  public init(_ bytes: [UInt8]) { self.bytes = bytes }
  public func makeIterator() -> IndexingIterator<[UInt8]> { bytes.makeIterator() }
  public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    try bytes.withUnsafeBytes(body)
  }
}

public protocol HashFunction {
  associatedtype Digest: CryptoKit.Digest
  static var blockByteCount: Int { get }
  init()
  mutating func update<D: DataProtocol>(data: D)
  mutating func update(bufferPointer: UnsafeRawBufferPointer)
  func finalize() -> Digest
}

extension HashFunction {
  public static func hash<D: DataProtocol>(data: D) -> Digest {
    var hasher = Self()
    hasher.update(data: data)
    return hasher.finalize()
  }
}

public struct SHA256: HashFunction, Sendable {
  public typealias Digest = SHA256Digest
  public static let blockByteCount = 64
  private var buffer: [UInt8] = []

  public init() {}

  public mutating func update<D: DataProtocol>(data: D) {
    buffer.append(contentsOf: data)
  }

  public mutating func update(bufferPointer: UnsafeRawBufferPointer) {
    buffer.append(contentsOf: bufferPointer)
  }

  public func finalize() -> SHA256Digest {
    #if os(Windows)
      var out = [UInt8](repeating: 0, count: 32)
      _ = buffer.withUnsafeBufferPointer { buf in
        cak_sha256(buf.baseAddress, buf.count, &out)
      }
      return SHA256Digest(out)
    #else
      return SHA256Digest(Self.pureSHA256(buffer))
    #endif
  }

  static func pureSHA256(_ message: [UInt8]) -> [UInt8] {
    let k: [UInt32] = [
      0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
      0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
      0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
      0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
      0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
      0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
      0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
      0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
    ]
    var h: [UInt32] = [
      0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a,
      0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
    ]
    var msg = message
    let bitLen = UInt64(msg.count) * 8
    msg.append(0x80)
    while (msg.count % 64) != 56 { msg.append(0) }
    for shift in stride(from: 56, through: 0, by: -8) {
      msg.append(UInt8((bitLen >> shift) & 0xff))
    }
    func rotr(_ x: UInt32, _ n: UInt32) -> UInt32 { (x >> n) | (x << (32 - n)) }
    var w = [UInt32](repeating: 0, count: 64)
    for chunk in stride(from: 0, to: msg.count, by: 64) {
      for i in 0..<16 {
        let j = chunk + i * 4
        w[i] = (UInt32(msg[j]) << 24) | (UInt32(msg[j + 1]) << 16) | (UInt32(msg[j + 2]) << 8) | UInt32(msg[j + 3])
      }
      for i in 16..<64 {
        let s0 = rotr(w[i - 15], 7) ^ rotr(w[i - 15], 18) ^ (w[i - 15] >> 3)
        let s1 = rotr(w[i - 2], 17) ^ rotr(w[i - 2], 19) ^ (w[i - 2] >> 10)
        w[i] = w[i - 16] &+ s0 &+ w[i - 7] &+ s1
      }
      var a = h[0], b = h[1], c = h[2], d = h[3], e = h[4], f = h[5], g = h[6], hh = h[7]
      for i in 0..<64 {
        let S1 = rotr(e, 6) ^ rotr(e, 11) ^ rotr(e, 25)
        let ch = (e & f) ^ ((~e) & g)
        let temp1 = hh &+ S1 &+ ch &+ k[i] &+ w[i]
        let S0 = rotr(a, 2) ^ rotr(a, 13) ^ rotr(a, 22)
        let maj = (a & b) ^ (a & c) ^ (b & c)
        let temp2 = S0 &+ maj
        hh = g; g = f; f = e; e = d &+ temp1
        d = c; c = b; b = a; a = temp1 &+ temp2
      }
      h[0] &+= a; h[1] &+= b; h[2] &+= c; h[3] &+= d
      h[4] &+= e; h[5] &+= f; h[6] &+= g; h[7] &+= hh
    }
    var out: [UInt8] = []
    out.reserveCapacity(32)
    for word in h {
      out.append(UInt8((word >> 24) & 0xff))
      out.append(UInt8((word >> 16) & 0xff))
      out.append(UInt8((word >> 8) & 0xff))
      out.append(UInt8(word & 0xff))
    }
    return out
  }
}

public struct SHA512: HashFunction, Sendable {
  public typealias Digest = SHA512Digest
  public static let blockByteCount = 128
  private var buffer: [UInt8] = []
  public init() {}
  public mutating func update<D: DataProtocol>(data: D) { buffer.append(contentsOf: data) }
  public mutating func update(bufferPointer: UnsafeRawBufferPointer) { buffer.append(contentsOf: bufferPointer) }
  public func finalize() -> SHA512Digest {
    var out = [UInt8](repeating: 0, count: 64)
    #if os(Windows)
      _ = buffer.withUnsafeBufferPointer { buf in cak_sha512(buf.baseAddress, buf.count, &out) }
    #endif
    return SHA512Digest(out)
  }
}

public enum Insecure {
  public struct SHA1Digest: Digest {
    public static let byteCount = 20
    private let bytes: [UInt8]
    public init(_ bytes: [UInt8]) { self.bytes = bytes }
    public func makeIterator() -> IndexingIterator<[UInt8]> { bytes.makeIterator() }
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
      try bytes.withUnsafeBytes(body)
    }
  }
  public struct MD5Digest: Digest {
    public static let byteCount = 16
    private let bytes: [UInt8]
    public init(_ bytes: [UInt8]) { self.bytes = bytes }
    public func makeIterator() -> IndexingIterator<[UInt8]> { bytes.makeIterator() }
    public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
      try bytes.withUnsafeBytes(body)
    }
  }
  public struct SHA1: HashFunction, Sendable {
    public typealias Digest = SHA1Digest
    public static let blockByteCount = 64
    private var buffer: [UInt8] = []
    public init() {}
    public mutating func update<D: DataProtocol>(data: D) { buffer.append(contentsOf: data) }
    public mutating func update(bufferPointer: UnsafeRawBufferPointer) { buffer.append(contentsOf: bufferPointer) }
    public func finalize() -> SHA1Digest {
      var out = [UInt8](repeating: 0, count: 20)
      #if os(Windows)
        _ = buffer.withUnsafeBufferPointer { buf in cak_sha1(buf.baseAddress, buf.count, &out) }
      #endif
      return SHA1Digest(out)
    }
  }
  public struct MD5: HashFunction, Sendable {
    public typealias Digest = MD5Digest
    public static let blockByteCount = 64
    private var buffer: [UInt8] = []
    public init() {}
    public mutating func update<D: DataProtocol>(data: D) { buffer.append(contentsOf: data) }
    public mutating func update(bufferPointer: UnsafeRawBufferPointer) { buffer.append(contentsOf: bufferPointer) }
    public func finalize() -> MD5Digest {
      var out = [UInt8](repeating: 0, count: 16)
      #if os(Windows)
        _ = buffer.withUnsafeBufferPointer { buf in cak_md5(buf.baseAddress, buf.count, &out) }
      #endif
      return MD5Digest(out)
    }
  }
}

public struct SymmetricKeySize: Sendable {
  public let bitCount: Int
  public init(bitsCount: Int) { self.bitCount = bitsCount }
  public static let bits128 = SymmetricKeySize(bitsCount: 128)
  public static let bits192 = SymmetricKeySize(bitsCount: 192)
  public static let bits256 = SymmetricKeySize(bitsCount: 256)
}

public struct SymmetricKey: ContiguousBytes, Equatable, Sendable {
  fileprivate let bytes: [UInt8]

  public init<D: ContiguousBytes>(data: D) {
    self.bytes = data.withUnsafeBytes { Array($0) }
  }

  public init(size: SymmetricKeySize) {
    let count = max(1, size.bitCount / 8)
    var random = [UInt8](repeating: 0, count: count)
    #if os(Windows)
      _ = cak_random_bytes(&random, count)
    #else
      for i in 0..<count { random[i] = UInt8.random(in: 0...255) }
    #endif
    self.bytes = random
  }

  public var bitCount: Int { bytes.count * 8 }

  public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    try bytes.withUnsafeBytes(body)
  }
}

public struct HashedAuthenticationCode<H: HashFunction>: ContiguousBytes, Sequence, Equatable, Hashable, Sendable {
  private let bytes: [UInt8]
  public init(_ bytes: [UInt8]) { self.bytes = bytes }
  public var byteCount: Int { bytes.count }
  public func makeIterator() -> IndexingIterator<[UInt8]> { bytes.makeIterator() }
  public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
    try bytes.withUnsafeBytes(body)
  }
}

public struct HMAC<H: HashFunction & Sendable>: Sendable {
  private let ipad: [UInt8]
  private let opad: [UInt8]
  private var inner: H

  public init(key: SymmetricKey) {
    let blockSize = H.blockByteCount
    var keyBytes = key.bytes
    if keyBytes.count > blockSize {
      var h = H()
      h.update(data: keyBytes)
      keyBytes = Array(h.finalize())
    }
    if keyBytes.count < blockSize {
      keyBytes.append(contentsOf: repeatElement(0, count: blockSize - keyBytes.count))
    }
    self.ipad = keyBytes.map { $0 ^ 0x36 }
    self.opad = keyBytes.map { $0 ^ 0x5c }
    var innerHasher = H()
    innerHasher.update(data: self.ipad)
    self.inner = innerHasher
  }

  public mutating func update<D: DataProtocol>(data: D) {
    inner.update(data: data)
  }

  public func finalize() -> HashedAuthenticationCode<H> {
    let innerDigest = Array(inner.finalize())
    var outer = H()
    outer.update(data: opad)
    outer.update(data: innerDigest)
    return HashedAuthenticationCode(Array(outer.finalize()))
  }

  public static func authenticationCode<D: DataProtocol>(
    for data: D,
    using key: SymmetricKey
  ) -> HashedAuthenticationCode<H> {
    var hmac = HMAC<H>(key: key)
    hmac.update(data: data)
    return hmac.finalize()
  }

  public static func isValidAuthenticationCode<D: DataProtocol>(
    _ authenticationCode: HashedAuthenticationCode<H>,
    authenticating bufferPointer: D,
    using key: SymmetricKey
  ) -> Bool {
    Self.authenticationCode(for: bufferPointer, using: key) == authenticationCode
  }
}

public enum AES {
  public enum GCM {
    public struct Nonce: ContiguousBytes, Sequence, Sendable {
      fileprivate let bytes: [UInt8]

      public init() {
        var random = [UInt8](repeating: 0, count: 12)
        #if os(Windows)
          _ = cak_random_bytes(&random, 12)
        #else
          for i in 0..<12 { random[i] = UInt8.random(in: 0...255) }
        #endif
        self.bytes = random
      }

      public init<D: DataProtocol>(data: D) throws {
        let b = Array(data)
        guard b.count >= 12 else { throw CryptoKitError.incorrectParameterSize }
        self.bytes = b
      }

      public func makeIterator() -> IndexingIterator<[UInt8]> { bytes.makeIterator() }
      public func withUnsafeBytes<R>(_ body: (UnsafeRawBufferPointer) throws -> R) rethrows -> R {
        try bytes.withUnsafeBytes(body)
      }
    }

    public struct SealedBox: Sendable {
      public let nonce: Nonce
      public let ciphertext: Data
      public let tag: Data

      public var combined: Data? {
        var d = Data(nonce.bytes)
        d.append(ciphertext)
        d.append(tag)
        return d
      }

      public init<C: DataProtocol, T: DataProtocol>(nonce: Nonce, ciphertext: C, tag: T) throws {
        let tagData = Data(tag)
        guard tagData.count >= 12 && tagData.count <= 16 else {
          throw CryptoKitError.incorrectParameterSize
        }
        self.nonce = nonce
        self.ciphertext = Data(ciphertext)
        self.tag = tagData
      }

      public init<D: DataProtocol>(combined: D) throws {
        let raw = Data(combined)
        guard raw.count >= 28 else { throw CryptoKitError.incorrectParameterSize }
        self.nonce = try Nonce(data: raw.prefix(12))
        self.ciphertext = raw.dropFirst(12).dropLast(16)
        self.tag = raw.suffix(16)
      }
    }

    public static func open(_ sealedBox: SealedBox, using key: SymmetricKey) throws -> Data {
      try open(sealedBox, using: key, authenticating: Data())
    }

    public static func open<AD: DataProtocol>(
      _ sealedBox: SealedBox,
      using key: SymmetricKey,
      authenticating authenticatedData: AD
    ) throws -> Data {
      #if os(Windows)
        let ct = Array(sealedBox.ciphertext)
        let aad = Array(authenticatedData)
        let tag = Array(sealedBox.tag)
        var out = [UInt8](repeating: 0, count: max(1, ct.count))
        let ok = key.bytes.withUnsafeBufferPointer { kBuf in
          sealedBox.nonce.bytes.withUnsafeBufferPointer { nBuf in
            ct.withUnsafeBufferPointer { cBuf in
              aad.withUnsafeBufferPointer { aBuf in
                tag.withUnsafeBufferPointer { tBuf in
                  cak_aes_gcm_decrypt(
                    kBuf.baseAddress, kBuf.count,
                    nBuf.baseAddress, nBuf.count,
                    cBuf.baseAddress, cBuf.count,
                    aBuf.baseAddress, aBuf.count,
                    tBuf.baseAddress, tBuf.count,
                    &out
                  )
                }
              }
            }
          }
        }
        guard ok != 0 else { throw CryptoKitError.authenticationFailure }
        return Data(out.prefix(ct.count))
      #else
        throw CryptoKitError.authenticationFailure
      #endif
    }

    public static func seal<Plaintext: DataProtocol>(
      _ message: Plaintext,
      using key: SymmetricKey,
      nonce: Nonce? = nil
    ) throws -> SealedBox {
      let useNonce = nonce ?? Nonce()
      #if os(Windows)
        let pt = Array(message)
        var ct = [UInt8](repeating: 0, count: max(1, pt.count))
        var tag = [UInt8](repeating: 0, count: 16)
        let ok = key.bytes.withUnsafeBufferPointer { kBuf in
          useNonce.bytes.withUnsafeBufferPointer { nBuf in
            pt.withUnsafeBufferPointer { pBuf in
              cak_aes_gcm_encrypt(
                kBuf.baseAddress, kBuf.count,
                nBuf.baseAddress, nBuf.count,
                pBuf.baseAddress, pBuf.count,
                nil, 0,
                &ct,
                &tag, 16
              )
            }
          }
        }
        guard ok != 0 else { throw CryptoKitError.authenticationFailure }
        return try SealedBox(nonce: useNonce, ciphertext: Data(ct.prefix(pt.count)), tag: Data(tag))
      #else
        throw CryptoKitError.authenticationFailure
      #endif
    }
  }
}

public enum Curve25519 {
  public enum Signing {
    public struct PublicKey: Sendable {
      public let rawRepresentation: Data
      public init<D: ContiguousBytes>(rawRepresentation: D) throws {
        let data = rawRepresentation.withUnsafeBytes { Data($0) }
        guard data.count == 32 else { throw CryptoKitError.incorrectKeySize }
        self.rawRepresentation = data
      }
      public func isValidSignature<S: DataProtocol, D: DataProtocol>(_ signature: S, for data: D) -> Bool {
        false
      }
    }
    public struct PrivateKey: Sendable {
      public let rawRepresentation: Data
      public init() {
        var b = [UInt8](repeating: 0, count: 32)
        #if os(Windows)
          _ = cak_random_bytes(&b, 32)
        #endif
        self.rawRepresentation = Data(b)
      }
      public init<D: ContiguousBytes>(rawRepresentation: D) throws {
        self.rawRepresentation = rawRepresentation.withUnsafeBytes { Data($0) }
      }
      public var publicKey: PublicKey { try! PublicKey(rawRepresentation: rawRepresentation) }
      public func signature<D: DataProtocol>(for data: D) throws -> Data { Data(repeating: 0, count: 64) }
    }
  }
}
