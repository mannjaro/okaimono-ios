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
            TextField("献立名", text: $editingName)
                .focused($isFocused)
                .onSubmit(onCommit)
                .onAppear { isFocused = true }
                .onChange(of: isFocused) { _, focused in
                    if !focused {
                        onCommit()
                    }
                }
                .accessibilityIdentifier("menu-name-field")
        } else {
            Text(menu.name ?? "")
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
                .onTapGesture(perform: onBeginEditing)
                .accessibilityAddTraits(.isButton)
                .accessibilityHint("ダブルタップで名前を編集")
        }
    }
}
