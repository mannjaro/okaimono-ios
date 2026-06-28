import CoreData

@objc(ShoppingList)
public class ShoppingList: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShoppingList> {
        NSFetchRequest<ShoppingList>(entityName: "ShoppingList")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var menus: NSSet?

    var menusArray: [MenuItem] {
        let set = menus as? Set<MenuItem> ?? []
        return set.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
    }

    var totalUncheckedCount: Int {
        menusArray.reduce(0) { $0 + $1.uncheckedCount }
    }
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setupDefaults()
    }
}

extension ShoppingList: Identifiable {}
extension ShoppingList: CoreDataEntity {}
