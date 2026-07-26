import CloudKit
import SharedWithYou
import SwiftUI

/// 共有済みリストの参加者表示・管理(SWCollaborationView)をSwiftUIから使うためのラッパー。
/// タップで開くポップオーバーに、システム提供の管理画面へのManageボタンが付く。
struct CollaborationView: View {
    let share: CKShare
    let container: CKContainer

    var body: some View {
        // SWCollaborationViewはNSItemProviderを初期化時にしか受け取れず、
        // あとから差し替えられない。CKShareが更新されたらViewごと作り直して
        // 古いshareを握り続けないようにする。
        CollaborationViewRepresentable(share: share, container: container)
            .id(share.recordChangeTag ?? share.recordID.recordName)
    }
}

private struct CollaborationViewRepresentable: UIViewRepresentable {
    let share: CKShare
    let container: CKContainer

    func makeUIView(context: Context) -> SWCollaborationView {
        let itemProvider = NSItemProvider()
        itemProvider.registerCKShare(share, container: container, allowedSharingOptions: .standard)
        let view = SWCollaborationView(itemProvider: itemProvider)
        view.setShowManageButton(true)
        view.activeParticipantCount = share.participants.count
        // 固有サイズを持たないためツールバー内で広がってしまうのを防ぐ
        view.setContentHuggingPriority(.required, for: .horizontal)
        view.setContentCompressionResistancePriority(.required, for: .horizontal)
        return view
    }

    func updateUIView(_ uiView: SWCollaborationView, context: Context) {
        uiView.activeParticipantCount = share.participants.count
    }

    func sizeThatFits(
        _ proposal: ProposedViewSize,
        uiView: SWCollaborationView,
        context: Context
    ) -> CGSize {
        CGSize(width: 28, height: 28)
    }
}
