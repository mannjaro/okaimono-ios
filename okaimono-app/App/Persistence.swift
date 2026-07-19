import CoreData
import CloudKit

@MainActor
@Observable
final class PersistenceController {
    private static let managedObjectModel: NSManagedObjectModel = {
        guard
            let modelURL = Bundle.main.url(forResource: "okaimono_app", withExtension: "momd"),
            let model = NSManagedObjectModel(contentsOf: modelURL)
        else {
            preconditionFailure("Failed to load Core Data model.")
        }
        return model
    }()

    static let shared = PersistenceController(
        inMemory: ProcessInfo.processInfo.arguments.contains("-ui-testing")
            || ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    )

    static let preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let context = result.container.viewContext
        for i in 1...2 {
            let list = ShoppingList(context: context)
            list.name = "Shopping list \(i)"

            let menu = MenuItem(context: context)
            menu.name = "Menu \(i)"
            menu.list = list

            for j in 1...2 {
                let ingredient = Ingredient(context: context)
                ingredient.name = "Ingredient \(j)"
                ingredient.quantity = "100g"
                ingredient.menu = menu
            }
        }
        try? context.save()
        return result
    }()

    let container: NSPersistentCloudKitContainer
    private(set) var storeLoadError: Error?
    private(set) var isStoreLoaded = false
    private(set) var privatePersistentStore: NSPersistentStore?
    private(set) var sharedPersistentStore: NSPersistentStore?
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
        loadStores()
    }

    private static func configureDescription(
        description: NSPersistentStoreDescription,
        cloudKitEnabled: Bool,
        scope: CKDatabase.Scope
    ) {
        // 属性のdefault追加など、軽量なモデル差分は自動移行する。
        description.shouldMigrateStoreAutomatically = true
        description.shouldInferMappingModelAutomatically = true

        if cloudKitEnabled {
            let options = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.mannjaro.okaimono-app"
            )
            description.setOption(
                true as NSNumber,
                forKey: NSPersistentHistoryTrackingKey
            )
            description.setOption(
                true as NSNumber,
                forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
            )
            options.databaseScope = scope
            description.cloudKitContainerOptions = options
        } else {
            description.cloudKitContainerOptions = nil
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

        guard let privateDescription = container.persistentStoreDescriptions.first else {
            return container
        }

        if let storeURL {
            privateDescription.url = storeURL
        }
        // shared ファイルを置くためのURLを定める
        guard let privateURL = privateDescription.url else {
            return container
        }
        // shared description の作成
        let sharedURL = privateURL
            .deletingLastPathComponent()
            .appendingPathComponent("okaimono_app_shared.sqlite")

        let sharedDescription = NSPersistentStoreDescription(url: sharedURL)

        if inMemory {
            privateDescription.type = NSInMemoryStoreType
            sharedDescription.type = NSInMemoryStoreType

            privateDescription.url = URL(fileURLWithPath: "/okaimono_app.sqlite")
            sharedDescription.url = URL(fileURLWithPath: "/okaimono_app_shared.sqlite")
        }

        // configure private
        configureDescription(
            description: privateDescription,
            cloudKitEnabled: cloudKitEnabled && !inMemory,
            scope: .private
        )
        // configure shared
        configureDescription(
            description: sharedDescription,
            cloudKitEnabled: cloudKitEnabled && !inMemory,
            scope: .shared
        )

        container.persistentStoreDescriptions = [
            privateDescription,
            sharedDescription
        ]
        return container
    }

    private func loadStores() {
        privatePersistentStore = nil
        sharedPersistentStore = nil
        isStoreLoaded = false
        storeLoadError = nil

        container.loadPersistentStores { description, error in
            Task { @MainActor in
                if let error {
                    self.storeLoadError = error
                    self.isStoreLoaded = false
                }

                let store = self.container.persistentStoreCoordinator.persistentStores
                    .first { $0.url == description.url }

                // CloudKit無効時はdatabaseScopeがnilになるため、ファイル名でshared側を判別する
                let isShared = description.cloudKitContainerOptions?.databaseScope == .shared
                    || description.url?.lastPathComponent.contains("_shared") == true

                if isShared {
                    self.sharedPersistentStore = store
                } else {
                    self.privatePersistentStore = store
                }

                if self.privatePersistentStore != nil,
                   self.sharedPersistentStore != nil {
                    self.storeLoadError = nil
                    self.isStoreLoaded = true
                }
            }
        }
    }

    private func configureViewContext() {
        let context = container.viewContext
        context.automaticallyMergesChangesFromParent = true
        // インライン編集中の未保存入力を、リモート競合で黙って潰さない。
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        context.shouldDeleteInaccessibleFaults = true
        context.name = "viewContext"
        context.transactionAuthor = "app"
    }

    func retryLoadingStores() {
        storeLoadError = nil
        isStoreLoaded = false

        let expected = container.persistentStoreDescriptions.count
        let loaded = container.persistentStoreCoordinator.persistentStores.count

        guard loaded < expected else {
            isStoreLoaded = true
            return
        }
        // 同じコンテナで再試行し、CloudKitの同期ハンドラを二重登録しない。
        loadStores()
    }

    /// ユーザーが明示的に選んだ場合だけ、端末内のストアを破棄して再作成する。
    /// CloudKit上のレコードは削除せず、接続後に再同期される。
    func resetLocalStore() {
        guard !inMemory else { return }

        storeLoadError = nil
        isStoreLoaded = false

        let description = container.persistentStoreDescriptions.first
        let url = description?.url ?? storeURL ?? Self.defaultStoreURL()

        container.viewContext.performAndWait {
            container.viewContext.reset()
        }

        do {
            let coordinator = container.persistentStoreCoordinator
            for store in coordinator.persistentStores {
                try coordinator.remove(store)
            }

            do {
                try coordinator.destroyPersistentStore(
                    at: url,
                    ofType: NSSQLiteStoreType,
                    options: description?.options
                )
            } catch {
                try Self.removeLocalStoreFiles(at: url)
            }

            // destroy後も同じコンテナを使い、CloudKit同期ハンドラの
            // 非同期tearDownと新規登録が競合しないようにする。
            loadStores()
        } catch {
            storeLoadError = error
            isStoreLoaded = false
        }
    }

    private static func defaultStoreURL() -> URL {
        URL.applicationSupportDirectory.appendingPathComponent("okaimono_app.sqlite")
    }

    private static func removeLocalStoreFiles(at url: URL) throws {
        let fileManager = FileManager.default
        let candidates = [
            url,
            URL(fileURLWithPath: url.path + "-wal"),
            URL(fileURLWithPath: url.path + "-shm")
        ]
        for candidate in candidates where fileManager.fileExists(atPath: candidate.path) {
            try fileManager.removeItem(at: candidate)
        }
    }
}
