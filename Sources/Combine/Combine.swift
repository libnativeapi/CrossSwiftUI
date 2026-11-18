import Foundation

public protocol Cancellable {
  func cancel()
}

public final class AnyCancellable: Cancellable, Hashable {
  private var cancelAction: (() -> Void)?

  public init(_ cancel: @escaping () -> Void) {
    self.cancelAction = cancel
  }

  public init<C: Cancellable>(_ canceller: C) {
    self.cancelAction = { canceller.cancel() }
  }

  public func cancel() {
    let action = cancelAction
    cancelAction = nil
    action?()
  }

  public func store(in set: inout Set<AnyCancellable>) {
    set.insert(self)
  }

  public func store<C: RangeReplaceableCollection>(in collection: inout C)
  where C.Element == AnyCancellable {
    collection.append(self)
  }

  deinit {
    cancel()
  }

  public static func == (lhs: AnyCancellable, rhs: AnyCancellable) -> Bool {
    lhs === rhs
  }

  public func hash(into hasher: inout Hasher) {
    hasher.combine(ObjectIdentifier(self))
  }
}

public protocol Publisher<Output, Failure> {
  associatedtype Output
  associatedtype Failure: Error
  func sink(receiveValue: @escaping (Output) -> Void) -> AnyCancellable
}

extension Publisher {
  public func eraseToAnyPublisher() -> AnyPublisher<Output, Failure> {
    AnyPublisher(self)
  }

  public func autoconnect() -> Self {
    self
  }
}

public struct AnyPublisher<Output, Failure: Error>: Publisher {
  private let subscribeHandler: (@escaping (Output) -> Void) -> AnyCancellable

  public init<P: Publisher>(_ publisher: P) where P.Output == Output, P.Failure == Failure {
    self.subscribeHandler = { publisher.sink(receiveValue: $0) }
  }

  public init(_ subscribe: @escaping (@escaping (Output) -> Void) -> AnyCancellable) {
    self.subscribeHandler = subscribe
  }

  public func sink(receiveValue: @escaping (Output) -> Void) -> AnyCancellable {
    subscribeHandler(receiveValue)
  }
}

public final class PassthroughSubject<Output, Failure: Error>: Publisher {
  private var subscribers: [UUID: (Output) -> Void] = [:]

  public init() {}

  public func send(_ value: Output) {
    for handler in Array(subscribers.values) {
      handler(value)
    }
  }

  public func sink(receiveValue: @escaping (Output) -> Void) -> AnyCancellable {
    let id = UUID()
    subscribers[id] = receiveValue
    return AnyCancellable { [weak self] in
      self?.subscribers.removeValue(forKey: id)
    }
  }
}

public final class CurrentValueSubject<Output, Failure: Error>: Publisher {
  public var value: Output {
    didSet {
      for handler in Array(subscribers.values) {
        handler(value)
      }
    }
  }
  private var subscribers: [UUID: (Output) -> Void] = [:]

  public init(_ value: Output) {
    self.value = value
  }

  public func send(_ input: Output) {
    self.value = input
  }

  public func sink(receiveValue: @escaping (Output) -> Void) -> AnyCancellable {
    let id = UUID()
    subscribers[id] = receiveValue
    receiveValue(value)
    return AnyCancellable { [weak self] in
      self?.subscribers.removeValue(forKey: id)
    }
  }
}

extension Timer {
  public struct TimerPublisher: Publisher {
    public typealias Output = Date
    public typealias Failure = Never

    public let interval: TimeInterval
    public let runLoop: RunLoop
    public let mode: RunLoop.Mode

    public init(interval: TimeInterval, tolerance: TimeInterval? = nil, runLoop: RunLoop, mode: RunLoop.Mode) {
      self.interval = interval
      self.runLoop = runLoop
      self.mode = mode
    }

    public func sink(receiveValue: @escaping (Date) -> Void) -> AnyCancellable {
      let timer = Timer(timeInterval: max(0.01, interval), repeats: true) { _ in
        receiveValue(Date())
      }
      runLoop.add(timer, forMode: mode)
      return AnyCancellable {
        timer.invalidate()
      }
    }
  }

  public static func publish(
    every interval: TimeInterval,
    tolerance: TimeInterval? = nil,
    on runLoop: RunLoop,
    in mode: RunLoop.Mode,
    options: RunLoop.SchedulerOptions? = nil
  ) -> TimerPublisher {
    TimerPublisher(interval: interval, tolerance: tolerance, runLoop: runLoop, mode: mode)
  }
}

extension RunLoop {
  public struct SchedulerOptions: Sendable {}
}

extension NotificationCenter {
  public struct Publisher: Combine.Publisher {
    public typealias Output = Notification
    public typealias Failure = Never

    public let center: NotificationCenter
    public let name: Notification.Name
    public let object: AnyObject?

    public init(center: NotificationCenter, name: Notification.Name, object: AnyObject? = nil) {
      self.center = center
      self.name = name
      self.object = object
    }

    public func sink(receiveValue: @escaping (Notification) -> Void) -> AnyCancellable {
      let token = center.addObserver(forName: name, object: object, queue: .main) { note in
        receiveValue(note)
      }
      return AnyCancellable { [center] in
        center.removeObserver(token)
      }
    }
  }

  public func publisher(for name: Notification.Name, object: AnyObject? = nil) -> Publisher {
    Publisher(center: self, name: name, object: object)
  }
}
