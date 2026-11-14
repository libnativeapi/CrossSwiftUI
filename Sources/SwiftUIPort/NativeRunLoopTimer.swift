import Foundation

#if os(Windows)
  import WinSDK
#elseif os(Linux)
  import CGTK3
#endif

/// Runs on the platform UI loop, including native menu tracking loops.
/// Unlike a dispatch-main task, it can run while a synchronous popup is open.
@MainActor
public final class NativeRunLoopTimer {
  private let action: () -> Void
  #if os(Windows)
    private struct WeakTimer { weak var value: NativeRunLoopTimer? }
    private static var timers: [UINT_PTR: WeakTimer] = [:]
    private var identifier: UINT_PTR = 0
  #elseif os(Linux)
    private var identifier: UInt32 = 0
  #endif

  public init(milliseconds: UInt32, action: @escaping () -> Void) {
    self.action = action
    #if os(Windows)
      identifier = SetTimer(nil, 0, milliseconds) { _, _, identifier, _ in
        MainActor.assumeIsolated { NativeRunLoopTimer.timers[identifier]?.value?.action() }
      }
      Self.timers[identifier] = WeakTimer(value: self)
    #elseif os(Linux)
      identifier = g_timeout_add(
        milliseconds,
        { context in
          guard let context else { return 0 }
          MainActor.assumeIsolated {
            Unmanaged<NativeRunLoopTimer>.fromOpaque(context).takeUnretainedValue().action()
          }
          return 1
        }, Unmanaged.passUnretained(self).toOpaque())
    #endif
  }

  public func invalidate() {
    #if os(Windows)
      if identifier != 0 {
        KillTimer(nil, identifier)
        Self.timers.removeValue(forKey: identifier)
        identifier = 0
      }
    #elseif os(Linux)
      if identifier != 0 {
        g_source_remove(identifier)
        identifier = 0
      }
    #endif
  }

  deinit {
    #if os(Windows)
      if identifier != 0 { KillTimer(nil, identifier) }
    #elseif os(Linux)
      if identifier != 0 { g_source_remove(identifier) }
    #endif
  }
}
