import SwiftUI
import CoreData

struct ShoppingListDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let list: ShoppingList

    @FetchRequest private var items: FetchedResults<MenuItem>

    @State private var isAddingItem = false
    @State private var newItemName = ""

    init(list: ShoppingList) {
        self.list = list
        _items = FetchRequest(
            sortDescriptors: [NSSortDescriptor(keyPath: \MenuItem.createdAt, ascending: true)],
            predicate: NSPredicate(format: "list == %@", list),
            animation: .default
        )
    }

    var body: some View {
        List {
            ForEach(items) { menu in
                NavigationLink(destination: IngredientView(menu: menu)) {
                    Text(menu.name ?? "")
                }
            }
        }
        .navigationTitle(list.name ?? "リスト")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button { isAddingItem = true } label: {
                    Label("追加", systemImage: "plus")
                }
            }
        }
        .alert("商品を追加", isPresented: $isAddingItem) {
            TextField("商品名", text: $newItemName)
            Button("追加") { addMenu() }
            Button("キャンセル", role: .cancel) { newItemName = "" }
        }
    }

    private func addMenu() {
        guard !newItemName.isEmpty else { return }
        withAnimation {
            let item = MenuItem(context: viewContext)
            item.id = UUID()
            item.name = newItemName
            item.createdAt = Date()
            item.list = list
            try? viewContext.save()
            newItemName = ""
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            offsets.map { items[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
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
