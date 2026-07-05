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

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setupDefaults()
    }
}

extension ShoppingList: Identifiable {}
extension ShoppingList: CoreDataEntity {}
