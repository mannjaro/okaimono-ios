import Foundation
import CoreData

@objc(MenuItem)
public class MenuItem: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<MenuItem> {
        NSFetchRequest<MenuItem>(entityName: "MenuItem")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var ingredients: NSSet?
    @NSManaged public var list: ShoppingList?

    var ingredientsArray: [Ingredient] {
        let set = ingredients as? Set<Ingredient> ?? []
        return set.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
    }

    var uncheckedCount: Int {
        (ingredients as? Set<Ingredient>)?.filter { !$0.isChecked }.count ?? 0
    }
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setupDefaults()
    }
}

extension MenuItem: Identifiable {}
extension MenuItem: CoreDataEntity {}
