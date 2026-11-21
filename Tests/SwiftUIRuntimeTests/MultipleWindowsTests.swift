@testable import SwiftUIRuntime
import XCTest

private final class SharedWindowModel: SwiftUIRuntime.ObservableObject {
  @SwiftUIRuntime.Published var value = 0
}

private struct WindowCounter: View {
  @State private var count = 0
  @ObservedObject var model: SharedWindowModel
  let appear: () -> Void
  let disappear: () -> Void

  var body: some View {
    VStack {
      Text("Local: \(count), shared: \(model.value)")
      Button("Increment") { count += 1 }
    }
    .onAppear(perform: appear)
    .onDisappear(perform: disappear)
  }
}

final class MultipleWindowsTests: XCTestCase {
  override func setUp() { StateRegistry.shared.reset() }

  func testWindowsKeepIndependentStateAndLifecyclesWhileSharingModels() {
    let model = SharedWindowModel()
    var appearances = 0
    var disappearances = 0
    let makeView = {
      AnyView(WindowCounter(model: model, appear: { appearances += 1 }, disappear: { disappearances += 1 }))
    }
    let firstBackend = FakeBackend()
    let first = Renderer(backend: firstBackend, root: makeView(), size: Size(width: 320, height: 200))
    first.mount()
    firstBackend.tap(findNode(in: first.tree!, kind: .button)!.id)
    let secondBackend = FakeBackend()
    var second: Renderer? = Renderer(backend: secondBackend, root: makeView(), size: Size(width: 320, height: 200))
    second!.mount()
    secondBackend.tap(findNode(in: second!.tree!, kind: .button)!.id)
    secondBackend.tap(findNode(in: second!.tree!, kind: .button)!.id)
    model.value = 7
    XCTAssertNotNil(findNode(in: first.tree!, text: "Local: 1, shared: 7"))
    XCTAssertNotNil(findNode(in: second!.tree!, text: "Local: 2, shared: 7"))
    first.resize(to: Size(width: 420, height: 300))
    XCTAssertEqual(appearances, 2)
    XCTAssertEqual(disappearances, 0)
    weak let released = second
    second = nil
    XCTAssertNil(released)
    model.value = 9
    firstBackend.tap(findNode(in: first.tree!, kind: .button)!.id)
    XCTAssertNotNil(findNode(in: first.tree!, text: "Local: 2, shared: 9"))
    XCTAssertEqual(appearances, 2)
  }

  @MainActor
  func testObservableEnvironmentAndBindableTrackingAcrossRenderers() async {
    let store = ModernObservableStore()
    let b1 = FakeBackend()
    let r1 = Renderer(
      backend: b1,
      root: AnyView(ObservableReaderView().environment(store)),
      size: Size(width: 320, height: 200)
    )
    r1.mount()
    XCTAssertNotNil(findNode(in: r1.tree!, text: "Query: hello (0)"))

    // Mutate via @Bindable button action inside transaction
    b1.tap(findNode(in: r1.tree!, kind: .button)!.id)
    XCTAssertNotNil(findNode(in: r1.tree!, text: "Query: hello! (1)"))

    // Mutate outside transaction and flush
    store.query = "tinycast"
    r1.renderIfNeeded()
    XCTAssertNotNil(findNode(in: r1.tree!, text: "Query: tinycast (1)"))
  }
}

@Observable
private final class ModernObservableStore {
  var query = "hello"
  var count = 0
}

private struct ObservableReaderView: View {
  @Environment(ModernObservableStore.self) private var store

  var body: some View {
    @Bindable var bindable = store
    VStack {
      Text("Query: \(store.query) (\(store.count))")
      Button("Mutate") {
        $bindable.query.wrappedValue += "!"
        store.count += 1
      }
    }
  }
}
