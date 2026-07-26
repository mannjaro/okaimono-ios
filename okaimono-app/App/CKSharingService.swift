import CoreData
import CloudKit
import OSLog

nonisolated final class CKSharingService: @unchecked Sendable {
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "okaimono-app",
        category: "CloudKitSharing"
    )

    private let container: NSPersistentCloudKitContainer
    private let privatePersistentStore: NSPersistentStore?
    private let sharedPersistentStore: NSPersistentStore?
    private let cloudKitContainer: CKContainer

    @MainActor
    init(persistence: PersistenceController) {
        container = persistence.container
        privatePersistentStore = persistence.privatePersistentStore
        sharedPersistentStore = persistence.sharedPersistentStore
        cloudKitContainer = CKContainer(identifier: CloudKitConfiguration.containerIdentifier)
    }
    
    enum SharingError: Error, Equatable {
        case notSavedObject
        case reSharingNotAllowed
        case missingShareResult
    }
    
    enum SharingStatus {
        case notShared
        case owner(share: CKShare, container: CKContainer)
        case participant(share: CKShare, container: CKContainer)
    }
    
    /// リストの共有を作る、もしくは既にあればそれを返す
    func fetchOrCreateShare(
        for objectID: NSManagedObjectID,
        title: String
    ) async throws -> (share: CKShare, container: CKContainer) {
        guard !objectID.isTemporaryID else {
            throw SharingError.notSavedObject
        }
        guard objectID.persistentStore != sharedPersistentStore else {
            throw SharingError.reSharingNotAllowed
        }

        if let share = try container.fetchShares(matching: [objectID])[objectID] {
            return (share, cloudKitContainer)
        }

        let share = try await createShare(for: objectID)
        share[CKShare.SystemFieldKey.title] = title

        if let privatePersistentStore {
            do {
                _ = try await container.persistUpdatedShare(share, in: privatePersistentStore)
            } catch {
                // タイトルが保存できなくても共有自体は成立しているので続行する。
                Self.logger.error("共有タイトルの保存に失敗しました: \(error.localizedDescription, privacy: .public)")
            }
        }

        return (share, cloudKitContainer)
    }

    private func createShare(for objectID: NSManagedObjectID) async throws -> CKShare {
        try await withCheckedThrowingContinuation { continuation in
            container.performBackgroundTask { context in
                do {
                    guard let list = try context.existingObject(with: objectID) as? ShoppingList else {
                        continuation.resume(throwing: SharingError.notSavedObject)
                        return
                    }
                    self.container.share([list], to: nil) { _, share, _, error in
                        if let error {
                            continuation.resume(throwing: error)
                        } else if let share {
                            continuation.resume(returning: share)
                        } else {
                            continuation.resume(throwing: SharingError.missingShareResult)
                        }
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    func canEdit(_ object: NSManagedObject) -> Bool {
        return container.canUpdateRecord(forManagedObjectWith: object.objectID)
    }
    
    func canDelete(_ object: NSManagedObject) -> Bool {
        return container.canDeleteRecord(forManagedObjectWith: object.objectID)
    }

    /// システム共有UIが更新したCKShareをCore Dataのローカルメタデータへ反映する。
    func persistUpdatedShare(_ share: CKShare, in store: NSPersistentStore) async throws {
        _ = try await container.persistUpdatedShare(share, in: store)
    }
    
    func sharingStatus(for list: ShoppingList) throws -> SharingStatus {
        let existingShares = try container.fetchShares(matching: [list.objectID])
        guard let share = existingShares[list.objectID] else {
            return .notShared
        }
        let container = cloudKitContainer
        if share.currentUserParticipant?.role == .owner {
            return .owner(share: share, container: container)
        } else {
            return .participant(share: share, container: container)
        }
    }
}
