import CoreData
import CloudKit

final class CKSharingService {
    private let persistence: PersistenceController
    
    init(persistence: PersistenceController) {
        self.persistence = persistence
    }
    
    enum SharingError: Error {
        case notSavedObject
        case reSharingNotAllowed
    }
    
    enum SharingStatus {
        case notShared
        case owner(share: CKShare, container: CKContainer)
        case participant(share: CKShare, container: CKContainer)
    }
    
    private var ckContainer: CKContainer {
        CKContainer(identifier: CloudKitConfiguration.containerIdentifier)
    }
    
    /// リストの共有を作る、もしくは既にあればそれを返す
    func fetchOrCreateShare(for list: ShoppingList) async throws -> (share: CKShare, container: CKContainer) {
        guard !list.objectID.isTemporaryID else {
            throw SharingError.notSavedObject
        }
        guard list.objectID.persistentStore != persistence.sharedPersistentStore else {
            throw SharingError.reSharingNotAllowed
        }

        let existingShares = try persistence.container.fetchShares(matching: [list.objectID])
        guard let share = existingShares[list.objectID] else {
            let (_, share, container) = try await persistence.container.share([list], to: nil)
            return (share, container)
        }
        let container = ckContainer
        return (share, container)
    }

    func canEdit(_ object: NSManagedObject) -> Bool {
        return persistence.container.canUpdateRecord(forManagedObjectWith: object.objectID)
    }
    
    func canDelete(_ object: NSManagedObject) -> Bool {
        return persistence.container.canDeleteRecord(forManagedObjectWith: object.objectID)
    }
    
    func sharingStatus(for list: ShoppingList) throws -> SharingStatus {
        let existingShares = try persistence.container.fetchShares(matching: [list.objectID])
        guard let share = existingShares[list.objectID] else {
            return .notShared
        }
        let container = ckContainer
        if share.currentUserParticipant?.role == .owner {
            return .owner(share: share, container: container)
        } else {
            return .participant(share: share, container: container)
        }
    }
}
