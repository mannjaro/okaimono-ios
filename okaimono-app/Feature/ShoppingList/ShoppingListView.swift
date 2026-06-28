import SwiftUI
import CoreData

struct ShoppingListView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ShoppingList.createdAt, ascending: false)],
        animation: .default
    )
    private var lists: FetchedResults<ShoppingList>

    @State private var isAddingList = false
    @State private var newListName = ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(lists) { list in
                    NavigationLink(destination: DetailView(list: list)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(list.name ?? "Unnamed list")
                                .font(.headline)
                        }
                    }
                }
                .onDelete(perform: deleteLists)
            }
            .navigationTitle("Shopping lists")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isAddingList = true } label: {
                        Label("Add list", systemImage: "plus")
                    }
                }
            }
            .alert("New list", isPresented: $isAddingList) {
                TextField("Name", text: $newListName)
                Button("Add") { addList() }
                Button("Cancel", role: .cancel) { newListName = "" }
            }
        }
    }

    private func addList() {
        guard !newListName.isEmpty else { return }
        withAnimation {
            let list = ShoppingList(context: viewContext)
            list.name = newListName
            viewContext.saveIfNeeded()
            newListName = ""
        }
    }

    private func deleteLists(offsets: IndexSet) {
        withAnimation {
            viewContext.delete(lists, at: offsets)
        }
    }
}

#Preview {
    ShoppingListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
