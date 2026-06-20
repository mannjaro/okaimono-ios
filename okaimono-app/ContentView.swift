//
//  ContentView.swift
//  okaimono-app
//
//  Created by Takayuki Zukawa on 2026/06/20.
//

import SwiftUI
import CoreData

struct ContentView: View {
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
                    NavigationLink(destination: ShoppingListDetailView(list: list)) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(list.name ?? "未名リスト")
                                .font(.headline)
                            let unchecked = list.uncheckedCount
                            let total = list.itemsArray.count
                            Text(total == 0 ? "商品なし" : "残り \(unchecked)/\(total) 品")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .onDelete(perform: deleteLists)
            }
            .navigationTitle("買い物リスト")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isAddingList = true } label: {
                        Label("リスト追加", systemImage: "plus")
                    }
                }
            }
            .alert("新しいリスト", isPresented: $isAddingList) {
                TextField("リスト名", text: $newListName)
                Button("追加") { addList() }
                Button("キャンセル", role: .cancel) { newListName = "" }
            }
        }
    }

    private func addList() {
        guard !newListName.isEmpty else { return }
        withAnimation {
            let list = ShoppingList(context: viewContext)
            list.id = UUID()
            list.name = newListName
            list.createdAt = Date()
            try? viewContext.save()
            newListName = ""
        }
    }

    private func deleteLists(offsets: IndexSet) {
        withAnimation {
            offsets.map { lists[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
