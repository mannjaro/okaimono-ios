import SwiftUI
import CoreData

struct MenuItemList: View {
    @Environment(\.managedObjectContext) private var viewContext

    let list: ShoppingList

    @FetchRequest private var items: FetchedResults<MenuItem>

    @State private var newItemName = ""
    @State private var expandedMenuIDs: Set<NSManagedObjectID> = []
    @State private var editingMenu: MenuItem?
    @State private var editingName = ""

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
                DisclosureGroup(isExpanded: isExpanded(menu)) {
                    IngredientListContent(menu: menu)
                } label: {
                    MenuRow(
                        menu: menu,
                        isEditing: editingMenu == menu,
                        editingName: $editingName,
                        onBeginEditing: { beginEditing(menu) },
                        onCommit: commitEditing
                    )
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            deleteMenu(menu)
                        }
                    }
                }
            }
            TextField("Add menu", text: $newItemName)
                .onSubmit(addMenu)
        }
        .navigationTitle(list.name ?? "List")
    }

    private func isExpanded(_ menu: MenuItem) -> Binding<Bool> {
        Binding(
            get: { expandedMenuIDs.contains(menu.objectID) },
            set: { isExpanded in
                if isExpanded {
                    expandedMenuIDs.insert(menu.objectID)
                } else {
                    expandedMenuIDs.remove(menu.objectID)
                }
            }
        )
    }
    
    private func beginEditing(_ menu: MenuItem) {
        editingMenu = menu
        editingName = menu.name ?? ""
    }

    private func commitEditing() {
        editingMenu?.name = editingName
        editingMenu = nil
        viewContext.saveIfNeeded()
    }
    
    private func addMenu() {
        let name = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let menu = MenuItem(context: viewContext)
        menu.name = name
        menu.list = list

        newItemName = ""
        viewContext.saveIfNeeded()
    }

    private func deleteMenu(_ menu: MenuItem) {
        viewContext.delete(menu)
        viewContext.saveIfNeeded()
    }
}
