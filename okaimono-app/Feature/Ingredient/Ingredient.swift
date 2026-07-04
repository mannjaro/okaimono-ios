import CoreData

@objc(Ingredient)
public class Ingredient: NSManagedObject {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Ingredient> {
        NSFetchRequest<Ingredient>(entityName: "Ingredient")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var quantity: String?
    @NSManaged public var isChecked: Bool
    @NSManaged public var createdAt: Date?
    @NSManaged public var menu: MenuItem?
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        setupDefaults()
    }
}

extension Ingredient: Identifiable {}
extension Ingredient: CoreDataEntity {}
extension Ingredient {
    func toggleCheck() {
        isChecked.toggle()
    }
}
