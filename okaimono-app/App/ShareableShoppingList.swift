import CloudKit
import CoreTransferable

/// ShoppingList を ShareLink に渡すための Transferable ラッパー。
/// 未共有なら送信時に CKShare を遅延作成し、共有済みなら既存の share を使う。
nonisolated struct ShareableShoppingList: Transferable {
    let title: String
    let existingShare: CKShare?
    let container: CKContainer
    let prepareShare: @Sendable () async throws -> CKShare

    static var transferRepresentation: some TransferRepresentation {
        CKShareTransferRepresentation { shareable in
            if let share = shareable.existingShare {
                return .existing(share, container: shareable.container)
            }
            return .prepareShare(container: shareable.container) {
                try await shareable.prepareShare()
            }
        }
    }
}
