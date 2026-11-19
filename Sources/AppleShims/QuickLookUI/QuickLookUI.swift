import Foundation
import CrossAppKit

#if !os(macOS)
  @MainActor
  public protocol QLPreviewItem: AnyObject {
    var previewItemURL: URL! { get }
    var previewItemTitle: String! { get }
  }

  extension NSURL: QLPreviewItem {
    public var previewItemURL: URL! { self as URL }
    public var previewItemTitle: String! { lastPathComponent ?? "" }
  }

  public enum QLPreviewViewStyle: UInt, Sendable {
    case normal = 0
    case compact = 1
  }

  @MainActor
  open class QLPreviewView: NSView {
    public var previewItem: (any QLPreviewItem)?
    public var autostarts: Bool = true
    public var shouldCloseWithWindow: Bool = true
    public override init(frame frameRect: NSRect) { super.init(frame: frameRect) }
    public init?(frame frameRect: NSRect, style: QLPreviewViewStyle) { super.init(frame: frameRect) }
    public required init?(coder: NSCoder) { super.init(coder: coder) }
    public func refreshPreviewItem() {}
    public func close() {}
  }
#endif
