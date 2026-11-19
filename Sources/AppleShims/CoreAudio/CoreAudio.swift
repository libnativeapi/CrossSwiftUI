import Foundation
import CoreFoundation

#if !os(macOS)
  public let noErr: Int32 = 0
  public typealias AudioObjectID = UInt32
  public typealias AudioDeviceID = AudioObjectID
  public typealias AudioObjectPropertySelector = UInt32
  public typealias AudioObjectPropertyScope = UInt32
  public typealias AudioObjectPropertyElement = UInt32

  public let kAudioObjectSystemObject: AudioObjectID = 1
  public let kAudioObjectUnknown: AudioObjectID = 0
  public let kAudioObjectPropertyScopeGlobal: AudioObjectPropertyScope = 0x676C6F62
  public let kAudioObjectPropertyScopeInput: AudioObjectPropertyScope = 0x696E7074
  public let kAudioDevicePropertyScopeInput: AudioObjectPropertyScope = 0x696E7074
  public let kAudioObjectPropertyScopeOutput: AudioObjectPropertyScope = 0x6F757470
  public let kAudioDevicePropertyScopeOutput: AudioObjectPropertyScope = 0x6F757470
  public let kAudioObjectPropertyElementMain: AudioObjectPropertyElement = 0
  public let kAudioObjectPropertyElementMaster: AudioObjectPropertyElement = 0
  public let kAudioHardwarePropertyDefaultOutputDevice: AudioObjectPropertySelector = 0x644F7574
  public let kAudioHardwarePropertyDefaultInputDevice: AudioObjectPropertySelector = 0x64496E20
  public let kAudioHardwarePropertyDevices: AudioObjectPropertySelector = 0x64657623
  public let kAudioDevicePropertyPreferredChannelsForStereo: AudioObjectPropertySelector = 0x64636832
  public let kAudioDevicePropertyVolumeScalar: AudioObjectPropertySelector = 0x766F6C6D
  public let kAudioDevicePropertyMute: AudioObjectPropertySelector = 0x6D757465
  public let kAudioHardwareServiceDeviceProperty_VirtualMainVolume: AudioObjectPropertySelector = 0x766D7663

  public struct AudioObjectPropertyAddress: Sendable {
    public var mSelector: AudioObjectPropertySelector
    public var mScope: AudioObjectPropertyScope
    public var mElement: AudioObjectPropertyElement
    public init(mSelector: AudioObjectPropertySelector = 0, mScope: AudioObjectPropertyScope = 0, mElement: AudioObjectPropertyElement = 0) {
      self.mSelector = mSelector; self.mScope = mScope; self.mElement = mElement
    }
  }

  public func AudioObjectHasProperty(_ inObjectID: AudioObjectID, _ inAddress: UnsafePointer<AudioObjectPropertyAddress>) -> Bool { false }
  public func AudioObjectIsPropertySettable(_ inObjectID: AudioObjectID, _ inAddress: UnsafePointer<AudioObjectPropertyAddress>, _ outIsSettable: UnsafeMutablePointer<DarwinBoolean>) -> Int32 {
    outIsSettable.pointee = DarwinBoolean(false)
    return -1
  }
  public func AudioObjectGetPropertyDataSize(_ inObjectID: AudioObjectID, _ inAddress: UnsafePointer<AudioObjectPropertyAddress>, _ inQualifierDataSize: UInt32, _ inQualifierData: UnsafeRawPointer?, _ outDataSize: UnsafeMutablePointer<UInt32>) -> Int32 {
    outDataSize.pointee = 0
    return -1
  }
  public func AudioObjectGetPropertyData(_ inObjectID: AudioObjectID, _ inAddress: UnsafePointer<AudioObjectPropertyAddress>, _ inQualifierDataSize: UInt32, _ inQualifierData: UnsafeRawPointer?, _ ioDataSize: UnsafeMutablePointer<UInt32>, _ outData: UnsafeMutableRawPointer) -> Int32 { -1 }
  public func AudioObjectSetPropertyData(_ inObjectID: AudioObjectID, _ inAddress: UnsafePointer<AudioObjectPropertyAddress>, _ inQualifierDataSize: UInt32, _ inQualifierData: UnsafeRawPointer?, _ inDataSize: UInt32, _ inData: UnsafeRawPointer) -> Int32 { -1 }

  public typealias AudioObjectPropertyListenerBlock = @Sendable (UInt32, UnsafePointer<AudioObjectPropertyAddress>) -> Void
  public func AudioObjectAddPropertyListenerBlock(_ inObjectID: AudioObjectID, _ inAddress: UnsafePointer<AudioObjectPropertyAddress>, _ inDispatchQueue: DispatchQueue?, _ inListener: @escaping AudioObjectPropertyListenerBlock) -> Int32 { 0 }
  public func AudioObjectRemovePropertyListenerBlock(_ inObjectID: AudioObjectID, _ inAddress: UnsafePointer<AudioObjectPropertyAddress>, _ inDispatchQueue: DispatchQueue?, _ inListener: @escaping AudioObjectPropertyListenerBlock) -> Int32 { 0 }
  public func AudioHardwareServiceHasProperty(_ inObjectID: AudioObjectID, _ inAddress: UnsafePointer<AudioObjectPropertyAddress>) -> Bool { false }
  public func AudioHardwareServiceGetPropertyData(_ inObjectID: AudioObjectID, _ inAddress: UnsafePointer<AudioObjectPropertyAddress>, _ inQualifierDataSize: UInt32, _ inQualifierData: UnsafeRawPointer?, _ ioDataSize: UnsafeMutablePointer<UInt32>, _ outData: UnsafeMutableRawPointer) -> Int32 { -1 }
  public func AudioHardwareServiceSetPropertyData(_ inObjectID: AudioObjectID, _ inAddress: UnsafePointer<AudioObjectPropertyAddress>, _ inQualifierDataSize: UInt32, _ inQualifierData: UnsafeRawPointer?, _ inDataSize: UInt32, _ inData: UnsafeRawPointer) -> Int32 { -1 }

  public let kAudioVolumeControlClassID: UInt32 = 0x766C6D65
  public let kAudioControlPropertyScope: AudioObjectPropertySelector = 0x63736370
  public let kAudioControlPropertyElement: AudioObjectPropertySelector = 0x63656C6D

  public final class AudioHardwareControl: @unchecked Sendable {
    public var classID: UInt32 { get throws { 0 } }
    public var volumeScalarValue: Float { get throws { 1.0 } }
    public func setVolumeScalarValue(_ value: Float) throws {}
    public func propertyData(address: AudioObjectPropertyAddress, qualifier: Data?) throws -> Data { Data() }
  }

  public final class AudioHardwareDevice: @unchecked Sendable {
    public var uid: String { get throws { "" } }
    public var controls: [AudioHardwareControl] { get throws { [] } }
  }

  public final class AudioHardwareSystem: @unchecked Sendable {
    public static let shared = AudioHardwareSystem()
    public var defaultOutputDevice: AudioHardwareDevice? { get throws { nil } }
    public func device(forUID uid: String) throws -> AudioHardwareDevice? { nil }
  }
#endif
