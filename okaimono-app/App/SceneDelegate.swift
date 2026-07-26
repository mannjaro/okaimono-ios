import CloudKit
import UIKit

/// 共有リンク経由の招待(CKShare.Metadata)を受け取る入口。
final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    /// アプリが終了状態から共有リンクで起動されたとき
    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        if let metadata = connectionOptions.cloudKitShareMetadata {
            PersistenceController.shared.acceptShareInvitation(metadata)
        }
    }

    /// アプリ起動中に共有リンクを開いたとき
    func windowScene(
        _ windowScene: UIWindowScene,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        PersistenceController.shared.acceptShareInvitation(cloudKitShareMetadata)
    }
}
