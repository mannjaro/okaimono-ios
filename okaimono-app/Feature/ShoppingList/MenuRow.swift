import SwiftUI

struct MenuRow: View {
    @ObservedObject var menu: MenuItem
    let isEditing: Bool
    @Binding var editingName: String
    let onBeginEditing: () -> Void
    let onCommit: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        if isEditing {
            TextField("Menu name", text: $editingName)
                .focused($isFocused)
                .onSubmit(onCommit)
                .onAppear { isFocused = true }
        } else {
            Text(menu.name ?? "")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(perform: onBeginEditing)
        }
    }
}
