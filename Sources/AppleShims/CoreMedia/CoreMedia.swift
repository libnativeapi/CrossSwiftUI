import Foundation
import CoreFoundation
import AudioToolbox

#if !os(macOS)
  public struct CMTime: Equatable, Hashable, Sendable {
    public var value: Int64
    public var timescale: Int32
    public static let zero = CMTime(value: 0, timescale: 1)
    public init(value: Int64 = 0, timescale: Int32 = 1) {
      self.value = value
      self.timescale = timescale
    }
    public var seconds: Double { timescale == 0 ? 0 : Double(value) / Double(timescale) }
  }

  public final class CMBlockBuffer: @unchecked Sendable {}
  public final class CMSampleBuffer: @unchecked Sendable {}

  public func CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(
    _ sbuf: CMSampleBuffer,
    bufferListSizeNeededOut: UnsafeMutablePointer<Int>?,
    bufferListOut: UnsafeMutablePointer<AudioBufferList>?,
    bufferListSize: Int,
    blockBufferAllocator: CFAllocator?,
    blockBufferMemoryAllocator: CFAllocator?,
    flags: UInt32,
    blockBufferOut: UnsafeMutablePointer<CMBlockBuffer?>?
  ) -> Int32 {
    -1
  }
#endif
