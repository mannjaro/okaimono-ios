import SwiftUI
import CoreData

struct MenuItemList: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(SaveErrorCenter.self) private var saveErrorCenter

    let list: ShoppingList

    @FetchRequest private var items: FetchedResults<MenuItem>

    @State private var newItemName = ""
    @State private var collapsedMenuIDs: Set<UUID> = []
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
            if items.isEmpty {
                ContentUnavailableView {
                    Label("献立がありません", systemImage: "fork.knife")
                } description: {
                    Text("下の入力欄から献立を追加できます。")
                }
                .listRowBackground(Color.clear)
            }

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
                        Button("削除", role: .destructive) {
                            deleteMenu(menu)
                        }
                    }
                }
                .accessibilityIdentifier("menu-row")
            }

            HStack {
                TextField("献立を追加", text: $newItemName)
                    .onSubmit(addMenu)
                    .accessibilityIdentifier("add-menu-field")

                Button("追加", action: addMenu)
                    .accessibilityIdentifier("confirm-add-menu-button")
            }
        }
        .navigationTitle(list.name ?? "リスト")
    }

    private func isExpanded(_ menu: MenuItem) -> Binding<Bool> {
        Binding(
            get: {
                guard let id = menu.id else { return true }
                return !collapsedMenuIDs.contains(id)
            },
            set: { isExpanded in
                guard let id = menu.id else { return }
                if isExpanded {
                    collapsedMenuIDs.remove(id)
                } else {
                    collapsedMenuIDs.insert(id)
                }
            }
        )
    }

    private func beginEditing(_ menu: MenuItem) {
        if editingMenu != nil, editingMenu != menu {
            commitEditing()
        }
        editingMenu = menu
        editingName = menu.name ?? ""
    }

    private func commitEditing() {
        guard let editingMenu else { return }
        let trimmed = editingName.trimmingCharacters(in: .whitespacesAndNewlines)
        editingMenu.name = trimmed.isEmpty ? editingMenu.name : trimmed
        self.editingMenu = nil
        viewContext.saveIfNeeded(reportingTo: saveErrorCenter)
    }

    private func addMenu() {
        let name = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let menu = MenuItem(context: viewContext)
        menu.name = name
        menu.list = list

        newItemName = ""
        viewContext.saveIfNeeded(reportingTo: saveErrorCenter)
    }

    private func deleteMenu(_ menu: MenuItem) {
        if editingMenu == menu {
            editingMenu = nil
        }
        if let id = menu.id {
            collapsedMenuIDs.remove(id)
        }
        withAnimation {
            viewContext.delete(menu)
            viewContext.saveIfNeeded(reportingTo: saveErrorCenter)
        }
    }
}
