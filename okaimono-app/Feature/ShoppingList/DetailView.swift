import CloudKit
import SwiftUI
import CoreData

struct DetailView: View {
    let list: ShoppingList
    @Environment(PersistenceController.self) private var persistence
    @Environment(\.scenePhase) private var scenePhase
    @State private var selectedTab = 0

    @State private var sharingStatus: CKSharingService.SharingStatus = .notShared
    @State private var isLoadingSharingStatus = true
    @State private var sharingErrorMessage: String?
    @State private var sharingUIObserver: CKSystemSharingUIObserver?

    private var sharingService: CKSharingService {
        CKSharingService(persistence: persistence)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            MenuItemList(list: list)
                .tabItem {
                    Label("献立", systemImage: "fork.knife")
                }
                .tag(0)

            CartView(list: list)
                .tabItem {
                    Label("買い物リスト", systemImage: "cart.fill")
                }
                .tag(1)
        }
        .toolbar {
            if selectedTab == 0 {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        ArchiveMenuList(list: list)
                    } label: {
                        Label("アーカイブ", systemImage: "archivebox")
                    }
                    .accessibilityIdentifier("archived-menus-button")
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                shareButton
            }
        }
        .task {
            configureSharingUIObserver()
            await refreshSharingStatus()
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await refreshSharingStatus() }
        }
        .alert(
            "共有エラー",
            isPresented: Binding(
                get: { sharingErrorMessage != nil },
                set: { if !$0 { sharingErrorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) { sharingErrorMessage = nil }
        } message: {
            Text(sharingErrorMessage ?? "")
        }
    }

    @ViewBuilder
    private var shareButton: some View {
        if isLoadingSharingStatus {
            ProgressView()
        } else {
            switch sharingStatus {
            case .notShared:
                ShareLink(
                    item: makeShareable(),
                    preview: SharePreview(list.name ?? "お買い物リスト")
                ) {
                    Label("共有を開始", systemImage: "person.badge.plus")
                }
                .accessibilityIdentifier("share-list-button")
            case .owner(let share, let container), .participant(let share, let container):
                CollaborationView(share: share, container: container)
                    .frame(width: 28, height: 28)
                    .accessibilityIdentifier("collaboration-button")
            }
        }
    }

    private func makeShareable() -> ShareableShoppingList {
        // prepareShareはシステムがメインスレッドを塞いだまま呼ぶことがあるため、
        // MainActorに依存するサービス生成はここで済ませ、closure内ではawaitでメインへ戻らない。
        let service = sharingService
        let objectID = list.objectID
        let title = list.name ?? "お買い物リスト"
        return ShareableShoppingList(
            container: CKContainer(identifier: CloudKitConfiguration.containerIdentifier),
            prepareShare: {
                do {
                    return try await service.fetchOrCreateShare(for: objectID, title: title).share
                } catch {
                    // ShareLinkはprepareShareの失敗をほとんど画面に出さないため、
                    // アプリ側でアラートに出したうえで再送出する。
                    Task { @MainActor in
                        sharingErrorMessage = "共有の作成に失敗しました。\n\(error.localizedDescription)"
                    }
                    throw error
                }
            },
            didPrepareShare: {
                // prepareShareが戻るまでメインスレッドが塞がれる場合があるため、
                // 完了を待たずにMainActorへ更新を予約する。
                Task { @MainActor in
                    await refreshSharingStatus()
                }
            }
        )
    }

    private func configureSharingUIObserver() {
        guard sharingUIObserver == nil else { return }

        let observer = CKSystemSharingUIObserver(
            container: CKContainer(identifier: CloudKitConfiguration.containerIdentifier)
        )
        observer.systemSharingUIDidSaveShareBlock = { _, result in
            Task { @MainActor in
                switch result {
                case .success(let share):
                    do {
                        guard let store = list.objectID.persistentStore else {
                            throw CKSharingService.SharingError.notSavedObject
                        }
                        // 戻り値のshareはchangeTagが最新なので、これで状態を更新する。
                        // 改めてfetchSharesし直す必要はない。
                        let updatedShare = try await sharingService.persistUpdatedShare(
                            share,
                            in: store
                        )
                        sharingStatus = sharingService.status(for: updatedShare)
                        isLoadingSharingStatus = false
                    } catch {
                        await handleSharingSaveError(
                            error,
                            message: "共有設定のローカル保存に失敗しました。"
                        )
                    }
                case .failure(let error):
                    await handleSharingSaveError(
                        error,
                        message: "共有設定の保存に失敗しました。"
                    )
                }
            }
        }
        observer.systemSharingUIDidStopSharingBlock = { _, result in
            Task { @MainActor in
                switch result {
                case .success:
                    await refreshSharingStatus()
                case .failure(let error):
                    sharingErrorMessage = "共有の停止に失敗しました。\n\(error.localizedDescription)"
                }
            }
        }
        sharingUIObserver = observer
    }

    /// 共有設定の保存エラーを処理する。
    /// 楽観ロック衝突は、同じzone shareへの書き込みが競合しただけで、
    /// 最新の共有を取り直せば回復するのでユーザーには見せない。
    private func handleSharingSaveError(_ error: Error, message: String) async {
        guard isRecoverableShareConflict(error) else {
            sharingErrorMessage = "\(message)\n\(error.localizedDescription)"
            return
        }
        await refreshSharingStatus()
    }

    /// CloudKitの楽観ロック衝突(client oplock error)かどうか。
    private func isRecoverableShareConflict(_ error: Error) -> Bool {
        if let ckError = error as? CKError {
            if ckError.code == .serverRecordChanged {
                return true
            }
            if ckError.code == .partialFailure,
               let partialErrors = ckError.partialErrorsByItemID,
               !partialErrors.isEmpty {
                return partialErrors.values.allSatisfy(isRecoverableShareConflict)
            }
            return false
        }
        // Core Data経由だとCKErrorがNSErrorに包まれてくることがある。
        let nsError = error as NSError
        if nsError.domain == CKError.errorDomain,
           nsError.code == CKError.Code.serverRecordChanged.rawValue {
            return true
        }
        return nsError.underlyingErrors.contains(where: isRecoverableShareConflict)
    }

    private func refreshSharingStatus() async {
        defer { isLoadingSharingStatus = false }
        do {
            sharingStatus = try sharingService.sharingStatus(for: list)
        } catch {
            sharingErrorMessage = "共有状態の取得に失敗しました。\n\(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        DetailView(list: {
            let context = PersistenceController.preview.container.viewContext
            return (try? context.fetch(ShoppingList.fetchRequest()).first)!
        }())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        .environment(SaveErrorCenter())
        .environment(PersistenceController.preview)
    }
}
