import Foundation

#if !os(macOS)
  public struct NWInterface: Sendable {
    public enum InterfaceType: Sendable {
      case other, wifi, cellular, wiredEthernet, loopback
    }
  }

  public enum NWEndpoint: Sendable {
    public struct Port: Equatable, Hashable, Sendable, ExpressibleByIntegerLiteral {
      public let rawValue: UInt16
      public init(integerLiteral value: UInt16) { self.rawValue = value }
      public init?(rawValue: UInt16) { self.rawValue = rawValue }
      public static let any = Port(integerLiteral: 0)
    }
    public struct Host: Equatable, Hashable, Sendable, ExpressibleByStringLiteral {
      public struct IPv4Address: Equatable, Hashable, Sendable {
        public static let loopback = IPv4Address()
      }
      public let rawValue: String
      public init(stringLiteral value: String) { self.rawValue = value }
      public init(_ value: String) { self.rawValue = value }
      public static let ipv4Loopback = Host("127.0.0.1")
      public static func ipv4(_ address: IPv4Address) -> Host { .ipv4Loopback }
    }
    case hostPort(host: Host, port: Port)
  }

  public final class NWParameters: @unchecked Sendable {
    public static let tcp = NWParameters()
    public static let ipv4 = NWParameters()
    public var allowLocalEndpointReuse: Bool = false
    public var requiredLocalEndpoint: NWEndpoint? = nil
    public var requiredInterfaceType: NWInterface.InterfaceType = .other
    public init() {}
  }

  public enum NWError: Error, Sendable {
    case posix(Int32)
    case dns(Int32)
    case tls(Int32)
  }

  public final class NWConnection: @unchecked Sendable {
    public enum State: Sendable {
      case setup, waiting(NWError), preparing, ready, failed(NWError), cancelled
    }
    public enum SendCompletion: @unchecked Sendable {
      case contentProcessed(@Sendable (NWError?) -> Void)
      case idempotent
    }
    public var stateUpdateHandler: (@Sendable (State) -> Void)?
    public func start(queue: DispatchQueue) {}
    public func cancel() {}
    public func forceCancel() {}
    public func receive(
      minimumIncompleteLength: Int,
      maximumLength: Int,
      completion: @escaping @Sendable (Data?, Any?, Bool, NWError?) -> Void
    ) {
      completion(nil, nil, true, nil)
    }
    public func send(
      content: Data?,
      contentContext: Any? = nil,
      isComplete: Bool = true,
      completion: SendCompletion
    ) {
      if case .contentProcessed(let fn) = completion { fn(nil) }
    }
  }

  public final class NWListener: @unchecked Sendable {
    public enum State: Sendable {
      case setup, waiting(NWError), ready, failed(NWError), cancelled
    }
    public var stateUpdateHandler: (@Sendable (State) -> Void)?
    public var newConnectionHandler: (@Sendable (NWConnection) -> Void)?
    public var port: NWEndpoint.Port? { nil }
    public init(using parameters: NWParameters, on port: NWEndpoint.Port = .any) throws {
      throw NWError.posix(78)
    }
    public func start(queue: DispatchQueue) {}
    public func cancel() {}
  }

  public struct TCP: Sendable {
    public init() {}
  }

  public struct NetworkParameters<ProtocolType>: Sendable {
    public init() {}
    public static func parameters(_ build: () -> ProtocolType) -> NetworkParameters<ProtocolType> {
      NetworkParameters()
    }
    public func localEndpoint(_ endpoint: NWEndpoint) -> NetworkParameters<ProtocolType> {
      self
    }
  }

  public final class NetworkConnection<ProtocolType>: @unchecked Sendable {
    public struct Metadata: Sendable {
      public var endOfStream: Bool
      public init(endOfStream: Bool = true) { self.endOfStream = endOfStream }
    }
    public struct ReceiveMessage: Sendable {
      public var content: Data
      public var metadata: Metadata
      public init(content: Data = Data(), metadata: Metadata = Metadata()) {
        self.content = content
        self.metadata = metadata
      }
    }
    public init() {}
    public func receive(atLeast min: Int, atMost max: Int) async throws -> ReceiveMessage {
      throw NWError.posix(78)
    }
    public func send(_ data: Data, endOfStream: Bool = false) async throws {
      throw NWError.posix(78)
    }
  }

  public final class NetworkListener<ProtocolType>: @unchecked Sendable {
    public enum State: Sendable {
      case setup, waiting(NWError), ready, failed(NWError), cancelled
    }
    public var newConnectionLimit: Int = 0
    public var port: NWEndpoint.Port? { nil }
    public init(using parameters: NetworkParameters<ProtocolType>) throws {
      throw NWError.posix(78)
    }
    @discardableResult
    public func onStateUpdate(
      _ handler: @escaping (NetworkListener<ProtocolType>, State) -> Void
    ) -> Self {
      self
    }
    public func run(
      _ handler: @escaping @Sendable (NetworkConnection<ProtocolType>) async -> Void
    ) async throws {
      throw NWError.posix(78)
    }
  }
#endif
