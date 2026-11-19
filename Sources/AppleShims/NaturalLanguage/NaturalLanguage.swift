import Foundation

#if !os(macOS)
  public struct NLLanguage: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public static let english = NLLanguage("en")
    public static let simplifiedChinese = NLLanguage("zh-Hans")
    public static let undetermined = NLLanguage("und")
  }

  public final class NLLanguageRecognizer: @unchecked Sendable {
    public var dominantLanguage: NLLanguage? { nil }
    public init() {}
    public func processString(_ string: String) {}
    public func reset() {}
  }
#endif
