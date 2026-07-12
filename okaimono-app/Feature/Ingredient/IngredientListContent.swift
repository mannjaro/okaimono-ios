import SwiftUI
import CoreData

struct IngredientListContent: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(SaveErrorCenter.self) private var saveErrorCenter
    let menu: MenuItem

    @FetchRequest private var ingredients: FetchedResults<Ingredient>
    @FetchRequest private var allIngredients: FetchedResults<Ingredient>

    @State private var newName = ""
    @State private var newQuantity = ""
    @FocusState private var focusedField: Field?

    private enum Field {
        case name, quantity
    }

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
        if ingredients.isEmpty {
            Text("材料がありません。下から追加できます。")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .accessibilityIdentifier("empty-ingredients-label")
        }

        ForEach(ingredients) { ingredient in
            IngredientRow(
                ingredient: ingredient,
                onSave: {
                    viewContext.saveIfNeeded(reportingTo: saveErrorCenter)
                },
                onDelete: { deleteIngredient(ingredient) }
            )
        }

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("材料を追加", text: $newName)
                    .focused($focusedField, equals: .name)
                    .onSubmit {
                        addIngredient()
                        focusedField = .name
                    }
                    .accessibilityIdentifier("add-ingredient-name-field")
                TextField("分量", text: $newQuantity)
                    .focused($focusedField, equals: .quantity)
                    .frame(width: 64)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.secondary)
                    .onSubmit {
                        addIngredient()
                        focusedField = .name
                    }
                    .accessibilityIdentifier("add-ingredient-quantity-field")
            }

            Button("材料を追加する", action: addIngredient)
                .accessibilityIdentifier("confirm-add-ingredient-button")

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
        let name = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let qty = newQuantity.trimmingCharacters(in: .whitespacesAndNewlines)
        newName = ""
        newQuantity = ""
        withAnimation {
            let item = Ingredient(context: viewContext)
            item.name = name
            item.quantity = qty.isEmpty ? nil : qty
            item.isChecked = false
            item.menu = menu
            viewContext.saveIfNeeded(reportingTo: saveErrorCenter)
        }
    }

    private func deleteIngredient(_ ingredient: Ingredient) {
        withAnimation {
            viewContext.delete(ingredient)
            viewContext.saveIfNeeded(reportingTo: saveErrorCenter)
        }
    }
}

private struct IngredientRow: View {
    @ObservedObject var ingredient: Ingredient
    let onSave: () -> Void
    let onDelete: () -> Void

    @FocusState private var focusedField: Field?

    private enum Field {
        case name, quantity
    }

    var body: some View {
        HStack {
            TextField("材料名", text: Binding(
                get: { ingredient.name ?? "" },
                set: { ingredient.name = $0 }
            ))
            .focused($focusedField, equals: .name)
            .onSubmit(saveName)
            .accessibilityLabel("材料名")

            Spacer()

            TextField("分量", text: Binding(
                get: { ingredient.quantity ?? "" },
                set: { ingredient.quantity = $0.isEmpty ? nil : $0 }
            ))
            .focused($focusedField, equals: .quantity)
            .frame(width: 64)
            .multilineTextAlignment(.trailing)
            .foregroundColor(.secondary)
            .onSubmit(saveQuantity)
            .accessibilityLabel("分量")
        }
        .onChange(of: focusedField) { oldValue, newValue in
            if oldValue == .name && newValue != .name {
                saveName()
            }
            if oldValue == .quantity && newValue != .quantity {
                saveQuantity()
            }
        }
        .swipeActions(edge: .trailing) {
            Button("削除", role: .destructive, action: onDelete)
        }
        .accessibilityIdentifier("ingredient-row")
    }

    private func saveName() {
        let trimmed = (ingredient.name ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            ingredient.name = trimmed
        }
        onSave()
    }

    private func saveQuantity() {
        if let quantity = ingredient.quantity {
            let trimmed = quantity.trimmingCharacters(in: .whitespacesAndNewlines)
            ingredient.quantity = trimmed.isEmpty ? nil : trimmed
        }
        onSave()
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let menu = (try? context.fetch(MenuItem.fetchRequest()).first)!
    return List {
        IngredientListContent(menu: menu)
    }
    .environment(\.managedObjectContext, context)
    .environment(SaveErrorCenter())
}
