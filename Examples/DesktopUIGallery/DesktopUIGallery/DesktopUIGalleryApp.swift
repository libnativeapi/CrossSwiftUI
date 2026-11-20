import SwiftUI

@main
struct DesktopUIGalleryApp: App {
  var body: some Scene {
    WindowGroup("Desktop UI Gallery") {
      GalleryRootView()
    }
    .defaultSize(width: 1080, height: 740)
  }
}
