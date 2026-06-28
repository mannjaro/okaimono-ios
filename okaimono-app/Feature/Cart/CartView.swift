import SwiftUI
import CoreData

struct CartView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let list: ShoppingList
    
    @FetchRequest private var ingredients: FetchedResults<Ingredient>
    
    init(list: ShoppingList) {
        self.list = list
        _ingredients = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Ingredient.createdAt, ascending: true)],
            predicate: NSPredicate(format: "menu.list == %@", list),
            animation: .default,
        )
    }
    
    var body: some View {
        ForEach (ingredients) { item in
            Text(item.name ?? "")
        }
    }
}

#Preview {
    NavigationStack {
        CartView(list: {
            let context = PersistenceController.preview.container.viewContext
            return try! context.fetch(ShoppingList.fetchRequest()).first!
        }())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
}
