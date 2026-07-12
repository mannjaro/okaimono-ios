import SwiftUI
import CoreData

struct DetailView: View {
    let list: ShoppingList
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            MenuItemList(list: list)
                .tabItem {
                    Label("献立", systemImage: "fork.knife")
                }
                .tag(0)

            CartView(list: list)
                .tabItem {
                    Label("買い物リスト", systemImage: "cart.fill")
                }
                .tag(1)
        }
        .toolbar {
            if selectedTab == 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ArchiveMenuList(list: list)
                    } label: {
                        Label("アーカイブ", systemImage: "archivebox")
                    }
                    .accessibilityIdentifier("archived-menus-button")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        DetailView(list: {
            let context = PersistenceController.preview.container.viewContext
            return (try? context.fetch(ShoppingList.fetchRequest()).first)!
        }())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environment(SaveErrorCenter())
    }
}
