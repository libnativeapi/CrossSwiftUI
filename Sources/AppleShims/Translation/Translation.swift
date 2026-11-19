import Foundation

#if !os(macOS)
  public final class LanguageAvailability: @unchecked Sendable {
    public enum Status: Sendable {
      case installed, supported, unsupported
    }
    public init() {}
    public var supportedLanguages: [Locale.Language] { get async { [] } }
    public func status(from source: Locale.Language, to target: Locale.Language?) async -> Status {
      .unsupported
    }
  }

  public final class TranslationSession: @unchecked Sendable {
    public struct Response: Sendable {
      public let targetText: String
      public init(targetText: String) { self.targetText = targetText }
    }
    public init(installedSource: Locale.Language, target: Locale.Language) {}
    public func translate(_ string: String) async throws -> Response {
      throw NSError(domain: "Translation", code: -1)
    }
  }
#endif
