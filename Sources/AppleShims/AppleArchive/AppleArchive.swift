import Foundation
import System

#if !os(macOS)
  public enum ArchiveCompression: Sendable {
    case lzfse, lzma, lz4, zlib
  }

  public enum ArchiveHeader {
    public struct FieldKeySet: Sendable {
      public let keys: String
      public init?(_ keys: String) { self.keys = keys }
    }
    public enum EntryMessage: Sendable { case processEntry }
    public enum EntryFilterData: Sendable {}
    public enum EntryMessageStatus: Sendable { case ok, skip, cancel }
  }

  public final class ArchiveByteStream: @unchecked Sendable {
    public static func fileStream(
      path: FilePath,
      mode: FileDescriptor.AccessMode,
      options: FileDescriptor.OpenOptions,
      permissions: FilePermissions
    ) -> ArchiveByteStream? { nil }

    public static func compressionStream(
      using algorithm: ArchiveCompression,
      writingTo stream: ArchiveByteStream
    ) -> ArchiveByteStream? { nil }

    public static func decompressionStream(
      readingFrom stream: ArchiveByteStream
    ) -> ArchiveByteStream? { nil }

    public func close() throws {}
  }

  public final class ArchiveStream: @unchecked Sendable {
    public static func withEncodeStream<R>(
      writingTo stream: ArchiveByteStream,
      _ body: (ArchiveStream) throws -> R
    ) throws -> R {
      try body(ArchiveStream())
    }

    public static func decodeStream(readingFrom stream: ArchiveByteStream) -> ArchiveStream? { nil }

    public static func withExtractStream<R>(
      extractingTo directory: FilePath,
      selectUsing filter: ((ArchiveHeader.EntryMessage, FilePath, ArchiveHeader.EntryFilterData?) -> ArchiveHeader.EntryMessageStatus)? = nil,
      _ body: (ArchiveStream) throws -> R
    ) throws -> R {
      try body(ArchiveStream())
    }

    public func writeDirectoryContents(archiveFrom directory: FilePath, keySet: ArchiveHeader.FieldKeySet) throws {}
    @discardableResult
    public static func process(readingFrom decoder: ArchiveStream, writingTo extractor: ArchiveStream) throws -> Int { 0 }
    public func close() throws {}
  }
#endif
