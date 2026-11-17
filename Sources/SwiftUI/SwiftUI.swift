// The user-facing compatibility module.
//
// Unofficial; not affiliated with Apple.

@_exported import SwiftUIRuntime
#if os(WASI)
  @_exported import SwiftUIWeb
#elseif os(Android)
  @_exported import SwiftUIAndroid
#elseif !SWIFTUI_PORT_HARMONY
  @_exported import SwiftUIPort
#endif
