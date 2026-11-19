import Foundation
import CoreFoundation
import CoreGraphics

#if !os(macOS)
  public final class CGImageSource: @unchecked Sendable {
    public let data: Data?
    public init(data: Data?) { self.data = data }
  }
  public final class CGImageDestination: @unchecked Sendable {}

  public let kCGImageSourceShouldCache: CFString = "kCGImageSourceShouldCache"
  public let kCGImageSourceShouldCacheImmediately: CFString = "kCGImageSourceShouldCacheImmediately"
  public let kCGImageSourceCreateThumbnailFromImageAlways: CFString = "kCGImageSourceCreateThumbnailFromImageAlways"
  public let kCGImageSourceCreateThumbnailFromImageIfAbsent: CFString = "kCGImageSourceCreateThumbnailFromImageIfAbsent"
  public let kCGImageSourceThumbnailMaxPixelSize: CFString = "kCGImageSourceThumbnailMaxPixelSize"
  public let kCGImageSourceCreateThumbnailWithTransform: CFString = "kCGImageSourceCreateThumbnailWithTransform"
  public let kCGImagePropertyPixelWidth: CFString = "PixelWidth"
  public let kCGImagePropertyPixelHeight: CFString = "PixelHeight"
  public let kCGImagePropertyOrientation: CFString = "Orientation"

  public func CGImageSourceCreateWithURL(_ url: URL, _ options: CFDictionary?) -> CGImageSource? {
    guard let data = try? Data(contentsOf: url) else { return nil }
    return CGImageSource(data: data)
  }
  public func CGImageSourceCreateWithURL(_ url: CFURL, _ options: CFDictionary?) -> CGImageSource? {
    CGImageSourceCreateWithURL(url as URL, options)
  }
  public func CGImageSourceCreateWithData(_ data: CFData, _ options: CFDictionary?) -> CGImageSource? {
    CGImageSource(data: data as Data)
  }
  public func CGImageSourceGetCount(_ isrc: CGImageSource) -> Int { isrc.data != nil ? 1 : 0 }
  public func CGImageSourceCopyPropertiesAtIndex(_ isrc: CGImageSource, _ index: Int, _ options: CFDictionary?) -> CFDictionary? { nil }
  public func CGImageSourceCreateThumbnailAtIndex(_ isrc: CGImageSource, _ index: Int, _ options: CFDictionary?) -> CGImage? { nil }
  public func CGImageSourceCreateImageAtIndex(_ isrc: CGImageSource, _ index: Int, _ options: CFDictionary?) -> CGImage? { nil }
#endif
