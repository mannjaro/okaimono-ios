import SwiftUI
import CoreData

extension NSManagedObjectContext {
    @discardableResult
    func saveIfNeeded(reportingTo errorCenter: SaveErrorCenter? = nil) -> Bool {
        guard hasChanges else { return true }

        do {
            try save()
            return true
        } catch {
            errorCenter?.present(error)
            return false
        }
    }
    
    // T は NSManagedObject を継承している型に限定
    func delete<T: NSManagedObject>(
        _ objects: FetchedResults<T>,
        at offsets: IndexSet,
        reportingTo errorCenter: SaveErrorCenter? = nil
    ) {
        // offsetsから要素を取り出して削除
        offsets.map { objects[$0] }.forEach(delete)
        saveIfNeeded(reportingTo: errorCenter)
    }
    
    /// object を parent と同じ永続ストアへ割り当てる。parent が未保存などでストアが取れない場合は false。
    @discardableResult
    func assign(_ object: NSManagedObject, toSameStoreAs parent: NSManagedObject) -> Bool {
        guard let store = parent.objectID.persistentStore else { return false }
        assign(object, to: store)
        return true
    }
}
