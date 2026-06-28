import SwiftUI

struct MenuRow: View {
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
                TextField("Menu name", text: $editingName)
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
