import SwiftUI
import CoreData

struct CartView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(SaveErrorCenter.self) private var saveErrorCenter

    let list: ShoppingList

    @FetchRequest private var ingredients: FetchedResults<Ingredient>

    init(list: ShoppingList) {
        self.list = list
        _ingredients = FetchRequest(
            sortDescriptors: [
                NSSortDescriptor(keyPath: \Ingredient.isChecked, ascending: true),
                NSSortDescriptor(key: "name", ascending: true, selector: #selector(NSString.localizedStandardCompare(_:)))
            ],
            predicate: NSPredicate(format: "menu.list == %@", list),
            animation: .default
        )
    }

    var body: some View {
        Group {
            if ingredients.isEmpty {
                ContentUnavailableView {
                    Label("買うものがありません", systemImage: "cart")
                } description: {
                    Text("献立タブで材料を追加すると、ここに買い物リストが表示されます。")
                }
            } else {
                List {
                    Section("未購入") {
                        if buyGroups.isEmpty {
                            Text("未購入の材料はありません")
                                .foregroundStyle(.secondary)
                        } else {
                            ForEach(buyGroups) { group in
                                cartRow(for: group)
                            }
                        }
                    }
                    Section("購入済み") {
                        ForEach(boughtGroups) { group in
                            cartRow(for: group)
                        }
                    }
                }
            }
        }
        .navigationTitle("買い物リスト")
    }

    private var buyGroups: [CartIngredientGroup] {
        CartIngredientGroup.makeGroups(from: Array(ingredients))
            .filter { !$0.isChecked }
    }

    private var boughtGroups: [CartIngredientGroup] {
        CartIngredientGroup.makeGroups(from: Array(ingredients))
            .filter(\.isChecked)
    }

    private func cartRow(for group: CartIngredientGroup) -> some View {
        CartRow(group: group) {
            withAnimation {
                group.setChecked(!group.isChecked)
                viewContext.saveIfNeeded(reportingTo: saveErrorCenter)
            }
        }
    }
}

struct CartRow: View {
    let group: CartIngredientGroup
    let onToggle: () -> Void

    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: group.isChecked ? "checkmark.circle.fill" : "circle")
                Text(group.displayName)
                Spacer()
                Text(group.displayQuantity)
                    .foregroundStyle(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(group.displayName)
        .accessibilityValue(group.isChecked ? "購入済み" : "未購入")
        .accessibilityHint("ダブルタップで購入状態を切り替え")
        .accessibilityIdentifier("cart-row")
    }
}

#Preview {
    NavigationStack {
        CartView(list: {
            let context = PersistenceController.preview.container.viewContext
            return (try? context.fetch(ShoppingList.fetchRequest()).first)!
        }())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environment(SaveErrorCenter())
    }
}
