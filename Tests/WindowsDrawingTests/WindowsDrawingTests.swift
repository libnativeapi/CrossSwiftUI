import CSwiftUIWindowsTestSupport
import NativeAPI
import SwiftUIPort
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
    print("Windows drawing probe: \(result.dpi) DPI, \(result.hover_events) hover transitions")
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
}
