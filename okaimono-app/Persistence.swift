import CoreData

// ============================================================
// CloudKit 移行チェックリスト（Apple Developer Program 承認後）
//
// 1. 下の "TODO: CloudKit 移行" のコメントを2箇所変更する
// 2. Xcode: Target → Signing & Capabilities → iCloud を追加
//    → CloudKit にチェック → コンテナ "iCloud.mannjaro.okaimono-app" を追加
// 3. okaimono_app.entitlements に以下を追加（コメント参照）
// ============================================================

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let context = result.container.viewContext
        for i in 1...2 {
            let list = ShoppingList(context: context)
            list.id = UUID()
            list.name = "買い物リスト \(i)"
            list.createdAt = Date()
            
            let menu = MenuItem(context: context)
            menu.id = UUID()
            menu.name = "献立 \(i)"
            menu.createdAt = Date()
            menu.list = list
            
            for i in 1...2 {
                let ingredient = Ingredient(context: context)
                ingredient.id = UUID()
                ingredient.name = "サンプル \(i)"
                ingredient.quantity = "100g"
                ingredient.isChecked = false
                ingredient.createdAt = Date()
                ingredient.menu = menu
            }
        }
        try? context.save()
        return result
    }()

    // TODO: CloudKit 移行 (1/2) — 型を NSPersistentCloudKitContainer に変更する
    // let container: NSPersistentCloudKitContainer
    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        // TODO: CloudKit 移行 (2/2) — NSPersistentContainer → NSPersistentCloudKitContainer に変更する
        // container = NSPersistentCloudKitContainer(name: "okaimono_app")
        container = NSPersistentContainer(name: "okaimono_app")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            // CloudKit 移行時はこのブロックのコメントを外す
            // let description = container.persistentStoreDescriptions.first!
            // let options = NSPersistentCloudKitContainerOptions(
            //     containerIdentifier: "iCloud.mannjaro.okaimono-app"
            // )
            // description.cloudKitContainerOptions = options
            // description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            // description.setOption(
            //     true as NSNumber,
            //     forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
            // )
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("CoreData load error: \(error)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
