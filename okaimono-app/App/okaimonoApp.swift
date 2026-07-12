import SwiftUI
import CoreData

@main
struct okaimonoApp: App {
    @State private var persistence = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            Group {
                if let error = persistence.storeLoadError {
                    PersistenceErrorView(
                        error: error,
                        onRetry: persistence.retryLoadingStores,
                        onReset: persistence.resetLocalStore
                    )
                } else if persistence.isStoreLoaded {
                    ShoppingListView()
                        .environment(\.managedObjectContext, persistence.container.viewContext)
                } else {
                    ProgressView("読み込み中…")
                }
            }
        }
    }
}
