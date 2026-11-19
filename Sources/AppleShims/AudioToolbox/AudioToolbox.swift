import Foundation

#if !os(macOS)
  public let noErr: Int32 = 0
  public typealias SystemSoundID = UInt32
  public let kAudioFormatLinearPCM: UInt32 = 0x6C70636D
  public let kAudioDeviceTransportTypeBluetooth: UInt32 = 0x626C7565
  public let kAudioDeviceTransportTypeBluetoothLE: UInt32 = 0x626C6561

  public struct AudioBuffer: @unchecked Sendable {
    public var mNumberChannels: UInt32
    public var mDataByteSize: UInt32
    public var mData: UnsafeMutableRawPointer?
    public init(mNumberChannels: UInt32 = 0, mDataByteSize: UInt32 = 0, mData: UnsafeMutableRawPointer? = nil) {
      self.mNumberChannels = mNumberChannels
      self.mDataByteSize = mDataByteSize
      self.mData = mData
    }
  }

  public struct AudioBufferList: @unchecked Sendable {
    public var mNumberBuffers: UInt32
    public var mBuffers: AudioBuffer
    public init(mNumberBuffers: UInt32 = 0, mBuffers: AudioBuffer = AudioBuffer()) {
      self.mNumberBuffers = mNumberBuffers
      self.mBuffers = mBuffers
    }
  }

  public func AudioServicesPlaySystemSound(_ inSystemSoundID: SystemSoundID) {}
#endif
