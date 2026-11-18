import Foundation
#if !os(macOS)
  import NativeAPI
#endif

@MainActor
open class NSScreen: NSObject, @unchecked Sendable {
  public let frame: NSRect
  public let visibleFrame: NSRect
  public let backingScaleFactor: CGFloat
  public let localizedName: String
  public let deviceDescription: [NSDeviceDescriptionKey: Any]

  public init(
    frame: NSRect,
    visibleFrame: NSRect,
    backingScaleFactor: CGFloat = 1.0,
    localizedName: String = "Display",
    screenNumber: UInt32 = 1
  ) {
    self.frame = frame
    self.visibleFrame = visibleFrame
    self.backingScaleFactor = backingScaleFactor
    self.localizedName = localizedName
    self.deviceDescription = [
      NSDeviceDescriptionKey("NSScreenNumber"): NSNumber(value: screenNumber)
    ]
    super.init()
  }

  public static var screens: [NSScreen] {
    #if !os(macOS)
      let displays = NativeAPI.DisplayManager.shared.getAll()
      if !displays.isEmpty {
        let primaryHeight = displays.first(where: { $0.isPrimary }).map { CGFloat($0.size.height) }
          ?? CGFloat(displays[0].size.height)
        return displays.enumerated().map { idx, d in
          let pos = d.position
          let sz = d.size
          let wa = d.workArea
          let appKitFrame = CrossAppKitCoordinates.rectFromNativeTopLeft(
            x: pos.x, y: pos.y, width: sz.width, height: sz.height, primaryHeight: primaryHeight
          )
          let appKitVisible = CrossAppKitCoordinates.rectFromNativeTopLeft(
            x: wa.x, y: wa.y, width: wa.width, height: wa.height, primaryHeight: primaryHeight
          )
          return NSScreen(
            frame: appKitFrame,
            visibleFrame: appKitVisible,
            backingScaleFactor: CGFloat(max(d.scaleFactor, 1.0)),
            localizedName: d.name ?? "Display \(idx + 1)",
            screenNumber: UInt32(idx + 1)
          )
        }
      }
    #endif
    let fallback = NSRect(x: 0, y: 0, width: 1920, height: 1080)
    return [NSScreen(frame: fallback, visibleFrame: NSRect(x: 0, y: 48, width: 1920, height: 1032))]
  }

  public static var main: NSScreen? {
    let all = screens
    if let key = NSApplication.shared.keyWindow {
      let center = NSPoint(x: key.frame.midX, y: key.frame.midY)
      if let hit = all.first(where: { $0.frame.contains(center) }) {
        return hit
      }
    }
    return all.first { $0.frame.origin == .zero } ?? all.first
  }
}
