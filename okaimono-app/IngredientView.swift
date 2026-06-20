import SwiftUI
import CoreData

struct IngredientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let menu: MenuItem

    @FetchRequest private var ingredients: FetchedResults<Ingredient>

    @State private var isAdding = false
    @State private var newName = ""
    @State private var newQuantity = ""

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
                    HStack {
                        Image(systemName: ingredient.isChecked ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(ingredient.isChecked ? .green : .secondary)
                            .onTapGesture { toggleCheck(ingredient) }
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
                .onDelete(perform: deleteIngredients)
            }
            .navigationTitle(menu.name ?? "材料")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("閉じる") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isAdding = true } label: {
                        Label("追加", systemImage: "plus")
                    }
                }
            }
            .alert("材料を追加", isPresented: $isAdding) {
                TextField("材料名", text: $newName)
                TextField("量（任意）", text: $newQuantity)
                Button("追加") { addIngredient() }
                Button("キャンセル", role: .cancel) { resetForm() }
            }
        }
    }

    private func toggleCheck(_ ingredient: Ingredient) {
        ingredient.isChecked.toggle()
        try? viewContext.save()
    }

    private func resetForm() {
        newName = ""
        newQuantity = ""
    }

    private func addIngredient() {
        guard !newName.isEmpty else { return }
        let now = Date()
        withAnimation {
            let item = Ingredient(context: viewContext)
            item.id = UUID()
            item.name = newName
            item.quantity = newQuantity.isEmpty ? nil : newQuantity
            item.isChecked = false
            item.createdAt = now
            item.menu = menu
            try? viewContext.save()
            resetForm()
        }
    }

    private func deleteIngredients(offsets: IndexSet) {
        withAnimation {
            offsets.map { ingredients[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let menu = try! context.fetch(MenuItem.fetchRequest()).first!
    return IngredientView(menu: menu)
        .environment(\.managedObjectContext, context)
}
