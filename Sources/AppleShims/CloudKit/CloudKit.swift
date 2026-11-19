import Foundation

#if !os(macOS)
  public let CKErrorUserDidResetEncryptedDataKey = "CKErrorUserDidResetEncryptedDataKey"

  extension Notification.Name {
    public static let CKAccountChanged = Notification.Name("CKAccountChangedNotification")
  }

  public enum CKAccountStatus: Int, Sendable {
    case couldNotDetermine = 0
    case available = 1
    case restricted = 2
    case noAccount = 3
    case temporarilyUnavailable = 4
  }

  public struct CKError: Error, @unchecked Sendable {
    public enum Code: Int, Sendable {
      case internalError = 1
      case partialFailure = 2
      case networkUnavailable = 3
      case networkFailure = 4
      case badContainer = 5
      case serviceUnavailable = 6
      case requestRateLimited = 7
      case missingEntitlement = 8
      case notAuthenticated = 9
      case permissionFailure = 10
      case unknownItem = 11
      case invalidArguments = 12
      case serverRecordChanged = 14
      case serverResponseLost = 20
      case changeTokenExpired = 21
      case zoneBusy = 23
      case quotaExceeded = 25
      case zoneNotFound = 26
      case managedAccountRestricted = 32
      case accountTemporarilyUnavailable = 36
    }
    public let code: Code
    public let userInfo: [String: Any]
    public init(_ code: Code, userInfo: [String: Any] = [:]) {
      self.code = code
      self.userInfo = userInfo
    }
    public var retryAfterSeconds: Double? { nil }
    public var serverRecord: CKRecord? { nil }
  }

  open class CKRecordZone: NSObject, @unchecked Sendable {
    public final class ID: NSObject, @unchecked Sendable {
      public let zoneName: String
      public let ownerName: String
      public init(zoneName: String, ownerName: String = "__defaultOwner__") {
        self.zoneName = zoneName
        self.ownerName = ownerName
      }
      public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ID else { return false }
        return zoneName == other.zoneName && ownerName == other.ownerName
      }
      public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(zoneName)
        hasher.combine(ownerName)
        return hasher.finalize()
      }
    }
    public let zoneID: ID
    public init(zoneID: ID) { self.zoneID = zoneID }
    public init(zoneName: String) { self.zoneID = ID(zoneName: zoneName) }
  }

  open class CKRecord: NSObject, @unchecked Sendable {
    public typealias RecordType = String
    public typealias FieldKey = String
    public final class ID: NSObject, @unchecked Sendable {
      public let recordName: String
      public let zoneID: CKRecordZone.ID
      public init(recordName: String, zoneID: CKRecordZone.ID = CKRecordZone.ID(zoneName: "_defaultZone")) {
        self.recordName = recordName
        self.zoneID = zoneID
      }
      public override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? ID else { return false }
        return recordName == other.recordName && zoneID == other.zoneID
      }
      public override var hash: Int {
        var hasher = Hasher()
        hasher.combine(recordName)
        hasher.combine(zoneID)
        return hasher.finalize()
      }
    }

    public final class EncryptedValues: @unchecked Sendable {
      private var storage: [String: Any] = [:]
      public init() {}
      public subscript(key: FieldKey) -> Any? {
        get { storage[key] }
        set { storage[key] = newValue }
      }
    }

    public let recordType: RecordType
    public let recordID: ID
    public var modificationDate: Date?
    public var creationDate: Date?
    public var recordChangeTag: String?
    public let encryptedValues = EncryptedValues()
    private var fields: [String: Any] = [:]

    public init(recordType: RecordType, recordID: ID = ID(recordName: UUID().uuidString)) {
      self.recordType = recordType
      self.recordID = recordID
    }
    public required init?(coder: NSCoder) {
      self.recordType = ""
      self.recordID = ID(recordName: "")
      return nil
    }
    public func encodeSystemFields(with coder: NSCoder) {}
    public subscript(key: FieldKey) -> Any? {
      get { fields[key] }
      set { fields[key] = newValue }
    }
    public func allKeys() -> [FieldKey] { Array(fields.keys) }
  }

  open class CKServerChangeToken: NSObject, @unchecked Sendable {}
  open class CKAsset: NSObject, @unchecked Sendable {
    public let fileURL: URL?
    public init(fileURL: URL) { self.fileURL = fileURL }
  }

  open class CKDatabase: NSObject, @unchecked Sendable {
    public func save(_ zone: CKRecordZone) async throws -> CKRecordZone { throw CKError(.notAuthenticated) }
    public func record(for recordID: CKRecord.ID) async throws -> CKRecord { throw CKError(.notAuthenticated) }
    public func save(_ record: CKRecord) async throws -> CKRecord { throw CKError(.notAuthenticated) }
    public func deleteRecord(withID recordID: CKRecord.ID) async throws -> CKRecord.ID { throw CKError(.notAuthenticated) }
  }

  open class CKContainer: NSObject, @unchecked Sendable {
    public let containerIdentifier: String?
    public lazy var privateCloudDatabase = CKDatabase()
    public init(identifier: String) { self.containerIdentifier = identifier }
    public static func `default`() -> CKContainer { CKContainer(identifier: "default") }
    public func accountStatus() async throws -> CKAccountStatus { .noAccount }
  }

  public protocol CKSyncEngineDelegate: AnyObject, Sendable {
    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async
    func nextRecordZoneChangeBatch(
      _ context: CKSyncEngine.SendChangesContext,
      syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch?
  }

  public final class CKSyncEngine: @unchecked Sendable {
    public struct Configuration: @unchecked Sendable {
      public var database: CKDatabase
      public var stateSerialization: State.Serialization?
      public weak var delegate: (any CKSyncEngineDelegate)?
      public var automaticallySync: Bool = true
      public init(
        database: CKDatabase,
        stateSerialization: State.Serialization?,
        delegate: any CKSyncEngineDelegate
      ) {
        self.database = database
        self.stateSerialization = stateSerialization
        self.delegate = delegate
      }
    }

    public enum PendingDatabaseChange: Hashable, Sendable {
      case saveZone(CKRecordZone)
      case deleteZone(CKRecordZone.ID)
    }

    public enum PendingRecordZoneChange: Hashable, Sendable {
      case saveRecord(CKRecord.ID)
      case deleteRecord(CKRecord.ID)
    }

    public final class State: @unchecked Sendable {
      public struct Serialization: Codable, Sendable {
        public init() {}
      }
      public private(set) var pendingDatabaseChanges: [PendingDatabaseChange] = []
      public private(set) var pendingRecordZoneChanges: [PendingRecordZoneChange] = []
      public init() {}
      public func add(pendingDatabaseChanges changes: [PendingDatabaseChange]) {
        pendingDatabaseChanges.append(contentsOf: changes)
      }
      public func remove(pendingDatabaseChanges changes: [PendingDatabaseChange]) {
        let set = Set(changes)
        pendingDatabaseChanges.removeAll { set.contains($0) }
      }
      public func add(pendingRecordZoneChanges changes: [PendingRecordZoneChange]) {
        pendingRecordZoneChanges.append(contentsOf: changes)
      }
      public func remove(pendingRecordZoneChanges changes: [PendingRecordZoneChange]) {
        let set = Set(changes)
        pendingRecordZoneChanges.removeAll { set.contains($0) }
      }
    }

    public struct SendChangesOptions: Sendable {
      public struct Scope: Sendable {
        public init() {}
        public func contains(_ change: PendingRecordZoneChange) -> Bool { true }
      }
      public var scope: Scope = Scope()
      public init(scope: Scope = Scope()) { self.scope = scope }
    }

    public struct SendChangesContext: Sendable {
      public var options: SendChangesOptions = SendChangesOptions()
      public init(options: SendChangesOptions = SendChangesOptions()) { self.options = options }
    }

    public struct RecordZoneChangeBatch: @unchecked Sendable {
      public var recordsToSave: [CKRecord]
      public var recordIDsToDelete: [CKRecord.ID]
      public init(recordsToSave: [CKRecord] = [], recordIDsToDelete: [CKRecord.ID] = []) {
        self.recordsToSave = recordsToSave
        self.recordIDsToDelete = recordIDsToDelete
      }
      public init?(
        pendingChanges: [PendingRecordZoneChange],
        recordProvider: @Sendable (CKRecord.ID) async -> CKRecord?
      ) async {
        var saves: [CKRecord] = []
        var deletes: [CKRecord.ID] = []
        for change in pendingChanges {
          switch change {
          case .saveRecord(let id):
            if let record = await recordProvider(id) { saves.append(record) }
          case .deleteRecord(let id):
            deletes.append(id)
          }
        }
        if saves.isEmpty && deletes.isEmpty { return nil }
        self.recordsToSave = saves
        self.recordIDsToDelete = deletes
      }
    }

    public enum Event: @unchecked Sendable {
      public struct StateUpdate: Sendable {
        public let stateSerialization: State.Serialization
        public init(stateSerialization: State.Serialization = .init()) {
          self.stateSerialization = stateSerialization
        }
      }
      public struct AccountChange: Sendable {
        public enum ChangeType: Sendable {
          case signIn(currentUser: CKRecord.ID)
          case signOut(previousUser: CKRecord.ID)
          case switchAccounts(previousUser: CKRecord.ID, currentUser: CKRecord.ID)
        }
        public let changeType: ChangeType
      }
      public struct FetchedDatabaseChanges: @unchecked Sendable {
        public struct Deletion: @unchecked Sendable {
          public enum Reason: Int, Sendable {
            case deleted = 0
            case purged = 1
            case encryptedDataReset = 2
          }
          public let zoneID: CKRecordZone.ID
          public let reason: Reason
        }
        public let modifications: [CKRecordZone]
        public let deletions: [Deletion]
      }
      public struct FetchedRecordZoneChanges: @unchecked Sendable {
        public struct Modification: @unchecked Sendable {
          public let record: CKRecord
        }
        public struct Deletion: @unchecked Sendable {
          public let recordID: CKRecord.ID
        }
        public let modifications: [Modification]
        public let deletions: [Deletion]
      }
      public struct SentRecordZoneChanges: @unchecked Sendable {
        public struct FailedRecordSave: @unchecked Sendable {
          public let record: CKRecord
          public let error: CKError
        }
        public let savedRecords: [CKRecord]
        public let failedRecordSaves: [FailedRecordSave]
        public let deletedRecordIDs: [CKRecord.ID]
        public let failedRecordDeletes: [CKRecord.ID: CKError]
      }
      public struct SentDatabaseChanges: @unchecked Sendable {
        public struct FailedZoneSave: @unchecked Sendable {
          public let zone: CKRecordZone
          public let error: CKError
        }
        public let savedZones: [CKRecordZone]
        public let failedZoneSaves: [FailedZoneSave]
        public let deletedZoneIDs: [CKRecordZone.ID]
      }
      public struct WillFetchChanges: Sendable {}
      public struct DidFetchChanges: Sendable {}
      public struct WillSendChanges: Sendable {}
      public struct DidSendChanges: Sendable {}

      case stateUpdate(StateUpdate)
      case accountChange(AccountChange)
      case fetchedDatabaseChanges(FetchedDatabaseChanges)
      case fetchedRecordZoneChanges(FetchedRecordZoneChanges)
      case sentRecordZoneChanges(SentRecordZoneChanges)
      case sentDatabaseChanges(SentDatabaseChanges)
      case willFetchChanges(WillFetchChanges)
      case didFetchChanges(DidFetchChanges)
      case willSendChanges(WillSendChanges)
      case didSendChanges(DidSendChanges)
    }

    public let database: CKDatabase
    public let state = State()

    public init(_ configuration: Configuration) {
      self.database = configuration.database
    }

    public func fetchChanges() async throws {
      throw CKError(.notAuthenticated)
    }

    public func sendChanges() async throws {
      throw CKError(.notAuthenticated)
    }

    public func cancelOperations() async {}
  }
#endif
