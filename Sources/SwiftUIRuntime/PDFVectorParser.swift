import Foundation

/// Minimal, zero-dependency single-page vector PDF parser for icon assets
/// (such as Apple `.xcassets` PDF vector imagesets used by Microsoft FluentIcons).
/// Extracts `/MediaBox` (or `/CropBox`) and converts PDF path operators
/// (`m`, `l`, `c`, `v`, `y`, `re`, `h`, `q`/`Q`/`cm`, `f`/`f*`/`S`/`s`/`B`/`b`)
/// from both uncompressed and `/FlateDecode` content streams into `VectorImage`.
package enum PDFVectorParser {
  private struct AffineMatrix {
    var a: Double = 1
    var b: Double = 0
    var c: Double = 0
    var d: Double = 1
    var e: Double = 0
    var f: Double = 0

    static let identity = AffineMatrix()

    /// Concatenates `local` onto `self` (`point -> local -> self`), matching PDF `cm`.
    func concatenating(_ local: AffineMatrix) -> AffineMatrix {
      AffineMatrix(
        a: local.a * a + local.b * c,
        b: local.a * b + local.b * d,
        c: local.c * a + local.d * c,
        d: local.c * b + local.d * d,
        e: local.e * a + local.f * c + e,
        f: local.e * b + local.f * d + f
      )
    }

    func apply(_ x: Double, _ y: Double) -> CGPoint {
      CGPoint(x: a * x + c * y + e, y: b * x + d * y + f)
    }
  }

  package static func parse(filePath: String) -> VectorImage? {
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: filePath)) else { return nil }
    return parse(data: data)
  }

  package static func parse(data: Data) -> VectorImage? {
    guard data.count >= 8 else { return nil }
    let bytes = [UInt8](data)
    let latin1 = String(decoding: bytes, as: UTF8.self)
    let headerText = String(bytes: bytes, encoding: .isoLatin1) ?? latin1

    guard let mediaBox = extractBox(named: "CropBox", in: headerText)
      ?? extractBox(named: "MediaBox", in: headerText),
      mediaBox.width > 0, mediaBox.height > 0
    else {
      return nil
    }

    let streams = extractContentStreams(bytes: bytes)
    var paths: [Path] = []
    for streamText in streams {
      let parsed = parseContentStream(streamText, mediaBox: mediaBox)
      paths.append(contentsOf: parsed)
    }
    guard !paths.isEmpty else { return nil }
    return VectorImage(bounds: mediaBox, paths: paths, strokeWidth: 0)
  }

  private static func extractBox(named name: String, in text: String) -> CGRect? {
    let pattern = "/\(name)\\s*\\[\\s*([-+]?[0-9]*\\.?[0-9]+)\\s+([-+]?[0-9]*\\.?[0-9]+)\\s+([-+]?[0-9]*\\.?[0-9]+)\\s+([-+]?[0-9]*\\.?[0-9]+)\\s*\\]"
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
          match.numberOfRanges == 5
    else {
      return nil
    }
    var vals: [Double] = []
    for i in 1...4 {
      guard let range = Range(match.range(at: i), in: text),
            let v = Double(text[range])
      else { return nil }
      vals.append(v)
    }
    let minX = min(vals[0], vals[2])
    let minY = min(vals[1], vals[3])
    let w = abs(vals[2] - vals[0])
    let h = abs(vals[3] - vals[1])
    return CGRect(x: minX, y: minY, width: w, height: h)
  }

  private static func extractContentStreams(bytes: [UInt8]) -> [String] {
    let streamMarker: [UInt8] = Array("stream".utf8)
    let endMarker: [UInt8] = Array("endstream".utf8)
    var results: [String] = []
    var idx = 0

    func matches(_ pattern: [UInt8], at pos: Int) -> Bool {
      guard pos + pattern.count <= bytes.count else { return false }
      for k in 0..<pattern.count where bytes[pos + k] != pattern[k] {
        return false
      }
      return true
    }

    while idx < bytes.count {
      guard matches(streamMarker, at: idx) else {
        idx += 1
        continue
      }
      // Ensure "stream" is not part of "endstream" or another identifier.
      let prevIsAlpha = idx > 0 && isASCIIAlpha(bytes[idx - 1])
      let afterPos = idx + streamMarker.count
      guard !prevIsAlpha, afterPos < bytes.count,
            bytes[afterPos] == 0x0A || bytes[afterPos] == 0x0D
      else {
        idx += 1
        continue
      }

      // Inspect the preceding dictionary snippet for filter / stream type.
      let dictStart = max(0, idx - 512)
      let dictSnippet = String(bytes: bytes[dictStart..<idx], encoding: .isoLatin1) ?? ""
      let isNonContent =
        dictSnippet.contains("/Type /XRef")
        || dictSnippet.contains("/Type/XRef")
        || dictSnippet.contains("/Type /ObjStm")
        || dictSnippet.contains("/Type/ObjStm")
        || dictSnippet.contains("/Subtype /Image")
        || dictSnippet.contains("/Subtype/Image")
        || dictSnippet.contains("/Type /Metadata")
        || dictSnippet.contains("/Type/Metadata")
      let isFlate = dictSnippet.contains("/FlateDecode")

      // Skip CRLF or LF after "stream".
      var contentStart = afterPos
      if bytes[contentStart] == 0x0D {
        contentStart += 1
        if contentStart < bytes.count && bytes[contentStart] == 0x0A {
          contentStart += 1
        }
      } else if bytes[contentStart] == 0x0A {
        contentStart += 1
      }

      // Find matching "endstream".
      var contentEnd = contentStart
      while contentEnd < bytes.count && !matches(endMarker, at: contentEnd) {
        contentEnd += 1
      }
      guard contentEnd < bytes.count else { break }

      if !isNonContent {
        var trimmedEnd = contentEnd
        while trimmedEnd > contentStart && (bytes[trimmedEnd - 1] == 0x0A || bytes[trimmedEnd - 1] == 0x0D) {
          trimmedEnd -= 1
        }
        let rawSlice = Array(bytes[contentStart..<trimmedEnd])
        let decodedBytes: [UInt8]?
        if isFlate {
          decodedBytes = ZlibInflater.decompress(rawSlice)
        } else {
          decodedBytes = rawSlice
        }
        if let decodedBytes, let text = String(bytes: decodedBytes, encoding: .isoLatin1) {
          results.append(text)
        }
      }

      idx = contentEnd + endMarker.count
    }

    return results
  }

  private static func isASCIIAlpha(_ b: UInt8) -> Bool {
    (b >= 0x41 && b <= 0x5A) || (b >= 0x61 && b <= 0x7A)
  }

  private static func parseContentStream(_ text: String, mediaBox: CGRect) -> [Path] {
    let tokens = tokenize(text)
    var paths: [Path] = []
    var currentPath = Path()
    var hasSubpath = false
    var currentPoint = CGPoint.zero
    var startPoint = CGPoint.zero
    var ctm = AffineMatrix.identity
    var stack: [AffineMatrix] = []
    var operands: [Double] = []

    func mapPoint(_ x: Double, _ y: Double) -> CGPoint {
      let t = ctm.apply(x, y)
      return CGPoint(x: t.x, y: mediaBox.minY + mediaBox.maxY - t.y)
    }

    func commitPath(close: Bool) {
      if close && hasSubpath {
        currentPath.closeSubpath()
      }
      if hasSubpath {
        paths.append(currentPath)
      }
      currentPath = Path()
      hasSubpath = false
    }

    for token in tokens {
      if let num = Double(token) {
        operands.append(num)
        continue
      }

      switch token {
      case "q":
        stack.append(ctm)
      case "Q":
        if let saved = stack.popLast() { ctm = saved }
      case "cm":
        if operands.count >= 6 {
          let n = operands.count
          let m = AffineMatrix(
            a: operands[n - 6], b: operands[n - 5],
            c: operands[n - 4], d: operands[n - 3],
            e: operands[n - 2], f: operands[n - 1]
          )
          ctm = ctm.concatenating(m)
        }
      case "m":
        if operands.count >= 2 {
          let x = operands[operands.count - 2]
          let y = operands[operands.count - 1]
          let pt = mapPoint(x, y)
          currentPath.move(to: pt)
          currentPoint = CGPoint(x: x, y: y)
          startPoint = currentPoint
          hasSubpath = true
        }
      case "l":
        if operands.count >= 2 {
          let x = operands[operands.count - 2]
          let y = operands[operands.count - 1]
          currentPath.addLine(to: mapPoint(x, y))
          currentPoint = CGPoint(x: x, y: y)
          hasSubpath = true
        }
      case "c":
        if operands.count >= 6 {
          let n = operands.count
          let c1 = mapPoint(operands[n - 6], operands[n - 5])
          let c2 = mapPoint(operands[n - 4], operands[n - 3])
          let endX = operands[n - 2]
          let endY = operands[n - 1]
          currentPath.addCurve(to: mapPoint(endX, endY), control1: c1, control2: c2)
          currentPoint = CGPoint(x: endX, y: endY)
          hasSubpath = true
        }
      case "v":
        if operands.count >= 4 {
          let n = operands.count
          let c1 = mapPoint(currentPoint.x, currentPoint.y)
          let c2 = mapPoint(operands[n - 4], operands[n - 3])
          let endX = operands[n - 2]
          let endY = operands[n - 1]
          currentPath.addCurve(to: mapPoint(endX, endY), control1: c1, control2: c2)
          currentPoint = CGPoint(x: endX, y: endY)
          hasSubpath = true
        }
      case "y":
        if operands.count >= 4 {
          let n = operands.count
          let c1 = mapPoint(operands[n - 4], operands[n - 3])
          let endX = operands[n - 2]
          let endY = operands[n - 1]
          let endPt = mapPoint(endX, endY)
          currentPath.addCurve(to: endPt, control1: c1, control2: endPt)
          currentPoint = CGPoint(x: endX, y: endY)
          hasSubpath = true
        }
      case "re":
        if operands.count >= 4 {
          let n = operands.count
          let x = operands[n - 4]
          let y = operands[n - 3]
          let w = operands[n - 2]
          let h = operands[n - 1]
          currentPath.move(to: mapPoint(x, y))
          currentPath.addLine(to: mapPoint(x + w, y))
          currentPath.addLine(to: mapPoint(x + w, y + h))
          currentPath.addLine(to: mapPoint(x, y + h))
          currentPath.closeSubpath()
          currentPoint = CGPoint(x: x, y: y)
          startPoint = currentPoint
          hasSubpath = true
        }
      case "h":
        if hasSubpath {
          currentPath.closeSubpath()
          currentPoint = startPoint
        }
      case "f", "F", "f*", "B", "B*", "S":
        commitPath(close: false)
      case "b", "b*", "s":
        commitPath(close: true)
      case "n":
        // End path without filling or stroking (e.g. after clipping W/W*).
        currentPath = Path()
        hasSubpath = false
      default:
        break
      }
      operands.removeAll(keepingCapacity: true)
    }

    return paths
  }

  private static func tokenize(_ source: String) -> [String] {
    var tokens: [String] = []
    let bytes = Array(source.utf8)
    var i = 0
    let count = bytes.count

    func isWhitespace(_ b: UInt8) -> Bool {
      b == 0x20 || b == 0x09 || b == 0x0A || b == 0x0D || b == 0x0C || b == 0x00
    }

    func isDelimiter(_ b: UInt8) -> Bool {
      switch b {
      case 0x28, 0x29, 0x3C, 0x3E, 0x5B, 0x5D, 0x7B, 0x7D, 0x2F, 0x25:
        return true
      default:
        return false
      }
    }

    while i < count {
      let b = bytes[i]
      if isWhitespace(b) {
        i += 1
        continue
      }
      if b == 0x25 { // '%' comment
        while i < count && bytes[i] != 0x0A && bytes[i] != 0x0D { i += 1 }
        continue
      }
      if b == 0x28 { // '(' literal string
        var depth = 1
        i += 1
        while i < count && depth > 0 {
          if bytes[i] == 0x5C { i += 2; continue }
          if bytes[i] == 0x28 { depth += 1 }
          else if bytes[i] == 0x29 { depth -= 1 }
          i += 1
        }
        continue
      }
      if b == 0x3C { // '<' hex string or '<<' dict
        if i + 1 < count && bytes[i + 1] == 0x3C {
          var depth = 1
          i += 2
          while i + 1 < count && depth > 0 {
            if bytes[i] == 0x3C && bytes[i + 1] == 0x3C { depth += 1; i += 2 }
            else if bytes[i] == 0x3E && bytes[i + 1] == 0x3E { depth -= 1; i += 2 }
            else { i += 1 }
          }
        } else {
          i += 1
          while i < count && bytes[i] != 0x3E { i += 1 }
          if i < count { i += 1 }
        }
        continue
      }
      if b == 0x5B || b == 0x5D { // '[' or ']'
        i += 1
        continue
      }
      if b == 0x2F { // '/' name
        let start = i
        i += 1
        while i < count && !isWhitespace(bytes[i]) && !isDelimiter(bytes[i]) { i += 1 }
        if let name = String(bytes: bytes[start..<i], encoding: .isoLatin1) {
          tokens.append(name)
        }
        continue
      }
      let start = i
      while i < count && !isWhitespace(bytes[i]) && !isDelimiter(bytes[i]) { i += 1 }
      if i > start, let tok = String(bytes: bytes[start..<i], encoding: .isoLatin1) {
        tokens.append(tok)
      } else {
        i += 1
      }
    }
    return tokens
  }
}

/// Pure-Swift RFC 1950 (zlib) / RFC 1951 (DEFLATE) inflater for PDF `/FlateDecode` streams.
enum ZlibInflater {
  private struct BitReader {
    let bytes: [UInt8]
    var bytePos: Int
    var bitBuf: UInt32 = 0
    var bitCount: Int = 0

    init(bytes: [UInt8], offset: Int) {
      self.bytes = bytes
      self.bytePos = offset
    }

    mutating func readBits(_ n: Int) -> Int? {
      if n == 0 { return 0 }
      while bitCount < n {
        guard bytePos < bytes.count else { return nil }
        bitBuf |= UInt32(bytes[bytePos]) << UInt32(bitCount)
        bytePos += 1
        bitCount += 8
      }
      let mask = (UInt32(1) << UInt32(n)) - 1
      let val = Int(bitBuf & mask)
      bitBuf >>= UInt32(n)
      bitCount -= n
      return val
    }

    mutating func alignToByte() {
      let drop = bitCount & 7
      bitBuf >>= UInt32(drop)
      bitCount -= drop
    }

    mutating func readUInt16LE() -> Int? {
      alignToByte()
      guard let lo = readBits(8), let hi = readBits(8) else { return nil }
      return lo | (hi << 8)
    }
  }

  private struct HuffmanTable {
    var counts: [Int]
    var symbols: [Int]

    init?(codeLengths: [Int]) {
      let maxBits = 15
      var blCount = [Int](repeating: 0, count: maxBits + 1)
      for len in codeLengths where len > 0 {
        guard len <= maxBits else { return nil }
        blCount[len] += 1
      }
      var offsets = [Int](repeating: 0, count: maxBits + 1)
      var total = 0
      for bits in 1...maxBits {
        offsets[bits] = total
        total += blCount[bits]
      }
      var syms = [Int](repeating: 0, count: total)
      for (sym, len) in codeLengths.enumerated() where len > 0 {
        syms[offsets[len]] = sym
        offsets[len] += 1
      }
      self.counts = blCount
      self.symbols = syms
    }

    func decode(_ reader: inout BitReader) -> Int? {
      var code = 0
      var first = 0
      var index = 0
      for len in 1...15 {
        guard let bit = reader.readBits(1) else { return nil }
        code |= bit
        let count = counts[len]
        if code - count < first {
          return symbols[index + (code - first)]
        }
        index += count
        first = (first + count) << 1
        code <<= 1
      }
      return nil
    }
  }

  private static let lengthBase = [
    3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 15, 17, 19, 23, 27, 31,
    35, 43, 51, 59, 67, 83, 99, 115, 131, 163, 195, 227, 258,
  ]
  private static let lengthExtra = [
    0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 2, 2, 2, 2,
    3, 3, 3, 3, 4, 4, 4, 4, 5, 5, 5, 5, 0,
  ]
  private static let distBase = [
    1, 2, 3, 4, 5, 7, 9, 13, 17, 25, 33, 49, 65, 97, 129, 193,
    257, 385, 513, 769, 1025, 1537, 2049, 3073, 4097, 6145, 8193, 12289, 16385, 24577,
  ]
  private static let distExtra = [
    0, 0, 0, 0, 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6,
    7, 7, 8, 8, 9, 9, 10, 10, 11, 11, 12, 12, 13, 13,
  ]
  private static let codeLengthOrder = [
    16, 17, 18, 0, 8, 7, 9, 6, 10, 5, 11, 4, 12, 3, 13, 2, 14, 1, 15,
  ]

  static func decompress(_ input: [UInt8]) -> [UInt8]? {
    guard input.count >= 2 else { return nil }
    var offset = 0
    let cmf = Int(input[0])
    let flg = Int(input[1])
    if (cmf & 0x0F) == 8 && ((cmf << 8) | flg) % 31 == 0 {
      offset = 2
      if (flg & 0x20) != 0 {
        offset += 4
      }
    }
    guard offset < input.count else { return nil }
    return inflateRaw(input, offset: offset)
  }

  private static func inflateRaw(_ input: [UInt8], offset: Int) -> [UInt8]? {
    var reader = BitReader(bytes: input, offset: offset)
    var output: [UInt8] = []
    output.reserveCapacity(input.count * 2)

    while true {
      guard let bfinal = reader.readBits(1),
            let btype = reader.readBits(2)
      else { return nil }

      switch btype {
      case 0:
        guard let len = reader.readUInt16LE(),
              let nlen = reader.readUInt16LE(),
              (len ^ 0xFFFF) == nlen
        else { return nil }
        for _ in 0..<len {
          guard let b = reader.readBits(8) else { return nil }
          output.append(UInt8(b))
        }

      case 1:
        var litLengths = [Int](repeating: 0, count: 288)
        for i in 0...143 { litLengths[i] = 8 }
        for i in 144...255 { litLengths[i] = 9 }
        for i in 256...279 { litLengths[i] = 7 }
        for i in 280...287 { litLengths[i] = 8 }
        let distLengths = [Int](repeating: 5, count: 32)
        guard let litTable = HuffmanTable(codeLengths: litLengths),
              let distTable = HuffmanTable(codeLengths: distLengths),
              decodeBlock(&reader, litTable: litTable, distTable: distTable, output: &output)
        else { return nil }

      case 2:
        guard let hlitRaw = reader.readBits(5),
              let hdistRaw = reader.readBits(5),
              let hclenRaw = reader.readBits(4)
        else { return nil }
        let hlit = hlitRaw + 257
        let hdist = hdistRaw + 1
        let hclen = hclenRaw + 4

        var clLengths = [Int](repeating: 0, count: 19)
        for i in 0..<hclen {
          guard let v = reader.readBits(3) else { return nil }
          clLengths[codeLengthOrder[i]] = v
        }
        guard let clTable = HuffmanTable(codeLengths: clLengths) else { return nil }

        let totalCodes = hlit + hdist
        var lengths = [Int](repeating: 0, count: totalCodes)
        var pos = 0
        while pos < totalCodes {
          guard let sym = clTable.decode(&reader) else { return nil }
          if sym < 16 {
            lengths[pos] = sym
            pos += 1
          } else if sym == 16 {
            guard pos > 0, let rep = reader.readBits(2) else { return nil }
            let count = rep + 3
            let prev = lengths[pos - 1]
            guard pos + count <= totalCodes else { return nil }
            for _ in 0..<count { lengths[pos] = prev; pos += 1 }
          } else if sym == 17 {
            guard let rep = reader.readBits(3) else { return nil }
            let count = rep + 3
            guard pos + count <= totalCodes else { return nil }
            for _ in 0..<count { lengths[pos] = 0; pos += 1 }
          } else if sym == 18 {
            guard let rep = reader.readBits(7) else { return nil }
            let count = rep + 11
            guard pos + count <= totalCodes else { return nil }
            for _ in 0..<count { lengths[pos] = 0; pos += 1 }
          } else {
            return nil
          }
        }

        let litLengths = Array(lengths[0..<hlit])
        let distLengths = Array(lengths[hlit..<totalCodes])
        guard let litTable = HuffmanTable(codeLengths: litLengths),
              let distTable = HuffmanTable(codeLengths: distLengths),
              decodeBlock(&reader, litTable: litTable, distTable: distTable, output: &output)
        else { return nil }

      default:
        return nil
      }

      if bfinal == 1 { break }
    }

    return output
  }

  private static func decodeBlock(
    _ reader: inout BitReader,
    litTable: HuffmanTable,
    distTable: HuffmanTable,
    output: inout [UInt8]
  ) -> Bool {
    while true {
      guard let sym = litTable.decode(&reader) else { return false }
      if sym < 256 {
        output.append(UInt8(sym))
      } else if sym == 256 {
        return true
      } else {
        let lenIdx = sym - 257
        guard lenIdx >= 0, lenIdx < lengthBase.count,
              let extraLen = reader.readBits(lengthExtra[lenIdx])
        else { return false }
        let length = lengthBase[lenIdx] + extraLen

        guard let distSym = distTable.decode(&reader),
              distSym >= 0, distSym < distBase.count,
              let extraDist = reader.readBits(distExtra[distSym])
        else { return false }
        let distance = distBase[distSym] + extraDist
        guard distance > 0, distance <= output.count else { return false }

        for _ in 0..<length {
          output.append(output[output.count - distance])
        }
      }
    }
  }
}
