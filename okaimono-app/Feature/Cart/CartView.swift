import SwiftUI
import CoreData

struct CartView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    let list: ShoppingList
    
    @FetchRequest private var ingredients: FetchedResults<Ingredient>
    
    init(list: ShoppingList) {
        self.list = list
        _ingredients = FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Ingredient.isChecked, ascending: true),
                NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))
            ],
            predicate: NSPredicate(format: "menu.list == %@", list),
            animation: .default,
        )
    }
    
    var body: some View {
        List {
            Section("Buy") {
                ForEach(uncheckedIngredients) { item in
                    cartRow(for: item)
                }
            }
            if !checkedIngredients.isEmpty {
                Section("Bought") {
                    ForEach(checkedIngredients) { item in
                        cartRow(for: item)
                    }
                }
            }
        }
        .navigationTitle("Ingredients")
    }
    
    
    private var uncheckedIngredients: [Ingredient] {
        ingredients.filter { !$0.isChecked }
    }
    private var checkedIngredients: [Ingredient] {
        ingredients.filter { $0.isChecked }
    }
    
    private func cartRow(for item: Ingredient) -> some View {
        CartRow(item: item, onToggle: {
            withAnimation {
                item.toggleCheck()
                viewContext.saveIfNeeded()
            }
        })
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
