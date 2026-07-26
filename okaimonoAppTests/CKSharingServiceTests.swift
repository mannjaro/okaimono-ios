import CoreData
import Foundation
import Testing
@testable import okaimono_app

@MainActor
@Suite(.serialized)
struct CKSharingServiceTests {

    @Test func fetchOrCreateShareThrowsForUnsavedList() async throws {
        // Arrange
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext

        // ShoppingList を作るが、context.saveIfNeeded() はしない（保存しなければ objectID.isTemporaryID が true のまま）
        let list = ShoppingList(context: context)
        list.name = "Not saved list"

        // CKSharingService(persistence:) を作る
        let service = CKSharingService(persistence: persistence)
        
        // Act & Assert
        await #expect(throws: CKSharingService.SharingError.notSavedObject) {
            try await service.fetchOrCreateShare(for: list)
        }
    }

    @Test func fetchOrCreateShareThrowsForSharedStoreList() async throws {
        // Arrange
        let persistence = PersistenceController(inMemory: true)
        #expect(await waitUntilLoaded(persistence))

        let context = persistence.container.viewContext
        let list = ShoppingList(context: context)
        list.name = "Saved list"
        context.assign(list, to: persistence.sharedPersistentStore!)
        #expect(context.saveIfNeeded())

        let service = CKSharingService(persistence: persistence)

        // Act & Assert
        await #expect(throws: CKSharingService.SharingError.reSharingNotAllowed) {
            try await service.fetchOrCreateShare(for: list)
        }
    }

    private func waitUntilLoaded(
        _ controller: PersistenceController,
        timeoutIterations: Int = 300
    ) async -> Bool {
        for _ in 0..<timeoutIterations {
            if controller.isStoreLoaded {
                return true
            }
            if controller.storeLoadError != nil {
                return false
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
        return false
    }
}
