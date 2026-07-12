import SwiftUI
import CoreData

@main
struct okaimonoApp: App {
    @State private var persistence = PersistenceController.shared
    @State private var saveErrorCenter = SaveErrorCenter()
    @Environment(\.scenePhase) private var scenePhase

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
            .environment(saveErrorCenter)
            .alert(
                "保存エラー",
                isPresented: Binding(
                    get: { saveErrorCenter.message != nil },
                    set: { if !$0 { saveErrorCenter.dismiss() } }
                )
            ) {
                Button("OK", role: .cancel) {
                    saveErrorCenter.dismiss()
                }
            } message: {
                Text(saveErrorCenter.message ?? "")
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            guard newPhase == .background else { return }
            guard persistence.isStoreLoaded else { return }
            persistence.container.viewContext.saveIfNeeded(reportingTo: saveErrorCenter)
        }
    }
}
