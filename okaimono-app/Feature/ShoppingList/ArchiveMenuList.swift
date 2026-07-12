import SwiftUI
import CoreData

struct ArchiveMenuList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(SaveErrorCenter.self) private var saveErrorCenter

    let list: ShoppingList

    @FetchRequest private var items: FetchedResults<MenuItem>

    init(list: ShoppingList) {
        self.list = list
        _items = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \MenuItem.createdAt, ascending: false)],
            predicate: NSPredicate(format: "list == %@ AND isArchived == YES", list),
            animation: .default
        )
    }

    var body: some View {
        List {
            if items.isEmpty {
                ContentUnavailableView {
                    Label("アーカイブした献立がありません", systemImage: "archivebox")
                } description: {
                    Text("献立をスワイプしてアーカイブすると、ここに表示されます。")
                }
                .listRowBackground(Color.clear)
            }

            ForEach(items) { menu in
                Text(menu.name ?? "名前なし")
                    .swipeActions(edge: .trailing) {
                        Button("復元") {
                            restoreMenu(menu)
                        }
                        .tint(.blue)
                        Button("削除", role: .destructive) {
                            deleteMenu(menu)
                        }
                    }
                    .accessibilityIdentifier("archived-menu-row")
            }
        }
        .navigationTitle("アーカイブ")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func restoreMenu(_ menu: MenuItem) {
        withAnimation {
            menu.isArchived = false
        }
        viewContext.saveIfNeeded(reportingTo: saveErrorCenter)
    }
    
    private func deleteMenu(_ menu: MenuItem) {
        withAnimation {
            viewContext.delete(menu)
        }
        viewContext.saveIfNeeded(reportingTo: saveErrorCenter)
    }
}
