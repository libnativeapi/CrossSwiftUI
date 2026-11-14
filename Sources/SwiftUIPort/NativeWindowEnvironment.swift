import NativeAPI
import SwiftUIRuntime

private struct NativeWindowKey: EnvironmentKey {
  static let defaultValue: NativeAPI.Window? = nil
}

extension EnvironmentValues {
  /// The window whose content coordinates are returned by GeometryProxy.global.
  /// Supplied by the backend, including when a Renderer is embedded manually.
  public var nativeWindow: NativeAPI.Window? {
    get { self[NativeWindowKey.self] }
    set { self[NativeWindowKey.self] = newValue }
  }

  static func hosting(_ window: NativeAPI.Window) -> EnvironmentValues {
    var values = EnvironmentValues()
    values.nativeWindow = window
    return values
  }
}
