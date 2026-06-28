import SwiftUI
import CoreData

struct IngredientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let menu: MenuItem

    @FetchRequest private var ingredients: FetchedResults<Ingredient>

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
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(ingredients) { ingredient in
                    IngredientRow(ingredient: ingredient) { toggleCheck(ingredient) }
                }
                .onDelete(perform: deleteIngredients)

                HStack {
                    TextField("Add ingredient", text: $newName)
                        .focused($focusedField, equals: .name)
                        .onSubmit {
                            if newName.isEmpty { return }
                            focusedField = .quantity
                        }
                    TextField("量", text: $newQuantity)
                        .focused($focusedField, equals: .quantity)
                        .frame(width: 64)
                        .multilineTextAlignment(.trailing)
                        .foregroundColor(.secondary)
                        .onSubmit {
                            addIngredient()
                            focusedField = .name
                        }
                }
            }
            .navigationTitle(menu.name ?? "Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    private func toggleCheck(_ ingredient: Ingredient) {
        ingredient.isChecked.toggle()
        viewContext.saveIfNeeded()
    }

    private func addIngredient() {
        guard !newName.isEmpty else { return }
        let name = newName
        let qty = newQuantity.isEmpty ? nil : newQuantity
        newName = ""
        newQuantity = ""
        let now = Date()
        withAnimation {
            let item = Ingredient(context: viewContext)
            item.id = UUID()
            item.name = name
            item.quantity = qty
            item.isChecked = false
            item.createdAt = now
            item.menu = menu
            viewContext.saveIfNeeded()
        }
    }

    private func deleteIngredients(offsets: IndexSet) {
        withAnimation {
            viewContext.delete(ingredients, at: offsets)
        }
    }
}

private struct IngredientRow: View {
    @ObservedObject var ingredient: Ingredient
    let onToggle: () -> Void

    var body: some View {
        HStack {
            Image(systemName: ingredient.isChecked ? "checkmark.circle.fill" : "circle")
                .foregroundColor(ingredient.isChecked ? .green : .secondary)
                .onTapGesture { onToggle() }
            Text(ingredient.name ?? "")
                .strikethrough(ingredient.isChecked)
                .foregroundColor(ingredient.isChecked ? .secondary : .primary)
            Spacer()
            if let qty = ingredient.quantity, !qty.isEmpty {
                Text(qty)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let menu = try! context.fetch(MenuItem.fetchRequest()).first!
    return IngredientView(menu: menu)
        .environment(\.managedObjectContext, context)
}
