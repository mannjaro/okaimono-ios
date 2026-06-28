import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
        let context = result.container.viewContext
        for i in 1...2 {
            let list = ShoppingList(context: context)
            list.id = UUID()
            list.name = "Shopping list \(i)"
            list.createdAt = Date()

            let menu = MenuItem(context: context)
            menu.id = UUID()
            menu.name = "Ingredient \(i)"
            menu.createdAt = Date()
            menu.list = list

            for i in 1...2 {
                let ingredient = Ingredient(context: context)
                ingredient.id = UUID()
                ingredient.name = "Sample \(i)"
                ingredient.quantity = "100g"
                ingredient.isChecked = false
                ingredient.createdAt = Date()
                ingredient.menu = menu
            }
        }
        try? context.save()
        return result
    }()

    let container: NSPersistentCloudKitContainer

    init(inMemory: Bool = false) {
        container = NSPersistentCloudKitContainer(name: "okaimono_app")

        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        } else {
            let description = container.persistentStoreDescriptions.first!
            let options = NSPersistentCloudKitContainerOptions(
                containerIdentifier: "iCloud.mannjaro.okaimono-app"
            )
            description.cloudKitContainerOptions = options

            // iCloudから変更があった場合に通知する設定
            description.setOption(
                true as NSNumber,
                forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey
            )
        }

        container.loadPersistentStores { _, error in
            if let error {
                fatalError("CoreData load error: \(error)")
            }
        }

        // 親から変更があったら自動で取り込む
        container.viewContext.automaticallyMergesChangesFromParent = true

        // 競合した場合はメモリ上のデータを優先する
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
