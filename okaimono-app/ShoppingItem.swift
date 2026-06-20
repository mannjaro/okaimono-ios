import Foundation
import CoreData

@objc(ShoppingItem)
public class ShoppingItem: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<ShoppingItem> {
        NSFetchRequest<ShoppingItem>(entityName: "ShoppingItem")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var quantity: Int16
    @NSManaged public var isChecked: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var list: ShoppingList?
}

extension ShoppingItem: Identifiable {}
