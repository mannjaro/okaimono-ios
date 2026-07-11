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
                ForEach(buyGroups) { group in
                    cartRow(for: group)
                }
            }
            if !boughtGroups.isEmpty {
                Section("Bought") {
                    ForEach(boughtGroups) { group in
                        cartRow(for: group)
                    }
                }
            }
        }
        .navigationTitle("買い物リスト")
    }
    
    
    private var buyGroups: [CartIngredientGroup] {
        CartIngredientGroup.makeGroups(from: Array(ingredients))
            .filter { !$0.isChecked }
    }
    
    private var boughtGroups: [CartIngredientGroup] {
        CartIngredientGroup.makeGroups(from: Array(ingredients))
            .filter(\.isChecked)
    }
    
    private func cartRow(for group: CartIngredientGroup) -> some View {
        CartRow(group: group, onToggle: {
            withAnimation {
                group.setChecked(!group.isChecked)
                viewContext.saveIfNeeded()
            }
        })
    }
}

struct CartRow: View {
    let group: CartIngredientGroup
    let onToggle: () -> Void
    var body: some View {
        HStack {
            Image(systemName: group.isChecked ? "checkmark.circle.fill" : "circle")
            Text(group.displayName)
            Spacer()
            Text(group.displayQuantity)
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
