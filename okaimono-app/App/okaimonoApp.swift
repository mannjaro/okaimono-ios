import SwiftUI
import CoreData

@main
struct okaimonoApp: App {
    let persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ShoppingListView()
                .environment(\.managedObjectContext, persistence.container.viewContext)
        }
    }
}
