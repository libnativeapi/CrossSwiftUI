import Foundation

public struct BuiltTargetArtifacts: Sendable {
  public let targetPlatform: TargetPlatform
  public let architecture: TargetArchitecture
  public let executableURL: URL
  public let buildDirectory: URL
  public let scratchDirectory: URL
  public let compiledAssets: CompiledAssets
  public let swiftExecutableURL: URL
  public let crossSwiftRoot: URL
  public let wasmPackageDirectory: URL?
  public let harmonyArtifacts: HarmonyBuildArtifacts?
  public let adaptedRemotePackageDirectories: [URL]

  public init(
    targetPlatform: TargetPlatform,
    architecture: TargetArchitecture,
    executableURL: URL,
    buildDirectory: URL,
    scratchDirectory: URL,
    compiledAssets: CompiledAssets,
    swiftExecutableURL: URL,
    crossSwiftRoot: URL,
    wasmPackageDirectory: URL?,
    harmonyArtifacts: HarmonyBuildArtifacts?,
    adaptedRemotePackageDirectories: [URL] = []
  ) {
    self.targetPlatform = targetPlatform
    self.architecture = architecture
    self.executableURL = executableURL
    self.buildDirectory = buildDirectory
    self.scratchDirectory = scratchDirectory
    self.compiledAssets = compiledAssets
    self.swiftExecutableURL = swiftExecutableURL
    self.crossSwiftRoot = crossSwiftRoot
    self.wasmPackageDirectory = wasmPackageDirectory
    self.harmonyArtifacts = harmonyArtifacts
    self.adaptedRemotePackageDirectories = adaptedRemotePackageDirectories
  }
}

public enum BuildBackendError: Error, LocalizedError {
  case crossSwiftNotFound
  case nativeAPINotFound(String)
  case toolMissing(String)
  case binaryMissing(String)

  public var errorDescription: String? {
    switch self {
    case .crossSwiftNotFound:
      return "Could not locate CrossSwiftUI checkout; pass --crossswift-path or set CROSS_SWIFTUI_PATH"
    case .nativeAPINotFound(let hint):
      return "Could not locate NativeAPI Swift binding (\(hint)); pass --nativeapi-path or set NATIVEAPI_SWIFT_PATH"
    case .toolMissing(let detail):
      return detail
    case .binaryMissing(let path):
      return "Built executable was not produced at '\(path)'"
    }
  }
}

public final class SwiftPMBackend {
  public init() {}

  public func build(
    project: ResolvedXcodeProject,
    platform: TargetPlatform,
    configuration: BuildConfiguration,
    derivedDataURL: URL,
    options: XcodeBuildOptions
  ) throws -> BuiltTargetArtifacts {
    let fm = FileManager.default
    let crossSwiftRoot = try Self.resolveCrossSwiftRoot(explicit: options.crossSwiftPath)
    let nativeAPISwiftRoot: URL?
    if platform == .wasm {
      nativeAPISwiftRoot = nil
    } else {
      nativeAPISwiftRoot = try Self.resolveNativeAPISwiftRoot(
        explicit: options.nativeAPISwiftPath,
        crossSwiftRoot: crossSwiftRoot
      )
    }

    if platform == .windows, let nativeAPISwiftRoot {
      try ensureWindowsNativeAPICoreJunction(nativeAPISwiftRoot: nativeAPISwiftRoot)
    }

    let buildRoot = resolveBuildDirectory(
      project: project,
      platform: platform,
      configuration: configuration,
      derivedDataURL: derivedDataURL,
      scratchDirectory: options.scratchDirectory,
      crossSwiftRoot: crossSwiftRoot
    )
    let scratchDir = buildRoot.appendingPathComponent(".b")
    try fm.createDirectory(at: buildRoot, withIntermediateDirectories: true)
    try fm.createDirectory(at: scratchDir, withIntermediateDirectories: true)

    let assetsStaging = buildRoot.appendingPathComponent("AssetsStaging")
    if fm.fileExists(atPath: assetsStaging.path) {
      try? fm.removeItem(at: assetsStaging)
    }
    let assetCompiler = AssetAndIconCompiler()
    let compiledAssets = try assetCompiler.compile(project: project, stagingRoot: assetsStaging)

    if platform == .harmonyos {
      guard let nativeAPISwiftRoot else {
        throw BuildBackendError.nativeAPINotFound(crossSwiftRoot.deletingLastPathComponent().path)
      }
      let harmony = try HarmonyBuilder.build(
        project: project,
        configuration: configuration,
        buildRoot: buildRoot,
        compiledAssets: compiledAssets,
        crossSwiftRoot: crossSwiftRoot,
        nativeAPISwiftRoot: nativeAPISwiftRoot
      )
      let swiftExe = (try? locateSwiftExecutable()) ?? URL(fileURLWithPath: "/usr/bin/swift")
      return BuiltTargetArtifacts(
        targetPlatform: .harmonyos,
        architecture: .arm64,
        executableURL: harmony.appObjectURL,
        buildDirectory: buildRoot,
        scratchDirectory: scratchDir,
        compiledAssets: compiledAssets,
        swiftExecutableURL: swiftExe,
        crossSwiftRoot: crossSwiftRoot,
        wasmPackageDirectory: nil,
        harmonyArtifacts: harmony
      )
    }

    var compiledResURL: URL?
    if platform == .windows, let rcURL = compiledAssets.windowsResourceScriptURL {
      compiledResURL = try compileWindowsResources(rcURL: rcURL)
    }

    try stageSources(
      project: project,
      platform: platform,
      generatedAssetSymbolsURL: compiledAssets.generatedSymbolsSwiftURL,
      buildRoot: buildRoot
    )

    let adaptedRemotePackages = try prepareAdaptedRemotePackages(
      project: project,
      platform: platform,
      buildRoot: buildRoot,
      crossSwiftRoot: crossSwiftRoot
    )

    let consoleSubsystem = options.consoleSubsystem
      || (project.mainTarget.buildSettings["CROSS_SWIFTUI_CONSOLE_SUBSYSTEM"]?.uppercased() == "YES")
    let manifestText = generatePackageManifest(
      project: project,
      platform: platform,
      configuration: configuration,
      consoleSubsystem: consoleSubsystem,
      crossSwiftRoot: crossSwiftRoot,
      nativeAPISwiftRoot: nativeAPISwiftRoot,
      compiledResourceURL: compiledResURL,
      adaptedRemotePackages: adaptedRemotePackages
    )
    let packageSwiftURL = buildRoot.appendingPathComponent("Package.swift")
    try writeIfChanged(text: manifestText, to: packageSwiftURL)

    if platform == .wasm {
      let (swiftTool, prefixArgs, wasmSDK) = try resolveWasmToolchainAndSDK(
        preferredSDK: project.mainTarget.buildSettings["SWIFT_WASM_SDK"]
          ?? ProcessRunner.environmentValue("SWIFT_WASM_SDK")
      )
      let jsArgs = prefixArgs + [
        "package",
        "--package-path", buildRoot.path,
        "--scratch-path", scratchDir.path,
        "--swift-sdk", wasmSDK,
        "js",
        "--product", project.mainTarget.executableName,
        "-c", configuration.swiftPMFlag,
      ]
      let logURL = buildRoot.appendingPathComponent("swift-wasm-build.log")
      let buildResult = try ProcessRunner.run(
        executable: swiftTool,
        arguments: jsArgs,
        workingDirectory: buildRoot,
        environmentOverrides: ["CROSS_SWIFTUI_WEB": "1"],
        logFile: logURL
      )
      if buildResult.exitCode != 0 {
        throw ProcessRunnerError.commandFailed(
          command: "\(swiftTool.path) \(jsArgs.joined(separator: " "))",
          exitCode: buildResult.exitCode,
          output: buildResult.stdout
        )
      }
      let wasmPkgDir = scratchDir.appendingPathComponent("plugins/PackageToJS/outputs/Package")
      let indexJS = wasmPkgDir.appendingPathComponent("index.js")
      guard fm.fileExists(atPath: indexJS.path) else {
        throw BuildBackendError.binaryMissing(indexJS.path)
      }
      let wasmBinary = wasmPkgDir.appendingPathComponent("\(project.mainTarget.executableName).wasm")
      return BuiltTargetArtifacts(
        targetPlatform: .wasm,
        architecture: .wasm32,
        executableURL: fm.fileExists(atPath: wasmBinary.path) ? wasmBinary : indexJS,
        buildDirectory: buildRoot,
        scratchDirectory: scratchDir,
        compiledAssets: compiledAssets,
        swiftExecutableURL: swiftTool,
        crossSwiftRoot: crossSwiftRoot,
        wasmPackageDirectory: wasmPkgDir,
        harmonyArtifacts: nil,
        adaptedRemotePackageDirectories: Array(adaptedRemotePackages.values)
      )
    }

    let swiftExe = try locateSwiftExecutable()
    var envOverrides: [String: String] = [:]
    if let nativeAPISwiftRoot {
      envOverrides["NATIVEAPI_SWIFT_PATH"] = nativeAPISwiftRoot.path
    }
    if platform == .windows,
       let devDir = ProcessRunner.environmentValue("DEVELOPER_DIR"),
       !devDir.isEmpty
    {
      envOverrides["DEVELOPER_DIR"] = devDir
    }

    var buildArgs = [
      "build",
      "-c", configuration.swiftPMFlag,
      "--package-path", buildRoot.path,
      "--scratch-path", scratchDir.path,
    ]
    if platform == .windows {
      buildArgs += ["--build-system", "native"]
    }
    if configuration == .release {
      buildArgs += [
        "-Xcc", "-ffunction-sections",
        "-Xcc", "-fdata-sections",
        "-Xcxx", "-ffunction-sections",
        "-Xcxx", "-fdata-sections",
      ]
    }
    let productArgs = buildArgs + ["--product", project.mainTarget.executableName]

    let logURL = buildRoot.appendingPathComponent("swift-build.log")
    let buildResult = try ProcessRunner.run(
      executable: swiftExe,
      arguments: productArgs,
      workingDirectory: buildRoot,
      environmentOverrides: envOverrides,
      logFile: logURL
    )
    if buildResult.exitCode != 0 {
      throw ProcessRunnerError.commandFailed(
        command: "\(swiftExe.path) \(productArgs.joined(separator: " "))",
        exitCode: buildResult.exitCode,
        output: buildResult.stdout
      )
    }

    let binPathArgs = buildArgs + ["--show-bin-path"]
    let binResult = try ProcessRunner.run(
      executable: swiftExe,
      arguments: binPathArgs,
      workingDirectory: buildRoot,
      environmentOverrides: envOverrides
    )
    if binResult.exitCode != 0 {
      throw ProcessRunnerError.commandFailed(
        command: "\(swiftExe.path) \(binPathArgs.joined(separator: " "))",
        exitCode: binResult.exitCode,
        output: binResult.stdout + "\n" + binResult.stderr
      )
    }

    let binDirPath = binResult.stdout
      .split(whereSeparator: \.isNewline)
      .last
      .map(String.init)?
      .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let binDirURL = URL(fileURLWithPath: binDirPath)
    let exeFilename =
      platform == .windows
      ? "\(project.mainTarget.executableName).exe"
      : project.mainTarget.executableName
    let executableURL = binDirURL.appendingPathComponent(exeFilename)
    guard fm.fileExists(atPath: executableURL.path) else {
      throw BuildBackendError.binaryMissing(executableURL.path)
    }

    return BuiltTargetArtifacts(
      targetPlatform: platform,
      architecture: .currentHost,
      executableURL: executableURL,
      buildDirectory: buildRoot,
      scratchDirectory: scratchDir,
      compiledAssets: compiledAssets,
      swiftExecutableURL: swiftExe,
      crossSwiftRoot: crossSwiftRoot,
      wasmPackageDirectory: nil,
      harmonyArtifacts: nil
    )
  }

  public static func resolveCrossSwiftRoot(explicit: URL?) throws -> URL {
    let fm = FileManager.default
    var candidates: [URL] = []
    if let explicit { candidates.append(explicit.standardizedFileURL) }
    if let envPath = ProcessRunner.environmentValue("CROSS_SWIFTUI_PATH"), !envPath.isEmpty {
      candidates.append(URL(fileURLWithPath: envPath).standardizedFileURL)
    }
    let fromFile = URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
    candidates.append(fromFile.standardizedFileURL)
    if let exeURL = Bundle.main.executableURL {
      var cursor = exeURL.resolvingSymlinksInPath().deletingLastPathComponent()
      for _ in 0..<5 {
        candidates.append(cursor)
        cursor = cursor.deletingLastPathComponent()
      }
    }
    var cwd = URL(fileURLWithPath: fm.currentDirectoryPath).standardizedFileURL
    for _ in 0..<6 {
      candidates.append(cwd)
      cwd = cwd.deletingLastPathComponent()
    }

    for candidate in candidates {
      let pkg = candidate.appendingPathComponent("Package.swift")
      let runtimeDir = candidate.appendingPathComponent("Sources/CrossSwiftUI")
      if fm.fileExists(atPath: pkg.path) && fm.fileExists(atPath: runtimeDir.path) {
        return candidate
      }
    }
    throw BuildBackendError.crossSwiftNotFound
  }

  public static func resolveNativeAPISwiftRoot(
    explicit: URL?,
    crossSwiftRoot: URL
  ) throws -> URL {
    let fm = FileManager.default
    var candidates: [URL] = []
    if let explicit { candidates.append(explicit.standardizedFileURL) }
    if let envPath = ProcessRunner.environmentValue("NATIVEAPI_SWIFT_PATH"), !envPath.isEmpty {
      candidates.append(URL(fileURLWithPath: envPath).standardizedFileURL)
    }
    let parentDir = crossSwiftRoot.deletingLastPathComponent()
    candidates.append(parentDir.appendingPathComponent("nativeapi/bindings/swift").standardizedFileURL)

    for candidate in candidates {
      let pkg = candidate.appendingPathComponent("Package.swift").path
      let coreSrc = candidate.appendingPathComponent("Sources/CNativeAPI/core/src").path
      if fm.fileExists(atPath: pkg) && fm.fileExists(atPath: coreSrc) {
        return candidate
      }
    }
    throw BuildBackendError.nativeAPINotFound(parentDir.path)
  }

  public func resolveBuildDirectory(
    project: ResolvedXcodeProject,
    platform: TargetPlatform,
    configuration: BuildConfiguration,
    derivedDataURL: URL,
    scratchDirectory: URL?,
    crossSwiftRoot _: URL
  ) -> URL {
    let slug = ProcessRunner.sanitizedSlug(project.mainTarget.executableName).prefix(16)
    let hash = ProcessRunner.fnv1aHex(
      "\(project.projectURL.path)|\(platform.rawValue)|\(configuration.rawValue)")

    if let scratch = scratchDirectory {
      return scratch.appendingPathComponent("\(slug)-\(hash)").standardizedFileURL
    }

    if platform == .windows {
      // Keep build and scratch paths short on Windows to avoid MAX_PATH (260 chars).
      return FileManager.default.temporaryDirectory
        .appendingPathComponent("csb/\(slug)-\(hash)")
        .standardizedFileURL
    }

    return derivedDataURL
      .appendingPathComponent("Build/Intermediates.noindex/\(slug)-\(hash)")
      .standardizedFileURL
  }

  private func ensureWindowsNativeAPICoreJunction(nativeAPISwiftRoot: URL) throws {
    let fm = FileManager.default
    let coreLink = nativeAPISwiftRoot.appendingPathComponent("Sources/CNativeAPI/core")
    let coreTarget = nativeAPISwiftRoot
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .appendingPathComponent("core")
      .standardizedFileURL

    var isDir: ObjCBool = false
    if fm.fileExists(atPath: coreLink.path, isDirectory: &isDir), isDir.boolValue {
      return
    }
    guard fm.fileExists(atPath: coreTarget.appendingPathComponent("src").path) else {
      return
    }
    if fm.fileExists(atPath: coreLink.path) {
      try? fm.removeItem(at: coreLink)
    }
    let cmdExe = URL(fileURLWithPath: ProcessRunner.environmentValue("ComSpec") ?? "C:\\Windows\\System32\\cmd.exe")
    let winLinkPath = coreLink.path.replacingOccurrences(of: "/", with: "\\")
    let winTargetPath = coreTarget.path.replacingOccurrences(of: "/", with: "\\")
    let res = try ProcessRunner.run(
      executable: cmdExe,
      arguments: ["/c", "mklink", "/J", winLinkPath, winTargetPath]
    )
    if res.exitCode != 0 {
      throw ProcessRunnerError.commandFailed(
        command: "mklink /J \(coreLink.path) \(coreTarget.path)",
        exitCode: res.exitCode,
        output: res.stdout + "\n" + res.stderr
      )
    }
  }

  private func compileWindowsResources(rcURL: URL) throws -> URL {
    let rcDir = rcURL.deletingLastPathComponent()
    let resURL = rcDir.appendingPathComponent("AppResources.res")
    var extraDirs: [URL] = []
    if let userProfile = ProcessRunner.environmentValue("USERPROFILE") {
      extraDirs.append(URL(fileURLWithPath: "\(userProfile)\\scoop\\apps\\llvm\\current\\bin"))
    }
    if let swift = try? locateSwiftExecutable() {
      extraDirs.append(swift.deletingLastPathComponent())
    }
    extraDirs.append(URL(fileURLWithPath: "C:\\Program Files\\LLVM\\bin"))

    guard let rcTool = ProcessRunner.findExecutable(
      named: ["llvm-rc", "rc"], extraDirectories: extraDirs)
    else {
      throw BuildBackendError.toolMissing(
        "Could not find 'llvm-rc' or 'rc.exe' to embed Windows icon and manifest"
      )
    }

    let isLlvmRc = rcTool.lastPathComponent.lowercased().contains("llvm-rc")
    let winResPath = resURL.path.replacingOccurrences(of: "/", with: "\\")
    var args: [String] = []
    if isLlvmRc {
      args = ["/C", "65001", "/FO", winResPath, rcURL.lastPathComponent]
    } else {
      args = ["/nologo", "/fo", winResPath, rcURL.lastPathComponent]
    }
    let result = try ProcessRunner.run(
      executable: rcTool,
      arguments: args,
      workingDirectory: rcDir
    )
    if result.exitCode != 0 {
      throw ProcessRunnerError.commandFailed(
        command: "\(rcTool.path) \(args.joined(separator: " "))",
        exitCode: result.exitCode,
        output: result.stdout + "\n" + result.stderr
      )
    }
    return resURL
  }

  private func locateSwiftExecutable() throws -> URL {
    var extraDirs: [URL] = []
    let fm = FileManager.default
    #if os(Windows)
      if let localAppData = ProcessRunner.environmentValue("LOCALAPPDATA") {
        let toolchainsDir = URL(fileURLWithPath: localAppData).appendingPathComponent("Programs/Swift/Toolchains")
        if let children = try? fm.contentsOfDirectory(at: toolchainsDir, includingPropertiesForKeys: nil) {
          for child in children.sorted(by: { $0.lastPathComponent > $1.lastPathComponent }) {
            extraDirs.append(child.appendingPathComponent("usr/bin"))
          }
        }
      }
    #elseif os(Linux)
      let home = fm.homeDirectoryForCurrentUser
      extraDirs.append(home.appendingPathComponent(".local/share/swiftly/bin"))
      extraDirs.append(home.appendingPathComponent(".local/bin"))
    #endif
    guard let swift = ProcessRunner.findExecutable(named: ["swift"], extraDirectories: extraDirs) else {
      throw BuildBackendError.toolMissing("Could not locate 'swift' compiler executable")
    }
    // Avoid `Circular swiftly proxy invocation` when `xcodebuild` itself is launched via `swift run`
    // under swiftly: resolve the proxy symlink directly to the active toolchain's `usr/bin/swift`.
    let resolved = swift.resolvingSymlinksInPath()
    if resolved.lastPathComponent == "swiftly" {
      if let locResult = try? ProcessRunner.run(executable: resolved, arguments: ["use", "--print-location"]),
         locResult.exitCode == 0
      {
        let toolchainRoot = locResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        if !toolchainRoot.isEmpty {
          let realSwift = URL(fileURLWithPath: toolchainRoot).appendingPathComponent("usr/bin/swift")
          if fm.isExecutableFile(atPath: realSwift.path) {
            return realSwift
          }
        }
      }
    }
    return swift
  }

  private func resolveWasmToolchainAndSDK(
    preferredSDK: String?
  ) throws -> (executable: URL, prefixArgs: [String], sdkID: String) {
    let fm = FileManager.default
    let home = fm.homeDirectoryForCurrentUser
    var candidates: [(URL, [String])] = []

    if let toolchainBin = ProcessRunner.environmentValue("SWIFT_TOOLCHAIN_BIN"), !toolchainBin.isEmpty {
      let swiftBin = URL(fileURLWithPath: toolchainBin).appendingPathComponent("swift")
      if fm.isExecutableFile(atPath: swiftBin.path) {
        candidates.append((swiftBin, []))
      }
    }

    let swiftlyDirs = [
      home.appendingPathComponent(".swiftly/bin"),
      home.appendingPathComponent(".local/share/swiftly/bin"),
      home.appendingPathComponent(".local/bin"),
    ]
    if let swiftly = ProcessRunner.findExecutable(named: ["swiftly"], extraDirectories: swiftlyDirs) {
      let toolchain = ProcessRunner.environmentValue("SWIFT_WASM_TOOLCHAIN") ?? "6.4.2"
      candidates.append((swiftly, ["run", "+\(toolchain)", "swift"]))
      candidates.append((swiftly, ["run", "swift"]))
    }

    if let defaultSwift = try? locateSwiftExecutable() {
      candidates.append((defaultSwift, []))
    }

    for (exe, prefix) in candidates {
      guard let res = try? ProcessRunner.run(executable: exe, arguments: prefix + ["sdk", "list"]),
            res.exitCode == 0
      else {
        continue
      }
      let sdks = res.stdout
        .components(separatedBy: .newlines)
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        .filter { !$0.isEmpty }

      if let preferred = preferredSDK, !preferred.isEmpty {
        if sdks.contains(preferred) {
          return (exe, prefix, preferred)
        }
      }
      if sdks.contains("swift-6.4.2-RELEASE_wasm") {
        return (exe, prefix, "swift-6.4.2-RELEASE_wasm")
      }
      if let matched = sdks.first(where: { $0.hasSuffix("_wasm") && !$0.contains("embedded") }) {
        return (exe, prefix, matched)
      }
    }

    if let preferred = preferredSDK, !preferred.isEmpty, let first = candidates.first {
      return (first.0, first.1, preferred)
    }

    throw BuildBackendError.toolMissing(
      "Could not find an installed Swift Wasm SDK (e.g. swift-6.4.2-RELEASE_wasm). Install one with 'swift sdk install' or set SWIFT_WASM_SDK."
    )
  }

  private func stageSources(
    project: ResolvedXcodeProject,
    platform: TargetPlatform,
    generatedAssetSymbolsURL: URL?,
    buildRoot: URL
  ) throws {
    let fm = FileManager.default
    let sourcesRoot = buildRoot.appendingPathComponent("Sources")
    if fm.fileExists(atPath: sourcesRoot.path) {
      try fm.removeItem(at: sourcesRoot)
    }
    try fm.createDirectory(at: sourcesRoot, withIntermediateDirectories: true)

    let shouldPreprocessSwift = (platform == .linux || platform == .windows)

    for target in project.allTargets {
      let isMain = target.name == project.mainTarget.name
      let targetDir = sourcesRoot.appendingPathComponent(target.name)
      try fm.createDirectory(at: targetDir, withIntermediateDirectories: true)

      let rootPrefix = project.projectRootURL.standardizedFileURL.path + "/"
      func copySourceList(_ files: [URL], into destRoot: URL, preprocessSwift: Bool) throws {
        var usedRelativePaths = Set<String>()
        for (idx, fileURL) in files.enumerated() {
          let stdPath = fileURL.standardizedFileURL.path
          var relPath: String
          if stdPath.hasPrefix(rootPrefix) {
            relPath = String(stdPath.dropFirst(rootPrefix.count))
          } else {
            relPath = "\(idx)_\(fileURL.lastPathComponent)"
          }
          if !usedRelativePaths.insert(relPath).inserted {
            relPath = "\(idx)_\(fileURL.lastPathComponent)"
          }
          let destURL = destRoot.appendingPathComponent(relPath)
          try fm.createDirectory(at: destURL.deletingLastPathComponent(), withIntermediateDirectories: true)
          if preprocessSwift, let content = try? String(contentsOf: fileURL, encoding: .utf8) {
            let rewritten = Self.preprocessSwiftSourceForCrossPlatform(content)
            if rewritten != content {
              try rewritten.write(to: destURL, atomically: true, encoding: .utf8)
              continue
            }
          }
          try linkOrCopyFile(from: fileURL, to: destURL)
        }
      }

      try copySourceList(target.swiftSources, into: targetDir, preprocessSwift: shouldPreprocessSwift)
      if !target.cSources.isEmpty {
        let cTargetDir = target.swiftSources.isEmpty
          ? targetDir
          : sourcesRoot.appendingPathComponent("\(target.name)C")
        try fm.createDirectory(at: cTargetDir, withIntermediateDirectories: true)
        try copySourceList(target.cSources, into: cTargetDir, preprocessSwift: false)
        let includeDir = cTargetDir.appendingPathComponent("include")
        try fm.createDirectory(at: includeDir, withIntermediateDirectories: true)
      }

      if isMain, let generatedAssetSymbolsURL {
        let dest = targetDir.appendingPathComponent("GeneratedAssetSymbols.swift")
        try fm.copyItem(at: generatedAssetSymbolsURL, to: dest)
      }
    }
  }

  /// Adapts unmodified macOS Swift source files for non-Darwin desktop toolchains:
  /// - Routes `import Foundation` through `CrossFoundation` so FoundationNetworking,
  ///   FoundationXML, Dispatch, Observation, and LocalizedStringResource are available.
  /// - Strips `@objc` attributes where Objective-C interop is unavailable.
  /// - Rewrites `#selector(...)` expressions to `Selector("...")`.
  public static func preprocessSwiftSourceForCrossPlatform(_ source: String) -> String {
    var result = source

    // 1. Replace standalone `import Foundation` lines with `import CrossFoundation`,
    //    and ensure `import CrossFoundation` is present so files that only import
    //    Apple frameworks (e.g. AVFoundation, Carbon, ApplicationServices) also see
    //    Foundation/CoreFoundation/Darwin/Dispatch/Observation like on Darwin.
    if let importRegex = try? NSRegularExpression(
      pattern: #"(?m)^([ \t]*)import[ \t]+Foundation([ \t]*(?://.*)?)$"#
    ) {
      let ns = result as NSString
      result = importRegex.stringByReplacingMatches(
        in: result,
        range: NSRange(location: 0, length: ns.length),
        withTemplate: "$1import CrossFoundation$2"
      )
    }
    if !result.contains("import CrossFoundation") {
      result = "import CrossFoundation\n" + result
    }

    // 2. Strip `@objc` / `@objc(...)` attributes.
    if let objcRegex = try? NSRegularExpression(
      pattern: #"(?<![A-Za-z0-9_])@objc(?:\([^)]*\))?[ \t]*"#
    ) {
      let ns = result as NSString
      result = objcRegex.stringByReplacingMatches(
        in: result,
        range: NSRange(location: 0, length: ns.length),
        withTemplate: ""
      )
    }

    // 3. Rewrite `#selector(...)` to `Selector("...")`.
    if let selRegex = try? NSRegularExpression(
      pattern: #"#selector\(([^()\n]*(?:\([^()\n]*\))?[^()\n]*)\)"#
    ) {
      let ns = result as NSString
      let matches = selRegex.matches(in: result, range: NSRange(location: 0, length: ns.length))
      if !matches.isEmpty {
        var mutable = result
        for match in matches.reversed() {
          guard match.numberOfRanges >= 2 else { continue }
          let inner = ns.substring(with: match.range(at: 1))
            .trimmingCharacters(in: .whitespacesAndNewlines)
          let selectorName = Self.selectorString(from: inner)
          let replacement = "Selector(\"\(selectorName)\")"
          if let range = Range(match.range, in: mutable) {
            mutable.replaceSubrange(range, with: replacement)
          }
        }
        result = mutable
      }
    }

    // 4. Strip `@convention(block)` (Objective-C block interop is unavailable on Linux/Windows).
    if result.contains("@convention(block)") {
      result = result.replacingOccurrences(of: "@convention(block) ", with: "")
      result = result.replacingOccurrences(of: "@convention(block)", with: "")
    }

    // 5. Strip `@convention(c)` on signatures that reference bridged CF/ObjC reference types
    //    (e.g. `Unmanaged<CFArray>`, `CFString`, `AXUIElement`, `AnyObject`), which Swift
    //    rejects without Objective-C interop.
    if let convCRegex = try? NSRegularExpression(
      pattern: #"@convention\(c\)[ \t]*(\([^)]*(?:CFArray|CFString|CFURL|CFTypeRef|DCSDictionary|AXUIElement|AnyObject)[^)]*\)|[^;\n]*Unmanaged<)"#
    ) {
      let ns = result as NSString
      result = convCRegex.stringByReplacingMatches(
        in: result,
        range: NSRange(location: 0, length: ns.length),
        withTemplate: "$1"
      )
    }

    return result
  }

  private static func selectorString(from expr: String) -> String {
    var trimmed = expr
    if trimmed.hasPrefix("getter:") {
      trimmed = String(trimmed.dropFirst("getter:".count)).trimmingCharacters(in: .whitespaces)
    } else if trimmed.hasPrefix("setter:") {
      trimmed = String(trimmed.dropFirst("setter:".count)).trimmingCharacters(in: .whitespaces)
    }
    // Split off parameter list if present: e.g. `NSResponder.insertTab(_:)` -> `NSResponder.insertTab` + `(_:)`
    let basePart: String
    let paramPart: String
    if let openParen = trimmed.firstIndex(of: "("), let closeParen = trimmed.lastIndex(of: ")") {
      basePart = String(trimmed[..<openParen])
      paramPart = String(trimmed[trimmed.index(after: openParen)..<closeParen])
    } else {
      basePart = trimmed
      paramPart = ""
    }
    let methodName = basePart.split(separator: ".").last.map(String.init) ?? basePart
    if paramPart.isEmpty {
      return methodName
    }
    let labels = paramPart.split(separator: ":").map { $0.trimmingCharacters(in: .whitespaces) }
    var out = methodName
    for (idx, label) in labels.enumerated() {
      if idx == 0 {
        out += ":"
      } else if label == "_" {
        out += ":"
      } else {
        out += "\(label):"
      }
    }
    return out
  }

  private func prepareAdaptedRemotePackages(
    project: ResolvedXcodeProject,
    platform: TargetPlatform,
    buildRoot: URL,
    crossSwiftRoot: URL
  ) throws -> [String: URL] {
    var adapted: [String: URL] = [:]
    let cacheRoot = buildRoot.deletingLastPathComponent().appendingPathComponent("AdaptedPackageCache")
    let stagingRoot = buildRoot.appendingPathComponent("AdaptedPackages")
    let allowedModules: Set<String> = platform == .wasm
      ? ["SwiftUI", "SwiftUIRuntime"]
      : PackageDependencyAdapter.crossSwiftProvidedModules

    let consumerRefs = project.remotePackages.isEmpty
      ? nil
      : PackageDependencyAdapter.ConsumerReferences.scan(project: project)

    for remote in project.remotePackages {
      guard let checkoutDir = try? PackageDependencyAdapter.checkoutRemotePackage(
        remote,
        cacheRoot: cacheRoot
      ) else {
        continue
      }
      let slug = ProcessRunner.sanitizedSlug(remote.packageName)
      let outputDir = stagingRoot.appendingPathComponent(slug.isEmpty ? remote.id : slug)
      if let adaptedURL = try PackageDependencyAdapter.adaptCheckoutIfNeeded(
        sourceRoot: checkoutDir,
        outputDirectory: outputDir,
        crossSwiftRoot: crossSwiftRoot,
        consumerReferences: consumerRefs,
        allowedCrossSwiftModules: allowedModules,
        useWasmBundleShim: platform == .wasm
      ) {
        adapted[remote.id] = adaptedURL
      }
    }

    return adapted
  }

  public func generatePackageManifest(
    project: ResolvedXcodeProject,
    platform: TargetPlatform,
    configuration: BuildConfiguration,
    consoleSubsystem: Bool,
    crossSwiftRoot: URL,
    nativeAPISwiftRoot: URL?,
    compiledResourceURL: URL?,
    adaptedRemotePackages: [String: URL] = [:]
  ) -> String {
    let crossSwiftIdentity = crossSwiftRoot.lastPathComponent.lowercased()
    let nativeAPIIdentity = nativeAPISwiftRoot?.lastPathComponent.lowercased() ?? "swift"

    var packageDecls: [String] = [
      "    .package(path: \(swiftStringLiteral(crossSwiftRoot.path)))"
    ]

    if platform == .wasm {
      packageDecls.append(
        "    .package(url: \"https://github.com/swiftwasm/JavaScriptKit.git\", exact: \"0.63.0\")"
      )
    }

    let needsDirectNativeAPI = platform != .wasm
      && nativeAPISwiftRoot != nil
      && project.allTargets.contains {
        $0.importedModules.contains("NativeAPI") || $0.importedModules.contains("CNativeAPI")
      }
    if needsDirectNativeAPI, let nativeAPISwiftRoot {
      packageDecls.append("    .package(path: \(swiftStringLiteral(nativeAPISwiftRoot.path)))")
    }

    for local in project.localPackages {
      packageDecls.append("    .package(path: \(swiftStringLiteral(local.path.path)))")
    }

    for remote in project.remotePackages {
      if let adaptedURL = adaptedRemotePackages[remote.id] {
        packageDecls.append("    .package(path: \(swiftStringLiteral(adaptedURL.path)))")
        continue
      }
      let reqExpr: String
      if let pinnedVersion = remote.pinnedVersion, !pinnedVersion.isEmpty {
        reqExpr = "exact: \(swiftStringLiteral(pinnedVersion))"
      } else if let pinnedRev = remote.pinnedRevision, !pinnedRev.isEmpty {
        reqExpr = "revision: \(swiftStringLiteral(pinnedRev))"
      } else {
        switch remote.requirement {
        case .upToNextMajor(let v): reqExpr = "from: \(swiftStringLiteral(v))"
        case .upToNextMinor(let v): reqExpr = ".upToNextMinor(from: \(swiftStringLiteral(v)))"
        case .exact(let v): reqExpr = "exact: \(swiftStringLiteral(v))"
        case .range(let from, let to): reqExpr = "\(swiftStringLiteral(from))..<\(swiftStringLiteral(to))"
        case .branch(let b): reqExpr = "branch: \(swiftStringLiteral(b))"
        case .revision(let r): reqExpr = "revision: \(swiftStringLiteral(r))"
        }
      }
      packageDecls.append("    .package(url: \(swiftStringLiteral(remote.repositoryURL)), \(reqExpr))")
    }

    let remoteIdentityByPkgName: [String: String] = Dictionary(
      uniqueKeysWithValues: project.remotePackages.map { pkg in
        if let adaptedURL = adaptedRemotePackages[pkg.id] {
          return (pkg.packageName.lowercased(), adaptedURL.lastPathComponent.lowercased())
        }
        let urlLast = pkg.repositoryURL
          .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
          .split(separator: "/").last.map(String.init) ?? pkg.packageName
        let slug = urlLast.hasSuffix(".git") ? String(urlLast.dropLast(4)) : urlLast
        return (pkg.packageName.lowercased(), slug)
      }
    )
    let localIdentityByPkgName: [String: String] = Dictionary(
      uniqueKeysWithValues: project.localPackages.map {
        ($0.name.lowercased(), $0.path.lastPathComponent.lowercased())
      }
    )

    var targetDecls: [String] = []
    for target in project.allTargets {
      let isMain = target.name == project.mainTarget.name
      var deps: [String] = []
      var seenDeps = Set<String>()

      func addDep(_ expr: String) {
        if seenDeps.insert(expr).inserted { deps.append("        \(expr)") }
      }

      if !target.cSources.isEmpty && !target.swiftSources.isEmpty {
        let cName = "\(target.name)C"
        targetDecls.append("""
            .target(
              name: \(swiftStringLiteral(cName)),
              publicHeadersPath: "include"
            )
        """)
        addDep(swiftStringLiteral(cName))
      }

      if isMain {
        for internalTarget in project.internalTargets {
          addDep(swiftStringLiteral(internalTarget.name))
        }
      }

      for mod in project.inferredCrossSwiftModules {
        if platform == .wasm && mod != "SwiftUI" && mod != "SwiftUIRuntime" { continue }
        if mod == "SQLite3" && platform != .windows && platform != .linux { continue }
        if target.importedModules.contains(mod)
          || (isMain && mod == "SwiftUI" && project.inferredCrossSwiftModules.contains("SwiftUI"))
        {
          addDep(".product(name: \(swiftStringLiteral(mod)), package: \(swiftStringLiteral(crossSwiftIdentity)))")
        }
      }
      if (platform == .linux || platform == .windows)
        && (target.importedModules.contains("Foundation") || target.importedModules.contains("CrossFoundation"))
      {
        addDep(".product(name: \"CrossFoundation\", package: \(swiftStringLiteral(crossSwiftIdentity)))")
      }
      if platform != .wasm && nativeAPISwiftRoot != nil {
        if target.importedModules.contains("NativeAPI") {
          addDep(".product(name: \"NativeAPI\", package: \(swiftStringLiteral(nativeAPIIdentity)))")
        }
        if target.importedModules.contains("CNativeAPI") {
          addDep(".product(name: \"CNativeAPI\", package: \(swiftStringLiteral(nativeAPIIdentity)))")
        }
      }

      for prod in project.productDependencies where prod.targetName == target.name {
        if let pkgName = prod.packageName?.lowercased() {
          if let localId = localIdentityByPkgName[pkgName] {
            addDep(".product(name: \(swiftStringLiteral(prod.productName)), package: \(swiftStringLiteral(localId)))")
          } else if let remoteId = remoteIdentityByPkgName[pkgName] {
            addDep(".product(name: \(swiftStringLiteral(prod.productName)), package: \(swiftStringLiteral(remoteId)))")
          }
        }
      }

      var swiftSettingsLines: [String] = []
      swiftSettingsLines.append("        .enableUpcomingFeature(\"BareSlashRegexLiterals\")")
      swiftSettingsLines.append("        .enableUpcomingFeature(\"IsolatedDefaultValues\")")
      swiftSettingsLines.append("        .enableUpcomingFeature(\"GlobalActorIsolatedTypesUsability\")")
      for cond in target.activeCompilationConditions {
        if cond == "DEBUG" && configuration != .debug { continue }
        swiftSettingsLines.append("        .define(\(swiftStringLiteral(cond)))")
      }
      if target.defaultActorIsolation?.caseInsensitiveCompare("MainActor") == .orderedSame {
        swiftSettingsLines.append("        .unsafeFlags([\"-Xfrontend\", \"-default-isolation\", \"-Xfrontend\", \"MainActor\"])")
      }

      var linkerSettingLines: [String] = []
      if isMain {
        if platform == .windows {
          var flags = ["-Xlinker", "/STACK:16777216"]
          if !consoleSubsystem {
            flags += ["-Xlinker", "/SUBSYSTEM:WINDOWS", "-Xlinker", "/ENTRY:mainCRTStartup"]
          }
          if configuration == .release {
            flags += ["-Xlinker", "/OPT:REF", "-Xlinker", "/OPT:ICF", "-Xlinker", "/DEBUG:NONE"]
          }
          if let compiledResourceURL {
            flags += ["-Xlinker", compiledResourceURL.path]
          }
          linkerSettingLines.append("        .unsafeFlags([\(flags.map(swiftStringLiteral).joined(separator: ", "))])")
        } else if platform == .linux {
          var flags = ["-Xlinker", "-rpath", "-Xlinker", "$ORIGIN/lib"]
          if configuration == .release {
            flags += ["-Xlinker", "--gc-sections", "-Xlinker", "-s"]
          }
          linkerSettingLines.append("        .unsafeFlags([\(flags.map(swiftStringLiteral).joined(separator: ", "))])")
        } else if platform == .wasm {
          var flags = ["-Xlinker", "-z", "-Xlinker", "stack-size=16777216"]
          if configuration == .release {
            flags += ["-Xlinker", "--gc-sections", "-Xlinker", "--strip-all"]
          }
          linkerSettingLines.append(
            "        .unsafeFlags([\(flags.map(swiftStringLiteral).joined(separator: ", "))], .when(platforms: [.wasi]))"
          )
        }
      }

      let declType = isMain ? ".executableTarget" : ".target"
      let targetEntryName = isMain ? target.executableName : target.name
      let pathLine = isMain && target.executableName != target.name
        ? ",\n      path: \(swiftStringLiteral("Sources/\(target.name)"))"
        : ""
      let depsSection = deps.isEmpty ? "[]" : "[\n\(deps.joined(separator: ",\n"))\n      ]"
      let swiftSettingsSection = swiftSettingsLines.isEmpty
        ? ""
        : ",\n      swiftSettings: [\n\(swiftSettingsLines.joined(separator: ",\n"))\n      ]"
      let linkerSection = linkerSettingLines.isEmpty
        ? ""
        : ",\n      linkerSettings: [\n\(linkerSettingLines.joined(separator: ",\n"))\n      ]"

      targetDecls.append("""
          \(declType)(
            name: \(swiftStringLiteral(targetEntryName)),
            dependencies: \(depsSection)\(pathLine)\(swiftSettingsSection)\(linkerSection)
          )
      """)
    }

    let execName = project.mainTarget.executableName
    return """
    // swift-tools-version: 5.9
    import PackageDescription

    let package = Package(
      name: \(swiftStringLiteral(project.projectName)),
      platforms: [.macOS(.v14)],
      products: [
        .executable(name: \(swiftStringLiteral(execName)), targets: [\(swiftStringLiteral(execName))])
      ],
      dependencies: [
    \(packageDecls.joined(separator: ",\n"))
      ],
      targets: [
    \(targetDecls.joined(separator: ",\n"))
      ],
      cxxLanguageStandard: .cxx17
    )
    """
  }

  private func linkOrCopyFile(from source: URL, to destination: URL) throws {
    let fm = FileManager.default
    #if !os(Windows)
      if (try? fm.createSymbolicLink(at: destination, withDestinationURL: source.standardizedFileURL)) != nil {
        return
      }
    #endif
    try fm.copyItem(at: source, to: destination)
  }

  private func writeIfChanged(text: String, to url: URL) throws {
    if let existing = try? String(contentsOf: url, encoding: .utf8), existing == text {
      return
    }
    try text.write(to: url, atomically: true, encoding: .utf8)
  }

  private func swiftStringLiteral(_ value: String) -> String {
    let escaped = value
      .replacingOccurrences(of: "\\", with: "\\\\")
      .replacingOccurrences(of: "\"", with: "\\\"")
    return "\"\(escaped)\""
  }
}
