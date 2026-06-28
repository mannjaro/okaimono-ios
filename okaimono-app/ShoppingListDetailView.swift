import SwiftUI
import CoreData

struct ShoppingListDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext

    let list: ShoppingList

    var body: some View {
        ZStack {
            MenuItemList(list: list)
            VStack {
                Spacer()
                NavigationLink(destination: CartView(list: list)) {
                    Image(systemName: "cart.fill")
                }
                .buttonStyle(.glassProminent)
                .padding()
            }
        }
    }
}

#Preview {
    NavigationStack {
        ShoppingListDetailView(list: {
            let context = PersistenceController.preview.container.viewContext
            return try! context.fetch(ShoppingList.fetchRequest()).first!
        }())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
