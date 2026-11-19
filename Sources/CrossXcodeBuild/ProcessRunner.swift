import Foundation

public struct ProcessResult: Sendable {
  public let exitCode: Int32
  public let stdout: String
  public let stderr: String
}

public enum ProcessRunnerError: Error, LocalizedError {
  case executableNotFound(String)
  case commandFailed(command: String, exitCode: Int32, output: String)

  public var errorDescription: String? {
    switch self {
    case .executableNotFound(let name):
      return "Required executable '\(name)' was not found in PATH"
    case .commandFailed(let command, let code, let output):
      let tail = output.split(separator: "\n").suffix(40).joined(separator: "\n")
      return "Command failed (exit \(code)): \(command)\n\(tail)"
    }
  }
}

public enum ProcessRunner {
  public static func run(
    executable: URL,
    arguments: [String],
    workingDirectory: URL? = nil,
    environmentOverrides: [String: String] = [:],
    logFile: URL? = nil,
    echoOutput: Bool = false
  ) throws -> ProcessResult {
    let process = Process()
    process.executableURL = executable
    process.arguments = arguments
    if let workingDirectory {
      process.currentDirectoryURL = workingDirectory
    }
    var env = ProcessInfo.processInfo.environment
    for (k, v) in environmentOverrides {
      #if os(Windows)
        for existingKey in env.keys where existingKey.caseInsensitiveCompare(k) == .orderedSame && existingKey != k {
          env.removeValue(forKey: existingKey)
        }
      #endif
      env[k] = v
    }
    process.environment = env

    if let logFile {
      _ = FileManager.default.createFile(atPath: logFile.path, contents: nil)
      let handle = try FileHandle(forWritingTo: logFile)
      defer { try? handle.close() }
      process.standardOutput = handle
      process.standardError = handle
      try process.run()
      process.waitUntilExit()
      let combined = (try? String(contentsOf: logFile, encoding: .utf8)) ?? ""
      if echoOutput && !combined.isEmpty {
        print(combined, terminator: "")
      }
      return ProcessResult(exitCode: process.terminationStatus, stdout: combined, stderr: "")
    }

    let outPipe = Pipe()
    let errPipe = Pipe()
    process.standardOutput = outPipe
    process.standardError = errPipe
    try process.run()

    final class DataBox: @unchecked Sendable {
      var data = Data()
    }
    let outBox = DataBox()
    let errBox = DataBox()
    let group = DispatchGroup()
    group.enter()
    DispatchQueue.global().async {
      outBox.data = outPipe.fileHandleForReading.readDataToEndOfFile()
      group.leave()
    }
    group.enter()
    DispatchQueue.global().async {
      errBox.data = errPipe.fileHandleForReading.readDataToEndOfFile()
      group.leave()
    }
    process.waitUntilExit()
    group.wait()

    let stdout = String(data: outBox.data, encoding: .utf8) ?? ""
    let stderr = String(data: errBox.data, encoding: .utf8) ?? ""
    if echoOutput {
      if !stdout.isEmpty { print(stdout, terminator: "") }
      if !stderr.isEmpty { fputs(stderr, stderrStream) }
    }
    return ProcessResult(exitCode: process.terminationStatus, stdout: stdout, stderr: stderr)
  }

  public static func environmentValue(_ key: String) -> String? {
    let env = ProcessInfo.processInfo.environment
    if let exact = env[key] { return exact }
    #if os(Windows)
      return env.first { $0.key.caseInsensitiveCompare(key) == .orderedSame }?.value
    #else
      return nil
    #endif
  }

  public static func findExecutable(
    named candidates: [String],
    extraDirectories: [URL] = []
  ) -> URL? {
    let fm = FileManager.default
    let pathEnv = environmentValue("PATH") ?? ""
    #if os(Windows)
      let separator: Character = ";"
      let pathExts = ["", ".exe", ".cmd", ".bat"]
    #else
      let separator: Character = ":"
      let pathExts = [""]
    #endif

    let searchDirs = extraDirectories + pathEnv.split(separator: separator).map {
      URL(fileURLWithPath: String($0))
    }

    for name in candidates {
      if name.contains("/") || name.contains("\\") {
        let direct = URL(fileURLWithPath: name)
        if fm.isExecutableFile(atPath: direct.path) || fm.fileExists(atPath: direct.path) {
          return direct
        }
      }
      for dir in searchDirs {
        for ext in pathExts {
          let fileName = (ext.isEmpty || name.lowercased().hasSuffix(ext)) ? name : name + ext
          let candidate = dir.appendingPathComponent(fileName)
          #if os(Windows)
            if fm.fileExists(atPath: candidate.path) {
              return candidate
            }
          #else
            if fm.isExecutableFile(atPath: candidate.path) {
              return candidate
            }
          #endif
        }
      }
    }
    return nil
  }

  public static func fnv1aHex(_ input: String) -> String {
    var hash: UInt64 = 14695981039346656037
    for byte in input.utf8 {
      hash ^= UInt64(byte)
      hash = hash &* 1099511628211
    }
    return String(format: "%08x", UInt32(truncatingIfNeeded: hash))
  }

  public static func sanitizedSlug(_ name: String) -> String {
    let chars = name.unicodeScalars.map { s -> Character in
      if CharacterSet.alphanumerics.contains(s) { return Character(s) }
      return "-"
    }
    let collapsed = String(chars).trimmingCharacters(in: CharacterSet(charactersIn: "-"))
    return collapsed.isEmpty ? "app" : collapsed
  }
}

private let stderrStream = FileHandle.standardError

private func fputs(_ text: String, _ handle: FileHandle) {
  if let data = text.data(using: .utf8) {
    try? handle.write(contentsOf: data)
  }
}
