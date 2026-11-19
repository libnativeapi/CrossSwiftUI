import Foundation

public enum OpenStepPlistError: Error, LocalizedError {
  case unexpectedEndOfInput
  case unexpectedCharacter(Character, offset: Int)
  case invalidDataLiteral(offset: Int)
  case expectedToken(String, offset: Int)

  public var errorDescription: String? {
    switch self {
    case .unexpectedEndOfInput:
      return "Unexpected end of OpenStep property list"
    case .unexpectedCharacter(let ch, let offset):
      return "Unexpected character '\(ch)' at offset \(offset)"
    case .invalidDataLiteral(let offset):
      return "Invalid hex data literal at offset \(offset)"
    case .expectedToken(let expected, let offset):
      return "Expected '\(expected)' at offset \(offset)"
    }
  }
}

/// Pure-Swift parser for OpenStep ASCII property lists (`.pbxproj` and `.plist`),
/// with automatic fallback to `PropertyListSerialization` for XML/binary plists.
public struct OpenStepPlistParser {
  private let scalars: [UnicodeScalar]
  private var index: Int = 0

  public static func parse(fileAt url: URL) throws -> Any {
    let data = try Data(contentsOf: url)
    return try parse(data: data)
  }

  public static func parse(data: Data) throws -> Any {
    if data.starts(with: Array("bplist".utf8)) {
      return try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
    }
    guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
      return try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
    }
    let trimmed = text.drop(while: { $0 == "\u{FEFF}" || $0.isWhitespace })
    if trimmed.hasPrefix("<?xml") || trimmed.hasPrefix("<plist") {
      return try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
    }
    var parser = OpenStepPlistParser(text: String(trimmed))
    return try parser.parseRoot()
  }

  private init(text: String) {
    self.scalars = Array(text.unicodeScalars)
  }

  private mutating func parseRoot() throws -> Any {
    skipWhitespaceAndComments()
    let value = try parseValue()
    skipWhitespaceAndComments()
    return value
  }

  private var isAtEnd: Bool { index >= scalars.count }

  private func peek(_ offset: Int = 0) -> UnicodeScalar? {
    let pos = index + offset
    return pos < scalars.count ? scalars[pos] : nil
  }

  private mutating func advance() -> UnicodeScalar {
    let s = scalars[index]
    index += 1
    return s
  }

  private mutating func skipWhitespaceAndComments() {
    while !isAtEnd {
      let s = scalars[index]
      if s == " " || s == "\t" || s == "\r" || s == "\n" {
        index += 1
        continue
      }
      if s == "/" && peek(1) == "/" {
        index += 2
        while !isAtEnd && scalars[index] != "\n" {
          index += 1
        }
        continue
      }
      if s == "/" && peek(1) == "*" {
        index += 2
        while !isAtEnd {
          if scalars[index] == "*" && peek(1) == "/" {
            index += 2
            break
          }
          index += 1
        }
        continue
      }
      break
    }
  }

  private mutating func parseValue() throws -> Any {
    skipWhitespaceAndComments()
    guard let ch = peek() else {
      throw OpenStepPlistError.unexpectedEndOfInput
    }
    switch ch {
    case "{":
      return try parseDictionary()
    case "(":
      return try parseArray()
    case "<":
      return try parseDataLiteral()
    case "\"":
      return try parseQuotedString()
    default:
      return try parseUnquotedString()
    }
  }

  private mutating func parseDictionary() throws -> [String: Any] {
    _ = advance() // '{'
    var dict: [String: Any] = [:]
    while true {
      skipWhitespaceAndComments()
      guard let ch = peek() else {
        throw OpenStepPlistError.unexpectedEndOfInput
      }
      if ch == "}" {
        _ = advance()
        return dict
      }
      let key: String
      if ch == "\"" {
        key = try parseQuotedString()
      } else {
        key = try parseUnquotedString()
      }
      skipWhitespaceAndComments()
      guard peek() == "=" else {
        throw OpenStepPlistError.expectedToken("=", offset: index)
      }
      _ = advance()
      let value = try parseValue()
      dict[key] = value
      skipWhitespaceAndComments()
      if peek() == ";" || peek() == "," {
        _ = advance()
      }
    }
  }

  private mutating func parseArray() throws -> [Any] {
    _ = advance() // '('
    var items: [Any] = []
    while true {
      skipWhitespaceAndComments()
      guard let ch = peek() else {
        throw OpenStepPlistError.unexpectedEndOfInput
      }
      if ch == ")" {
        _ = advance()
        return items
      }
      let value = try parseValue()
      items.append(value)
      skipWhitespaceAndComments()
      if peek() == "," {
        _ = advance()
      }
    }
  }

  private mutating func parseDataLiteral() throws -> Data {
    let startOffset = index
    _ = advance() // '<'
    var hex = ""
    while !isAtEnd {
      let ch = advance()
      if ch == ">" {
        if hex.count % 2 != 0 {
          throw OpenStepPlistError.invalidDataLiteral(offset: startOffset)
        }
        var data = Data()
        data.reserveCapacity(hex.count / 2)
        var i = hex.startIndex
        while i < hex.endIndex {
          let next = hex.index(i, offsetBy: 2)
          guard let byte = UInt8(hex[i..<next], radix: 16) else {
            throw OpenStepPlistError.invalidDataLiteral(offset: startOffset)
          }
          data.append(byte)
          i = next
        }
        return data
      }
      if ch == " " || ch == "\t" || ch == "\r" || ch == "\n" {
        continue
      }
      hex.append(Character(ch))
    }
    throw OpenStepPlistError.unexpectedEndOfInput
  }

  private mutating func parseQuotedString() throws -> String {
    _ = advance() // '"'
    var out = ""
    while !isAtEnd {
      let ch = advance()
      if ch == "\"" {
        return out
      }
      if ch != "\\" {
        out.append(Character(ch))
        continue
      }
      guard !isAtEnd else {
        throw OpenStepPlistError.unexpectedEndOfInput
      }
      let esc = advance()
      switch esc {
      case "n": out.append("\n")
      case "r": out.append("\r")
      case "t": out.append("\t")
      case "\"": out.append("\"")
      case "\\": out.append("\\")
      case "a": out.append("\u{07}")
      case "b": out.append("\u{08}")
      case "f": out.append("\u{0C}")
      case "v": out.append("\u{0B}")
      case "U", "u":
        var digits = ""
        for _ in 0..<4 where !isAtEnd {
          if let p = peek(), isHexDigit(p) {
            digits.append(Character(advance()))
          }
        }
        if let code = UInt32(digits, radix: 16), let scalar = UnicodeScalar(code) {
          out.append(Character(scalar))
        }
      case "x":
        var digits = ""
        for _ in 0..<2 where !isAtEnd {
          if let p = peek(), isHexDigit(p) {
            digits.append(Character(advance()))
          }
        }
        if let code = UInt32(digits, radix: 16), let scalar = UnicodeScalar(code) {
          out.append(Character(scalar))
        }
      case "0"..."7":
        var digits = String(Character(esc))
        for _ in 0..<2 where !isAtEnd {
          if let p = peek(), p >= "0" && p <= "7" {
            digits.append(Character(advance()))
          } else {
            break
          }
        }
        if let code = UInt32(digits, radix: 8), let scalar = UnicodeScalar(code) {
          out.append(Character(scalar))
        }
      default:
        out.append(Character(esc))
      }
    }
    throw OpenStepPlistError.unexpectedEndOfInput
  }

  private mutating func parseUnquotedString() throws -> String {
    let startOffset = index
    var out = ""
    while !isAtEnd {
      let ch = scalars[index]
      if ch == "/" && (peek(1) == "/" || peek(1) == "*") {
        break
      }
      if isUnquotedScalar(ch) {
        out.append(Character(advance()))
      } else {
        break
      }
    }
    if out.isEmpty {
      let bad = peek().map { Character($0) } ?? "?"
      throw OpenStepPlistError.unexpectedCharacter(bad, offset: startOffset)
    }
    return out
  }

  private func isHexDigit(_ s: UnicodeScalar) -> Bool {
    (s >= "0" && s <= "9") || (s >= "a" && s <= "f") || (s >= "A" && s <= "F")
  }

  private func isUnquotedScalar(_ s: UnicodeScalar) -> Bool {
    (s >= "a" && s <= "z")
      || (s >= "A" && s <= "Z")
      || (s >= "0" && s <= "9")
      || s == "_" || s == "$" || s == "/" || s == "." || s == "-" || s == "+" || s == ":"
  }
}
