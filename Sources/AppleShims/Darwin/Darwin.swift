@_exported import Foundation
#if os(Windows)
  import ucrt
#elseif canImport(Glibc)
  import Glibc
#endif

#if !os(macOS)
  public typealias uid_t = UInt32
  public typealias gid_t = UInt32
  public typealias pid_t = Int32
  public typealias mode_t = UInt16
  public typealias off_t = Int64

  public let F_SETNOSIGPIPE: Int32 = 73
  public let F_SETFD: Int32 = 2
  public let FD_CLOEXEC: Int32 = 1
  public let O_EVTONLY: Int32 = 0x8000
  public let O_RDONLY: Int32 = 0
  public let O_WRONLY: Int32 = 1
  public let O_RDWR: Int32 = 2
  public let O_CREAT: Int32 = 0x0100
  public let O_NONBLOCK: Int32 = 0x0004
  public let O_NOFOLLOW: Int32 = 0x0100
  public let O_CLOEXEC: Int32 = 0x1000000
  public let LOCK_EX: Int32 = 2
  public let LOCK_NB: Int32 = 4
  public let LOCK_UN: Int32 = 8
  public let SIGKILL: Int32 = 9
  public let SIGHUP: Int32 = 1
  public let WNOHANG: Int32 = 1
  public let TIOCSWINSZ: UInt = 0x80087467
  public let X_OK: Int32 = 1
  public let R_OK: Int32 = 4
  public let W_OK: Int32 = 2
  public let F_OK: Int32 = 0
  public let XATTR_NOFOLLOW: Int32 = 0x0001
  public let M_PI: Double = Double.pi
  public let M_E: Double = 2.71828182845904523536028747135266250

  public func getuid() -> uid_t { 0 }
  public func geteuid() -> uid_t { 0 }
  public func getgid() -> gid_t { 0 }
  public func getegid() -> gid_t { 0 }
  public func getgroups(_ count: Int32, _ list: UnsafeMutablePointer<gid_t>?) -> Int32 { 0 }
  public func mach_absolute_time() -> UInt64 { UInt64(ProcessInfo.processInfo.systemUptime * 1_000_000_000) }
  public func sysctlbyname(_ name: UnsafePointer<CChar>, _ oldp: UnsafeMutableRawPointer?, _ oldlenp: UnsafeMutablePointer<Int>?, _ newp: UnsafeMutableRawPointer?, _ newlen: Int) -> Int32 { -1 }

  public let FNM_CASEFOLD: Int32 = 0x10
  public func strcasecmp(_ s1: UnsafePointer<CChar>, _ s2: UnsafePointer<CChar>) -> Int32 {
    #if os(Windows)
      return _stricmp(s1, s2)
    #else
      return String(cString: s1).lowercased().compare(String(cString: s2).lowercased()).rawValue == 0 ? 0 : 1
    #endif
  }

  public func fnmatch(_ pattern: UnsafePointer<CChar>, _ string: UnsafePointer<CChar>, _ flags: Int32) -> Int32 {
    let caseFold = (flags & FNM_CASEFOLD) != 0
    let p = Array((caseFold ? String(cString: pattern).lowercased() : String(cString: pattern)).unicodeScalars)
    let s = Array((caseFold ? String(cString: string).lowercased() : String(cString: string)).unicodeScalars)
    var pi = 0, si = 0, starIdx = -1, matchIdx = 0
    while si < s.count {
      if pi < p.count && (p[pi] == "?" || p[pi] == s[si]) {
        pi += 1; si += 1
      } else if pi < p.count && p[pi] == "*" {
        starIdx = pi; matchIdx = si; pi += 1
      } else if starIdx != -1 {
        pi = starIdx + 1; matchIdx += 1; si = matchIdx
      } else {
        return 1
      }
    }
    while pi < p.count && p[pi] == "*" { pi += 1 }
    return pi == p.count ? 0 : 1
  }

  @discardableResult
  public func fcntl(_ fd: Int32, _ cmd: Int32, _ arg: Int32 = 0) -> Int32 { 0 }

  @discardableResult
  public func flock(_ fd: Int32, _ op: Int32) -> Int32 { 0 }

  @discardableResult
  public func kill(_ pid: pid_t, _ sig: Int32) -> Int32 { 0 }

  @discardableResult
  public func getxattr(_ path: UnsafePointer<CChar>?, _ name: UnsafePointer<CChar>?, _ value: UnsafeMutableRawPointer?, _ size: Int, _ position: UInt32, _ options: Int32) -> Int { -1 }

  @discardableResult
  public func removexattr(_ path: UnsafePointer<CChar>?, _ name: UnsafePointer<CChar>?, _ options: Int32) -> Int32 { -1 }

  public struct winsize: Sendable {
    public var ws_row: UInt16 = 24
    public var ws_col: UInt16 = 80
    public var ws_xpixel: UInt16 = 0
    public var ws_ypixel: UInt16 = 0
    public init(ws_row: UInt16 = 24, ws_col: UInt16 = 80, ws_xpixel: UInt16 = 0, ws_ypixel: UInt16 = 0) {
      self.ws_row = ws_row; self.ws_col = ws_col; self.ws_xpixel = ws_xpixel; self.ws_ypixel = ws_ypixel
    }
  }

  public func ioctl(_ fd: Int32, _ req: UInt, _ ptr: UnsafeMutableRawPointer?) -> Int32 { -1 }
  public func openpty(_ amaster: UnsafeMutablePointer<Int32>?, _ aslave: UnsafeMutablePointer<Int32>?, _ name: UnsafeMutablePointer<CChar>?, _ termp: UnsafeMutableRawPointer?, _ winp: UnsafeMutablePointer<winsize>?) -> Int32 { -1 }
  public func waitpid(_ pid: pid_t, _ status: UnsafeMutablePointer<Int32>?, _ options: Int32) -> pid_t { -1 }

  public func open(_ path: UnsafePointer<CChar>, _ oflag: Int32, _ mode: mode_t = 0) -> Int32 { -1 }
  @discardableResult
  public func close(_ fd: Int32) -> Int32 { 0 }

  // POSIX networking stubs for ExtensionNameResolver
  public typealias socklen_t = UInt32
  public let AF_UNSPEC: Int32 = 0
  public let AF_INET: Int32 = 2
  public let AF_INET6: Int32 = 23
  public let SOCK_STREAM: Int32 = 1
  public let NI_NUMERICHOST: Int32 = 2
  public let NI_MAXHOST: Int32 = 1025
  public struct sockaddr: Sendable { public init() {} }
  public struct addrinfo: @unchecked Sendable {
    public var ai_flags: Int32 = 0
    public var ai_family: Int32 = 0
    public var ai_socktype: Int32 = 0
    public var ai_protocol: Int32 = 0
    public var ai_addrlen: UInt32 = 0
    public var ai_canonname: UnsafeMutablePointer<CChar>? = nil
    public var ai_addr: UnsafeMutablePointer<sockaddr>? = nil
    public var ai_next: UnsafeMutablePointer<addrinfo>? = nil
    public init() {}
  }
  public func getaddrinfo(_ node: UnsafePointer<CChar>?, _ service: UnsafePointer<CChar>?, _ hints: UnsafePointer<addrinfo>?, _ res: UnsafeMutablePointer<UnsafeMutablePointer<addrinfo>?>?) -> Int32 { -1 }
  public func freeaddrinfo(_ res: UnsafeMutablePointer<addrinfo>?) {}
  public func getnameinfo(_ sa: UnsafePointer<sockaddr>?, _ salen: UInt32, _ host: UnsafeMutablePointer<CChar>?, _ hostlen: UInt32, _ serv: UnsafeMutablePointer<CChar>?, _ servlen: UInt32, _ flags: Int32) -> Int32 { -1 }
#endif
