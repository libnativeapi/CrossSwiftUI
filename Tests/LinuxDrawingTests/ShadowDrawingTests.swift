import CGTK3
import Foundation
import XCTest

@testable import CrossSwiftUI
@testable import SwiftUIRuntime

final class ShadowDrawingTests: XCTestCase {
  func testShadowFalloffOpacityClippingAndDPI() throws {
    let drawing = LinuxDrawing()
    for scale in [1.0, 2.0] {
      let size = Int32(400 * scale)
      let surface = try XCTUnwrap(cairo_image_surface_create(CAIRO_FORMAT_ARGB32, size, size))
      defer { cairo_surface_destroy(surface) }
      cairo_surface_set_device_scale(surface, scale, scale)
      let context = try XCTUnwrap(cairo_create(surface))
      defer { cairo_destroy(context) }
      let stride = Int(cairo_image_surface_get_stride(surface))
      func red(_ x: Int, _ y: Int) -> Int {
        cairo_surface_flush(surface)
        let bytes = cairo_image_surface_get_data(surface)!
        return Int(bytes[Int(Double(y) * scale) * stride + Int(Double(x) * scale) * 4 + 2])
      }
      func render(opacity: Double, parentOpacity: Double = 1) {
        cairo_set_source_rgb(context, 1, 1, 1)
        cairo_paint(context)
        var props = NodeProps()
        props.background = .white
        props.cornerRadius = 12
        props.opacity = opacity
        props.clipped = true  // A view's own clip must not cut off its shadow.
        props.shadows = [Shadow(color: .black.opacity(0.4), radius: 24, x: 0, y: 8)]
        var dialog = Element(kind: .shape, props: props)
        dialog.frame = Rect(x: 100, y: 100, width: 200, height: 160)
        var parentProps = NodeProps()
        parentProps.opacity = parentOpacity
        var parent = Element(kind: .zStack, props: parentProps, children: [dialog])
        parent.frame = Rect(x: 0, y: 0, width: 400, height: 400)
        drawing.paint(
          parent, in: context, clip: parent.frame, damage: parent.frame,
          motions: [:], now: 0)
      }
      render(opacity: 1)
      let full = 255 - red(90, 180)
      XCTAssertGreaterThan(full, 20)
      XCTAssertGreaterThan(255 - red(76, 180), 8)  // Beyond the former 5.5pt extent.
      XCTAssertLessThanOrEqual(255 - red(26, 180), 1)
      var previous = 0
      for x in 26..<100 {
        let darkness = 255 - red(x, 180)
        XCTAssertGreaterThanOrEqual(darkness, previous)
        XCTAssertLessThanOrEqual(darkness - previous, 3)
        previous = darkness
      }
      if let path = ProcessInfo.processInfo.environment["SWIFTUI_SHADOW_PREVIEW"], scale == 1 {
        XCTAssertEqual(cairo_surface_write_to_png(surface, path), CAIRO_STATUS_SUCCESS)
      }
      render(opacity: 0.5)
      XCTAssertEqual(Double(255 - red(90, 180)), Double(full) / 2, accuracy: 2)
      render(opacity: 0.25, parentOpacity: 0.5)
      XCTAssertEqual(Double(255 - red(90, 180)), Double(full) / 4, accuracy: 2)
    }
  }
}
