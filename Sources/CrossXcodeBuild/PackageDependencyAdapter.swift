import Foundation

/// Generic adapter for external Apple-ecosystem SwiftPM packages consumed by an
/// Xcode project when building on Windows or Linux through CrossSwiftUI.
///
/// Two Apple-only assumptions break unmodified SwiftPM packages on non-Apple hosts:
/// 1. Targets `import SwiftUI`, `AppKit`, `CoreGraphics`, etc. without declaring a
///    SwiftPM dependency because those modules live in Apple's system SDK.
/// 2. Targets ship `*.xcassets` catalogs without declaring `resources:` in
///    `Package.swift`, relying on Xcode's implicit asset-catalog compilation and
///    `Bundle.module` synthesis.
///
/// `PackageDependencyAdapter` inspects a package checkout, detects whether either
/// condition applies, and — when needed — writes a patched `Package.swift` that
/// injects the required CrossSwiftUI product dependencies and explicit `.copy(...)`
/// resource entries for undeclared `*.xcassets` catalogs. Pure-Swift packages that
/// need neither patch are left untouched.
public enum PackageDependencyAdapter {
  /// Modules provided by CrossSwiftUI that Apple packages import implicitly from the SDK.
  public static let crossSwiftProvidedModules: Set<String> = [
    "SwiftUI",
    "AppKit",
    "CoreGraphics",
    "Combine",
    "CryptoKit",
    "UniformTypeIdentifiers",
    "OSLog",
    "ServiceManagement",
    "ImageIO",
    "QuickLookThumbnailing",
    "AVKit",
    "CloudKit",
    "ColorSync",
    "CommonCrypto",
    "Compression",
    "JavaScriptCore",
    "Translation",
  ]

  public struct TargetInspection: Equatable, Sendable {
    public let name: String
    public let relativePath: String
    public let importedCrossSwiftModules: [String]
    public let undeclaredAssetCatalogs: [String]
  }

  public struct InspectionResult: Equatable, Sendable {
    public let targets: [TargetInspection]
    public var needsAdaptation: Bool {
      targets.contains { !$0.importedCrossSwiftModules.isEmpty || !$0.undeclaredAssetCatalogs.isEmpty }
    }
  }

  /// Inspects a local Swift package directory to determine whether any of its
  /// targets need CrossSwiftUI module dependencies or undeclared `.xcassets` resources.
  public static func inspect(packageRoot: URL) -> InspectionResult {
    let manifestURL = packageRoot.appendingPathComponent("Package.swift")
    guard let manifest = try? String(contentsOf: manifestURL, encoding: .utf8) else {
      return InspectionResult(targets: [])
    }

    // If the package already explicitly references CrossSwiftUI, leave it as-is.
    if manifest.contains("CrossSwiftUI") {
      return InspectionResult(targets: [])
    }

    let declaredTargets = parseTargetDeclarations(from: manifest)
    let fm = FileManager.default
    var results: [TargetInspection] = []

    for decl in declaredTargets {
      let relPath = decl.path ?? "Sources/\(decl.name)"
      let targetDir = packageRoot.appendingPathComponent(relPath)
      guard fm.fileExists(atPath: targetDir.path) else { continue }

      let imports = scanImportedModules(in: targetDir)
        .filter { crossSwiftProvidedModules.contains($0) }
        .sorted()

      let catalogs = findAssetCatalogs(in: targetDir)
        .filter { relCatalog in
          // Skip catalogs already mentioned in the target's manifest slice.
          let catalogName = URL(fileURLWithPath: relCatalog).lastPathComponent
          return !decl.rawBody.contains(relCatalog) && !decl.rawBody.contains(catalogName)
        }
        .sorted()

      results.append(TargetInspection(
        name: decl.name,
        relativePath: relPath,
        importedCrossSwiftModules: imports,
        undeclaredAssetCatalogs: catalogs
      ))
    }

    return InspectionResult(targets: results)
  }

  /// Patches `Package.swift` text in-place for a checked-out package so its targets
  /// depend on CrossSwiftUI products for implicitly imported Apple frameworks and
  /// explicitly copy any undeclared `*.xcassets` catalogs into `Bundle.module`.
  public static func patchManifest(
    _ manifest: String,
    inspection: InspectionResult,
    crossSwiftRoot: URL
  ) -> String {
    guard inspection.needsAdaptation else { return manifest }

    let crossSwiftIdentity = crossSwiftRoot.lastPathComponent.lowercased()
    let crossSwiftPkgDecl = ".package(path: \(swiftStringLiteral(crossSwiftRoot.path)))"
    var updated = manifest

    // 1. Ensure top-level `dependencies: [...]` includes CrossSwiftUI.
    updated = injectTopLevelPackageDependency(updated, packageDecl: crossSwiftPkgDecl)

    // 2. For each target needing modules or resources, patch its `.target(...)` block.
    for target in inspection.targets
      where !target.importedCrossSwiftModules.isEmpty || !target.undeclaredAssetCatalogs.isEmpty
    {
      let productDeps = target.importedCrossSwiftModules.map { mod in
        ".product(name: \(swiftStringLiteral(mod)), package: \(swiftStringLiteral(crossSwiftIdentity)))"
      }
      let resourceDecls = target.undeclaredAssetCatalogs.map { relPath in
        ".copy(\(swiftStringLiteral(relPath)))"
      }
      updated = patchTargetBlock(
        in: updated,
        targetName: target.name,
        addDependencies: productDeps,
        addResources: resourceDecls
      )
    }

    return updated
  }

  /// Adapts a checked-out package directory into `outputDirectory` if inspection shows
  /// it needs CrossSwiftUI module injection or undeclared `.xcassets` resource wiring.
  /// Returns `nil` if the package needs no adaptation.
  public static func adaptCheckoutIfNeeded(
    sourceRoot: URL,
    outputDirectory: URL,
    crossSwiftRoot: URL
  ) throws -> URL? {
    let inspection = inspect(packageRoot: sourceRoot)
    guard inspection.needsAdaptation else { return nil }

    let manifestURL = sourceRoot.appendingPathComponent("Package.swift")
    let originalManifest = try String(contentsOf: manifestURL, encoding: .utf8)
    let patchedManifest = patchManifest(
      originalManifest,
      inspection: inspection,
      crossSwiftRoot: crossSwiftRoot
    )

    let fm = FileManager.default
    if fm.fileExists(atPath: outputDirectory.path) {
      try fm.removeItem(at: outputDirectory)
    }
    try fm.createDirectory(at: outputDirectory, withIntermediateDirectories: true)

    // Stage top-level entries from sourceRoot (using directory links where possible to avoid
    // duplicating large asset trees, and writing the patched Package.swift).
    let items = try fm.contentsOfDirectory(atPath: sourceRoot.path)
    for item in items {
      if item == ".git" || item == ".build" || item == "Package.swift" { continue }
      let src = sourceRoot.appendingPathComponent(item)
      let dst = outputDirectory.appendingPathComponent(item)
      var isDir: ObjCBool = false
      let exists = fm.fileExists(atPath: src.path, isDirectory: &isDir)
      guard exists else { continue }
      if isDir.boolValue {
        try linkOrCopyDirectory(from: src, to: dst)
      } else {
        try fm.copyItem(at: src, to: dst)
      }
    }

    try patchedManifest.write(
      to: outputDirectory.appendingPathComponent("Package.swift"),
      atomically: true,
      encoding: .utf8
    )

    return outputDirectory
  }

  /// Shallow-clones (or reuses a cached checkout of) a remote package dependency.
  public static func checkoutRemotePackage(
    _ remote: RemotePackageDependency,
    cacheRoot: URL
  ) throws -> URL {
    let fm = FileManager.default
    let targetRef: String? = {
      if let rev = remote.pinnedRevision, !rev.isEmpty { return rev }
      if let ver = remote.pinnedVersion, !ver.isEmpty { return ver }
      switch remote.requirement {
      case .revision(let r): return r
      case .branch(let b): return b
      case .exact(let v): return v
      default: return nil
      }
    }()

    let refKey = targetRef ?? "default"
    let slug = ProcessRunner.sanitizedSlug(remote.packageName).prefix(24)
    let hash = ProcessRunner.fnv1aHex(remote.repositoryURL + "|" + refKey)
    let checkoutDir = cacheRoot.appendingPathComponent("\(slug)-\(hash)")
    if fm.fileExists(atPath: checkoutDir.appendingPathComponent("Package.swift").path) {
      return checkoutDir
    }

    guard let gitExe = ProcessRunner.findExecutable(named: ["git"]) else {
      throw BuildBackendError.toolMissing(
        "Could not locate 'git' to inspect remote package \(remote.repositoryURL)"
      )
    }

    try fm.createDirectory(at: cacheRoot, withIntermediateDirectories: true)
    if fm.fileExists(atPath: checkoutDir.path) {
      try? fm.removeItem(at: checkoutDir)
    }

    if let targetRef {
      try fm.createDirectory(at: checkoutDir, withIntermediateDirectories: true)
      for args in [
        ["init"],
        ["remote", "add", "origin", remote.repositoryURL],
        ["fetch", "--depth", "1", "origin", targetRef],
        ["checkout", "FETCH_HEAD"],
      ] {
        let res = try ProcessRunner.run(executable: gitExe, arguments: args, workingDirectory: checkoutDir)
        if res.exitCode != 0 {
          throw ProcessRunnerError.commandFailed(
            command: "git \(args.joined(separator: " "))",
            exitCode: res.exitCode,
            output: res.stdout + "\n" + res.stderr
          )
        }
      }
    } else {
      let args = ["clone", "--depth", "1", remote.repositoryURL, checkoutDir.path]
      let res = try ProcessRunner.run(executable: gitExe, arguments: args)
      if res.exitCode != 0 {
        throw ProcessRunnerError.commandFailed(
          command: "git \(args.joined(separator: " "))",
          exitCode: res.exitCode,
          output: res.stdout + "\n" + res.stderr
        )
      }
    }

    return checkoutDir
  }

  // MARK: - Helpers

  private struct RawTargetDecl {
    let name: String
    let path: String?
    let rawBody: String
  }

  private static func parseTargetDeclarations(from manifest: String) -> [RawTargetDecl] {
    var result: [RawTargetDecl] = []
    guard let regex = try? NSRegularExpression(pattern: "\\.(?:target|executableTarget)\\s*\\(") else {
      return result
    }
    let ns = manifest as NSString
    let matches = regex.matches(in: manifest, range: NSRange(location: 0, length: ns.length))
    for match in matches {
      let openParenIdx = match.range.location + match.range.length - 1
      guard let closeParenIdx = findMatchingDelimiter(in: manifest, openIndex: openParenIdx, open: "(", close: ")")
      else { continue }
      let bodyRange = NSRange(location: openParenIdx + 1, length: closeParenIdx - openParenIdx - 1)
      let body = ns.substring(with: bodyRange)
      guard let name = extractStringArgument(named: "name", in: body) else { continue }
      let path = extractStringArgument(named: "path", in: body)
      result.append(RawTargetDecl(name: name, path: path, rawBody: body))
    }
    return result
  }

  private static func extractStringArgument(named label: String, in text: String) -> String? {
    let pattern = "(?:^|[,\\s])\(label)\\s*:\\s*\"([^\"]+)\""
    guard let regex = try? NSRegularExpression(pattern: pattern),
          let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
          let range = Range(match.range(at: 1), in: text)
    else { return nil }
    return String(text[range])
  }

  private static func findMatchingDelimiter(
    in text: String,
    openIndex: Int,
    open: UInt8,
    close: UInt8
  ) -> Int? {
    let bytes = Array(text.utf8)
    guard openIndex < bytes.count, bytes[openIndex] == open else { return nil }
    var depth = 0
    var inString = false
    var escaped = false
    var i = openIndex
    while i < bytes.count {
      let b = bytes[i]
      if inString {
        if escaped { escaped = false }
        else if b == 0x5C { escaped = true }
        else if b == 0x22 { inString = false }
      } else {
        if b == 0x22 { inString = true }
        else if b == open { depth += 1 }
        else if b == close {
          depth -= 1
          if depth == 0 { return i }
        }
      }
      i += 1
    }
    return nil
  }

  private static func findMatchingDelimiter(
    in text: String,
    openIndex: Int,
    open: Character,
    close: Character
  ) -> Int? {
    guard let o = open.asciiValue, let c = close.asciiValue else { return nil }
    return findMatchingDelimiter(in: text, openIndex: openIndex, open: o, close: c)
  }

  private static func scanImportedModules(in directory: URL) -> Set<String> {
    let fm = FileManager.default
    guard let enumerator = fm.enumerator(
      at: directory,
      includingPropertiesForKeys: [.isDirectoryKey],
      options: [.skipsHiddenFiles]
    ) else { return [] }

    guard let regex = try? NSRegularExpression(
      pattern: "(?m)^\\s*(?:@\\w+\\s+)*import\\s+(?:(?:typealias|struct|class|enum|protocol|let|var|func)\\s+)?([A-Za-z_][A-Za-z0-9_]*)"
    ) else { return [] }

    var modules = Set<String>()
    for case let fileURL as URL in enumerator {
      let name = fileURL.lastPathComponent
      if name.lowercased().hasSuffix(".xcassets") || name == ".build" || name == ".git" {
        enumerator.skipDescendants()
        continue
      }
      guard fileURL.pathExtension.lowercased() == "swift",
            let text = try? String(contentsOf: fileURL, encoding: .utf8)
      else { continue }
      let range = NSRange(text.startIndex..., in: text)
      for match in regex.matches(in: text, range: range) {
        if let r = Range(match.range(at: 1), in: text) {
          modules.insert(String(text[r]))
        }
      }
    }
    return modules
  }

  private static func findAssetCatalogs(in targetDir: URL) -> [String] {
    let fm = FileManager.default
    guard let enumerator = fm.enumerator(
      at: targetDir,
      includingPropertiesForKeys: [.isDirectoryKey],
      options: [.skipsHiddenFiles]
    ) else { return [] }

    let basePath = targetDir.standardizedFileURL.path
    var catalogs: [String] = []
    for case let itemURL as URL in enumerator {
      if itemURL.lastPathComponent.lowercased().hasSuffix(".xcassets") {
        let full = itemURL.standardizedFileURL.path
        if full.hasPrefix(basePath + "/") {
          catalogs.append(String(full.dropFirst(basePath.count + 1)))
        } else {
          catalogs.append(itemURL.lastPathComponent)
        }
        enumerator.skipDescendants()
      }
    }
    return catalogs
  }

  private static func injectTopLevelPackageDependency(_ manifest: String, packageDecl: String) -> String {
    // Look for top-level `dependencies: [` inside `Package(...)`.
    guard let pkgRegex = try? NSRegularExpression(pattern: "Package\\s*\\("),
          let pkgMatch = pkgRegex.firstMatch(in: manifest, range: NSRange(manifest.startIndex..., in: manifest))
    else { return manifest }

    let ns = manifest as NSString
    let searchStart = pkgMatch.range.location + pkgMatch.range.length
    let searchRange = NSRange(location: searchStart, length: ns.length - searchStart)

    // Find `dependencies: [` that appears BEFORE `targets: [`.
    let targetsLoc = (try? NSRegularExpression(pattern: "\\btargets\\s*:\\s*\\["))?
      .firstMatch(in: manifest, range: searchRange)?.range.location ?? ns.length

    let beforeTargets = NSRange(location: searchStart, length: max(0, targetsLoc - searchStart))
    if let depRegex = try? NSRegularExpression(pattern: "\\bdependencies\\s*:\\s*\\["),
       let depMatch = depRegex.firstMatch(in: manifest, range: beforeTargets)
    {
      let openBracket = depMatch.range.location + depMatch.range.length - 1
      if let closeBracket = findMatchingDelimiter(in: manifest, openIndex: openBracket, open: "[", close: "]") {
        let inner = ns.substring(with: NSRange(location: openBracket + 1, length: closeBracket - openBracket - 1))
        let trimmed = inner.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix = ns.substring(to: closeBracket)
        let suffix = ns.substring(from: closeBracket)
        let sep = trimmed.isEmpty ? "\n    " : (trimmed.hasSuffix(",") ? "\n    " : ",\n    ")
        return prefix + sep + packageDecl + "\n  " + suffix
      }
    }

    // No top-level `dependencies:` parameter; insert right before `targets:`.
    if targetsLoc < ns.length {
      let prefix = ns.substring(to: targetsLoc)
      let suffix = ns.substring(from: targetsLoc)
      return prefix + "dependencies: [\n    \(packageDecl)\n  ],\n  " + suffix
    }
    return manifest
  }

  private static func patchTargetBlock(
    in manifest: String,
    targetName: String,
    addDependencies: [String],
    addResources: [String]
  ) -> String {
    guard let regex = try? NSRegularExpression(pattern: "\\.(?:target|executableTarget)\\s*\\(") else {
      return manifest
    }
    let ns = manifest as NSString
    let matches = regex.matches(in: manifest, range: NSRange(location: 0, length: ns.length))
    for match in matches {
      let openParen = match.range.location + match.range.length - 1
      guard let closeParen = findMatchingDelimiter(in: manifest, openIndex: openParen, open: "(", close: ")")
      else { continue }
      let bodyRange = NSRange(location: openParen + 1, length: closeParen - openParen - 1)
      let body = ns.substring(with: bodyRange)
      guard extractStringArgument(named: "name", in: body) == targetName else { continue }

      var patchedBody = body
      if !addDependencies.isEmpty {
        patchedBody = insertIntoArrayParameter(
          in: patchedBody,
          paramName: "dependencies",
          entries: addDependencies
        )
      }
      if !addResources.isEmpty {
        patchedBody = insertIntoArrayParameter(
          in: patchedBody,
          paramName: "resources",
          entries: addResources
        )
      }

      let prefix = ns.substring(to: bodyRange.location)
      let suffix = ns.substring(from: bodyRange.location + bodyRange.length)
      return prefix + patchedBody + suffix
    }
    return manifest
  }

  private static func insertIntoArrayParameter(
    in targetBody: String,
    paramName: String,
    entries: [String]
  ) -> String {
    let ns = targetBody as NSString
    if let regex = try? NSRegularExpression(pattern: "\\b\(paramName)\\s*:\\s*\\["),
       let match = regex.firstMatch(in: targetBody, range: NSRange(location: 0, length: ns.length))
    {
      let openBracket = match.range.location + match.range.length - 1
      if let closeBracket = findMatchingDelimiter(in: targetBody, openIndex: openBracket, open: "[", close: "]") {
        let inner = ns.substring(with: NSRange(location: openBracket + 1, length: closeBracket - openBracket - 1))
        let trimmed = inner.trimmingCharacters(in: .whitespacesAndNewlines)
        let prefix = ns.substring(to: closeBracket)
        let suffix = ns.substring(from: closeBracket)
        let joined = entries.joined(separator: ",\n        ")
        let sep = trimmed.isEmpty ? "\n        " : (trimmed.hasSuffix(",") ? "\n        " : ",\n        ")
        return prefix + sep + joined + "\n      " + suffix
      }
    }

    let trimmedEnd = targetBody.trimmingCharacters(in: .whitespacesAndNewlines)
    let comma = trimmedEnd.hasSuffix(",") ? "" : ","
    let joined = entries.joined(separator: ",\n        ")
    return targetBody + "\(comma)\n      \(paramName): [\n        \(joined)\n      ]"
  }

  private static func linkOrCopyDirectory(from src: URL, to dst: URL) throws {
    let fm = FileManager.default
    #if os(Windows)
      let cmdExe = URL(fileURLWithPath: ProcessRunner.environmentValue("ComSpec") ?? "C:\\Windows\\System32\\cmd.exe")
      let winDst = dst.path.replacingOccurrences(of: "/", with: "\\")
      let winSrc = src.path.replacingOccurrences(of: "/", with: "\\")
      if let res = try? ProcessRunner.run(
        executable: cmdExe,
        arguments: ["/c", "mklink", "/J", winDst, winSrc]
      ), res.exitCode == 0 {
        return
      }
    #else
      if (try? fm.createSymbolicLink(at: dst, withDestinationURL: src)) != nil {
        return
      }
    #endif
    try fm.copyItem(at: src, to: dst)
  }

  private static func swiftStringLiteral(_ value: String) -> String {
    let escaped = value
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
    return "\"\(escaped)\""
  }
}
