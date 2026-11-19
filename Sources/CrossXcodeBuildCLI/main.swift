import CrossXcodeBuild
import Foundation

private func writeStderr(_ message: String) {
  FileHandle.standardError.write(Data(message.utf8))
}

do {
  let args = Array(CommandLine.arguments.dropFirst())
  let outcome = try XcodeBuildCLIParser.parse(arguments: args)

  switch outcome {
  case .showHelp:
    print(XcodeBuildCLIParser.usageText)
    exit(0)
  case .run(let options):
    let driver = XcodeBuildDriver()
    switch options.mode {
    case .version:
      print(driver.versionOutput())
    case .list:
      print(try driver.list(options: options))
    case .showBuildSettings:
      print(try driver.showBuildSettings(options: options))
    case .actions(let actions):
      _ = try driver.runActions(actions, options: options)
    }
  }
} catch {
  writeStderr("xcodebuild: error: \(error.localizedDescription)\n")
  exit(65)
}
