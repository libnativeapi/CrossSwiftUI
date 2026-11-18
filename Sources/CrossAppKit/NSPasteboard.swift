import Foundation
#if !os(macOS)
  import NativeAPI
#endif
#if os(Windows)
  import CAppKitWindows
#endif

public protocol NSPasteboardWriting: NSObjectProtocol {}
public protocol NSPasteboardReading: NSObjectProtocol {}

extension NSString: NSPasteboardWriting, NSPasteboardReading {}
extension NSURL: NSPasteboardWriting, NSPasteboardReading {}
extension NSImage: NSPasteboardWriting, NSPasteboardReading {}

open class NSPasteboardItem: NSObject, NSPasteboardWriting, NSPasteboardReading {
  private var storage: [NSPasteboard.PasteboardType: Data] = [:]

  public var types: [NSPasteboard.PasteboardType] {
    Array(storage.keys)
  }

  public override init() {
    super.init()
  }

  @discardableResult
  public func setData(_ data: Data, forType type: NSPasteboard.PasteboardType) -> Bool {
    storage[type] = data
    return true
  }

  @discardableResult
  public func setString(_ string: String, forType type: NSPasteboard.PasteboardType) -> Bool {
    storage[type] = Data(string.utf8)
    return true
  }

  public func data(forType type: NSPasteboard.PasteboardType) -> Data? {
    storage[type]
  }

  public func string(forType type: NSPasteboard.PasteboardType) -> String? {
    guard let data = storage[type] else { return nil }
    return String(data: data, encoding: .utf8)
  }
}

open class NSPasteboard: NSObject, @unchecked Sendable {
  public struct Name: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let general = Name("Apple CFPasteboard general")
  }

  public struct PasteboardType: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public init(rawValue: String) { self.rawValue = rawValue }

    public static let string = PasteboardType("public.utf8-plain-text")
    public static let fileURL = PasteboardType("public.file-url")
    public static let URL = PasteboardType("public.url")
    public static let png = PasteboardType("public.png")
    public static let tiff = PasteboardType("public.tiff")
    public static let html = PasteboardType("public.html")
    public static let rtf = PasteboardType("public.rtf")
    public static let pdf = PasteboardType("com.adobe.pdf")
  }

  public struct ReadingOptionKey: RawRepresentable, Equatable, Hashable, Sendable {
    public let rawValue: String
    public init(_ rawValue: String) { self.rawValue = rawValue }
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let urlReadingFileURLsOnly = ReadingOptionKey("NSPasteboardURLReadingFileURLsOnlyKey")
    public static let urlReadingContentsConformToTypes = ReadingOptionKey("NSPasteboardURLReadingContentsConformToTypesKey")
  }

  public static let general = NSPasteboard(name: .general, isSystemGeneral: true)

  public let name: Name
  private let isSystemGeneral: Bool
  private var localChangeCount: Int = 0
  private var localItems: [NSPasteboardItem] = []

  public init(name: Name, isSystemGeneral: Bool = false) {
    self.name = name
    self.isSystemGeneral = isSystemGeneral
    super.init()
  }

  public static func withUniqueName() -> NSPasteboard {
    NSPasteboard(name: Name("CrossAppKit.\(UUID().uuidString)"), isSystemGeneral: false)
  }

  public var changeCount: Int {
    #if os(Windows)
      if isSystemGeneral {
        return Int(cak_clipboard_sequence_number()) + localChangeCount
      }
    #endif
    return localChangeCount
  }

  @discardableResult
  public func clearContents() -> Int {
    localItems.removeAll()
    #if os(Windows)
      if isSystemGeneral {
        _ = cak_clipboard_clear()
        return changeCount
      }
    #endif
    localChangeCount += 1
    return localChangeCount
  }

  @discardableResult
  public func declareTypes(_ newTypes: [PasteboardType], owner newOwner: Any?) -> Int {
    clearContents()
  }

  @discardableResult
  public func setString(_ string: String, forType dataType: PasteboardType) -> Bool {
    if localItems.isEmpty { localItems.append(NSPasteboardItem()) }
    _ = localItems[0].setString(string, forType: dataType)
    #if os(Windows)
      if isSystemGeneral {
        if dataType == .fileURL, let url = URL(string: string), url.isFileURL {
          let path = url.path
          return path.withCString { cstr in
            var ptr: UnsafePointer<CChar>? = cstr
            return withUnsafePointer(to: &ptr) { arr in
              cak_clipboard_set_files(arr, 1) != 0
            }
          }
        }
        if dataType == .string || dataType == .URL || dataType == .html {
          return cak_clipboard_set_text(string) != 0
        }
        localChangeCount += 1
        return true
      }
    #endif
    localChangeCount += 1
    return true
  }

  public func string(forType dataType: PasteboardType) -> String? {
    #if os(Windows)
      if isSystemGeneral {
        if dataType == .string {
          if let cstr = cak_clipboard_get_text() {
            defer { cak_free(cstr) }
            return String(cString: cstr)
          }
          return nil
        }
        if dataType == .fileURL {
          if let files = readSystemFileURLs().first {
            return files.absoluteString
          }
        }
      }
    #endif
    return localItems.first?.string(forType: dataType)
  }

  @discardableResult
  public func setData(_ data: Data?, forType dataType: PasteboardType) -> Bool {
    guard let data else { return false }
    if localItems.isEmpty { localItems.append(NSPasteboardItem()) }
    _ = localItems[0].setData(data, forType: dataType)
    #if os(Windows)
      if isSystemGeneral && (dataType == .png || dataType == .tiff) {
        return data.withUnsafeBytes { raw in
          cak_clipboard_set_png(raw.bindMemory(to: UInt8.self).baseAddress, data.count) != 0
        }
      }
    #endif
    localChangeCount += 1
    return true
  }

  public func data(forType dataType: PasteboardType) -> Data? {
    #if os(Windows)
      if isSystemGeneral && (dataType == .png || dataType == .tiff) {
        var len: Int = 0
        if let ptr = cak_clipboard_get_png(&len), len > 0 {
          let d = Data(bytes: ptr, count: len)
          cak_free(ptr)
          return d
        }
      }
    #endif
    return localItems.first?.data(forType: dataType)
  }

  @discardableResult
  public func writeObjects(_ objects: [any NSPasteboardWriting]) -> Bool {
    var urls: [URL] = []
    var strings: [String] = []
    var images: [NSImage] = []
    var items: [NSPasteboardItem] = []

    for obj in objects {
      if let u = obj as? NSURL, let swiftURL = u as URL? {
        if swiftURL.isFileURL { urls.append(swiftURL) } else { strings.append(swiftURL.absoluteString) }
      } else if let s = obj as? NSString {
        strings.append(s as String)
      } else if let attr = obj as? NSAttributedString {
        strings.append(attr.string)
      } else if let img = obj as? NSImage {
        images.append(img)
      } else if let item = obj as? NSPasteboardItem {
        items.append(item)
      }
    }

    if !items.isEmpty {
      localItems = items
    }

    #if os(Windows)
      if isSystemGeneral {
        if !urls.isEmpty {
          let cStrings = urls.map { _strdup($0.path) }
          defer { for p in cStrings { free(p) } }
          let ptrs: [UnsafePointer<CChar>?] = cStrings.map { UnsafePointer($0) }
          return ptrs.withUnsafeBufferPointer { buf in
            cak_clipboard_set_files(buf.baseAddress, Int32(buf.count)) != 0
          }
        }
        if let firstImg = images.first, let data = firstImg.imageData {
          return setData(data, forType: .png)
        }
        if let firstStr = strings.first {
          return setString(firstStr, forType: .string)
        }
      }
    #endif

    if !urls.isEmpty {
      localItems = urls.map { u in
        let item = NSPasteboardItem()
        item.setString(u.absoluteString, forType: .fileURL)
        return item
      }
    } else if let firstImg = images.first, let data = firstImg.imageData {
      _ = setData(data, forType: .png)
    } else if let firstStr = strings.first {
      _ = setString(firstStr, forType: .string)
    }
    localChangeCount += 1
    return true
  }

  public func readObjects(forClasses classArray: [AnyClass], options: [ReadingOptionKey: Any]? = nil) -> [Any]? {
    var results: [Any] = []
    let wantsURL = classArray.contains { $0 === NSURL.self }
    let wantsString = classArray.contains { $0 === NSString.self }
    let wantsImage = classArray.contains { $0 === NSImage.self }

    if wantsURL {
      let urls = readFileURLs()
      if !urls.isEmpty { results.append(contentsOf: urls) }
    }
    if wantsImage, let data = data(forType: .png), let img = NSImage(data: data) {
      results.append(img)
    }
    if wantsString, let str = string(forType: .string) {
      results.append(str)
    }
    return results.isEmpty ? nil : results
  }

  public var pasteboardItems: [NSPasteboardItem]? {
    #if os(Windows)
      if isSystemGeneral {
        let urls = readSystemFileURLs()
        if !urls.isEmpty {
          return urls.map { u in
            let item = NSPasteboardItem()
            item.setString(u.absoluteString, forType: .fileURL)
            return item
          }
        }
        var synthetic: [NSPasteboardItem] = []
        let item = NSPasteboardItem()
        var hasAny = false
        if let s = string(forType: .string) {
          item.setString(s, forType: .string)
          hasAny = true
        }
        if let png = data(forType: .png) {
          item.setData(png, forType: .png)
          hasAny = true
        }
        if hasAny { synthetic.append(item) }
        if !localItems.isEmpty {
          for (k, v) in localItems[0].types.compactMap({ t in localItems[0].data(forType: t).map { (t, $0) } }) {
            if item.data(forType: k) == nil {
              item.setData(v, forType: k)
              if synthetic.isEmpty { synthetic.append(item) }
            }
          }
        }
        return synthetic.isEmpty ? nil : synthetic
      }
    #endif
    return localItems.isEmpty ? nil : localItems
  }

  public var types: [PasteboardType]? {
    guard let items = pasteboardItems, let first = items.first else { return nil }
    return first.types
  }

  public func canReadObject(forClasses classArray: [AnyClass], options: [ReadingOptionKey: Any]? = nil) -> Bool {
    if classArray.contains(where: { $0 == NSURL.self }) {
      return !readFileURLs().isEmpty
    }
    if classArray.contains(where: { $0 == NSString.self }) {
      return string(forType: .string) != nil
    }
    return false
  }

  public func availableType(from types: [PasteboardType]) -> PasteboardType? {
    let available = Set(self.types ?? [])
    return types.first { available.contains($0) }
  }

  private func readFileURLs() -> [URL] {
    #if os(Windows)
      if isSystemGeneral {
        return readSystemFileURLs()
      }
    #endif
    return localItems.compactMap { item in
      guard let str = item.string(forType: .fileURL) else { return nil }
      return URL(string: str)
    }
  }

  #if os(Windows)
    private func readSystemFileURLs() -> [URL] {
      guard let cstr = cak_clipboard_get_files_newline() else { return [] }
      defer { cak_free(cstr) }
      let raw = String(cString: cstr)
      return raw.split(separator: "\n").map { URL(fileURLWithPath: String($0)) }
    }
  #endif
}
