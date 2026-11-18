import CGTK3
import Foundation
import NativeAPI
import XCTest

@testable import CrossSwiftUI
@testable import SwiftUIRuntime

final class EditorPlaceholderTests: XCTestCase {
  func testMultilinePlaceholderFollowsTextAndAllowsPointerInput() throws {
    guard gtk_init_check(nil, nil) != 0 else { throw XCTSkip("Requires a GTK display (use Xvfb)") }
    _ = NativeAPI.Application.shared.isRunning()
    let window = try XCTUnwrap(NativeAPI.Window.create())
    let backend = try XCTUnwrap(LinuxDrawingBackend(window: window))
    final class Model: SwiftUIRuntime.ObservableObject { @SwiftUIRuntime.Published var text = "" }
    struct Content: SwiftUIRuntime.View {
      @ObservedObject var model: Model
      var body: some SwiftUIRuntime.View {
        TextField("Write something", text: $model.text, axis: .vertical)
          .font(.system(size: 22)).frame(width: 300, height: 120)
      }
    }
    let model = Model()
    let renderer = Renderer(
      backend: backend, root: AnyView(Content(model: model)),
      size: .init(width: 300, height: 120))
    renderer.mount()
    let native = try XCTUnwrap(window.contentView?.nativeObject)
    func descendants(_ widget: UnsafeMutablePointer<GtkWidget>) -> [UnsafeMutablePointer<GtkWidget>]
    {
      guard
        g_type_check_instance_is_a(
          UnsafeMutableRawPointer(widget).assumingMemoryBound(to: GTypeInstance.self),
          gtk_container_get_type()) != 0
      else { return [widget] }
      let list = gtk_container_get_children(
        UnsafeMutableRawPointer(widget).assumingMemoryBound(to: GtkContainer.self))
      defer { g_list_free(list) }
      var result = [widget]
      var item = list
      while let entry = item {
        if let data = entry.pointee.data {
          result += descendants(data.assumingMemoryBound(to: GtkWidget.self))
        }
        item = entry.pointee.next
      }
      return result
    }
    let widgets = descendants(native.assumingMemoryBound(to: GtkWidget.self))
    let placeholder = try XCTUnwrap(
      widgets.first {
        g_type_check_instance_is_a(
          UnsafeMutableRawPointer($0).assumingMemoryBound(to: GTypeInstance.self),
          gtk_label_get_type()) != 0
      })
    let label = UnsafeMutableRawPointer(placeholder).assumingMemoryBound(to: GtkLabel.self)
    XCTAssertEqual(String(cString: gtk_label_get_text(label)), "Write something")
    XCTAssertNotEqual(gtk_widget_get_visible(placeholder), 0)
    let parent = try XCTUnwrap(gtk_widget_get_parent(placeholder))
    XCTAssertNotEqual(
      gtk_overlay_get_overlay_pass_through(
        UnsafeMutableRawPointer(parent).assumingMemoryBound(to: GtkOverlay.self), placeholder), 0)
    model.text = "Typed"
    renderer.renderIfNeeded()
    XCTAssertEqual(gtk_widget_get_visible(placeholder), 0)
    model.text = ""
    renderer.renderIfNeeded()
    XCTAssertNotEqual(gtk_widget_get_visible(placeholder), 0)
  }
}
