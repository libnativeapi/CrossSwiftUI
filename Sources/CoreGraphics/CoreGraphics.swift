@_exported import Foundation

#if !os(macOS)
  public typealias CGDirectDisplayID = UInt32
  public typealias CGKeyCode = UInt16
  public typealias UniChar = UInt16

  extension CGRect {
    public func equalTo(_ rect2: CGRect) -> Bool {
      self == rect2
    }
  }

  public final class CGColor: @unchecked Sendable {
    public let red: CGFloat
    public let green: CGFloat
    public let blue: CGFloat
    public let alpha: CGFloat

    public init(red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
      self.red = red
      self.green = green
      self.blue = blue
      self.alpha = alpha
    }

    public init(srgbRed red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
      self.red = red
      self.green = green
      self.blue = blue
      self.alpha = alpha
    }

    public init(gray: CGFloat, alpha: CGFloat) {
      self.red = gray
      self.green = gray
      self.blue = gray
      self.alpha = alpha
    }

    public var components: [CGFloat]? { [red, green, blue, alpha] }
    public var numberOfComponents: Int { 4 }

    public func copy(alpha: CGFloat) -> CGColor? {
      CGColor(red: red, green: green, blue: blue, alpha: alpha)
    }

    public static let clear = CGColor(red: 0, green: 0, blue: 0, alpha: 0)
    public static let black = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    public static let white = CGColor(red: 1, green: 1, blue: 1, alpha: 1)
  }

  public final class CGImage: @unchecked Sendable {
    public let width: Int
    public let height: Int
    public let pngData: Data?

    public init(width: Int, height: Int, pngData: Data? = nil) {
      self.width = width
      self.height = height
      self.pngData = pngData
    }
  }

  public struct CGAffineTransform: Equatable, Sendable {
    public var a: CGFloat
    public var b: CGFloat
    public var c: CGFloat
    public var d: CGFloat
    public var tx: CGFloat
    public var ty: CGFloat

    public init(a: CGFloat, b: CGFloat, c: CGFloat, d: CGFloat, tx: CGFloat, ty: CGFloat) {
      self.a = a
      self.b = b
      self.c = c
      self.d = d
      self.tx = tx
      self.ty = ty
    }

    public static let identity = CGAffineTransform(a: 1, b: 0, c: 0, d: 1, tx: 0, ty: 0)
  }

  open class CGPath: @unchecked Sendable {
    public init() {}
    public init(roundedRect rect: CGRect, cornerWidth: CGFloat, cornerHeight: CGFloat, transform: UnsafePointer<CGAffineTransform>?) {}
    public init(rect: CGRect, transform: UnsafePointer<CGAffineTransform>?) {}
    public init(ellipseIn rect: CGRect, transform: UnsafePointer<CGAffineTransform>?) {}
  }

  public final class CGMutablePath: CGPath, @unchecked Sendable {
    public override init() { super.init() }
    public func move(to point: CGPoint) {}
    public func addLine(to point: CGPoint) {}
    public func addRect(_ rect: CGRect) {}
    public func addRoundedRect(in rect: CGRect, cornerWidth: CGFloat, cornerHeight: CGFloat) {}
    public func closeSubpath() {}
  }

  public final class CGContext: @unchecked Sendable {
    public var textMatrix: CGAffineTransform = .identity
    public init() {}
    public func saveGState() {}
    public func restoreGState() {}
    public func setFillColor(_ color: CGColor) {}
    public func setStrokeColor(_ color: CGColor) {}
    public func setLineWidth(_ width: CGFloat) {}
    public func translateBy(x: CGFloat, y: CGFloat) {}
    public func scaleBy(x: CGFloat, y: CGFloat) {}
    public func addPath(_ path: Any) {}
    public func fillPath() {}
    public func strokePath() {}
    public func fill(_ rect: CGRect) {}
    public func stroke(_ rect: CGRect) {}
  }

  public struct CGEventFlags: OptionSet, Hashable, Sendable {
    public let rawValue: UInt64
    public init(rawValue: UInt64) { self.rawValue = rawValue }
    public static let maskAlphaShift = CGEventFlags(rawValue: 0x00010000)
    public static let maskShift = CGEventFlags(rawValue: 0x00020000)
    public static let maskControl = CGEventFlags(rawValue: 0x00040000)
    public static let maskAlternate = CGEventFlags(rawValue: 0x00080000)
    public static let maskCommand = CGEventFlags(rawValue: 0x00100000)
    public static let maskNumericPad = CGEventFlags(rawValue: 0x00200000)
    public static let maskHelp = CGEventFlags(rawValue: 0x00400000)
    public static let maskSecondaryFn = CGEventFlags(rawValue: 0x00800000)
    public static let maskNonCoalesced = CGEventFlags(rawValue: 0x00000100)
  }

  public enum CGEventType: UInt32, Sendable {
    case null = 0
    case leftMouseDown = 1
    case leftMouseUp = 2
    case rightMouseDown = 3
    case rightMouseUp = 4
    case mouseMoved = 5
    case leftMouseDragged = 6
    case rightMouseDragged = 7
    case keyDown = 10
    case keyUp = 11
    case flagsChanged = 12
    case scrollWheel = 22
    case otherMouseDown = 25
    case otherMouseUp = 26
    case otherMouseDragged = 27
    case tapDisabledByTimeout = 0xFFFFFFFE
    case tapDisabledByUserInput = 0xFFFFFFFF
  }

  public func CGMainDisplayID() -> CGDirectDisplayID { 1 }
#endif
