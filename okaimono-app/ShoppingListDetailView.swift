import SwiftUI
import CoreData

struct ShoppingListDetailView: View {
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
        ZStack {
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
                
                TextField("献立を追加", text: $newItemName)
                    .onSubmit(addMenu)
            }
            .navigationTitle(list.name ?? "リスト")
            .sheet(item: $selectedMenu) { menu in
                IngredientView(menu: menu)
            }
            VStack {
                Spacer()
                NavigationLink(destination: CartView(list: list)) {
                    Image(systemName: "cart.fill")
                }
                .buttonStyle(.glassProminent)
                .padding()
            }
        }
    }

    // MARK: - Editing

    private func beginEditing(_ menu: MenuItem) {
        editingMenu = menu
        editingName = menu.name ?? ""
    }

    private func commitEditing() {
        editingMenu?.name = editingName
        editingMenu = nil
        save()
    }

    // MARK: - CRUD

    /// ※ 元コードに addMenu / deleteItems が無かったため一般的な実装で補完しています。
    ///   既存の実装があるならそちらを優先してください。
    private func addMenu() {
        let name = newItemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }

        let menu = MenuItem(context: viewContext)
        menu.name = name
        menu.createdAt = Date()
        menu.list = list

        newItemName = ""
        save()
    }

    private func deleteItems(at offsets: IndexSet) {
        offsets.map { items[$0] }.forEach(viewContext.delete)
        save()
    }

    private func save() {
        guard viewContext.hasChanges else { return }
        do {
            try viewContext.save()
        } catch {
            // 本番ではログ送信やユーザーへのエラー表示を検討
            print("Core Data save error: \(error)")
        }
    }
}

// MARK: - Row

private struct MenuRow: View {
    @ObservedObject var menu: MenuItem
    let isEditing: Bool
    @Binding var editingName: String
    let onBeginEditing: () -> Void
    let onCommit: () -> Void
    let onShowIngredients: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack {
            if isEditing {
                TextField("献立名", text: $editingName)
                    .focused($isFocused)
                    .onSubmit(onCommit)
                    .onAppear { isFocused = true }
            } else {
                Text(menu.name ?? "")
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onBeginEditing)
            }
            
            Button {
                onShowIngredients()
            } label: {
                Image(systemName: "pencil.line")
                    .frame(width: 24, height: 24)
            }
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
