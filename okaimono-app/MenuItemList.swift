//
//  MenuItemList.swift
//  okaimono-app
//
//  Created by Takayuki Zukawa on 2026/06/28.
//

import SwiftUI
import CoreData

struct MenuItemList: View {
    @Environment(\.managedObjectContext) private var viewContext

    let list: ShoppingList

    @FetchRequest private var items: FetchedResults<MenuItem>

    @State private var newItemName = ""
    @State private var selectedMenu: MenuItem?
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
                MenuRow(
                    menu: menu,
                    isEditing: editingMenu == menu,
                    editingName: $editingName,
                    onBeginEditing: { beginEditing(menu) },
                    onCommit: commitEditing,
                    onShowIngredients: { selectedMenu = menu }
                )
            }
            .onDelete(perform: deleteItems)
            
            TextField("Add menu", text: $newItemName)
                .onSubmit(addMenu)
        }
        .navigationTitle(list.name ?? "List")
        .sheet(item: $selectedMenu) { menu in
            IngredientView(menu: menu)
        }
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

    private func deleteItems(at offsets: IndexSet) {
        viewContext.delete(items, at: offsets)
    }
}
