import CSwiftUIAndroid
import Foundation
import SwiftUIRuntime

private struct Control: Encodable {
  let id: Int
  let button: Bool
  let text: String
  let x, y, width, height: Double
  let fontSize: Double
  let fontFamily: String
  let fontWeight: Int
  let alignment: String
  let lineSpacing: Double
  let enabled: Bool
  let opacity: Double
  let foreground: UInt32?
  let accessibilityLabel: String
  let accessibilityHidden: Bool

  init(_ element: Element) {
    let props = element.props
    let font = props.font ?? .body
    id = element.id.rawValue
    button = element.kind == .button
    text = props.renderedText ?? props.text
    (x, y, width, height) = (element.frame.minX, element.frame.minY, element.frame.width, element.frame.height)
    (fontSize, fontFamily, fontWeight) = (font.size, font.family, Int(font.weight.value))
    switch props.textAlignment {
    case .leading: alignment = "leading"
    case .center: alignment = "center"
    case .trailing: alignment = "trailing"
    }
    lineSpacing = props.lineSpacing
    enabled = props.enabled && props.hitTesting
    opacity = props.opacity
    foreground = props.foreground.map { color in
      func byte(_ value: Double) -> UInt32 { UInt32((min(1, max(0, value)) * 255).rounded()) }
      return byte(color.opacity) << 24 | byte(color.red) << 16 | byte(color.green) << 8 | byte(color.blue)
    }
    accessibilityLabel = props.accessibilityLabel
    accessibilityHidden = props.accessibilityHidden
  }
}

private final class AndroidBackend: RenderBackend {
  var tapHandler: ((NodeID) -> Void)?
  let needsRenderCommands = false
  private(set) var controls: [Control] = []

  func perform(_ commands: [RenderCommand]) {}

  func didRender(_ root: Element) {
    controls.removeAll(keepingCapacity: true)
    collect(root)
  }

  private func collect(_ element: Element) {
    guard element.props.visible else { return }
    switch element.kind {
    case .text, .button:
      if !element.frame.size.isEmpty { controls.append(Control(element)) }
    case .fragment, .container, .padding, .frame, .grid, .zStack, .geometry, .customLayout:
      element.children.forEach(collect)
    case .layer, .presentation:
      if let base = element.children.first { collect(base) }
    default:
      break
    }
  }
}

private func javaString(_ value: String, in env: SwiftUIJNIEnvironment) -> jstring? {
  Array(value.utf16).withUnsafeBufferPointer {
    swiftui_android_string(env, $0.baseAddress, Int32($0.count))
  }
}

private final class TextMeasurer {
  struct Context {
    let env: SwiftUIJNIEnvironment
    let host: jobject
    let method: jmethodID
  }

  // JNIEnv and the host reference belong to the current JNI call.
  var context: Context?
  var method: jmethodID?

  func measure(_ text: String, font: Font) -> Size {
    guard let context else {
      return Size(width: Double(text.count) * 8, height: Double(font.size))
    }
    let env = context.env
    let packed = UInt64(bitPattern: swiftui_android_measure_text(
      env, context.host, context.method, javaString(text, in: env), Double(font.size),
      javaString(font.family, in: env), Int32(font.weight.value)))
    return Size(
      width: Double(Float(bitPattern: UInt32(packed >> 32))),
      height: Double(Float(bitPattern: UInt32(truncatingIfNeeded: packed))))
  }
}

/// Owns one Android Activity's renderer. SwiftUIComposeHost takes ownership
/// of the handle and releases it on the Android UI thread when closed.
@MainActor
public final class AndroidHost {
  private let renderer: Renderer
  private let backend: AndroidBackend
  private let textMeasurer: TextMeasurer

  private init(root: AnyView) {
    let backend = AndroidBackend()
    let textMeasurer = TextMeasurer()
    self.backend = backend
    self.textMeasurer = textMeasurer
    renderer = Renderer(
      backend: backend, root: root, size: .zero,
      layoutEngine: LayoutEngine(
        metrics: TextMetrics(buttonHorizontalPadding: 16, buttonVerticalPadding: 16),
        textMeasurer: textMeasurer.measure))
  }

  public static func retain(root: AnyView) -> Int64 {
    let host = Unmanaged.passRetained(AndroidHost(root: root)).toOpaque()
    return Int64(Int(bitPattern: host))
  }

  fileprivate static func fromHandle(_ handle: jlong) -> Unmanaged<AndroidHost> {
    Unmanaged.fromOpaque(UnsafeRawPointer(bitPattern: Int(handle))!)
  }

  fileprivate func update(
    env: SwiftUIJNIEnvironment, host: jobject, change: (Renderer) -> Void
  ) -> jstring? {
    if textMeasurer.method == nil {
      textMeasurer.method = swiftui_android_text_measurer(env, host)
    }
    guard let method = textMeasurer.method else { return nil }
    textMeasurer.context = TextMeasurer.Context(env: env, host: host, method: method)
    defer { textMeasurer.context = nil }
    change(renderer)
    guard let data = try? JSONEncoder().encode(backend.controls) else { return nil }
    return javaString(String(decoding: data, as: UTF8.self), in: env)
  }
}

// SwiftUIComposeHost calls these synchronously on the Android UI thread.
@MainActor @_cdecl("Java_dev_crossswiftui_android_SwiftUIComposeHost_nativeResize")
public func androidResize(
  _ env: SwiftUIJNIEnvironment, _ host: jobject, _ handle: jlong, _ width: jdouble, _ height: jdouble,
  _ invalidateMeasurements: jboolean
) -> jstring? {
  AndroidHost.fromHandle(handle).takeUnretainedValue().update(env: env, host: host) {
    $0.resize(to: Size(width: width, height: height), invalidateMeasurements: invalidateMeasurements != 0)
  }
}

@MainActor @_cdecl("Java_dev_crossswiftui_android_SwiftUIComposeHost_nativeTap")
public func androidTap(
  _ env: SwiftUIJNIEnvironment, _ host: jobject, _ handle: jlong, _ id: jlong
) -> jstring? {
  AndroidHost.fromHandle(handle).takeUnretainedValue().update(env: env, host: host) {
    $0.performTap(NodeID(rawValue: Int(id)))
  }
}

@MainActor @_cdecl("Java_dev_crossswiftui_android_SwiftUIComposeHost_nativeDestroy")
public func androidDestroy(_ env: SwiftUIJNIEnvironment, _ host: jobject, _ handle: jlong) {
  AndroidHost.fromHandle(handle).release()
}
