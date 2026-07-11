import SwiftUI
import CoreData

struct IngredientListContent: View {
    @Environment(\.managedObjectContext) private var viewContext
    let menu: MenuItem

    @FetchRequest private var ingredients: FetchedResults<Ingredient>
    @FetchRequest private var allIngredients: FetchedResults<Ingredient>

    @State private var newName = ""
    @State private var newQuantity = ""
    @FocusState private var focusedField: Field?

    private enum Field { case name, quantity }

    init(menu: MenuItem) {
        self.menu = menu
        _ingredients = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Ingredient.createdAt, ascending: true)],
            predicate: NSPredicate(format: "menu == %@", menu),
            animation: .default
        )
        _allIngredients = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \Ingredient.createdAt, ascending: false)],
            animation: .default
        )
    }

    private var suggestions: [String] {
        guard focusedField == .name else { return [] }
        return IngredientNameSuggestions.suggestions(
            from: Array(allIngredients),
            matching: newName,
            excluding: ingredients.compactMap(\.name)
        )
    }

    var body: some View {
        ForEach(ingredients) { ingredient in
            IngredientRow(ingredient: ingredient)
        }

        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("Add ingredient", text: $newName)
                    .focused($focusedField, equals: .name)
                    .onSubmit {
                        addIngredient()
                        focusedField = .name
                    }
                TextField("qty.", text: $newQuantity)
                    .focused($focusedField, equals: .quantity)
                    .frame(width: 64)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.secondary)
                    .onSubmit {
                        addIngredient()
                        focusedField = .name
                    }
            }

            if !suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(suggestions, id: \.self) { name in
                            Button(name) {
                                newName = name
                                focusedField = .quantity
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func addIngredient() {
        guard !newName.isEmpty else { return }
        let name = newName
        let qty = newQuantity.isEmpty ? nil : newQuantity
        newName = ""
        newQuantity = ""
        withAnimation {
            let item = Ingredient(context: viewContext)
            item.name = name
            item.quantity = qty
            item.isChecked = false
            item.menu = menu
            viewContext.saveIfNeeded()
        }
    }
}

private struct IngredientRow: View {
    @Environment(\.managedObjectContext) private var viewContext

    @ObservedObject var ingredient: Ingredient

    var body: some View {
        HStack {
            TextField("", text: Binding(
                get: { ingredient.name ?? "" },
                set: { ingredient.name = $0 }
            ))
            Spacer()

            TextField("qty.", text: Binding(
                get: { ingredient.quantity ?? "" },
                set: { ingredient.quantity = $0.isEmpty ? nil : $0 }
            ))
            .frame(width: 64)
            .multilineTextAlignment(.trailing)
            .foregroundColor(.secondary)
            .onSubmit { viewContext.saveIfNeeded() }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                deleteIngredient(ingredient)
            }
        }
    }

    private func deleteIngredient(_ ingredient: Ingredient) {
        withAnimation {
            viewContext.delete(ingredient)
            viewContext.saveIfNeeded()
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let menu = try! context.fetch(MenuItem.fetchRequest()).first!
    return List {
        IngredientListContent(menu: menu)
    }
    .environment(\.managedObjectContext, context)
}
