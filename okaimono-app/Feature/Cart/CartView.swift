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
        List {
            ForEach(ingredients) { item in
                CartRow(
                    item: item,
                    onToggle: {
                        withAnimation {
                            item.toggleCheck()
                            viewContext.saveIfNeeded()
                        }
                    }
                )
            }
        }
        .navigationTitle("Ingredients")
    }
}

struct CartRow: View {
    @ObservedObject var item: Ingredient
    let onToggle: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
            Text(item.name ?? "")
            Spacer()
            Text(item.quantity ?? "")
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
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
