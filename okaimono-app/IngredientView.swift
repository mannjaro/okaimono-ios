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
                    TextField("材料を追加", text: $newName)
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
            .navigationTitle(menu.name ?? "材料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
            }
        }
    }

    private func toggleCheck(_ ingredient: Ingredient) {
        ingredient.isChecked.toggle()
        try? viewContext.save()
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
            try? viewContext.save()
        }
    }

    private func deleteIngredients(offsets: IndexSet) {
        withAnimation {
            offsets.map { ingredients[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
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
