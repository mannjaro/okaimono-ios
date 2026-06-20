import SwiftUI
import CoreData

struct ShoppingListDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let list: ShoppingList

    @FetchRequest private var items: FetchedResults<MenuItem>

    @State private var newItemName = ""
    @State private var selectedMenu: MenuItem?

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
                Button {
                    selectedMenu = menu
                } label: {
                    HStack {
                        Text(menu.name ?? "")
                            .foregroundColor(.primary)
                        Spacer()
                        if menu.uncheckedCount > 0 {
                            Text("\(menu.uncheckedCount)品")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            TextField("献立を追加", text: $newItemName)
                .onSubmit { addMenu() }
        }
        .navigationTitle(list.name ?? "リスト")
        .sheet(item: $selectedMenu) { menu in
            IngredientView(menu: menu)
        }
    }

    private func addMenu() {
        guard !newItemName.isEmpty else { return }
        let name = newItemName
        newItemName = ""
        withAnimation {
            let item = MenuItem(context: viewContext)
            item.id = UUID()
            item.name = name
            item.createdAt = Date()
            item.list = list
            try? viewContext.save()
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
