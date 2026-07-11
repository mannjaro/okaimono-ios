import SwiftUI
import CoreData

struct DetailView: View {
    let list: ShoppingList

    var body: some View {
        TabView {
            MenuItemList(list: list)
                .tabItem {
                    Label("献立", systemImage: "fork.knife")
                }

            CartView(list: list)
                .tabItem {
                    Label("買い物リスト", systemImage: "cart.fill")
                }
        }
    }
}

#Preview {
    NavigationStack {
        DetailView(list: {
            let context = PersistenceController.preview.container.viewContext
            return try! context.fetch(ShoppingList.fetchRequest()).first!
        }())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
