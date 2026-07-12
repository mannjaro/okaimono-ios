import SwiftUI
import CoreData

struct ShoppingListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(SaveErrorCenter.self) private var saveErrorCenter

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \ShoppingList.createdAt, ascending: false)],
        animation: .default
    )
    private var lists: FetchedResults<ShoppingList>

    @State private var isAddingList = false
    @State private var newListName = ""

    var body: some View {
        NavigationStack {
            Group {
                if lists.isEmpty {
                    ContentUnavailableView {
                        Label("買い物リストがありません", systemImage: "cart")
                    } description: {
                        Text("右上の＋から最初の買い物リストを作成できます。")
                    } actions: {
                        Button("リストを追加") {
                            isAddingList = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                } else {
                    List {
                        ForEach(lists) { list in
                            NavigationLink(destination: DetailView(list: list)) {
                                Text(list.name ?? "名前なしのリスト")
                                    .font(.headline)
                            }
                            .accessibilityIdentifier("shopping-list-row")
                        }
                        .onDelete(perform: deleteLists)
                    }
                }
            }
            .navigationTitle("買い物リスト")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !lists.isEmpty {
                        EditButton()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isAddingList = true
                    } label: {
                        Label("リストを追加", systemImage: "plus")
                    }
                    .accessibilityIdentifier("add-list-button")
                }
            }
            .alert("新しいリスト", isPresented: $isAddingList) {
                TextField("名前", text: $newListName)
                Button("追加") { addList() }
                Button("キャンセル", role: .cancel) { newListName = "" }
            }
        }
    }

    private func addList() {
        let name = newListName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        withAnimation {
            let list = ShoppingList(context: viewContext)
            list.name = name
            viewContext.saveIfNeeded(reportingTo: saveErrorCenter)
            newListName = ""
        }
    }

    private func deleteLists(offsets: IndexSet) {
        withAnimation {
            viewContext.delete(lists, at: offsets, reportingTo: saveErrorCenter)
        }
    }
}

#Preview {
    ShoppingListView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environment(SaveErrorCenter())
}
