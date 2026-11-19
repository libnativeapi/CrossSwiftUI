import Foundation
import CrossAppKit
import CoreGraphics

#if !os(macOS)
  open class PDFPage: NSObject, @unchecked Sendable {
    public var string: String? { nil }
    public func bounds(for box: Int) -> CGRect { .zero }
  }

  open class PDFDocument: NSObject, @unchecked Sendable {
    public var documentURL: URL?
    public var pageCount: Int { 0 }
    public var string: String? { nil }
    public init?(url: URL) { return nil }
    public init?(data: Data) { return nil }
    public func page(at index: Int) -> PDFPage? { nil }
  }

  public enum PDFDisplayMode: Int, Sendable {
    case singlePage = 0
    case singlePageContinuous = 1
    case twoUp = 2
    case twoUpContinuous = 3
  }

  @MainActor
  open class PDFView: NSView {
    public var document: PDFDocument?
    public var autoScales: Bool = true
    public var displaysPageBreaks: Bool = true
    public var backgroundColor: NSColor = .clear
    public var displayMode: PDFDisplayMode = .singlePageContinuous
  }
#endif
