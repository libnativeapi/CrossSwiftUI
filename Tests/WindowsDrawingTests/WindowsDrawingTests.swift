import CSwiftUIWindowsTestSupport
import CrossAppKit
import NativeAPI
@testable import CrossSwiftUI
import SwiftUIRuntime
import XCTest

final class WindowsDrawingTests: XCTestCase {
  func testTransparentNativeButtonKeepsShortcutWithoutCoveringCanvas() throws {
    final class Model: ObservableObject {
      @Published var opacity = 0.0
      var clicks = 0
    }
    struct Content: SwiftUIRuntime.View {
      @ObservedObject var model: Model
      var body: some SwiftUIRuntime.View {
        SwiftUIRuntime.Button("Shortcut") { model.clicks += 1 }
          .keyboardShortcut(.return, modifiers: .option)
          .opacity(model.opacity)
      }
    }
    WindowsDrawingBackend.prepareApplication()
    _ = NativeAPI.Application.shared.isRunning()
    let window = try XCTUnwrap(NativeAPI.Window.create())
    let backend = try XCTUnwrap(WindowsDrawingBackend(window: window))
    XCTAssertFalse(backend.needsRenderCommands)
    let model = Model()
    let renderer = Renderer(backend: backend, root: AnyView(Content(model: model)),
                            size: .init(width: 300, height: 200))
    renderer.mount()
    func buttonID(_ element: Element) -> NodeID? {
      if element.kind == .button { return element.id }
      return element.children.lazy.compactMap(buttonID).first
    }
    let id = try XCTUnwrap(buttonID(try XCTUnwrap(renderer.tree)))
    let button = try XCTUnwrap(backend.nativeButton(id))
    let handle = try XCTUnwrap(button.nativeObject)
    func opacity(_ element: Element) -> Double? {
      if element.id == id { return element.props.opacity }
      return element.children.lazy.compactMap(opacity).first
    }
    XCTAssertEqual(opacity(try XCTUnwrap(renderer.tree)), 0)
    XCTAssertEqual(control_visible(handle), 0)
    XCTAssertTrue(renderer.input(id: nil, event: 6, point: .zero, value: 13,
                                 modifiers: .option))
    XCTAssertEqual(model.clicks, 1)
    model.opacity = 1
    renderer.renderIfNeeded()
    XCTAssertEqual(control_visible(handle), 1)
    model.opacity = 0
    renderer.renderIfNeeded()
    XCTAssertEqual(control_visible(handle), 0)
    XCTAssertTrue(renderer.input(id: nil, event: 6, point: .zero, value: 13,
                                 modifiers: .option))
    XCTAssertEqual(model.clicks, 2)
  }
  func testSidebarCollapseAnimatesAndClipsNativeTextFieldWithoutHidingEarly() throws {
    struct SidebarHost: SwiftUIRuntime.View {
      @State private var open = true
      @State private var query = "Filter"
      var body: some SwiftUIRuntime.View {
        SwiftUIRuntime.HStack(spacing: 0) {
          SwiftUIRuntime.VStack(spacing: 0) {
            SwiftUIRuntime.TextField("Search", text: $query)
              .padding(8)
              .frame(width: 200, height: 32)
          }
          .frame(width: 220, height: 200)
          .frame(width: open ? 220 : 0, alignment: .leading)
          .clipped()
          .allowsHitTesting(open)

          SwiftUIRuntime.Button("Toggle") {
            SwiftUIRuntime.withAnimation(.timingCurve(0.2, 0, 0, 1, duration: 0.2)) {
              open.toggle()
            }
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
      }
    }
    WindowsDrawingBackend.prepareApplication()
    _ = NativeAPI.Application.shared.isRunning()
    let window = try XCTUnwrap(NativeAPI.Window.create())
    let backend = try XCTUnwrap(WindowsDrawingBackend(window: window))
    var now = 50.0
    let renderer = Renderer(
      backend: backend, root: AnyView(SidebarHost()), size: .init(width: 500, height: 200))
    renderer.clock = { now }
    renderer.mount()

    func findKind(_ kind: ElementKind, in node: Element) -> NodeID? {
      if node.kind == kind { return node.id }
      return node.children.lazy.compactMap { findKind(kind, in: $0) }.first
    }
    let tree = try XCTUnwrap(renderer.tree)
    let editID = try XCTUnwrap(findKind(.textField, in: tree))
    let buttonID = try XCTUnwrap(findKind(.button, in: tree))
    let field = try XCTUnwrap(backend.nativeTextField(editID))
    let editHandle = try XCTUnwrap(field.nativeObject)
    let fullClipWidth = control_clip_width(editHandle)
    XCTAssertEqual(control_visible(editHandle), 1)
    XCTAssertGreaterThan(fullClipWidth, 0)

    renderer.performTap(buttonID)
    XCTAssertTrue(renderer.hasActiveAnimations)
    // Even with `.allowsHitTesting(false)` during collapse, the native EDIT
    // stays visible and progressively clips against the shrinking sidebar edge.
    XCTAssertEqual(control_visible(editHandle), 1)
    XCTAssertFalse(field.isEnabled)

    now = 50.05
    XCTAssertTrue(renderer.stepAnimations())
    let midClipWidth = control_clip_width(editHandle)
    XCTAssertEqual(control_visible(editHandle), 1)
    XCTAssertGreaterThan(midClipWidth, 0)
    XCTAssertLessThan(midClipWidth, fullClipWidth)

    now = 50.25
    XCTAssertFalse(renderer.stepAnimations())
    XCTAssertEqual(control_visible(editHandle), 0)
    XCTAssertEqual(control_clip_width(editHandle), 0)
  }
  func testResizingMultilineEditorClearsPixelsExposedBySidebarCollapse() {
    WindowsDrawingBackend.prepareApplication()
    XCTAssertEqual(editor_resize_probe(), 0,
      "A moved multiline editor must erase its full native frame, including unused line space")
  }
  func testShadowMaskFalloffTintOpacityClippingAndRetainedLifetime() throws {
    WindowsDrawingBackend.prepareApplication()
    for scale in [1.0, 2.0] {
      let mask = try XCTUnwrap(ShadowMask(width: 200, height: 160, cornerRadius: 12,
                                         radius: 24, scale: scale))
      let errors = mask.alpha.withUnsafeBufferPointer {
        shadow_probe($0.baseAddress, Int32(mask.width), Int32(mask.height), mask.inset, mask.scale)
      }
      XCTAssertEqual(errors, 0)
    }
  }
  func testScrollPixelReuseMatchesFreshRenderingAndFallsBackForUnsafeFrames() {
    WindowsDrawingBackend.prepareApplication()
    let result = scroll_probe()
    XCTAssertGreaterThanOrEqual(result.copies, 4)
    XCTAssertEqual(result.pixel_errors, 0, "Cached scroll pixels must exactly match a fresh render")
    XCTAssertEqual(
      result.fallback_errors, 0,
      "Backgrounds, overlays, content edits and fractional pixels must fall back")
  }
  func testHighDpiPixelsAndHoverDoNotRepositionControls() {
    WindowsDrawingBackend.prepareApplication()
    let result = drawing_probe()
    print(
      "Windows drawing probe: \(result.dpi) DPI, \(result.hover_events) hover transitions, "
        + "boundary_errors=\(result.boundary_errors), ink_y=\(result.min_ink_y)...\(result.max_ink_y)")
    XCTAssertEqual(result.aware, 1, "Windows must use per-monitor V2 before creating HWNDs")
    XCTAssertGreaterThanOrEqual(result.dpi, 96)
    XCTAssertEqual(result.pixel_errors, 0, "The framebuffer must be copied at physical pixel size")
    XCTAssertEqual(
      result.child_pixel_errors, 0, "Owner-drawn controls must share the host's exact pixels")
    XCTAssertEqual(result.hover_events, 40)
    XCTAssertEqual(result.expose_errors, 0,
      "Full exposes must paint the canvas once and retain native-widget overlap paints")
    XCTAssertEqual(
      result.position_changes, 0, "Hover must not re-order or reset the region of a control")
    XCTAssertEqual(
      result.immediate_paints, 0, "Publishing a frame must not paint intermediate states")
    XCTAssertEqual(
      result.clip_errors, 0, "Clipping must recover when a control scrolls back into view")
    XCTAssertEqual(
      result.atomic_errors, 0, "A native paint during updates must see a complete frame")
    XCTAssertGreaterThan(result.damage_pixels, 0)
    XCTAssertLessThan(
      result.damage_pixels, result.surface_pixels / 2,
      "Hover should invalidate the button's ink, not the full window")
    XCTAssertEqual(
      result.scope_errors, 0, "Changing visible commands must repaint only their shared clip")
    XCTAssertEqual(
      result.group_errors, 0,
      "Nested scrolling must preserve pixels, native coordinates, activation and Tab order")
  }

  @MainActor
  func testNSPanelHostsSwiftUIViewWithObservableAndNSViewRepresentable() async throws {
    let state = PanelState()
    weak var reportedWindow: CrossAppKit.NSWindow?
    let panel = CrossAppKit.NSPanel(
      contentRect: NSRect(x: 100, y: 100, width: 400, height: 120),
      styleMask: [.borderless, .nonactivatingPanel],
      backing: .buffered,
      defer: false
    )
    panel.backgroundColor = .clear
    let hosting = NSHostingView(rootView: PanelContent(onWindow: { reportedWindow = $0 }).environment(state))
    hosting.sizingOptions = []
    panel.contentView = hosting

    let renderer = try XCTUnwrap(hosting.renderer)
    XCTAssertTrue(reportedWindow === panel)
    func hasText(_ expected: String, in node: Element) -> Bool {
      if node.kind == .text && node.props.text == expected { return true }
      return node.children.contains { hasText(expected, in: $0) }
    }
    XCTAssertTrue(hasText("Search apps", in: try XCTUnwrap(renderer.tree)))

    state.query = "Calculator: 42"
    renderer.renderIfNeeded()
    XCTAssertTrue(hasText("Calculator: 42", in: try XCTUnwrap(renderer.tree)))
    panel.close()
  }

  @MainActor
  func testSFSymbolCatalogAndStringLocalizedOnWindows() async {
    _ = NSHostingView(rootView: SwiftUIRuntime.EmptyView())
    let sampleSymbols = [
      "magnifyingglass", "gearshape", "sparkles", "apple.intelligence",
      "doc.on.clipboard", "macwindow", "puzzlepiece.extension", "stop.fill"
    ]
    for sym in sampleSymbols {
      XCTAssertNotNil(CrossAppKit.NSImage(systemSymbolName: sym, accessibilityDescription: nil), "Missing symbol \(sym)")
    }
    XCTAssertNil(CrossAppKit.NSImage(systemSymbolName: "CustomBrandAssetName", accessibilityDescription: nil))

    let msg = String(localized: "Found \(5) apps")
    XCTAssertEqual(msg, "Found 5 apps")
  }

  func testPDFVectorParserHandlesUncompressedAndFlateDecodePDFs() throws {
    let rawStream = "q 1 0 0 1 0 0 cm 2 4 m 18 4 l 18 16 l 2 16 l h f Q"
    let uncompressedPDF = """
    %PDF-1.4
    1 0 obj << /Type /Page /MediaBox [0 0 20 20] >> endobj
    2 0 obj << /Length \(rawStream.utf8.count) >>
    stream
    \(rawStream)
    endstream
    endobj
    %%EOF
    """
    let img = try XCTUnwrap(PDFVectorParser.parse(data: Data(uncompressedPDF.utf8)))
    XCTAssertEqual(img.bounds, CGRect(x: 0, y: 0, width: 20, height: 20))
    XCTAssertEqual(img.paths.count, 1)

    // Verify FlateDecode using a stored (uncompressed) zlib block wrapping the same content stream.
    let payload = Array(rawStream.utf8)
    var zlibBytes: [UInt8] = [0x78, 0x01] // zlib header (deflate, fastest)
    zlibBytes.append(0x01) // BFINAL=1, BTYPE=00 (stored block)
    let len = UInt16(payload.count)
    let nlen = ~len
    zlibBytes.append(UInt8(len & 0xFF))
    zlibBytes.append(UInt8((len >> 8) & 0xFF))
    zlibBytes.append(UInt8(nlen & 0xFF))
    zlibBytes.append(UInt8((nlen >> 8) & 0xFF))
    zlibBytes.append(contentsOf: payload)
    zlibBytes.append(contentsOf: [0, 0, 0, 0]) // placeholder adler32

    var compressedPDF = Data("%PDF-1.4\n1 0 obj << /Type /Page /MediaBox [0 0 20 20] >> endobj\n2 0 obj << /Filter /FlateDecode /Length \(zlibBytes.count) >>\nstream\n".utf8)
    compressedPDF.append(contentsOf: zlibBytes)
    compressedPDF.append(Data("\nendstream\nendobj\n%%EOF\n".utf8))

    let flateImg = try XCTUnwrap(PDFVectorParser.parse(data: compressedPDF))
    XCTAssertEqual(flateImg.bounds, CGRect(x: 0, y: 0, width: 20, height: 20))
    XCTAssertEqual(flateImg.paths.count, 1)

    // Verify VectorImage.load loads .pdf files from disk.
    let tmpPDF = FileManager.default.temporaryDirectory
      .appendingPathComponent("crossswift-vector-\(UUID().uuidString).pdf")
    try compressedPDF.write(to: tmpPDF)
    defer { try? FileManager.default.removeItem(at: tmpPDF) }

    let loaded = try XCTUnwrap(VectorImage.load(tmpPDF.path))
    XCTAssertEqual(loaded.bounds, CGRect(x: 0, y: 0, width: 20, height: 20))
    XCTAssertEqual(loaded.paths.count, 1)
  }
}

@Observable
private final class PanelState {
  var query = "Search apps"
}

private struct WindowProbe: NSViewRepresentable {
  let onWindow: (CrossAppKit.NSWindow?) -> Void
  func makeNSView(context: Context) -> CrossAppKit.NSView {
    CrossAppKit.NSView(frame: .zero)
  }
  func updateNSView(_ nsView: CrossAppKit.NSView, context: Context) {
    onWindow(nsView.window)
  }
}

private struct PanelContent: SwiftUIRuntime.View {
  @Environment(PanelState.self) var state
  let onWindow: (CrossAppKit.NSWindow?) -> Void
  var body: some SwiftUIRuntime.View {
    SwiftUIRuntime.VStack(spacing: 8) {
      SwiftUIRuntime.Text(state.query)
      WindowProbe(onWindow: onWindow)
        .frame(width: 10, height: 10)
    }
    .padding(12)
  }
}
