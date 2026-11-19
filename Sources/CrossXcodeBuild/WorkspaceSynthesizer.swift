import Foundation

public struct BuiltTargetArtifacts: Sendable {
  public let targetPlatform: TargetPlatform
  public let architecture: TargetArchitecture
  public let executableURL: URL
  public let buildDirectory: URL
  public let scratchDirectory: URL
  public let compiledAssets: CompiledAssets
  public let swiftExecutableURL: URL
}

public enum WorkspaceSynthesizerError: Error, LocalizedError {
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

public final class WorkspaceSynthesizer {
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
    let nativeAPISwiftRoot = try Self.resolveNativeAPISwiftRoot(
      explicit: options.nativeAPISwiftPath,
      crossSwiftRoot: crossSwiftRoot
    )

    if platform == .windows {
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

    var compiledResURL: URL?
    if platform == .windows, let rcURL = compiledAssets.windowsResourceScriptURL {
      compiledResURL = try compileWindowsResources(rcURL: rcURL)
    }

    try stageSources(
      project: project,
      generatedAssetSymbolsURL: compiledAssets.generatedSymbolsSwiftURL,
      buildRoot: buildRoot
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
      compiledResourceURL: compiledResURL
    )
    let packageSwiftURL = buildRoot.appendingPathComponent("Package.swift")
    try writeIfChanged(text: manifestText, to: packageSwiftURL)

    let swiftExe = try locateSwiftExecutable()
    var envOverrides: [String: String] = [
      "NATIVEAPI_SWIFT_PATH": nativeAPISwiftRoot.path,
    ]
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
      throw WorkspaceSynthesizerError.binaryMissing(executableURL.path)
    }

    return BuiltTargetArtifacts(
      targetPlatform: platform,
      architecture: .currentHost,
      executableURL: executableURL,
      buildDirectory: buildRoot,
      scratchDirectory: scratchDir,
      compiledAssets: compiledAssets,
      swiftExecutableURL: swiftExe
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
    throw WorkspaceSynthesizerError.crossSwiftNotFound
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
    throw WorkspaceSynthesizerError.nativeAPINotFound(parentDir.path)
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
      throw WorkspaceSynthesizerError.toolMissing(
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
      throw WorkspaceSynthesizerError.toolMissing("Could not locate 'swift' compiler executable")
    }
    return swift
  }

  private func stageSources(
    project: ResolvedXcodeProject,
    generatedAssetSymbolsURL: URL?,
    buildRoot: URL
  ) throws {
    let fm = FileManager.default
    let sourcesRoot = buildRoot.appendingPathComponent("Sources")
    if fm.fileExists(atPath: sourcesRoot.path) {
      try fm.removeItem(at: sourcesRoot)
    }
    try fm.createDirectory(at: sourcesRoot, withIntermediateDirectories: true)

    for target in project.allTargets {
      let isMain = target.name == project.mainTarget.name
      let targetDir = sourcesRoot.appendingPathComponent(target.name)
      try fm.createDirectory(at: targetDir, withIntermediateDirectories: true)

      let rootPrefix = project.projectRootURL.standardizedFileURL.path + "/"
      func copySourceList(_ files: [URL], into destRoot: URL) throws {
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
          try fm.copyItem(at: fileURL, to: destURL)
        }
      }

      try copySourceList(target.swiftSources, into: targetDir)
      if !target.cSources.isEmpty {
        let cTargetDir = target.swiftSources.isEmpty
          ? targetDir
          : sourcesRoot.appendingPathComponent("\(target.name)C")
        try fm.createDirectory(at: cTargetDir, withIntermediateDirectories: true)
        try copySourceList(target.cSources, into: cTargetDir)
        let includeDir = cTargetDir.appendingPathComponent("include")
        try fm.createDirectory(at: includeDir, withIntermediateDirectories: true)
      }

      if isMain, let generatedAssetSymbolsURL {
        let dest = targetDir.appendingPathComponent("GeneratedAssetSymbols.swift")
        try fm.copyItem(at: generatedAssetSymbolsURL, to: dest)
      }
    }
  }

  public func generatePackageManifest(
    project: ResolvedXcodeProject,
    platform: TargetPlatform,
    configuration: BuildConfiguration,
    consoleSubsystem: Bool,
    crossSwiftRoot: URL,
    nativeAPISwiftRoot: URL,
    compiledResourceURL: URL?
  ) -> String {
    let crossSwiftIdentity = crossSwiftRoot.lastPathComponent.lowercased()
    let nativeAPIIdentity = nativeAPISwiftRoot.lastPathComponent.lowercased()

    var packageDecls: [String] = [
      "    .package(path: \(swiftStringLiteral(crossSwiftRoot.path)))"
    ]

    let needsDirectNativeAPI = project.allTargets.contains {
      $0.importedModules.contains("NativeAPI") || $0.importedModules.contains("CNativeAPI")
    }
    if needsDirectNativeAPI {
      packageDecls.append("    .package(path: \(swiftStringLiteral(nativeAPISwiftRoot.path)))")
    }

    for local in project.localPackages {
      packageDecls.append("    .package(path: \(swiftStringLiteral(local.path.path)))")
    }

    for remote in project.remotePackages {
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
        if mod == "SQLite3" && platform != .windows { continue }
        if target.importedModules.contains(mod)
          || (isMain && mod == "SwiftUI" && project.inferredCrossSwiftModules.contains("SwiftUI"))
        {
          addDep(".product(name: \(swiftStringLiteral(mod)), package: \(swiftStringLiteral(crossSwiftIdentity)))")
        }
      }
      if target.importedModules.contains("NativeAPI") {
        addDep(".product(name: \"NativeAPI\", package: \(swiftStringLiteral(nativeAPIIdentity)))")
      }
      if target.importedModules.contains("CNativeAPI") {
        addDep(".product(name: \"CNativeAPI\", package: \(swiftStringLiteral(nativeAPIIdentity)))")
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
      for cond in target.activeCompilationConditions {
        if cond == "DEBUG" && configuration != .debug { continue }
        swiftSettingsLines.append("        .define(\(swiftStringLiteral(cond)))")
      }
      if target.defaultActorIsolation?.caseInsensitiveCompare("MainActor") == .orderedSame {
        swiftSettingsLines.append("        .unsafeFlags([\"-Xfrontend\", \"-default-isolation\", \"-Xfrontend\", \"MainActor\"])")
      }

      var linkerFlags: [String] = []
      if isMain {
        if platform == .windows {
          linkerFlags += ["-Xlinker", "/STACK:16777216"]
          if !consoleSubsystem {
            linkerFlags += ["-Xlinker", "/SUBSYSTEM:WINDOWS", "-Xlinker", "/ENTRY:mainCRTStartup"]
          }
          if let compiledResourceURL {
            linkerFlags += ["-Xlinker", compiledResourceURL.path]
          }
        } else if platform == .linux {
          linkerFlags += ["-Xlinker", "-rpath", "-Xlinker", "$ORIGIN/lib"]
        }
      }

      let declType = isMain ? ".executableTarget" : ".target"
      let targetEntryName = isMain ? target.executableName : target.name
      let pathLine = isMain && target.executableName != target.name
        ? "\n      path: \(swiftStringLiteral("Sources/\(target.name)")),"
        : ""
      let depsSection = deps.isEmpty ? "[]" : "[\n\(deps.joined(separator: ",\n"))\n      ]"
      let swiftSettingsSection = swiftSettingsLines.isEmpty
        ? ""
        : ",\n      swiftSettings: [\n\(swiftSettingsLines.joined(separator: ",\n"))\n      ]"
      let linkerSection = linkerFlags.isEmpty
        ? ""
        : ",\n      linkerSettings: [\n        .unsafeFlags([\(linkerFlags.map(swiftStringLiteral).joined(separator: ", "))])\n      ]"

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
