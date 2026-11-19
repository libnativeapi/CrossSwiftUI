import Foundation
import CrossAppKit
import CoreGraphics

#if !os(macOS)
  public final class QLThumbnailRepresentation: NSObject, @unchecked Sendable {
    public let nsImage: NSImage
    public var cgImage: CGImage { CGImage(width: Int(nsImage.size.width), height: Int(nsImage.size.height)) }
    public init(nsImage: NSImage) { self.nsImage = nsImage }
  }

  public final class QLThumbnailGenerator: NSObject, @unchecked Sendable {
    public static let shared = QLThumbnailGenerator()

    public final class Request: NSObject, @unchecked Sendable {
      public struct RepresentationTypes: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let icon = RepresentationTypes(rawValue: 1 << 0)
        public static let lowQualityThumbnail = RepresentationTypes(rawValue: 1 << 1)
        public static let thumbnail = RepresentationTypes(rawValue: 1 << 2)
        public static let all: RepresentationTypes = [.icon, .lowQualityThumbnail, .thumbnail]
      }
      public let fileURL: URL
      public let size: CGSize
      public let scale: CGFloat
      public let representationTypes: RepresentationTypes
      public init(fileAt url: URL, size: CGSize, scale: CGFloat, representationTypes: RepresentationTypes) {
        self.fileURL = url
        self.size = size
        self.scale = scale
        self.representationTypes = representationTypes
      }
    }

    public func generateBestRepresentation(for request: Request) async throws -> QLThumbnailRepresentation {
      throw NSError(domain: "QLThumbnailGenerator", code: -1)
    }

    public func generateBestRepresentation(
      for request: Request,
      completion completionHandler: @escaping @Sendable (QLThumbnailRepresentation?, (any Error)?) -> Void
    ) {
      completionHandler(nil, NSError(domain: "QLThumbnailGenerator", code: -1))
    }
  }
#endif
