import CoreData
import Foundation

@MainActor
@Observable
final class PersistenceController {
    private static let managedObjectModel: NSManagedObjectModel = {
        guard
            let modelURL = Bundle.main.url(forResource: "okaimono_app", withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelURL)
        else {
            preconditionFailure("Core Dataモデルを読み込めませんでした。")
        }
        return model
    }()

    static let shared = PersistenceController(
        inMemory: ProcessInfo.processInfo.arguments.contains("-ui-testing")
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    )

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let context = result.container.viewContext
        for i in 1...2 {
            let list = ShoppingList(context: context)
            list.name = "買い物リスト \(i)"

            let menu = MenuItem(context: context)
            menu.name = "献立 \(i)"
            menu.list = list

            for j in 1...2 {
                let ingredient = Ingredient(context: context)
                ingredient.name = "材料 \(j)"
                ingredient.quantity = "100g"
                ingredient.menu = menu
            }
        }
        try? context.save()
        return result
    }()

    private(set) var container: NSPersistentCloudKitContainer
    private(set) var storeLoadError: Error?
    private(set) var isStoreLoaded = false
    private let inMemory: Bool
    private let storeURL: URL?
    private let cloudKitEnabled: Bool

    init(
        inMemory: Bool = false,
        storeURL: URL? = nil,
        cloudKitEnabled: Bool = true
    ) {
        self.inMemory = inMemory
        self.storeURL = storeURL
        self.cloudKitEnabled = cloudKitEnabled
        container = Self.makeContainer(
            inMemory: inMemory,
            storeURL: storeURL,
            cloudKitEnabled: cloudKitEnabled
        )
        configureViewContext()
        if inMemory {
            loadInMemoryStore()
        } else {
            loadStores(for: container)
        }
    }

    private static func makeContainer(
        inMemory: Bool,
        storeURL: URL?,
        cloudKitEnabled: Bool
    ) -> NSPersistentCloudKitContainer {
        let container = NSPersistentCloudKitContainer(
            name: "okaimono_app",
            managedObjectModel: managedObjectModel
        )

        guard !inMemory, let description = container.persistentStoreDescriptions.first else {
            return container
        }

        if let storeURL {
            description.url = storeURL
        }

        // 属性のdefault追加など、軽量なモデル差分は自動移行する。
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true

        if cloudKitEnabled {
            let options = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.mannjaro.okaimono-app"
            )
            description.cloudKitContainerOptions = options
            description.setOption(
                true as NSNumber,
                forKey: NSPersistentHistoryTrackingKey
            )
            description.setOption(
                true as NSNumber,
                forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
            )
        } else {
            description.cloudKitContainerOptions = nil
        }

        return container
    }

    private func loadInMemoryStore() {
        do {
            try container.persistentStoreCoordinator.addPersistentStore(
                ofType: NSInMemoryStoreType,
                configurationName: nil,
                at: nil
            )
            storeLoadError = nil
            isStoreLoaded = true
        } catch {
            storeLoadError = error
            isStoreLoaded = false
        }
    }

    private func loadStores(for candidate: NSPersistentCloudKitContainer) {
        candidate.loadPersistentStores { [weak self, weak candidate] _, error in
            Task { @MainActor in
                guard let self, let candidate, self.container === candidate else { return }
                if let error {
                    self.storeLoadError = error
                    self.isStoreLoaded = false
                } else {
                    self.storeLoadError = nil
                    self.isStoreLoaded = true
                }
            }
        }
    }

    private func configureViewContext() {
        container.viewContext.automaticallyMergesChangesFromParent = true
        // インライン編集中の未保存入力を、リモート競合で黙って潰さない。
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.shouldDeleteInaccessibleFaults = true
        container.viewContext.name = "viewContext"
        container.viewContext.transactionAuthor = "app"
    }

    func retryLoadingStores() {
        storeLoadError = nil
        isStoreLoaded = false

        if inMemory {
            if container.persistentStoreCoordinator.persistentStores.isEmpty {
                loadInMemoryStore()
            } else {
                isStoreLoaded = true
            }
        } else if container.persistentStoreCoordinator.persistentStores.isEmpty {
            // 同じコンテナで再試行し、CloudKitの同期ハンドラを二重登録しない。
            loadStores(for: container)
        } else {
            isStoreLoaded = true
        }
    }

    /// ユーザーが明示的に選んだ場合だけ、端末内のストアを破棄して再作成する。
    /// CloudKit上のレコードは削除せず、接続後に再同期される。
    func resetLocalStore() {
        guard !inMemory else { return }

        storeLoadError = nil
        isStoreLoaded = false

        let previousContainer = container
        let description = previousContainer.persistentStoreDescriptions.first
        let url = description?.url ?? storeURL ?? Self.defaultStoreURL()

        previousContainer.viewContext.performAndWait {
            previousContainer.viewContext.reset()
        }

        do {
            let coordinator = previousContainer.persistentStoreCoordinator
            for store in coordinator.persistentStores {
                try coordinator.remove(store)
            }

            if let url {
                do {
                    try coordinator.destroyPersistentStore(
                        at: url,
                        ofType: NSSQLiteStoreType,
                        options: description?.options
                    )
                } catch {
                    try Self.removeLocalStoreFiles(at: url)
                }
            }

            // destroy後も同じコンテナを使い、CloudKit同期ハンドラの
            // 非同期tearDownと新規登録が競合しないようにする。
            loadStores(for: previousContainer)
        } catch {
            storeLoadError = error
            isStoreLoaded = false
        }
    }

    private static func defaultStoreURL() -> URL? {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        return folder?.appendingPathComponent("okaimono_app.sqlite")
    }

    private static func removeLocalStoreFiles(at url: URL) throws {
        let fileManager = FileManager.default
        let candidates = [
            url,
            URL(fileURLWithPath: url.path + "-wal"),
            URL(fileURLWithPath: url.path + "-shm"),
            url.deletingPathExtension().appendingPathExtension("sqlite-wal"),
            url.deletingPathExtension().appendingPathExtension("sqlite-shm")
        ]
        for candidate in candidates where fileManager.fileExists(atPath: candidate.path) {
            try fileManager.removeItem(at: candidate)
        }
    }
}
