import Foundation
import Observation
import XCTest
@testable import SwiftUIRuntime

private enum SidebarTestTab: String, CaseIterable, Identifiable, Hashable {
  case general, about
  var id: Self { self }
}

@MainActor
@Observable
private final class SidebarTestNav {
  var tab: SidebarTestTab = .general
}

final class ControlsAndContainersTests: XCTestCase {
  @MainActor
  func testGroupedFormTogglePickerAndSectionRenderAndMutate() {
    struct FormDemo: View {
      @State var launchAtLogin = false
      @State var mode = "compact"

      var body: some View {
        Form {
          Section("General") {
            Toggle("Launch at login", isOn: $launchAtLogin)
            Picker("Window mode", selection: $mode) {
              Text(verbatim: "Compact").tag("compact")
              Text(verbatim: "Expanded").tag("expanded")
            }
            .pickerStyle(.segmented)
          }
        }
        .formStyle(.grouped)
      }
    }

    let backend = FakeBackend()
    let renderer = Renderer(backend: backend, root: AnyView(FormDemo()), size: Size(width: 600, height: 400))
    renderer.mount()

    let root = renderer.tree!
    XCTAssertNotNil(findNode(in: root, text: "General"))
    XCTAssertNotNil(findNode(in: root, text: "Launch at login"))
    XCTAssertNotNil(findNode(in: root, text: "Expanded"))
  }

  @MainActor
  func testSafeAreaInsetUpdatesScrollContentInsetsAndScrollGeometry() {
    var capturedInsetTop: Double = -1
    var capturedOffset: Double = 999

    struct PaletteLikeScroll: View {
      let onGeo: (ScrollGeometry) -> Void
      var body: some View {
        ScrollView {
          VStack(spacing: 8) {
            ForEach(0..<20) { idx in
              Text(verbatim: "Row \(idx)").frame(height: 36)
            }
          }
        }
        .onScrollGeometryChange(for: ScrollGeometry.self, of: { $0 }) { _, new in
          onGeo(new)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
          Rectangle().fill(.blue).frame(height: 56)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
          Rectangle().fill(.green).frame(height: 52)
        }
      }
    }

    let backend = FakeBackend()
    let renderer = Renderer(
      backend: backend,
      root: AnyView(PaletteLikeScroll { geo in
        capturedInsetTop = geo.contentInsets.top
        capturedOffset = Double(geo.contentOffset.y)
      }),
      size: Size(width: 750, height: 475)
    )
    renderer.mount()
    renderer.renderIfNeeded()

    XCTAssertEqual(capturedInsetTop, 56, accuracy: 0.5)
    XCTAssertEqual(capturedOffset, -56, accuracy: 0.5)
  }

  @MainActor
  func testLazyVStackVirtualizesLargeCollectionsInScrollView() {
    var evaluatedCount = 0
    struct CountingRow: View {
      let index: Int
      let onEval: () -> Void
      var body: some View {
        let _ = onEval()
        return Text(verbatim: "Item \(index)").frame(height: 40)
      }
    }

    struct BigList: View {
      let onEval: () -> Void
      var body: some View {
        ScrollView {
          LazyVStack(spacing: 0) {
            ForEach(0..<400) { i in
              CountingRow(index: i, onEval: onEval)
            }
          }
        }
      }
    }

    let backend = FakeBackend()
    let renderer = Renderer(
      backend: backend,
      root: AnyView(BigList { evaluatedCount += 1 }),
      size: Size(width: 400, height: 500)
    )
    renderer.mount()
    // Should evaluate only the visible/buffer slice rather than all 400 rows
    XCTAssertLessThan(evaluatedCount, 80)
  }

  func testXCStringsCatalogLoadsTranslationsAndPlurals() throws {
    let sampleJSON = """
    {
      "sourceLanguage" : "en",
      "strings" : {
        "Show Launcher" : {
          "localizations" : {
            "zh-Hans" : {
              "stringUnit" : { "state" : "translated", "value" : "显示启动器" }
            }
          }
        },
        "%@ (%lld items)" : {
          "localizations" : {
            "en" : {
              "variations" : {
                "plural" : {
                  "one" : { "stringUnit" : { "state" : "translated", "value" : "%@ (%lld item)" } },
                  "other" : { "stringUnit" : { "state" : "translated", "value" : "%@ (%lld items)" } }
                }
              }
            },
            "zh-Hans" : {
              "variations" : {
                "plural" : {
                  "other" : { "stringUnit" : { "state" : "translated", "value" : "%@（%lld 项）" } }
                }
              }
            }
          }
        }
      }
    }
    """
    let tempURL = FileManager.default.temporaryDirectory
      .appendingPathComponent("test-\(UUID().uuidString).xcstrings")
    try sampleJSON.data(using: .utf8)!.write(to: tempURL)
    defer { try? FileManager.default.removeItem(at: tempURL) }

    let catalog = XCStringsCatalog()
    XCTAssertTrue(catalog.load(from: tempURL))

    catalog.preferredLanguage = "zh-Hans"
    XCTAssertEqual(catalog.resolve(key: "Show Launcher"), "显示启动器")
    XCTAssertEqual(
      catalog.resolve(key: "%@ (%lld items)", arguments: [.string("Emoji"), .int(5)]),
      "Emoji（5 项）"
    )

    catalog.preferredLanguage = "en"
    XCTAssertEqual(
      catalog.resolve(key: "%@ (%lld items)", arguments: [.string("Emoji"), .int(1)]),
      "Emoji (1 item)"
    )
    XCTAssertEqual(
      catalog.resolve(key: "%@ (%lld items)", arguments: [.string("Emoji"), .int(3)]),
      "Emoji (3 items)"
    )
  }

  @MainActor
  func testSidebarListSelectionSwitchesObservableTab() {
    struct Sidebar: View {
      @Environment(SidebarTestNav.self) private var nav
      private var selection: Binding<SidebarTestTab?> {
        Binding(get: { nav.tab }, set: { if let t = $0 { nav.tab = t } })
      }
      var body: some View {
        List(selection: selection) {
          ForEach(["Section1"], id: \.self) { title in
            Section(title) {
              ForEach(SidebarTestTab.allCases) { tab in
                Label {
                  Text(tab.rawValue)
                } icon: {
                  Image(systemName: "gear")
                }
                .tag(tab)
              }
            }
          }
        }
        .listStyle(.sidebar)
        .labelStyle(.titleAndIcon)
      }
    }
    struct Root: View {
      @Environment(SidebarTestNav.self) private var nav
      var body: some View {
        NavigationSplitView {
          Sidebar()
        } detail: {
          Text("Detail: \(nav.tab.rawValue)")
        }
      }
    }

    let nav = SidebarTestNav()
    let backend = FakeBackend()
    let renderer = Renderer(
      backend: backend,
      root: AnyView(Root().environment(nav)),
      size: Size(width: 800, height: 600)
    )
    renderer.mount()

    func findButtons(_ el: Element) -> [Element] {
      var out: [Element] = []
      if el.kind == .styledButton || el.kind == .button { out.append(el) }
      for c in el.children { out.append(contentsOf: findButtons(c)) }
      return out
    }
    func findTexts(_ el: Element) -> [String] {
      var out: [String] = []
      if el.kind == .text { out.append(el.props.text) }
      for c in el.children { out.append(contentsOf: findTexts(c)) }
      return out
    }

    let buttons = findButtons(renderer.tree!)
    XCTAssertEqual(buttons.count, 2, "Expected 2 sidebar tab buttons, got \(buttons.count)")
    XCTAssertTrue(findTexts(renderer.tree!).contains("Detail: general"))

    backend.tap(buttons[1].id)
    renderer.renderIfNeeded()
    XCTAssertEqual(nav.tab, .about)
    XCTAssertTrue(findTexts(renderer.tree!).contains("Detail: about"))
  }
}
