import Foundation

#if !os(macOS)
  public final class SMAppService: @unchecked Sendable {
    public enum Status: Int, Sendable {
      case notRegistered = 0
      case enabled = 1
      case requiresApproval = 2
      case notFound = 3
    }

    public static let mainApp = SMAppService()

    public var status: Status {
      #if os(Windows)
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "C:\\Windows\\System32\\reg.exe")
        proc.arguments = ["query", "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run", "/v", appName]
        proc.standardOutput = Pipe()
        proc.standardError = Pipe()
        do {
          try proc.run()
          proc.waitUntilExit()
          return proc.terminationStatus == 0 ? .enabled : .notRegistered
        } catch {
          return .notRegistered
        }
      #else
        return .notRegistered
      #endif
    }

    public func register() throws {
      #if os(Windows)
        let exe = CommandLine.arguments.first ?? ""
        guard !exe.isEmpty else { return }
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "C:\\Windows\\System32\\reg.exe")
        proc.arguments = [
          "add", "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
          "/v", appName, "/t", "REG_SZ", "/d", "\"\(exe)\" --background", "/f",
        ]
        try proc.run()
        proc.waitUntilExit()
      #endif
    }

    public func unregister() throws {
      #if os(Windows)
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: "C:\\Windows\\System32\\reg.exe")
        proc.arguments = [
          "delete", "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run",
          "/v", appName, "/f",
        ]
        try proc.run()
        proc.waitUntilExit()
      #endif
    }

    private var appName: String {
      Bundle.main.infoDictionary?["CFBundleName"] as? String ?? "Tinycast"
    }
  }
#endif
