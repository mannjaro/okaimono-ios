import CoreData
import Foundation
import Observation

@MainActor
@Observable
final class DeletionUndoCenter {
    private(set) var message: String?

    private var context: NSManagedObjectContext?
    private var manager: UndoManager?
    private var saveErrorCenter: SaveErrorCenter?
    private var restore: ((NSManagedObjectContext) -> Void)?
    private var reapplyDeletion: ((NSManagedObjectContext) -> Void)?
    private var expirationTask: Task<Void, Never>?

    func deleteShoppingLists(
        _ lists: [ShoppingList],
        in context: NSManagedObjectContext,
        message: String,
        reportingTo saveErrorCenter: SaveErrorCenter
    ) {
        let snapshots = lists.map(ShoppingListSnapshot.init)
        let ids = Set(snapshots.compactMap(\.id))
        beginDeletion(
            in: context,
            message: message,
            reportingTo: saveErrorCenter,
            restore: { context in
                snapshots.forEach { $0.restore(in: context) }
            },
            reapplyDeletion: { context in
                guard !ids.isEmpty else { return }
                let request = ShoppingList.fetchRequest()
                request.predicate = NSPredicate(format: "id IN %@", ids)
                (try? context.fetch(request))?.forEach(context.delete)
            }
        )
        lists.forEach(context.delete)
        context.processPendingChanges()
    }

    func deleteMenu(
        _ menu: MenuItem,
        in context: NSManagedObjectContext,
        message: String,
        reportingTo saveErrorCenter: SaveErrorCenter
    ) {
        let snapshot = MenuSnapshot(menu)
        let id = snapshot.id
        beginDeletion(
            in: context,
            message: message,
            reportingTo: saveErrorCenter,
            restore: { context in
                snapshot.restore(in: context)
            },
            reapplyDeletion: { context in
                guard let id else { return }
                let request = MenuItem.fetchRequest()
                request.fetchLimit = 1
                request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
                if let menu = try? context.fetch(request).first {
                    context.delete(menu)
                }
            }
        )
        context.delete(menu)
        context.processPendingChanges()
    }

    func undo() {
        expirationTask?.cancel()
        expirationTask = nil

        guard let context, let manager else {
            clear()
            return
        }

        // 初回は復元、保存失敗後の再タップは保存のみ再試行する。
        if manager.canUndo {
            manager.undo()
            context.processPendingChanges()
        }

        let saved = context.saveIfNeeded(reportingTo: saveErrorCenter)
        if saved {
            manager.removeAllActions()
            clear()
        }
    }

    func commitPendingDeletion() {
        expirationTask?.cancel()
        expirationTask = nil

        guard let context else {
            clear()
            return
        }

        let saved = context.saveIfNeeded(reportingTo: saveErrorCenter)
        if saved {
            manager?.removeAllActions()
            clear()
            return
        }

        // 保存に失敗した削除は取り消し、カスケード対象も復元する。
        if let manager, manager.canUndo {
            manager.undo()
            context.processPendingChanges()
        }
        clear()
    }

    /// 他機能の変更を保存する。保留中のリスト/献立削除は確定させない。
    @discardableResult
    func savePreservingPendingDeletion(
        in context: NSManagedObjectContext,
        reportingTo errorCenter: SaveErrorCenter? = nil
    ) -> Bool {
        guard
            self.context === context,
            let manager,
            manager.canUndo,
            let restore,
            let reapplyDeletion
        else {
            return context.saveIfNeeded(reportingTo: errorCenter)
        }

        // 削除をいったん復元してから保存し、Undo可能期間中は再度未保存削除に戻す。
        manager.undo()
        context.processPendingChanges()

        let saved = context.saveIfNeeded(reportingTo: errorCenter ?? saveErrorCenter)

        reapplyDeletion(context)
        context.processPendingChanges()
        manager.removeAllActions()
        manager.registerUndo(withTarget: context, handler: restore)

        return saved
    }

    private func beginDeletion(
        in context: NSManagedObjectContext,
        message: String,
        reportingTo saveErrorCenter: SaveErrorCenter,
        restore: @escaping (NSManagedObjectContext) -> Void,
        reapplyDeletion: @escaping (NSManagedObjectContext) -> Void
    ) {
        commitPendingDeletion()

        let manager = UndoManager()
        manager.registerUndo(withTarget: context, handler: restore)

        self.context = context
        self.manager = manager
        self.saveErrorCenter = saveErrorCenter
        self.restore = restore
        self.reapplyDeletion = reapplyDeletion
        self.message = message

        expirationTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(8))
            guard !Task.isCancelled else { return }
            self?.commitPendingDeletion()
        }
    }

    private func clear() {
        context = nil
        manager = nil
        saveErrorCenter = nil
        restore = nil
        reapplyDeletion = nil
        message = nil
    }
}

@MainActor
private struct IngredientSnapshot {
    let id: UUID?
    let name: String?
    let quantity: String?
    let isChecked: Bool
    let createdAt: Date?

    init(_ ingredient: Ingredient) {
        id = ingredient.id
        name = ingredient.name
        quantity = ingredient.quantity
        isChecked = ingredient.isChecked
        createdAt = ingredient.createdAt
    }

    func restore(in context: NSManagedObjectContext, menu: MenuItem) {
        let ingredient = Ingredient(context: context)
        ingredient.id = id
        ingredient.name = name
        ingredient.quantity = quantity
        ingredient.isChecked = isChecked
        ingredient.createdAt = createdAt
        ingredient.menu = menu
    }
}

@MainActor
private struct MenuSnapshot {
    let id: UUID?
    let name: String?
    let createdAt: Date?
    let listID: UUID?
    let ingredients: [IngredientSnapshot]

    init(_ menu: MenuItem) {
        id = menu.id
        name = menu.name
        createdAt = menu.createdAt
        listID = menu.list?.id
        ingredients = (menu.ingredients?.allObjects as? [Ingredient] ?? [])
            .map(IngredientSnapshot.init)
    }

    func restore(in context: NSManagedObjectContext, list: ShoppingList? = nil) {
        let menu = MenuItem(context: context)
        menu.id = id
        menu.name = name
        menu.createdAt = createdAt
        menu.list = list ?? fetchList(in: context)
        ingredients.forEach { $0.restore(in: context, menu: menu) }
    }

    private func fetchList(in context: NSManagedObjectContext) -> ShoppingList? {
        guard let listID else { return nil }
        let request = ShoppingList.fetchRequest()
        request.fetchLimit = 1
        request.predicate = NSPredicate(format: "id == %@", listID as CVarArg)
        return try? context.fetch(request).first
    }
}

@MainActor
private struct ShoppingListSnapshot {
    let id: UUID?
    let name: String?
    let createdAt: Date?
    let menus: [MenuSnapshot]

    init(_ list: ShoppingList) {
        id = list.id
        name = list.name
        createdAt = list.createdAt
        menus = (list.menus?.allObjects as? [MenuItem] ?? [])
            .map(MenuSnapshot.init)
    }

    func restore(in context: NSManagedObjectContext) {
        let list = ShoppingList(context: context)
        list.id = id
        list.name = name
        list.createdAt = createdAt
        menus.forEach { $0.restore(in: context, list: list) }
    }
}
