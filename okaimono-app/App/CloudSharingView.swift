import CloudKit
import SwiftUI
import UIKit

/// UICloudSharingController を SwiftUI から使うためのラッパー
struct CloudSharingView: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    var onStopSharing: (() -> Void)?

    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        // 招待制(allowPrivate) + 参加者は読み書き可能(allowReadWrite)。
        // アクセス方式と権限の両軸を指定しないと送信手段が表示されないことがある。
        controller.availablePermissions = [.allowPrivate, .allowReadWrite]
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ uiViewController: UICloudSharingController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(onStopSharing: onStopSharing)
    }

    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        private let onStopSharing: (() -> Void)?

        init(onStopSharing: (() -> Void)?) {
            self.onStopSharing = onStopSharing
        }

        func itemTitle(for csc: UICloudSharingController) -> String? {
            csc.share?[CKShare.SystemFieldKey.title] as? String
        }

        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) {
            print("共有の保存に失敗しました: \(error.localizedDescription)")
        }

        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) {
            onStopSharing?()
        }
    }
}
