import Foundation
import CoreFoundation
import CoreGraphics
#if os(Windows)
  import CAppKitWindows
#endif

#if !os(macOS)
  public final class CGImageSource: @unchecked Sendable {
    public let data: Data?
    public let url: URL?
    public init(data: Data?, url: URL? = nil) {
      self.data = data
      self.url = url
    }
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
    guard FileManager.default.fileExists(atPath: url.path) else { return nil }
    let data = try? Data(contentsOf: url, options: .mappedIfSafe)
    return CGImageSource(data: data, url: url)
  }
  public func CGImageSourceCreateWithURL(_ url: CFURL, _ options: CFDictionary?) -> CGImageSource? {
    CGImageSourceCreateWithURL(url as URL, options)
  }
  public func CGImageSourceCreateWithData(_ data: CFData, _ options: CFDictionary?) -> CGImageSource? {
    CGImageSource(data: data as Data)
  }
  public func CGImageSourceGetCount(_ isrc: CGImageSource) -> Int {
    (isrc.data != nil || isrc.url != nil) ? 1 : 0
  }
  public func CGImageSourceCopyPropertiesAtIndex(
    _ isrc: CGImageSource, _ index: Int, _ options: CFDictionary?
  ) -> CFDictionary? {
    guard index == 0 else { return nil }
    #if os(Windows)
      var w: Int32 = 0
      var h: Int32 = 0
      var ok: Int32 = 0
      if let url = isrc.url {
        ok = cak_image_file_dimensions(url.path, &w, &h)
      }
      if ok == 0, let data = isrc.data, !data.isEmpty {
        ok = data.withUnsafeBytes { raw in
          cak_image_dimensions(raw.bindMemory(to: UInt8.self).baseAddress, data.count, &w, &h)
        }
      }
      if ok != 0 && w > 0 && h > 0 {
        let dict: [CFString: Any] = [
          kCGImagePropertyPixelWidth: Int(w),
          kCGImagePropertyPixelHeight: Int(h),
        ]
        return dict as CFDictionary
      }
    #endif
    return nil
  }

  public func CGImageSourceCreateThumbnailAtIndex(
    _ isrc: CGImageSource, _ index: Int, _ options: CFDictionary?
  ) -> CGImage? {
    guard index == 0 else { return nil }
    var maxPixel = 1024
    if let dict = options as? [CFString: Any], let rawMax = dict[kCGImageSourceThumbnailMaxPixelSize] {
      if let d = rawMax as? Double { maxPixel = max(1, Int(d.rounded(.up))) }
      else if let cg = rawMax as? CGFloat { maxPixel = max(1, Int(cg.rounded(.up))) }
      else if let i = rawMax as? Int { maxPixel = max(1, i) }
      else if let num = rawMax as? NSNumber { maxPixel = max(1, Int(ceil(num.doubleValue))) }
    }
    #if os(Windows)
      let bytes = isrc.data ?? (isrc.url.flatMap { try? Data(contentsOf: $0, options: .mappedIfSafe) })
      guard let data = bytes, !data.isEmpty else { return nil }
      var outW: Int32 = 0
      var outH: Int32 = 0
      var outLen: Int = 0
      let ptr = data.withUnsafeBytes { raw in
        cak_image_resize_png_dims(
          raw.bindMemory(to: UInt8.self).baseAddress,
          data.count,
          Int32(maxPixel),
          &outW,
          &outH,
          &outLen
        )
      }
      guard let ptr, outLen > 0, outW > 0, outH > 0 else {
        if let ptr { cak_free(ptr) }
        return nil
      }
      let png = Data(bytes: ptr, count: outLen)
      cak_free(ptr)
      return CGImage(width: Int(outW), height: Int(outH), pngData: png)
    #else
      return nil
    #endif
  }

  public func CGImageSourceCreateImageAtIndex(
    _ isrc: CGImageSource, _ index: Int, _ options: CFDictionary?
  ) -> CGImage? {
    guard index == 0 else { return nil }
    #if os(Windows)
      let bytes = isrc.data ?? (isrc.url.flatMap { try? Data(contentsOf: $0, options: .mappedIfSafe) })
      guard let data = bytes, !data.isEmpty else { return nil }
      var outW: Int32 = 0
      var outH: Int32 = 0
      var outLen: Int = 0
      let ptr = data.withUnsafeBytes { raw in
        cak_image_resize_png_dims(
          raw.bindMemory(to: UInt8.self).baseAddress,
          data.count,
          8192,
          &outW,
          &outH,
          &outLen
        )
      }
      guard let ptr, outLen > 0, outW > 0, outH > 0 else {
        if let ptr { cak_free(ptr) }
        return nil
      }
      let png = Data(bytes: ptr, count: outLen)
      cak_free(ptr)
      return CGImage(width: Int(outW), height: Int(outH), pngData: png)
    #else
      return nil
    #endif
  }
#endif
