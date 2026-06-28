import CoreData

protocol CoreDataEntity: NSManagedObject {
    var id: UUID? { get set }
    var createdAt: Date? { get set }
}

extension CoreDataEntity {
    func setupDefaults() {
        id = UUID()
        createdAt = Date()
    }
}
