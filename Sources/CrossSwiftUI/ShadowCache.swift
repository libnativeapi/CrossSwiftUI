import SwiftUIRuntime

/// Owns native masks, independent of position, tint and animated opacity.
final class ShadowCache<Value> {
  private struct Key: Hashable {
    let width, height, corner, radius, scale: Double
  }
  private var entries: [Key: (ShadowMask, Value)] = [:]
  private var bytes = 0

  func value(
    width: Double, height: Double, corner: Double, radius: Double, scale: Double,
    create: (ShadowMask) -> Value?
  ) -> (ShadowMask, Value)? {
    let corner = corner.isNaN ? corner : max(0, min(corner, min(width, height) / 2))
    let key = Key(width: width, height: height, corner: corner, radius: radius, scale: scale)
    if let entry = entries[key] { return entry }
    guard
      let mask = ShadowMask(
        width: width, height: height, cornerRadius: corner,
        radius: radius, scale: scale), let value = create(mask)
    else { return nil }
    // Native surfaces need up to four bytes per pixel in addition to alpha.
    if entries.count >= 16 || bytes + mask.alpha.count * 5 > 16 * 1024 * 1024 {
      entries.removeAll(keepingCapacity: true)
      bytes = 0
    }
    entries[key] = (mask, value)
    bytes += mask.alpha.count * 5
    return (mask, value)
  }
}
