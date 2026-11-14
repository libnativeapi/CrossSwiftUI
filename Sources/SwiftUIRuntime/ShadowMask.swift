import Foundation

/// A rounded-rectangle alpha mask shared by the desktop drawing backends.
/// Three separable box filters approximate a Gaussian without drawing nested
/// translucent outlines. Radius is the Gaussian standard deviation, in points.
public struct ShadowMask {
  public let width: Int
  public let height: Int
  public let scale: Double
  public let inset: Double
  public let alpha: [UInt8]

  public static func padding(radius: Double) -> Double {
    radius.isFinite ? ceil(max(0, radius) * 3) + 2 : 0
  }

  public init?(
    width: Double, height: Double, cornerRadius: Double,
    radius: Double, scale: Double = 1
  ) {
    guard width.isFinite, height.isFinite, cornerRadius.isFinite,
      radius.isFinite, scale.isFinite, width > 0, height > 0, scale > 0
    else { return nil }
    let padding = Self.padding(radius: radius)
    let paddedWidth = width + padding * 2
    let paddedHeight = height + padding * 2
    guard paddedWidth.isFinite, paddedHeight.isFinite else { return nil }
    // Bound temporary storage for oversized views; downsampling changes only
    // resolution, never the logical blur radius or its extent.
    let scale = min(scale, 2048 / max(paddedWidth, paddedHeight))
    let w = Int(ceil(paddedWidth * scale))
    let h = Int(ceil(paddedHeight * scale))
    guard w > 0, h > 0 else { return nil }
    self.width = w
    self.height = h
    self.scale = scale
    self.inset = padding
    let left = padding * scale
    let top = padding * scale
    let right = left + width * scale
    let bottom = top + height * scale
    let corner = max(0, min(cornerRadius, min(width, height) / 2)) * scale
    var pixels = [Float](repeating: 0, count: w * h)
    // Integrate coverage along each scanline, including fractional-size edges.
    for y in 0..<h {
      for sample in 0..<4 {
        let py = Double(y) + (Double(sample) + 0.5) / 4
        guard py > top, py < bottom else { continue }
        let dy = max(0, top + corner - py, py - (bottom - corner))
        let cut = corner - sqrt(max(0, corner * corner - dy * dy))
        let start = left + cut
        let end = right - cut
        for x in max(0, Int(floor(start)))..<min(w, Int(ceil(end))) {
          pixels[y * w + x] += Float(max(0, min(Double(x + 1), end) - max(Double(x), start))) / 4
        }
      }
    }
    let sigma = max(0, radius) * scale
    if sigma > 0 {
      // Choose adjacent odd box widths whose combined variance is sigma².
      let ideal = sqrt(4 * sigma * sigma + 1)
      var lower = Int(floor(ideal))
      if lower % 2 == 0 { lower -= 1 }
      lower = max(1, lower)
      let upper = lower + 2
      let count = Int(
        round(
          (12 * sigma * sigma - 3 * Double(lower * lower)
            - 12 * Double(lower) - 9) / (-4 * Double(lower) - 4)))
      var scratch = [Float](repeating: 0, count: pixels.count)
      for pass in 0..<3 {
        let boxRadius = ((pass < count ? lower : upper) - 1) / 2
        guard boxRadius > 0 else { continue }
        Self.blur(pixels, into: &scratch, width: w, height: h, radius: boxRadius, horizontal: true)
        Self.blur(scratch, into: &pixels, width: w, height: h, radius: boxRadius, horizontal: false)
      }
    }
    self.alpha = pixels.map { UInt8(clamping: Int((max(0, min(1, $0)) * 255).rounded())) }
  }

  private static func blur(
    _ input: [Float], into output: inout [Float],
    width: Int, height: Int, radius: Int, horizontal: Bool
  ) {
    let length = horizontal ? width : height
    let lines = horizontal ? height : width
    let stride = horizontal ? 1 : width
    let divisor = Float(radius * 2 + 1)
    for line in 0..<lines {
      let base = horizontal ? line * width : line
      var sum: Float = 0
      for i in 0..<min(length, radius + 1) { sum += input[base + i * stride] }
      for i in 0..<length {
        output[base + i * stride] = sum / divisor
        if i >= radius { sum -= input[base + (i - radius) * stride] }
        if i + radius + 1 < length { sum += input[base + (i + radius + 1) * stride] }
      }
    }
  }
}
