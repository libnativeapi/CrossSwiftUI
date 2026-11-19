import Foundation
import CoreFoundation
import CoreGraphics
import CrossAppKit

#if !os(macOS)
  public typealias CTFont = NSFont
  public final class CTFontDescriptor: @unchecked Sendable {}
  public final class CTLine: @unchecked Sendable {
    public let text: String
    public init(text: String) { self.text = text }
  }
  public final class CTRun: @unchecked Sendable {}
  public typealias CGGlyph = UInt16
  public typealias CTFontUIFontType = UInt32
  public typealias CTFontTableTag = UInt32
  public enum CTFontOrientation: UInt32, Sendable {
    case `default` = 0
    case horizontal = 1
    case vertical = 2
  }
  public struct CTFontTableOptions: OptionSet, Sendable {
    public let rawValue: UInt32
    public init(rawValue: UInt32) { self.rawValue = rawValue }
    public static let noOptions = CTFontTableOptions([])
  }
  public struct CTLineBoundsOptions: OptionSet, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let excludeTypographicLeading = CTLineBoundsOptions(rawValue: 1 << 0)
    public static let excludeTypographicShifts = CTLineBoundsOptions(rawValue: 1 << 1)
    public static let useHangingPunctuation = CTLineBoundsOptions(rawValue: 1 << 2)
    public static let useGlyphPathBounds = CTLineBoundsOptions(rawValue: 1 << 3)
    public static let useOpticalBounds = CTLineBoundsOptions(rawValue: 1 << 4)
  }
  public let kCTFontUIFontSystem: CTFontUIFontType = 2
  public let kCTFontAttributeName: CFString = "NSFont" as NSString

  public func CTFontCreateUIFontForLanguage(_ uiType: CTFontUIFontType, _ size: CGFloat, _ language: CFString?) -> CTFont? {
    NSFont.systemFont(ofSize: size)
  }
  public func CTFontCopyGraphicsFont(_ font: CTFont, _ attributes: UnsafeMutablePointer<CTFontDescriptor?>?) -> AnyObject {
    font
  }
  public func CTFontCopyTable(_ font: CTFont, _ table: CTFontTableTag, _ options: CTFontTableOptions) -> CFData? {
    nil
  }
  public func CTFontDrawGlyphs(_ font: CTFont, _ glyphs: UnsafePointer<CGGlyph>, _ positions: UnsafePointer<CGPoint>, _ count: Int, _ context: CGContext) {}

  public func CTFontCreateWithName(_ name: CFString, _ size: CGFloat, _ matrix: UnsafePointer<CGAffineTransform>?) -> CTFont {
    NSFont(name: name as String, size: size) ?? NSFont.systemFont(ofSize: size)
  }
  public func CTFontGetSize(_ font: CTFont) -> CGFloat { font.pointSize }
  public func CTFontGetAscent(_ font: CTFont) -> CGFloat { font.pointSize * 0.8 }
  public func CTFontGetDescent(_ font: CTFont) -> CGFloat { font.pointSize * 0.2 }
  public func CTFontGetLeading(_ font: CTFont) -> CGFloat { 0 }
  public func CTFontGetXHeight(_ font: CTFont) -> CGFloat { font.pointSize * 0.5 }
  public func CTFontGetCapHeight(_ font: CTFont) -> CGFloat { font.pointSize * 0.7 }
  public func CTFontGetUnitsPerEm(_ font: CTFont) -> UInt32 { 1000 }
  public func CTFontGetGlyphsForCharacters(_ font: CTFont, _ characters: UnsafePointer<UniChar>, _ glyphs: UnsafeMutablePointer<CGGlyph>, _ count: CFIndex) -> Bool {
    for i in 0..<count { glyphs[i] = 0 }
    return false
  }
  @discardableResult
  public func CTFontGetAdvancesForGlyphs(_ font: CTFont, _ orientation: CTFontOrientation, _ glyphs: UnsafePointer<CGGlyph>, _ advances: UnsafeMutablePointer<CGSize>?, _ count: CFIndex) -> Double {
    let adv = CGSize(width: font.pointSize * 0.55, height: 0)
    if let advances {
      for i in 0..<count { advances[i] = adv }
    }
    return Double(count) * Double(adv.width)
  }
  @discardableResult
  public func CTFontGetBoundingRectsForGlyphs(_ font: CTFont, _ orientation: CTFontOrientation, _ glyphs: UnsafePointer<CGGlyph>, _ boundingRects: UnsafeMutablePointer<CGRect>?, _ count: CFIndex) -> CGRect {
    let rect = CGRect(x: 0, y: 0, width: font.pointSize * 0.55, height: font.pointSize)
    if let boundingRects {
      for i in 0..<count { boundingRects[i] = rect }
    }
    return rect
  }
  public func CTLineCreateWithAttributedString(_ attrString: NSAttributedString) -> CTLine {
    CTLine(text: attrString.string)
  }
  public func CTLineGetTypographicBounds(_ line: CTLine, _ ascent: UnsafeMutablePointer<CGFloat>?, _ descent: UnsafeMutablePointer<CGFloat>?, _ leading: UnsafeMutablePointer<CGFloat>?) -> Double {
    ascent?.pointee = 12
    descent?.pointee = 3
    leading?.pointee = 0
    return Double(line.text.count) * 8.0
  }
  public func CTLineGetBoundsWithOptions(_ line: CTLine, _ options: CTLineBoundsOptions) -> CGRect {
    CGRect(x: 0, y: -3, width: Double(line.text.count) * 8.0, height: 15)
  }
  public func CTLineGetGlyphRuns(_ line: CTLine) -> CFArray {
    NSArray()
  }
  public func CTRunGetGlyphCount(_ run: CTRun) -> CFIndex { 0 }
  public func CTRunGetGlyphs(_ run: CTRun, _ range: CFRange, _ buffer: UnsafeMutablePointer<CGGlyph>) {}
  public func CTRunGetPositions(_ run: CTRun, _ range: CFRange, _ buffer: UnsafeMutablePointer<CGPoint>) {}
  public func CTRunGetAttributes(_ run: CTRun) -> CFDictionary { NSDictionary() }
  public func CTLineDraw(_ line: CTLine, _ context: CGContext) {}
#endif
