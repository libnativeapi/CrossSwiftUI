import XCTest

@testable import SwiftUIRuntime

private struct HostKey: EnvironmentKey { static let defaultValue = "none" }
extension EnvironmentValues {
  fileprivate var hostName: String {
    get { self[HostKey.self] }
    set { self[HostKey.self] = newValue }
  }
}
private final class HostBackend: RenderBackend {
  var tapHandler: ((NodeID) -> Void)?
  var environment: EnvironmentValues {
    var result = EnvironmentValues()
    result.hostName = "window"
    return result
  }
  func perform(_ commands: [RenderCommand]) {}
}
private struct HostProbe: View {
  @Environment(\.hostName) var name
  var body: some View { Text(name) }
}

final class NativePresentationTests: XCTestCase {
  override func setUp() { StateRegistry.shared.reset() }

  func testBackendEnvironmentReachesGeometryAndCanBeOverridden() {
    let renderer = Renderer(
      backend: HostBackend(),
      root: AnyView(
        VStack {
          HostProbe()
          HostProbe().environment(\.hostName, "nested")
          GeometryReader { _ in HostProbe() }
        }), size: Size(width: 300, height: 200))
    renderer.mount()
    func texts(_ node: Element) -> [String] {
      (node.kind == .text ? [node.props.text] : []) + node.children.flatMap(texts)
    }
    XCTAssertEqual(texts(renderer.tree!), ["window", "nested", "window"])
    XCTAssertEqual(EnvironmentValues.current.hostName, "none")
  }

  func testSecondaryClickUsesLocalCoordinatesAndPreservesPrimaryAction() throws {
    var secondary: CGPoint?
    var primary = 0
    let renderer = Renderer(
      backend: FakeBackend(),
      root: AnyView(
        Button("Anchor") { primary += 1 }
          .frame(width: 100, height: 40)
          .onSecondaryClick { secondary = $0 }
          .padding(20)
      ), size: Size(width: 200, height: 100))
    renderer.mount()
    func find(_ node: Element) -> Element? {
      if node.secondaryAction != nil { return node }
      return node.children.compactMap(find).first
    }
    let anchor = try XCTUnwrap(find(renderer.tree!))
    _ = renderer.input(
      id: nil, event: 9,
      point: CGPoint(x: anchor.frame.minX + 7, y: anchor.frame.minY + 9))
    XCTAssertEqual(secondary, CGPoint(x: 7, y: 9))
    XCTAssertEqual(primary, 0)
    func button(_ node: Element) -> Element? {
      if node.action != nil { return node }
      return node.children.compactMap(button).first
    }
    renderer.performTap(try XCTUnwrap(button(renderer.tree!)).id)
    XCTAssertEqual(primary, 1)
  }
}
