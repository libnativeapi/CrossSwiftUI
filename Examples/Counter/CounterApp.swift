import SwiftUI
#if os(macOS)
import AppKit

/// A SwiftPM executable is not an app bundle, so AppKit starts it as a
/// background app: the window exists but opens behind the terminal. Make it a
/// regular foreground app and activate it once launched.
final class CounterAppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_ notification: Notification) {
    NSApp.setActivationPolicy(.regular)
    NSApp.activate(ignoringOtherApps: true)
  }
}
#endif

@main
struct CounterApp: App {
  #if os(macOS)
  @NSApplicationDelegateAdaptor(CounterAppDelegate.self) private var appDelegate
  #endif

  var body: some Scene {
    WindowGroup("Counter") {
      CounterView()
    }
  }
}
