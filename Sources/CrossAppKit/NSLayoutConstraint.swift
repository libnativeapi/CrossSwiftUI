import Foundation

open class NSLayoutConstraint: NSObject {
  public var isActive: Bool = false
  public var constant: CGFloat = 0
  public var priority: NSLayoutPriority = .required
  public var identifier: String?

  public override init() {
    super.init()
  }

  public static func activate(_ constraints: [NSLayoutConstraint]) {
    for constraint in constraints { constraint.isActive = true }
  }

  public static func deactivate(_ constraints: [NSLayoutConstraint]) {
    for constraint in constraints { constraint.isActive = false }
  }
}

open class NSLayoutAnchor<AnchorType: AnyObject>: NSObject {
  public override init() { super.init() }

  public func constraint(equalTo anchor: NSLayoutAnchor<AnchorType>, constant c: CGFloat = 0) -> NSLayoutConstraint {
    let constraint = NSLayoutConstraint()
    constraint.constant = c
    return constraint
  }

  public func constraint(greaterThanOrEqualTo anchor: NSLayoutAnchor<AnchorType>, constant c: CGFloat = 0) -> NSLayoutConstraint {
    let constraint = NSLayoutConstraint()
    constraint.constant = c
    return constraint
  }

  public func constraint(lessThanOrEqualTo anchor: NSLayoutAnchor<AnchorType>, constant c: CGFloat = 0) -> NSLayoutConstraint {
    let constraint = NSLayoutConstraint()
    constraint.constant = c
    return constraint
  }
}

public final class NSLayoutXAxisAnchor: NSLayoutAnchor<NSLayoutXAxisAnchor> {}
public final class NSLayoutYAxisAnchor: NSLayoutAnchor<NSLayoutYAxisAnchor> {}

public final class NSLayoutDimension: NSLayoutAnchor<NSLayoutDimension> {
  public func constraint(equalToConstant c: CGFloat) -> NSLayoutConstraint {
    let constraint = NSLayoutConstraint()
    constraint.constant = c
    return constraint
  }

  public func constraint(greaterThanOrEqualToConstant c: CGFloat) -> NSLayoutConstraint {
    let constraint = NSLayoutConstraint()
    constraint.constant = c
    return constraint
  }

  public func constraint(lessThanOrEqualToConstant c: CGFloat) -> NSLayoutConstraint {
    let constraint = NSLayoutConstraint()
    constraint.constant = c
    return constraint
  }

  public func constraint(equalTo anchor: NSLayoutDimension, multiplier m: CGFloat, constant c: CGFloat = 0) -> NSLayoutConstraint {
    let constraint = NSLayoutConstraint()
    constraint.constant = c
    return constraint
  }
}

extension NSView {
  public var leadingAnchor: NSLayoutXAxisAnchor { NSLayoutXAxisAnchor() }
  public var trailingAnchor: NSLayoutXAxisAnchor { NSLayoutXAxisAnchor() }
  public var leftAnchor: NSLayoutXAxisAnchor { NSLayoutXAxisAnchor() }
  public var rightAnchor: NSLayoutXAxisAnchor { NSLayoutXAxisAnchor() }
  public var topAnchor: NSLayoutYAxisAnchor { NSLayoutYAxisAnchor() }
  public var bottomAnchor: NSLayoutYAxisAnchor { NSLayoutYAxisAnchor() }
  public var centerXAnchor: NSLayoutXAxisAnchor { NSLayoutXAxisAnchor() }
  public var centerYAnchor: NSLayoutYAxisAnchor { NSLayoutYAxisAnchor() }
  public var firstBaselineAnchor: NSLayoutYAxisAnchor { NSLayoutYAxisAnchor() }
  public var lastBaselineAnchor: NSLayoutYAxisAnchor { NSLayoutYAxisAnchor() }
  public var widthAnchor: NSLayoutDimension { NSLayoutDimension() }
  public var heightAnchor: NSLayoutDimension { NSLayoutDimension() }
}
