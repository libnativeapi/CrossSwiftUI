import Foundation

/// Tracks and interpolates layout-sizing properties across `withAnimation` and
/// `.animation(_:value:)` transactions so sibling panes and native child controls
/// reflow together frame by frame.
final class LayoutAnimator {
  enum Field: Hashable {
    case frameWidth, frameHeight
    case minWidth, minHeight
    case idealWidth, idealHeight
    case maxWidth, maxHeight
    case paddingTop, paddingLeading, paddingBottom, paddingTrailing
    case spacing
  }

  struct ScalarMotion {
    let from: Double
    let to: Double
    let animation: Animation
    let start: TimeInterval

    func isActive(at now: TimeInterval) -> Bool {
      animation.duration > 0 && now < start + animation.duration
    }

    func value(at now: TimeInterval, nonNegative: Bool) -> Double {
      let progress = animation.progress(at: now, start: start)
      let interpolated = from + (to - from) * progress
      return nonNegative ? max(0, interpolated) : interpolated
    }
  }

  struct TargetSizing: Equatable {
    var frameWidth: Double?
    var frameHeight: Double?
    var minWidth: Double?
    var minHeight: Double?
    var idealWidth: Double?
    var idealHeight: Double?
    var maxWidth: Double?
    var maxHeight: Double?
    var padding: EdgeInsets
    var spacing: Double

    init(_ props: NodeProps) {
      frameWidth = props.frameWidth
      frameHeight = props.frameHeight
      minWidth = props.minWidth
      minHeight = props.minHeight
      idealWidth = props.idealWidth
      idealHeight = props.idealHeight
      maxWidth = props.maxWidth
      maxHeight = props.maxHeight
      padding = props.padding
      spacing = props.spacing
    }
  }

  private struct GeometryScope {
    let previousChildren: [Element]
    let inheritedAnimation: Animation?
  }

  private var targets: [NodeID: TargetSizing] = [:]
  private var motions: [NodeID: [Field: ScalarMotion]] = [:]
  private var geometryScopes: [NodeID: GeometryScope] = [:]
  private var visitedMotions = Set<NodeID>()
  private var passes = 0

  var hasActiveMotions: Bool { !motions.isEmpty }

  func beginPass() {
    visitedMotions.removeAll(keepingCapacity: true)
    geometryScopes.removeAll(keepingCapacity: true)
  }

  func finishPass(mounted: Element?) {
    if !motions.isEmpty {
      motions = motions.filter { visitedMotions.contains($0.key) && !$0.value.isEmpty }
    }
    guard let mounted else { return }
    seedMissingTargets(mounted)
    passes += 1
    if passes % 16 == 0 && motions.isEmpty {
      var live = Set<NodeID>()
      collectIDs(mounted, into: &live)
      targets = targets.filter { live.contains($0.key) }
    }
  }

  func seed(_ root: Element) {
    seedMissingTargets(root)
  }

  private func seedMissingTargets(_ node: Element) {
    if node.id.rawValue != 0 && targets[node.id] == nil {
      targets[node.id] = TargetSizing(node.props)
    } else if node.reusesLayout && node.id.rawValue != 0 && targets[node.id] != nil {
      return
    }
    for child in node.children {
      seedMissingTargets(child)
    }
  }

  private func collectIDs(_ node: Element, into live: inout Set<NodeID>) {
    if node.id.rawValue != 0 { live.insert(node.id) }
    for child in node.children { collectIDs(child, into: &live) }
  }

  func apply(
    to element: inout Element,
    previous: Element?,
    inheritedAnimation: Animation?,
    renderPass: Int,
    now: TimeInterval
  ) {
    let effectiveAnimation: Animation?
    if element.props.animationPass == renderPass {
      element.hasScopedAnimation = true
      if element.props.animationDisabled {
        effectiveAnimation = nil
      } else {
        effectiveAnimation = element.props.animation ?? inheritedAnimation
      }
    } else {
      element.props.animation = nil
      element.props.animationDisabled = false
      element.props.animationPass = 0
      element.hasScopedAnimation = false
      effectiveAnimation = inheritedAnimation
    }

    let matched = previous.flatMap { $0.kind == element.kind && $0.id.rawValue != 0 ? $0 : nil }
    if let matched {
      let id = matched.id
      if element.reusesLayout && !matched.hasLayoutAnimation && !matched.hasScopedAnimation
        && motions[id] == nil && effectiveAnimation == nil
      {
        element.hasLayoutAnimation = false
        element.hasScopedAnimation = false
        return
      }
      element.hasLayoutAnimation = interpolateNode(
        id: id, props: &element.props, animation: effectiveAnimation, now: now)
      if element.kind == .geometry {
        element.id = id
        geometryScopes[id] = GeometryScope(
          previousChildren: matched.children,
          inheritedAnimation: effectiveAnimation)
      }
    } else {
      element.hasLayoutAnimation = false
    }

    guard !element.children.isEmpty else { return }
    if let matched {
      let oldChildren = matched.children
      let aligned =
        oldChildren.count == element.children.count
        && oldChildren.indices.allSatisfy { idx in
          let oldChild = oldChildren[idx]
          let newChild = element.children[idx]
          let expected: ElementKey =
            newChild.explicitID.map(ElementKey.explicit) ?? .structural(newChild.kind, idx)
          return oldChild.key == expected && oldChild.kind == newChild.kind
        }
      if aligned {
        for index in element.children.indices {
          apply(
            to: &element.children[index],
            previous: oldChildren[index],
            inheritedAnimation: effectiveAnimation,
            renderPass: renderPass,
            now: now)
          if element.children[index].hasLayoutAnimation { element.hasLayoutAnimation = true }
          if element.children[index].hasScopedAnimation { element.hasScopedAnimation = true }
        }
      } else {
        var oldByKey: [ElementKey: Element] = [:]
        oldByKey.reserveCapacity(oldChildren.count)
        for child in oldChildren where oldByKey[child.key] == nil {
          oldByKey[child.key] = child
        }
        for index in element.children.indices {
          let child = element.children[index]
          let key: ElementKey =
            child.explicitID.map(ElementKey.explicit) ?? .structural(child.kind, index)
          let oldChild = oldByKey[key].flatMap { $0.kind == child.kind ? $0 : nil }
          apply(
            to: &element.children[index],
            previous: oldChild,
            inheritedAnimation: effectiveAnimation,
            renderPass: renderPass,
            now: now)
          if element.children[index].hasLayoutAnimation { element.hasLayoutAnimation = true }
          if element.children[index].hasScopedAnimation { element.hasScopedAnimation = true }
        }
      }
    } else {
      for index in element.children.indices {
        apply(
          to: &element.children[index],
          previous: nil,
          inheritedAnimation: effectiveAnimation,
          renderPass: renderPass,
          now: now)
        if element.children[index].hasScopedAnimation { element.hasScopedAnimation = true }
      }
    }
  }

  func applyGeometryChild(
    _ child: inout Element,
    geometryID: NodeID,
    fallbackPrevious: Element?,
    renderPass: Int,
    now: TimeInterval
  ) {
    let scope = geometryID.rawValue != 0 ? geometryScopes[geometryID] : nil
    let candidate = scope?.previousChildren.first ?? fallbackPrevious
    let prior = candidate.flatMap { $0.kind == child.kind ? $0 : nil }
    apply(
      to: &child,
      previous: prior,
      inheritedAnimation: scope?.inheritedAnimation,
      renderPass: renderPass,
      now: now)
  }

  private func interpolateNode(
    id: NodeID,
    props: inout NodeProps,
    animation: Animation?,
    now: TimeInterval
  ) -> Bool {
    let nextTarget = TargetSizing(props)
    guard let prevTarget = targets[id] else {
      targets[id] = nextTarget
      return false
    }
    targets[id] = nextTarget

    let animatable = (animation != nil && animation!.duration > 0 && !animation!.repeats)
      ? animation : nil
    var nodeMotions = motions[id] ?? [:]

    func stepOptional(
      _ field: Field, previous: Double?, target: Double?, nonNegative: Bool
    ) -> Double? {
      guard let target, target.isFinite else {
        nodeMotions.removeValue(forKey: field)
        return target
      }
      guard let previous, previous.isFinite else {
        nodeMotions.removeValue(forKey: field)
        return target
      }
      return stepScalar(field, previous: previous, target: target, nonNegative: nonNegative)
    }

    func stepScalar(
      _ field: Field, previous: Double, target: Double, nonNegative: Bool
    ) -> Double {
      let existing = nodeMotions[field]
      if target == previous {
        if let existing, existing.isActive(at: now) {
          return existing.value(at: now, nonNegative: nonNegative)
        }
        nodeMotions.removeValue(forKey: field)
        return target
      }
      guard let animatable else {
        nodeMotions.removeValue(forKey: field)
        return target
      }
      let currentShown: Double
      if let existing, existing.isActive(at: now) {
        currentShown = existing.value(at: now, nonNegative: nonNegative)
      } else {
        currentShown = previous
      }
      guard abs(currentShown - target) > 1e-6 else {
        nodeMotions.removeValue(forKey: field)
        return target
      }
      let motion = ScalarMotion(
        from: currentShown,
        to: target,
        animation: animatable,
        start: now + max(0, animatable.delay))
      if motion.isActive(at: now) {
        nodeMotions[field] = motion
        return motion.value(at: now, nonNegative: nonNegative)
      }
      nodeMotions.removeValue(forKey: field)
      return target
    }

    props.frameWidth = stepOptional(
      .frameWidth, previous: prevTarget.frameWidth, target: nextTarget.frameWidth, nonNegative: true)
    props.frameHeight = stepOptional(
      .frameHeight, previous: prevTarget.frameHeight, target: nextTarget.frameHeight,
      nonNegative: true)
    props.minWidth = stepOptional(
      .minWidth, previous: prevTarget.minWidth, target: nextTarget.minWidth, nonNegative: true)
    props.minHeight = stepOptional(
      .minHeight, previous: prevTarget.minHeight, target: nextTarget.minHeight, nonNegative: true)
    props.idealWidth = stepOptional(
      .idealWidth, previous: prevTarget.idealWidth, target: nextTarget.idealWidth, nonNegative: true)
    props.idealHeight = stepOptional(
      .idealHeight, previous: prevTarget.idealHeight, target: nextTarget.idealHeight,
      nonNegative: true)
    props.maxWidth = stepOptional(
      .maxWidth, previous: prevTarget.maxWidth, target: nextTarget.maxWidth, nonNegative: true)
    props.maxHeight = stepOptional(
      .maxHeight, previous: prevTarget.maxHeight, target: nextTarget.maxHeight, nonNegative: true)
    props.padding.top = stepScalar(
      .paddingTop, previous: prevTarget.padding.top, target: nextTarget.padding.top,
      nonNegative: false)
    props.padding.leading = stepScalar(
      .paddingLeading, previous: prevTarget.padding.leading, target: nextTarget.padding.leading,
      nonNegative: false)
    props.padding.bottom = stepScalar(
      .paddingBottom, previous: prevTarget.padding.bottom, target: nextTarget.padding.bottom,
      nonNegative: false)
    props.padding.trailing = stepScalar(
      .paddingTrailing, previous: prevTarget.padding.trailing, target: nextTarget.padding.trailing,
      nonNegative: false)
    props.spacing = stepScalar(
      .spacing, previous: prevTarget.spacing, target: nextTarget.spacing, nonNegative: false)

    if nodeMotions.isEmpty {
      motions.removeValue(forKey: id)
      return false
    }
    motions[id] = nodeMotions
    visitedMotions.insert(id)
    return true
  }
}
