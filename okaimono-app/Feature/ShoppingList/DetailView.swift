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
                    item: makeShareable(existingShare: nil),
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

    private func makeShareable(existingShare: CKShare?) -> ShareableShoppingList {
        // prepareShareはシステムがメインスレッドを塞いだまま呼ぶことがあるため、
        // MainActorに依存する値はここで取り出し、closure内ではawaitでメインへ戻らない。
        let container = persistence.container
        let privateStore = persistence.privatePersistentStore
        let list = list
        let title = list.name ?? "お買い物リスト"
        return ShareableShoppingList(
            title: title,
            existingShare: existingShare,
            container: CKContainer(identifier: CloudKitConfiguration.containerIdentifier),
            prepareShare: {
                do {
                    print("[Share] prepare開始 objectID=\(list.objectID)")
                    if let existing = try container.fetchShares(matching: [list.objectID])[list.objectID] {
                        print("[Share] 既存の共有を返す url=\(existing.url?.absoluteString ?? "nil")")
                        return existing
                    }
                    print("[Share] 新規共有を作成中…")
                    let (_, share, _) = try await container.share([list], to: nil)
                    print("[Share] 作成完了 url=\(share.url?.absoluteString ?? "nil")")
                    share[CKShare.SystemFieldKey.title] = title
                    if let privateStore {
                        do {
                            _ = try await container.persistUpdatedShare(share, in: privateStore)
                            print("[Share] タイトル保存完了")
                        } catch {
                            // タイトルが保存できなくても共有自体は成立しているので続行する
                            print("[Share] タイトル保存失敗(続行): \(error)")
                        }
                    }
                    return share
                } catch {
                    print("[Share] 失敗: \(error)")
                    throw error
                }
            }
        )
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
