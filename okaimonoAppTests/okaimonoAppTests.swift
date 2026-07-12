import CoreData
import Foundation
import Testing
@testable import okaimono_app

@MainActor
@Suite(.serialized)
struct okaimono_appTests {

    @Test func coreDataSavePersistsShoppingList() throws {
        let context = PersistenceController(inMemory: true).container.viewContext

        let list = ShoppingList(context: context)
        list.name = "週末の買い物"
        try context.save()

        let request = ShoppingList.fetchRequest()
        let results = try context.fetch(request)
        #expect(results.count == 1)
        #expect(results.first?.name == "週末の買い物")
        #expect(results.first?.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }

    @Test func cloudKitModelAttributesAreOptionalOrHaveDefaults() {
        let model = PersistenceController(inMemory: true)
            .container
            .managedObjectModel

        for entity in model.entities {
            for attribute in entity.attributesByName.values {
                #expect(
                    attribute.isOptional || attribute.defaultValue != nil,
                    "CloudKit同期属性 \(entity.name ?? "")・\(attribute.name) にoptionalまたはdefaultが必要です"
                )
            }
            for relationship in entity.relationshipsByName.values {
                #expect(
                    relationship.isOptional,
                    "CloudKit同期リレーション \(entity.name ?? "")・\(relationship.name) はoptionalが必要です"
                )
            }
        }
    }

    @Test func diskStoreLoadsPersistsAndCanBeExplicitlyReset() async throws {
        let directory = FileManager.default.temporaryDirectory
            .appending(path: "okaimono-tests-\(UUID().uuidString)", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let storeURL = directory.appending(path: "Test.sqlite")

        var firstController: PersistenceController? = PersistenceController(
            storeURL: storeURL,
            cloudKitEnabled: false
        )
        #expect(await waitUntilLoaded(firstController!))

        let firstContext = firstController!.container.viewContext
        let list = ShoppingList(context: firstContext)
        list.name = "ディスク保存"
        try firstContext.save()
        firstController = nil

        var secondController: PersistenceController? = PersistenceController(
            storeURL: storeURL,
            cloudKitEnabled: false
        )
        #expect(await waitUntilLoaded(secondController!))
        #expect(try secondController!.container.viewContext.count(for: ShoppingList.fetchRequest()) == 1)

        secondController!.resetLocalStore()
        #expect(await waitUntilLoaded(secondController!))
        #expect(try secondController!.container.viewContext.count(for: ShoppingList.fetchRequest()) == 0)

        let coordinator = secondController!.container.persistentStoreCoordinator
        if let store = coordinator.persistentStores.first, let url = store.url {
            try coordinator.destroyPersistentStore(at: url, ofType: store.type)
        }
        secondController = nil
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
