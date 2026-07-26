import CloudKit
import SwiftUI
import CoreData

private struct ShareSheetItem: Identifiable {
    let share: CKShare
    let container: CKContainer
    var id: String { share.recordID.recordName }
}

struct DetailView: View {
    let list: ShoppingList
    @Environment(PersistenceController.self) private var persistence
    @State private var selectedTab = 0

    @State private var sharingStatus: CKSharingService.SharingStatus = .notShared
    @State private var isLoadingSharingStatus = true
    @State private var isPreparingShare = false
    @State private var shareSheetItem: ShareSheetItem?
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
        .sheet(item: $shareSheetItem, onDismiss: {
            Task { await refreshSharingStatus() }
        }) { item in
            CloudSharingView(share: item.share, container: item.container) {
                Task { await refreshSharingStatus() }
            }
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
        if isLoadingSharingStatus || isPreparingShare {
            ProgressView()
        } else {
            Button {
                Task { await presentSharingSheet() }
            } label: {
                switch sharingStatus {
                case .notShared:
                    Label("共有を開始", systemImage: "person.badge.plus")
                case .owner:
                    Label("共有を管理", systemImage: "person.2.fill")
                case .participant:
                    Label("共有情報", systemImage: "person.2")
                }
            }
            .accessibilityIdentifier("share-list-button")
        }
    }

    private func refreshSharingStatus() async {
        defer { isLoadingSharingStatus = false }
        do {
            sharingStatus = try sharingService.sharingStatus(for: list)
        } catch {
            sharingErrorMessage = "共有状態の取得に失敗しました。\n\(error.localizedDescription)"
        }
    }

    private func presentSharingSheet() async {
        isPreparingShare = true
        defer { isPreparingShare = false }
        do {
            let (share, container) = try await sharingService.fetchOrCreateShare(for: list)
            shareSheetItem = ShareSheetItem(share: share, container: container)
        } catch {
            sharingErrorMessage = "共有の準備に失敗しました。\n\(error.localizedDescription)"
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
