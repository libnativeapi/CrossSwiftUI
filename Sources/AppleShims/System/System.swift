import Foundation

#if !os(macOS)
  public struct FilePath: Hashable, Sendable {
    public struct Component: Hashable, Sendable {
      public let string: String
      public init(_ string: String) { self.string = string }
    }
    public let string: String
    public init(_ string: String) { self.string = string }
    public var isAbsolute: Bool {
      string.hasPrefix("/") || string.hasPrefix("\\") || (string.count >= 2 && string[string.index(after: string.startIndex)] == ":")
    }
    public var components: [Component] {
      string.split { $0 == "/" || $0 == "\\" }.map { Component(String($0)) }
    }
  }

  public struct FilePermissions: OptionSet, Sendable {
    public let rawValue: UInt16
    public init(rawValue: UInt16) { self.rawValue = rawValue }
  }

  public struct FileDescriptor: RawRepresentable, Hashable, Sendable {
    public let rawValue: Int32
    public init(rawValue: Int32) { self.rawValue = rawValue }
    public enum AccessMode: Int32, Sendable {
      case readOnly = 0
      case writeOnly = 1
      case readWrite = 2
    }
    public struct OpenOptions: OptionSet, Sendable {
      public let rawValue: Int32
      public init(rawValue: Int32) { self.rawValue = rawValue }
      public static let create = OpenOptions(rawValue: 1 << 0)
      public static let truncate = OpenOptions(rawValue: 1 << 1)
    }
  }
#endif
