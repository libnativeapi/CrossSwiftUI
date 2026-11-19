import Foundation

#if (os(macOS) || os(iOS) || os(tvOS) || os(watchOS) || os(visionOS)) && canImport(CoreGraphics)
  import CoreGraphics
#endif

/// Presents the first child that fits the proposed size along the chosen axes.
public struct ViewThatFits<Content: View>: View, _PrimitiveView {
  public typealias Body = Never
  let axes: Axis.Set
  let content: Content

  public init(in axes: Axis.Set = [.horizontal, .vertical], @ViewBuilder content: () -> Content) {
    self.axes = axes
    self.content = content()
  }

  public var body: Never { fatalError("ViewThatFits is primitive") }

  func _makeElement(path: ViewPath) -> Element {
    // An unselected candidate can have a fixed-size descendant. Clip at a
    // wrapper whose zero allocation cannot be overridden by that descendant.
    var clip = NodeProps()
    clip.clipped = true
    let children = flattenChildren(_render(content, path: path)).map {
      Element(kind: .frame, props: clip, children: [$0])
    }
    var element = Element(kind: .customLayout, children: children)
    element.layout = FittingLayout(axes: axes)
    return element
  }
}

private struct FittingLayout: _LayoutBridge {
  let axes: Axis.Set

  private func selection(
    _ proposal: ProposedViewSize, children: [Element], engine: LayoutEngine
  ) -> Int? {
    let ideal = ProposedViewSize(
      width: axes.contains(.horizontal) ? nil : proposal.width,
      height: axes.contains(.vertical) ? nil : proposal.height)
    return children.firstIndex { child in
      let size = engine.sizeThatFits(child, proposal: ideal)
      return (!axes.contains(.horizontal) || proposal.width.map { size.width <= $0 } != false)
        && (!axes.contains(.vertical) || proposal.height.map { size.height <= $0 } != false)
    } ?? children.indices.last
  }

  func measure(_ proposal: ProposedViewSize, children: [Element], engine: LayoutEngine) -> CGSize {
    guard let index = selection(proposal, children: children, engine: engine) else { return .zero }
    return engine.sizeThatFits(children[index], proposal: proposal)
  }

  func placements(_ bounds: CGRect, children: [Element], engine: LayoutEngine) -> [CGRect] {
    let proposal = ProposedViewSize(bounds.size)
    let index = selection(proposal, children: children, engine: engine)
    return children.indices.map { $0 == index ? bounds : .zero }
  }
}

public struct AnimationTimelineSchedule: Equatable {
  let interval: TimeInterval
  let paused: Bool

  public static func animation(
    minimumInterval: Double? = nil, paused: Bool = false
  ) -> Self {
    let requested = minimumInterval ?? 1.0 / 60
    let interval = requested.isFinite ? min(max(requested, 1.0 / 240), 86_400) : 1.0 / 60
    return Self(interval: interval, paused: paused)
  }

  public static func periodic(from startDate: Date, by interval: TimeInterval) -> Self {
    let clamped = interval.isFinite ? min(max(interval, 1.0 / 240), 86_400) : 1.0
    return Self(interval: clamped, paused: false)
  }

  public static var everyMinute: Self {
    Self(interval: 60, paused: false)
  }
}

public struct TimelineContext {
  public let date: Date
}

public struct TimelineView<Content: View>: View {
  public typealias Context = TimelineContext

  let schedule: AnimationTimelineSchedule
  let content: (Context) -> Content
  @State private var date = Date()

  public init(
    _ schedule: AnimationTimelineSchedule, @ViewBuilder content: @escaping (Context) -> Content
  ) {
    self.schedule = schedule
    self.content = content
  }

  public var body: some View {
    content(Context(date: date)).task(id: schedule) {
      guard !schedule.paused else { return }
      while !Task.isCancelled {
        do { try await Task.sleep(nanoseconds: UInt64(schedule.interval * 1_000_000_000)) } catch {
          return
        }
        guard !Task.isCancelled else { return }
        date = Date()
      }
    }
  }
}
