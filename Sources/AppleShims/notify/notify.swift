import Foundation

#if !os(macOS)
  public let NOTIFY_STATUS_OK: UInt32 = 0
  public let NOTIFY_TOKEN_INVALID: Int32 = -1
  public func notify_register_dispatch(
    _ name: UnsafePointer<CChar>,
    _ out_token: UnsafeMutablePointer<Int32>,
    _ queue: DispatchQueue,
    _ handler: @escaping @Sendable (Int32) -> Void
  ) -> UInt32 {
    out_token.pointee = 0
    return NOTIFY_STATUS_OK
  }
  @discardableResult
  public func notify_cancel(_ token: Int32) -> UInt32 { NOTIFY_STATUS_OK }
#endif
