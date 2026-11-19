import Foundation
import CoreGraphics
import CrossAppKit
@_exported import CoreMedia

#if !os(macOS)
  public struct AVLayerVideoGravity: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let resizeAspect = AVLayerVideoGravity(rawValue: "AVLayerVideoGravityResizeAspect")
    public static let resizeAspectFill = AVLayerVideoGravity(rawValue: "AVLayerVideoGravityResizeAspectFill")
    public static let resize = AVLayerVideoGravity(rawValue: "AVLayerVideoGravityResize")
  }

  public enum AVAudioCommonFormat: UInt, Sendable {
    case otherFormat = 0
    case pcmFormatFloat32 = 1
    case pcmFormatFloat64 = 2
    case pcmFormatInt16 = 3
    case pcmFormatInt32 = 4
  }

  open class AVAsset: NSObject, @unchecked Sendable {
    public init(url: URL) { super.init() }
    public var duration: CMTime { .zero }
  }
  open class AVURLAsset: AVAsset, @unchecked Sendable {}

  open class AVCapturePhoto: NSObject, @unchecked Sendable {
    public func fileDataRepresentation() -> Data? { nil }
  }
  open class AVCapturePhotoSettings: NSObject, @unchecked Sendable {}
  public protocol AVCapturePhotoCaptureDelegate: AnyObject {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: (any Error)?)
  }
  open class AVCapturePhotoOutput: AVCaptureOutput, @unchecked Sendable {
    public func capturePhoto(with settings: AVCapturePhotoSettings, delegate: any AVCapturePhotoCaptureDelegate) {}
  }

  open class AVCaptureConnection: NSObject, @unchecked Sendable {
    public var isVideoMirroringSupported: Bool = false
    public var automaticallyAdjustsVideoMirroring: Bool = true
    public var isVideoMirrored: Bool = false
  }

  open class AVAudioConverter: NSObject, @unchecked Sendable {
    public init?(from fromFormat: AVAudioFormat, to toFormat: AVAudioFormat) { super.init() }
  }

  extension Notification.Name {
    public static let AVPlayerItemDidPlayToEndTime = Notification.Name("AVPlayerItemDidPlayToEndTimeNotification")
  }
  public struct AVMediaType: RawRepresentable, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public static let audio = AVMediaType(rawValue: "soun")
    public static let video = AVMediaType(rawValue: "vide")
  }

  public enum AVAuthorizationStatus: Int, Sendable {
    case notDetermined = 0
    case restricted = 1
    case denied = 2
    case authorized = 3
  }

  open class AVCaptureDevice: NSObject, @unchecked Sendable {
    public var uniqueID: String = ""
    public var localizedName: String = ""
    public var isSuspended: Bool = false
    public var isConnected: Bool = false
    public var transportType: Int32 = 0
    public static func authorizationStatus(for mediaType: AVMediaType) -> AVAuthorizationStatus { .denied }
    public static func requestAccess(for mediaType: AVMediaType) async -> Bool { false }
    public static func `default`(for mediaType: AVMediaType) -> AVCaptureDevice? { nil }
    public final class DiscoverySession: NSObject, @unchecked Sendable {
      public let devices: [AVCaptureDevice] = []
      public init(deviceTypes: [DeviceType], mediaType: AVMediaType?, position: Position) {}
    }
    public struct DeviceType: RawRepresentable, Hashable, Sendable {
      public let rawValue: String
      public init(rawValue: String) { self.rawValue = rawValue }
      public static let builtInWideAngleCamera = DeviceType(rawValue: "builtInWideAngleCamera")
      public static let external = DeviceType(rawValue: "external")
      public static let continuityCamera = DeviceType(rawValue: "continuityCamera")
      public static let deskViewCamera = DeviceType(rawValue: "deskViewCamera")
      public static let microphone = DeviceType(rawValue: "microphone")
    }
    public enum Position: Int, Sendable { case unspecified = 0; case back = 1; case front = 2 }
  }

  open class AVCaptureInput: NSObject, @unchecked Sendable {}
  open class AVCaptureDeviceInput: AVCaptureInput, @unchecked Sendable {
    public init(device: AVCaptureDevice) throws { super.init() }
  }
  open class AVCaptureOutput: NSObject, @unchecked Sendable {
    public func connection(with mediaType: AVMediaType) -> AVCaptureConnection? { nil }
  }
  open class AVCaptureVideoDataOutput: AVCaptureOutput, @unchecked Sendable {}

  public let AVFormatIDKey: String = "AVFormatIDKey"
  public let AVSampleRateKey: String = "AVSampleRateKey"
  public let AVNumberOfChannelsKey: String = "AVNumberOfChannelsKey"
  public let AVLinearPCMBitDepthKey: String = "AVLinearPCMBitDepthKey"
  public let AVLinearPCMIsFloatKey: String = "AVLinearPCMIsFloatKey"
  public let AVLinearPCMIsNonInterleaved: String = "AVLinearPCMIsNonInterleaved"

  public protocol AVCaptureAudioDataOutputSampleBufferDelegate: AnyObject {
    func captureOutput(
      _ output: AVCaptureOutput,
      didOutput sampleBuffer: CMSampleBuffer,
      from connection: AVCaptureConnection
    )
  }

  open class AVCaptureAudioDataOutput: AVCaptureOutput, @unchecked Sendable {
    public var audioSettings: [String: Any] = [:]
    public func setSampleBufferDelegate(
      _ sampleBufferDelegate: (any AVCaptureAudioDataOutputSampleBufferDelegate)?,
      queue sampleBufferCallbackQueue: DispatchQueue?
    ) {}
  }
  open class AVCaptureSession: NSObject, @unchecked Sendable {
    public struct Preset: RawRepresentable, Hashable, Sendable {
      public let rawValue: String
      public init(rawValue: String) { self.rawValue = rawValue }
      public static let photo = Preset(rawValue: "AVCaptureSessionPresetPhoto")
      public static let high = Preset(rawValue: "AVCaptureSessionPresetHigh")
      public static let medium = Preset(rawValue: "AVCaptureSessionPresetMedium")
      public static let hd1280x720 = Preset(rawValue: "AVCaptureSessionPreset1280x720")
      public static let hd1920x1080 = Preset(rawValue: "AVCaptureSessionPreset1920x1080")
    }
    public var sessionPreset: Preset = .high
    public var isRunning: Bool = false
    public var inputs: [AVCaptureInput] = []
    public var outputs: [AVCaptureOutput] = []
    public func beginConfiguration() {}
    public func commitConfiguration() {}
    public func canAddInput(_ input: AVCaptureInput) -> Bool { false }
    public func addInput(_ input: AVCaptureInput) {}
    public func removeInput(_ input: AVCaptureInput) {}
    public func canAddOutput(_ output: AVCaptureOutput) -> Bool { false }
    public func addOutput(_ output: AVCaptureOutput) {}
    public func startRunning() { isRunning = true }
    public func stopRunning() { isRunning = false }
  }

  open class AVCaptureVideoPreviewLayer: CALayer, @unchecked Sendable {
    public var session: AVCaptureSession?
    public var videoGravity: AVLayerVideoGravity = .resizeAspectFill
    public var connection: AVCaptureConnection? = AVCaptureConnection()
    public init(session: AVCaptureSession) {
      self.session = session
      super.init()
    }
    public override init() { super.init() }
  }

  open class AVPlayerItem: NSObject, @unchecked Sendable {
    public init(url: URL) { super.init() }
    public init(asset: AVAsset) { super.init() }
  }

  open class AVPlayer: NSObject, @unchecked Sendable {
    public enum TimeControlStatus: Int, Sendable {
      case paused = 0
      case waitingToPlayAtSpecifiedRate = 1
      case playing = 2
    }
    public var rate: Float = 0
    public var isMuted: Bool = false
    public var timeControlStatus: TimeControlStatus { rate > 0 ? .playing : .paused }
    public var currentItem: AVPlayerItem?
    public init(url: URL) {
      self.currentItem = AVPlayerItem(url: url)
      super.init()
    }
    public init(playerItem: AVPlayerItem?) {
      self.currentItem = playerItem
      super.init()
    }
    public func play() { rate = 1 }
    public func pause() { rate = 0 }
    public func seek(to time: CMTime) {}
    public func seek(to time: CMTime, toleranceBefore: CMTime, toleranceAfter: CMTime) async -> Bool { true }
    public func replaceCurrentItem(with item: AVPlayerItem?) { currentItem = item }
    public func addPeriodicTimeObserver(forInterval interval: CMTime, queue: DispatchQueue?, using block: @escaping @Sendable (CMTime) -> Void) -> Any { NSObject() }
    public func removeTimeObserver(_ observer: Any) {}
  }

  open class AVAudioFormat: NSObject, @unchecked Sendable {
    public var sampleRate: Double = 16000
    public var channelCount: UInt32 = 1
    public init?(commonFormat: AVAudioCommonFormat = .pcmFormatFloat32, sampleRate: Double, channels: UInt32, interleaved: Bool) {
      self.sampleRate = sampleRate
      self.channelCount = channels
    }
  }

  open class AVAudioPCMBuffer: NSObject, @unchecked Sendable {
    public var frameLength: UInt32 = 0
    public var floatChannelData: UnsafePointer<UnsafeMutablePointer<Float>>? { nil }
  }

  open class AVAudioNode: NSObject, @unchecked Sendable {
    public func outputFormat(forBus bus: Int) -> AVAudioFormat {
      AVAudioFormat(sampleRate: 16000, channels: 1, interleaved: false)!
    }
    public func installTap(onBus bus: Int, bufferSize: UInt32, format: AVAudioFormat?, block: @escaping @Sendable (AVAudioPCMBuffer, AnyObject) -> Void) {}
    public func removeTap(onBus bus: Int) {}
  }

  open class AVAudioEngine: NSObject, @unchecked Sendable {
    public let inputNode = AVAudioNode()
    public var isRunning: Bool = false
    public func prepare() {}
    public func start() throws { isRunning = true }
    public func stop() { isRunning = false }
  }
#endif
