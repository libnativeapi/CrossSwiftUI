import Foundation
import CrossAppKit
@_exported import AVFoundation

#if !os(macOS)
  @MainActor
  open class AVPlayerView: NSView {
    public enum ControlsStyle: Int, Sendable {
      case none = 0
      case inline = 1
      case floating = 2
      case minimal = 3
      case `default` = 4
    }
    public var player: AVPlayer?
    public var controlsStyle: ControlsStyle = .inline
    public var showsFullScreenToggleButton: Bool = false
    public var videoGravity: AVLayerVideoGravity = .resizeAspect
  }
#endif
