import Foundation
import CoreGraphics

#if !os(macOS)
  public enum EKEntityType: UInt, Sendable {
    case event = 0
    case reminder = 1
  }

  public enum EKAuthorizationStatus: Int, Sendable {
    case notDetermined = 0
    case restricted = 1
    case denied = 2
    case fullAccess = 3
    case writeOnly = 4
  }

  public enum EKSpan: Int, Sendable {
    case thisEvent = 0
    case futureEvents = 1
  }

  public enum EKEventAvailability: Int, Sendable {
    case notSupported = -1
    case busy = 0
    case free = 1
    case tentative = 2
    case unavailable = 3
  }

  public enum EKParticipantStatus: Int, Sendable {
    case unknown = 0
    case pending = 1
    case accepted = 2
    case declined = 3
    case tentative = 4
    case delegated = 5
    case completed = 6
    case inProcess = 7
  }

  open class EKSource: NSObject, @unchecked Sendable {
    public var title: String = ""
    public var sourceIdentifier: String = ""
  }

  open class EKCalendar: NSObject, @unchecked Sendable {
    public var calendarIdentifier: String = ""
    public var title: String = ""
    public var allowsContentModifications: Bool = false
    public var isImmutable: Bool = true
    public var cgColor: CGColor! = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
    public var source: EKSource! = EKSource()
  }

  open class EKParticipant: NSObject, @unchecked Sendable {
    public var name: String?
    public var url: URL = URL(fileURLWithPath: "/")
    public var participantStatus: EKParticipantStatus = .unknown
    public var isCurrentUser: Bool = false
  }

  open class EKAlarm: NSObject, @unchecked Sendable {
    public var relativeOffset: TimeInterval = 0
    public init(relativeOffset offset: TimeInterval) { self.relativeOffset = offset }
  }

  public enum EKEventStatus: Int, Sendable {
    case none = 0
    case confirmed = 1
    case tentative = 2
    case canceled = 3
  }

  open class EKEvent: NSObject, @unchecked Sendable {
    public var eventIdentifier: String! = UUID().uuidString
    public var calendarItemIdentifier: String = UUID().uuidString
    public var title: String! = ""
    public var startDate: Date! = Date()
    public var endDate: Date! = Date()
    public var occurrenceDate: Date! { startDate }
    public var status: EKEventStatus = .none
    public var isAllDay: Bool = false
    public var location: String?
    public var notes: String?
    public var url: URL?
    public var calendar: EKCalendar! = EKCalendar()
    public var availability: EKEventAvailability = .busy
    public var attendees: [EKParticipant]?
    public var organizer: EKParticipant?
    public var hasRecurrenceRules: Bool = false
    public var alarms: [EKAlarm]?
    public init(eventStore: EKEventStore) { super.init() }
    public func addAlarm(_ alarm: EKAlarm) {
      if alarms == nil { alarms = [] }
      alarms?.append(alarm)
    }
  }

  open class EKEventStore: NSObject, @unchecked Sendable {
    public static func authorizationStatus(for entityType: EKEntityType) -> EKAuthorizationStatus { .denied }
    public func requestFullAccessToEvents() async throws -> Bool { false }
    public func calendars(for entityType: EKEntityType) -> [EKCalendar] { [] }
    public func calendar(withIdentifier identifier: String) -> EKCalendar? { nil }
    public var defaultCalendarForNewEvents: EKCalendar? { nil }
    public func predicateForEvents(withStart startDate: Date, end endDate: Date, calendars: [EKCalendar]?) -> NSPredicate {
      NSPredicate(value: false)
    }
    public func events(matching predicate: NSPredicate) -> [EKEvent] { [] }
    public func event(withIdentifier identifier: String) -> EKEvent? { nil }
    public func save(_ event: EKEvent, span: EKSpan, commit: Bool = true) throws {}
    public func remove(_ event: EKEvent, span: EKSpan, commit: Bool = true) throws {}
    public func commit() throws {}
  }

  public let EKEventStoreChangedNotification = Notification.Name("EKEventStoreChangedNotification")

  extension Notification.Name {
    public static let EKEventStoreChanged = EKEventStoreChangedNotification
  }
#endif
