import SwiftUI
import Foundation

struct PersistenceErrorView: View {
    let error: Error
    let onRetry: () -> Void
    let onReset: () -> Void

    @State private var isConfirmingReset = false

    var body: some View {
        ContentUnavailableView {
            Label("データを読み込めませんでした", systemImage: "exclamationmark.triangle")
        } description: {
            Text(Self.description(for: error))
        } actions: {
            VStack(spacing: 12) {
                Button("再試行", action: onRetry)
                    .buttonStyle(.borderedProminent)
                Button("ローカルデータをリセット", role: .destructive) {
                    isConfirmingReset = true
                }
            }
        }
        .padding()
        .confirmationDialog(
            "端末内のデータをリセットしますか？",
            isPresented: $isConfirmingReset,
            titleVisibility: .visible
        ) {
            Button("リセットして再作成", role: .destructive, action: onReset)
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("この端末でまだiCloudへ同期されていない変更は失われます。iCloud上のデータは削除されず、接続後に再同期されます。")
        }
    }
}

private extension PersistenceErrorView {
    static func description(for error: Error) -> String {
        let detail = error.localizedDescription
        if Self.isIncompatibleStore(error) {
            return """
            アプリのデータ形式が更新されたため、この端末の保存領域を開けませんでした。
            まず「再試行」を試し、続く場合は「ローカルデータをリセット」で端末内ストアを作り直してください。iCloud上のデータは削除されず、接続後に再同期されます。

            \(detail)
            """
        }
        return """
        買い物リストの保存領域を開けませんでした。端末の空き容量やiCloudの状態を確認してから、もう一度お試しください。

        \(detail)
        """
    }

    static func isIncompatibleStore(_ error: Error) -> Bool {
        let nsError = error as NSError
        if nsError.domain == NSCocoaErrorDomain,
           [134100, 134110, 134130].contains(nsError.code) {
            return true
        }
        let text = nsError.localizedDescription.lowercased()
        return text.contains("incompatible") || text.contains("モデル")
    }
}

#Preview {
    PersistenceErrorView(
        error: NSError(
            domain: "okaimono",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "プレビュー用のエラー"]
        ),
        onRetry: {},
        onReset: {}
    )
}
