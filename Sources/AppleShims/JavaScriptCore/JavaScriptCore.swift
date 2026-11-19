import Foundation

#if !os(macOS)
  open class JSVirtualMachine: NSObject, @unchecked Sendable {}

  open class JSValue: NSObject, @unchecked Sendable {
    public override init() { super.init() }
    public init?(newObjectIn context: JSContext!) { super.init() }
    public var isUndefined: Bool { true }
    public var isNull: Bool { false }
    public var isBoolean: Bool { false }
    public var isNumber: Bool { false }
    public var isString: Bool { false }
    public var isObject: Bool { false }
    public var isArray: Bool { false }
    public func toString() -> String! { "" }
    public func toBool() -> Bool { false }
    public func toInt32() -> Int32 { 0 }
    public func toDouble() -> Double { 0 }
    public func toObject() -> Any! { nil }
    public func toDictionary() -> [AnyHashable: Any]! { [:] }
    public func toArray() -> [Any]! { [] }
    public func objectForKeyedSubscript(_ key: Any!) -> JSValue! { JSValue() }
    public func setObject(_ object: Any!, forKeyedSubscript key: Any!) {}
    @discardableResult
    public func call(withArguments arguments: [Any]!) -> JSValue! { JSValue() }
    @discardableResult
    public func invokeMethod(_ method: String!, withArguments arguments: [Any]!) -> JSValue! { JSValue() }
  }

  open class JSContext: @unchecked Sendable {
    public var exception: JSValue?
    public var exceptionHandler: ((JSContext?, JSValue?) -> Void)?
    public var globalObject: JSValue! { JSValue() }
    public var name: String?
    public init!() {}
    public init!(virtualMachine: JSVirtualMachine!) {}
    @discardableResult
    public func evaluateScript(_ script: String!, withSourceURL sourceURL: URL? = nil) -> JSValue! { JSValue() }
    public func setObject(_ object: Any!, forKeyedSubscript key: Any!) {}
    public func objectForKeyedSubscript(_ key: Any!) -> JSValue! { JSValue() }
  }
#endif
