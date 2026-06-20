import Foundation
import CoreData

@objc(ShoppingList)
public class ShoppingList: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShoppingList> {
        NSFetchRequest<ShoppingList>(entityName: "ShoppingList")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var createdAt: Date?
    @NSManaged public var items: NSSet?

    var itemsArray: [ShoppingItem] {
        let set = items as? Set<ShoppingItem> ?? []
        return set.sorted { ($0.createdAt ?? .distantPast) < ($1.createdAt ?? .distantPast) }
    }

    var uncheckedCount: Int {
        itemsArray.filter { !$0.isChecked }.count
    }
}

extension ShoppingList: Identifiable {}
