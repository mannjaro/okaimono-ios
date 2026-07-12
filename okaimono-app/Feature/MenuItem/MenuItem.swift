import CoreData

@objc(MenuItem)
public class MenuItem: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MenuItem> {
        NSFetchRequest<MenuItem>(entityName: "MenuItem")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var isArchived: Bool
    @NSManaged public var ingredients: NSSet?
    @NSManaged public var list: ShoppingList?

    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setupDefaults()
    }
}

extension MenuItem: Identifiable {}
extension MenuItem: CoreDataEntity {}
