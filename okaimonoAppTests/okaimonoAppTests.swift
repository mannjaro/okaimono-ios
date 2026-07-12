import CoreData
import Foundation
import Testing
@testable import okaimono_app

@MainActor
@Suite(.serialized)
struct okaimono_appTests {

    @Test func normalizedIngredientNameHandlesWhitespaceKanaAndWidth() {
        #expect(" りんご ".normalizedForIngredientMatch == "りんご".normalizedForIngredientMatch)
        #expect("トウモロコシ".normalizedForIngredientMatch == "とうもろこし".normalizedForIngredientMatch)
        #expect("ＡＢＣ".normalizedForIngredientMatch == "abc")
    }

    @Test func ingredientSuggestionsMatchPrefixAndExcludeCurrentMenu() {
        let context = PersistenceController(inMemory: true).container.viewContext

        let list = ShoppingList(context: context)
        list.name = "テスト"

        let menu = MenuItem(context: context)
        menu.name = "献立"
        menu.list = list

        let tomato = Ingredient(context: context)
        tomato.name = "トマト"
        tomato.menu = menu

        let otherMenu = MenuItem(context: context)
        otherMenu.name = "別献立"
        otherMenu.list = list

        let tomatoPaste = Ingredient(context: context)
        tomatoPaste.name = "トマトペースト"
        tomatoPaste.menu = otherMenu

        let onion = Ingredient(context: context)
        onion.name = "玉ねぎ"
        onion.menu = otherMenu

        #expect(context.saveIfNeeded())

        let suggestions = IngredientNameSuggestions.suggestions(
            from: [tomato, tomatoPaste, onion],
            matching: "トマ",
            excluding: ["トマト"]
        )

        #expect(suggestions == ["トマトペースト"])
    }

    @Test func cartGroupsMergeNormalizedNames() {
        let context = PersistenceController(inMemory: true).container.viewContext

        let list = ShoppingList(context: context)
        let menu = MenuItem(context: context)
        menu.list = list

        let first = Ingredient(context: context)
        first.name = "ねぎ"
        first.quantity = "1本"
        first.isChecked = false
        first.menu = menu

        let second = Ingredient(context: context)
        second.name = "ネギ"
        second.quantity = "2本"
        second.isChecked = false
        second.menu = menu

        #expect(context.saveIfNeeded())
        #expect("ねぎ".normalizedForIngredientMatch == "ネギ".normalizedForIngredientMatch)

        let groups = CartIngredientGroup.makeGroups(from: [first, second])
        #expect(groups.count == 1)

        guard let group = groups.first else {
            return
        }
        #expect(group.items.count == 2)
        #expect(group.displayQuantity.contains("1本"))
        #expect(group.displayQuantity.contains("2本"))
    }

    @Test func coreDataSavePersistsShoppingList() throws {
        let context = PersistenceController(inMemory: true).container.viewContext

        let list = ShoppingList(context: context)
        list.name = "週末の買い物"
        #expect(context.saveIfNeeded())

        let request = ShoppingList.fetchRequest()
        let results = try context.fetch(request)
        #expect(results.count == 1)
        #expect(results.first?.name == "週末の買い物")
        #expect(results.first?.id != UUID(uuidString: "00000000-0000-0000-0000-000000000000"))
    }

    @Test func undoListDeletionRestoresCascadeDataAndSaves() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let errorCenter = SaveErrorCenter()
        let deletionCenter = DeletionUndoCenter()

        let list = ShoppingList(context: context)
        list.name = "復元対象"
        let menu = MenuItem(context: context)
        menu.name = "カレー"
        menu.list = list
        let ingredient = Ingredient(context: context)
        ingredient.name = "にんじん"
        ingredient.menu = menu
        #expect(context.saveIfNeeded())

        deletionCenter.deleteShoppingLists(
            [list],
            in: context,
            message: "削除しました",
            reportingTo: errorCenter
        )

        #expect(try context.count(for: ShoppingList.fetchRequest()) == 0)
        #expect(try context.count(for: MenuItem.fetchRequest()) == 0)
        #expect(try context.count(for: Ingredient.fetchRequest()) == 0)
        #expect(deletionCenter.message != nil)

        deletionCenter.undo()

        #expect(try context.count(for: ShoppingList.fetchRequest()) == 1)
        #expect(try context.count(for: MenuItem.fetchRequest()) == 1)
        #expect(try context.count(for: Ingredient.fetchRequest()) == 1)
        #expect(deletionCenter.message == nil)
        #expect(errorCenter.message == nil)
    }

    @Test func unrelatedSaveDoesNotCommitPendingListDeletion() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let errorCenter = SaveErrorCenter()
        let deletionCenter = DeletionUndoCenter()

        let pendingList = ShoppingList(context: context)
        pendingList.name = "削除保留"
        let otherList = ShoppingList(context: context)
        otherList.name = "別リスト"
        let menu = MenuItem(context: context)
        menu.name = "献立"
        menu.list = otherList
        let ingredient = Ingredient(context: context)
        ingredient.name = "材料"
        ingredient.isChecked = false
        ingredient.menu = menu
        #expect(context.saveIfNeeded())

        deletionCenter.deleteShoppingLists(
            [pendingList],
            in: context,
            message: "削除しました",
            reportingTo: errorCenter
        )
        #expect(deletionCenter.message != nil)

        ingredient.isChecked = true
        #expect(
            deletionCenter.savePreservingPendingDeletion(
                in: context,
                reportingTo: errorCenter
            )
        )
        #expect(deletionCenter.message != nil)

        context.reset()
        let lists = try context.fetch(ShoppingList.fetchRequest())
        #expect(lists.count == 2)
        #expect(lists.contains { $0.name == "削除保留" })

        let savedIngredient = try context.fetch(Ingredient.fetchRequest()).first
        #expect(savedIngredient?.isChecked == true)
    }

    @Test func committedMenuDeletionRemovesCascadeData() throws {
        let context = PersistenceController(inMemory: true).container.viewContext
        let errorCenter = SaveErrorCenter()
        let deletionCenter = DeletionUndoCenter()

        let list = ShoppingList(context: context)
        list.name = "保存対象"
        let menu = MenuItem(context: context)
        menu.name = "献立"
        menu.list = list
        let ingredient = Ingredient(context: context)
        ingredient.name = "材料"
        ingredient.menu = menu
        #expect(context.saveIfNeeded())

        deletionCenter.deleteMenu(
            menu,
            in: context,
            message: "削除しました",
            reportingTo: errorCenter
        )
        deletionCenter.commitPendingDeletion()

        context.reset()
        #expect(try context.count(for: ShoppingList.fetchRequest()) == 1)
        #expect(try context.count(for: MenuItem.fetchRequest()) == 0)
        #expect(try context.count(for: Ingredient.fetchRequest()) == 0)
        #expect(deletionCenter.message == nil)
        #expect(errorCenter.message == nil)
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
        #expect(firstContext.saveIfNeeded())
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
