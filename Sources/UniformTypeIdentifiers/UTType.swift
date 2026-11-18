import Foundation

public struct UTType: Hashable, Codable, Sendable, CustomStringConvertible {
  public let identifier: String
  public let preferredFilenameExtension: String?
  public let preferredMIMEType: String?
  private let supertypes: Set<String>

  public var description: String { identifier }
  public var isDynamic: Bool { identifier.hasPrefix("dyn.") }
  public var isDeclared: Bool { !isDynamic }
  public var localizedDescription: String? {
    if isDynamic {
      return preferredFilenameExtension.map { "\($0.uppercased()) File" }
    }
    return identifier.split(separator: ".").last.map { String($0).replacingOccurrences(of: "-", with: " ") }
  }

  public init(
    _ identifier: String,
    preferredFilenameExtension: String? = nil,
    preferredMIMEType: String? = nil,
    supertypes: Set<String> = ["public.item", "public.data"]
  ) {
    self.identifier = identifier
    self.preferredFilenameExtension = preferredFilenameExtension
    self.preferredMIMEType = preferredMIMEType
    self.supertypes = supertypes
  }

  public init?(_ identifier: String) {
    if let known = Self.byIdentifier[identifier.lowercased()] {
      self = known
    } else {
      self.init(identifier, preferredFilenameExtension: nil, preferredMIMEType: nil)
    }
  }

  public init(exportedAs identifier: String, conformingTo parent: UTType? = nil) {
    var supers: Set<String> = ["public.item", "public.data"]
    if let parent {
      supers.insert(parent.identifier)
      supers.formUnion(parent.supertypes)
    }
    self.init(identifier, supertypes: supers)
  }

  public init(importedAs identifier: String, conformingTo parent: UTType? = nil) {
    self.init(exportedAs: identifier, conformingTo: parent)
  }

  public init?(filenameExtension: String, conformingTo supertype: UTType? = nil) {
    let ext = filenameExtension.lowercased().trimmingCharacters(in: CharacterSet(charactersIn: "."))
    guard !ext.isEmpty else { return nil }
    if let match = Self.byExtension[ext] {
      if let supertype, !match.conforms(to: supertype) { return nil }
      self = match
      return
    }
    var supers: Set<String> = ["public.item", "public.data"]
    if let supertype {
      supers.insert(supertype.identifier)
      supers.formUnion(supertype.supertypes)
    }
    self.init("dyn.ext.\(ext)", preferredFilenameExtension: ext, supertypes: supers)
  }

  public init?(mimeType: String, conformingTo supertype: UTType? = nil) {
    let clean = mimeType.split(separator: ";").first.map {
      String($0).trimmingCharacters(in: .whitespaces).lowercased()
    } ?? ""
    guard !clean.isEmpty else { return nil }
    if let match = Self.byMIME[clean] {
      if let supertype, !match.conforms(to: supertype) { return nil }
      self = match
      return
    }
    var supers: Set<String> = ["public.item", "public.data"]
    if clean.hasPrefix("image/") { supers.insert("public.image") }
    if clean.hasPrefix("audio/") { supers.insert("public.audio") }
    if clean.hasPrefix("video/") { supers.insert("public.movie") }
    if clean.hasPrefix("text/") { supers.insert("public.text") }
    if let supertype {
      supers.insert(supertype.identifier)
      supers.formUnion(supertype.supertypes)
    }
    let ext = clean.split(separator: "/").last.map(String.init)
    self.init("dyn.mime.\(clean)", preferredFilenameExtension: ext, preferredMIMEType: clean, supertypes: supers)
  }

  public func conforms(to type: UTType) -> Bool {
    identifier == type.identifier || supertypes.contains(type.identifier)
  }

  public static let item = UTType("public.item", supertypes: [])
  public static let content = UTType("public.content", supertypes: ["public.item"])
  public static let data = UTType("public.data", supertypes: ["public.item"])
  public static let directory = UTType("public.directory", supertypes: ["public.item"])
  public static let folder = UTType("public.folder", supertypes: ["public.directory", "public.item"])
  public static let volume = UTType("public.volume", supertypes: ["public.folder", "public.directory", "public.item"])
  public static let package = UTType("com.apple.package", supertypes: ["public.directory", "public.item"])
  public static let bundle = UTType("com.apple.bundle", supertypes: ["public.directory", "public.item"])
  public static let application = UTType("com.apple.application", preferredFilenameExtension: "exe", supertypes: ["public.executable", "public.item"])
  public static let applicationBundle = UTType("com.apple.application-bundle", preferredFilenameExtension: "app", supertypes: ["com.apple.application", "com.apple.package", "public.directory", "public.item"])
  public static let unixExecutable = UTType("public.unix-executable", preferredFilenameExtension: "exe", supertypes: ["public.executable", "public.data", "public.item"])
  public static let executable = UTType("public.executable", preferredFilenameExtension: "exe", supertypes: ["public.item"])
  public static let fileURL = UTType("public.file-url", supertypes: ["public.url", "public.data"])
  public static let url = UTType("public.url", supertypes: ["public.data"])
  public static let text = UTType("public.text", preferredMIMEType: "text/plain", supertypes: ["public.data", "public.content"])
  public static let plainText = UTType("public.plain-text", preferredFilenameExtension: "txt", preferredMIMEType: "text/plain", supertypes: ["public.text", "public.data", "public.content"])
  public static let utf8PlainText = UTType("public.utf8-plain-text", preferredFilenameExtension: "txt", preferredMIMEType: "text/plain", supertypes: ["public.plain-text", "public.text", "public.data"])
  public static let sourceCode = UTType("public.source-code", supertypes: ["public.plain-text", "public.text", "public.data"])
  public static let json = UTType("public.json", preferredFilenameExtension: "json", preferredMIMEType: "application/json", supertypes: ["public.text", "public.data"])
  public static let xml = UTType("public.xml", preferredFilenameExtension: "xml", preferredMIMEType: "application/xml", supertypes: ["public.text", "public.data"])
  public static let html = UTType("public.html", preferredFilenameExtension: "html", preferredMIMEType: "text/html", supertypes: ["public.text", "public.data"])
  public static let rtf = UTType("public.rtf", preferredFilenameExtension: "rtf", preferredMIMEType: "application/rtf", supertypes: ["public.text", "public.data"])
  public static let pdf = UTType("com.adobe.pdf", preferredFilenameExtension: "pdf", preferredMIMEType: "application/pdf", supertypes: ["public.data", "public.content"])
  public static let image = UTType("public.image", supertypes: ["public.data", "public.content"])
  public static let png = UTType("public.png", preferredFilenameExtension: "png", preferredMIMEType: "image/png", supertypes: ["public.image", "public.data", "public.content"])
  public static let jpeg = UTType("public.jpeg", preferredFilenameExtension: "jpg", preferredMIMEType: "image/jpeg", supertypes: ["public.image", "public.data", "public.content"])
  public static let gif = UTType("com.compuserve.gif", preferredFilenameExtension: "gif", preferredMIMEType: "image/gif", supertypes: ["public.image", "public.data", "public.content"])
  public static let tiff = UTType("public.tiff", preferredFilenameExtension: "tiff", preferredMIMEType: "image/tiff", supertypes: ["public.image", "public.data", "public.content"])
  public static let webP = UTType("org.webmproject.webp", preferredFilenameExtension: "webp", preferredMIMEType: "image/webp", supertypes: ["public.image", "public.data", "public.content"])
  public static let svg = UTType("public.svg-image", preferredFilenameExtension: "svg", preferredMIMEType: "image/svg+xml", supertypes: ["public.image", "public.xml", "public.text", "public.data"])
  public static let heic = UTType("public.heic", preferredFilenameExtension: "heic", preferredMIMEType: "image/heic", supertypes: ["public.image", "public.data"])
  public static let icns = UTType("com.apple.icns", preferredFilenameExtension: "icns", supertypes: ["public.image", "public.data"])
  public static let ico = UTType("com.microsoft.ico", preferredFilenameExtension: "ico", preferredMIMEType: "image/x-icon", supertypes: ["public.image", "public.data"])
  public static let audio = UTType("public.audio", supertypes: ["public.audiovisual-content", "public.data", "public.content"])
  public static let mp3 = UTType("public.mp3", preferredFilenameExtension: "mp3", preferredMIMEType: "audio/mpeg", supertypes: ["public.audio", "public.data"])
  public static let wav = UTType("com.microsoft.waveform-audio", preferredFilenameExtension: "wav", preferredMIMEType: "audio/wav", supertypes: ["public.audio", "public.data"])
  public static let movie = UTType("public.movie", supertypes: ["public.audiovisual-content", "public.data", "public.content"])
  public static let mpeg4Movie = UTType("public.mpeg-4", preferredFilenameExtension: "mp4", preferredMIMEType: "video/mp4", supertypes: ["public.movie", "public.data"])
  public static let quickTimeMovie = UTType("com.apple.quicktime-movie", preferredFilenameExtension: "mov", preferredMIMEType: "video/quicktime", supertypes: ["public.movie", "public.data"])
  public static let archive = UTType("public.archive", supertypes: ["public.data"])
  public static let zip = UTType("public.zip-archive", preferredFilenameExtension: "zip", preferredMIMEType: "application/zip", supertypes: ["public.archive", "public.data"])
  public static let gzip = UTType("org.gnu.gnu-zip-archive", preferredFilenameExtension: "gz", preferredMIMEType: "application/gzip", supertypes: ["public.archive", "public.data"])
  public static let compositeContent = UTType("public.composite-content", supertypes: ["public.content", "public.item"])
  public static let spreadsheet = UTType("public.spreadsheet", supertypes: ["public.content", "public.item"])
  public static let presentation = UTType("public.presentation", supertypes: ["public.composite-content", "public.content", "public.item"])
  public static let mpeg2TransportStream = UTType("public.mpeg-2-transport-stream", preferredFilenameExtension: "ts", preferredMIMEType: "video/mp2t", supertypes: ["public.movie", "public.audiovisual-content", "public.data", "public.content"])

  private static let allKnown: [UTType] = [
    .item, .content, .data, .directory, .folder, .volume, .package, .bundle, .application,
    .applicationBundle, .unixExecutable, .executable, .fileURL, .url, .text, .plainText,
    .utf8PlainText, .sourceCode, .json, .xml, .html, .rtf, .pdf, .image, .png, .jpeg, .gif,
    .tiff, .webP, .svg, .heic, .icns, .ico, .audio, .mp3, .wav, .movie, .mpeg4Movie,
    .quickTimeMovie, .archive, .zip, .gzip,
  ]

  private static let byIdentifier: [String: UTType] = Dictionary(
    uniqueKeysWithValues: allKnown.map { ($0.identifier.lowercased(), $0) }
  )

  private static let byExtension: [String: UTType] = {
    var map: [String: UTType] = [:]
    for t in allKnown {
      if let ext = t.preferredFilenameExtension { map[ext] = t }
    }
    map["jpeg"] = .jpeg
    map["tif"] = .tiff
    map["htm"] = .html
    map["md"] = UTType("net.daringfireball.markdown", preferredFilenameExtension: "md", preferredMIMEType: "text/markdown", supertypes: ["public.plain-text", "public.text", "public.data"])
    map["swift"] = .sourceCode
    map["js"] = .sourceCode
    map["ts"] = .sourceCode
    map["py"] = .sourceCode
    map["rs"] = .sourceCode
    map["c"] = .sourceCode
    map["cpp"] = .sourceCode
    map["h"] = .sourceCode
    map["sh"] = .sourceCode
    map["ps1"] = .sourceCode
    map["bat"] = .executable
    map["cmd"] = .executable
    map["lnk"] = .application
    return map
  }()

  private static let byMIME: [String: UTType] = {
    var map: [String: UTType] = [:]
    for t in allKnown {
      if let mime = t.preferredMIMEType { map[mime] = t }
    }
    map["image/jpg"] = .jpeg
    return map
  }()
}

#if !os(macOS)
  extension URLResourceKey {
    public static let contentTypeKey = URLResourceKey("NSURLContentTypeKey")
  }

  extension URLResourceValues {
    public var contentType: UTType? { nil }
  }
#endif
