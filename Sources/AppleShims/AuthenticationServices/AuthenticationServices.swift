import Foundation
import CrossAppKit

#if !os(macOS)
  public typealias ASPresentationAnchor = NSWindow

  @MainActor
  public protocol ASWebAuthenticationPresentationContextProviding: AnyObject {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor
  }

  @MainActor
  open class ASWebAuthenticationSession: NSObject {
    public enum Callback: Sendable {
      case customScheme(String)
      case https(host: String, path: String)
    }

    public weak var presentationContextProvider: (any ASWebAuthenticationPresentationContextProviding)?
    public var prefersEphemeralWebBrowserSession: Bool = false
    private let completionHandler: (URL?, (any Error)?) -> Void

    public init(
      url: URL,
      callbackURLScheme: String?,
      completionHandler: @escaping (URL?, (any Error)?) -> Void
    ) {
      self.completionHandler = completionHandler
      super.init()
    }

    public init(
      url: URL,
      callback: Callback,
      completionHandler: @escaping (URL?, (any Error)?) -> Void
    ) {
      self.completionHandler = completionHandler
      super.init()
    }

    @discardableResult
    public func start() -> Bool {
      completionHandler(nil, NSError(domain: "ASWebAuthenticationSession", code: -1))
      return false
    }

    public func cancel() {}
  }

  public struct ASWebAuthenticationSessionError: Error, Equatable, Hashable, Sendable {
    public enum Code: Int, Sendable {
      case canceledLogin = 1
      case presentationContextNotProvided = 2
      case presentationContextInvalid = 3
    }
    public let code: Code
    public init(_ code: Code) { self.code = code }
  }
#endif
