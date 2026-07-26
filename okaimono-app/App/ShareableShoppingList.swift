import CloudKit
import CoreTransferable

/// ShoppingList を ShareLink に渡すための Transferable ラッパー。
/// 送信時に CKShare を遅延作成する。
nonisolated struct ShareableShoppingList: Transferable {
    let container: CKContainer
    let prepareShare: @Sendable () async throws -> CKShare
    let didPrepareShare: @Sendable () -> Void

    static var transferRepresentation: some TransferRepresentation {
        CKShareTransferRepresentation { shareable in
            return .prepareShare(container: shareable.container) {
                let share = try await shareable.prepareShare()
                shareable.didPrepareShare()
                return share
            }
        }
    }
}
