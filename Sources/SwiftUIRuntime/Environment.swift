import Foundation

/// Environment writes are value copies scoped to evaluating a subtree.

public protocol EnvironmentKey {
  associatedtype Value
  static var defaultValue: Value { get }
}

@attached(accessor)
@attached(peer, names: prefixed(__Key_))
public macro Entry() = #externalMacro(module: "SwiftUIRuntimeMacros", type: "EntryMacro")

@attached(accessor)
public macro _EntryDefaultValue() =
  #externalMacro(module: "SwiftUIRuntimeMacros", type: "EntryDefaultValueMacro")
public enum ColorScheme: Sendable { case light, dark }
public struct EnvironmentValues {
  var objects: [ObjectIdentifier: AnyObject] = [:]
  private var values: [ObjectIdentifier: Any] = [:]
  public var foregroundColor: Color?
  public var isEnabled: Bool
  public var layoutDirection: LayoutDirection = .leftToRight
  public var colorScheme: ColorScheme = .light
  public var tint: Color = .blue
  public var locale: Locale {
    get { self[LocaleKey.self] }
    set { self[LocaleKey.self] = newValue }
  }
  public var openURL: OpenURLAction {
    get { self[OpenURLKey.self] }
    set { self[OpenURLKey.self] = newValue }
  }
  public var font: Font? = nil
  public var accessibilityReduceMotion = false
  public init(foregroundColor: Color? = nil, isEnabled: Bool = true) {
    self.foregroundColor = foregroundColor
    self.isEnabled = isEnabled
  }
  public subscript<K: EnvironmentKey>(_ key: K.Type) -> K.Value {
    get { values[ObjectIdentifier(key)] as? K.Value ?? K.defaultValue }
    set { values[ObjectIdentifier(key)] = newValue }
  }
  public static let `default` = EnvironmentValues()
  package static var current = EnvironmentValues()
}
@propertyWrapper public struct Environment<Value>: _EnvironmentProperty {
  private final class Storage { var value: Value? }
  private enum Source {
    case keyPath(KeyPath<EnvironmentValues, Value>)
    case resolver((EnvironmentValues) -> Value)
  }
  private let storage = Storage()
  private let source: Source

  public init(_ keyPath: KeyPath<EnvironmentValues, Value>) {
    self.source = .keyPath(keyPath)
  }

  public init(_ objectType: Value.Type) where Value: AnyObject & Observable {
    self.source = .resolver { env in
      guard let object = env.objects[ObjectIdentifier(Value.self)] as? Value else {
        preconditionFailure("No Observable object of type \(Value.self) found in environment.")
      }
      return object
    }
  }

  public init<T: AnyObject & Observable>(_ objectType: T.Type) where Value == T? {
    self.source = .resolver { env in
      env.objects[ObjectIdentifier(T.self)] as? T
    }
  }

  private func read(from env: EnvironmentValues) -> Value {
    switch source {
    case .keyPath(let kp): return env[keyPath: kp]
    case .resolver(let fn): return fn(env)
    }
  }

  public var wrappedValue: Value { storage.value ?? read(from: EnvironmentValues.current) }
  func installEnvironment() { storage.value = read(from: EnvironmentValues.current) }
}
struct EnvironmentView<Content: View, Value>: View, _PrimitiveView {
  typealias Body = Never
  let content: Content
  let keyPath: WritableKeyPath<EnvironmentValues, Value>
  let value: Value
  var body: Never { fatalError("EnvironmentView is primitive") }
  func _makeElement(path: ViewPath) -> Element {
    let saved = EnvironmentValues.current
    var scoped = saved
    scoped[keyPath: keyPath] = value
    EnvironmentValues.current = scoped
    defer { EnvironmentValues.current = saved }
    return _render(content, path: path)
  }
}
extension View {
  public func environment<Value>(
    _ keyPath: WritableKeyPath<EnvironmentValues, Value>, _ value: Value
  ) -> some View {
    EnvironmentView(content: self, keyPath: keyPath, value: value)
  }
}

public struct OpenURLAction {
  public enum Result { case handled, discarded, systemAction }
  let action: (URL) -> Result

  public init(handler: @escaping (URL) -> Result) { action = handler }

  @discardableResult public func callAsFunction(_ url: URL) -> Result { action(url) }
}

private enum LocaleKey: EnvironmentKey {
  static var defaultValue: Locale { .current }
}

private enum OpenURLKey: EnvironmentKey {
  static let defaultValue = OpenURLAction { _ in .systemAction }
}
