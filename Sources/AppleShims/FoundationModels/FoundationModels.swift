import Foundation

#if !os(macOS)
  public struct Transcript: Sendable {
    public struct TextSegment: Sendable {
      public let content: String
      public init(content: String) { self.content = content }
    }
    public enum Segment: Sendable {
      case text(TextSegment)
    }
    public struct Instructions: Sendable {
      public let segments: [Segment]
      public let toolDefinitions: [Any]
      public init(segments: [Segment], toolDefinitions: [Any] = []) {
        self.segments = segments
        self.toolDefinitions = toolDefinitions
      }
    }
    public struct Prompt: Sendable {
      public let segments: [Segment]
      public init(segments: [Segment]) { self.segments = segments }
    }
    public struct Response: Sendable {
      public let assetIDs: [String]
      public let segments: [Segment]
      public init(assetIDs: [String] = [], segments: [Segment]) {
        self.assetIDs = assetIDs
        self.segments = segments
      }
    }
    public enum Entry: Sendable {
      case instructions(Instructions)
      case prompt(Prompt)
      case response(Response)
    }
    public let entries: [Entry]
    public init(entries: [Entry] = []) { self.entries = entries }
  }

  public final class SystemLanguageModel: @unchecked Sendable {
    public enum Guardrails: Sendable, Equatable {
      case `default`
      case permissiveContentTransformations
    }
    public enum Availability: Sendable, Equatable {
      public enum UnavailableReason: Sendable, Equatable {
        case deviceNotEligible
        case appleIntelligenceNotEnabled
        case modelNotReady
      }
      case available
      case unavailable(UnavailableReason)
    }
    public static let `default` = SystemLanguageModel()
    public let guardrails: Guardrails
    public var availability: Availability { .unavailable(.deviceNotEligible) }
    public init(guardrails: Guardrails = .default) {
      self.guardrails = guardrails
    }
  }

  public struct GenerationOptions: Sendable {
    public var maximumResponseTokens: Int?
    public init(maximumResponseTokens: Int? = nil) {
      self.maximumResponseTokens = maximumResponseTokens
    }
  }

  public final class LanguageModelSession: @unchecked Sendable {
    public enum GenerationError: Error, Sendable {
      public struct Context: Sendable {
        public let debugDescription: String
        public init(debugDescription: String = "") { self.debugDescription = debugDescription }
      }
      public struct Refusal: Sendable {
        public var explanation: Response { Response(content: "") }
        public init() {}
      }
      case guardrailViolation(Context)
      case refusal(Refusal, Context)
      case exceededContextWindowSize(Context)
      case assetsUnavailable(Context)
      case unsupportedLanguageOrLocale(Context)
      case concurrentRequests(Context)
      case rateLimited(Context)
      case decodingFailure(Context)
      case unsupportedGuide(Context)
    }

    public struct Response: Sendable {
      public let content: String
      public init(content: String = "") { self.content = content }
    }

    public struct ResponseStream: AsyncSequence, Sendable {
      public typealias Element = Snapshot
      public struct Snapshot: Sendable {
        public let content: String
        public init(content: String = "") { self.content = content }
      }
      public struct AsyncIterator: AsyncIteratorProtocol {
        public mutating func next() async throws -> Snapshot? {
          throw GenerationError.assetsUnavailable(.init(debugDescription: "Apple Intelligence is unavailable on this platform."))
        }
      }
      public func makeAsyncIterator() -> AsyncIterator { AsyncIterator() }
    }

    public init(model: SystemLanguageModel = .default, transcript: Transcript = Transcript()) {}
    public init(instructions: String? = nil) {}

    public func respond(to prompt: String) async throws -> Response {
      throw GenerationError.assetsUnavailable(.init(debugDescription: "Apple Intelligence is unavailable on this platform."))
    }

    public func streamResponse(to prompt: String, options: GenerationOptions = GenerationOptions()) -> ResponseStream {
      ResponseStream()
    }
  }
#endif
