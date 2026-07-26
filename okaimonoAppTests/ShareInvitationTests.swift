import CloudKit
import CoreData
import Foundation
import Testing
@testable import okaimono_app

@MainActor
@Suite(.serialized)
struct ShareInvitationTests {

    /// 本物の CKShare.Metadata は生成できない(initが例外を投げる)ため、
    /// ShareInvitationMetadata プロトコル準拠のスタブでキュー動作を検証する。
    private struct StubMetadata: ShareInvitationMetadata {}

    @Test func invitationIsQueuedUntilStoresLoadThenAccepted() async throws {
        // Arrange: init直後はまだストア未ロード(完了ハンドラはMainActorのTask待ち)
        let persistence = PersistenceController(inMemory: true)
        var acceptedBatches: [[any ShareInvitationMetadata]] = []
        persistence.shareInvitationAcceptor = { metadata, _ in
            acceptedBatches.append(metadata)
        }

        // Act: ロード完了前に招待を受け取る
        persistence.acceptShareInvitation(StubMetadata())

        // Assert: まだ受け入れは実行されず、保留されている
        #expect(acceptedBatches.isEmpty)
        #expect(persistence.pendingShareMetadata.count == 1)

        // Act: ロード完了を待つ
        let didLoad = await waitUntilLoaded(persistence)
        try #require(didLoad)

        // Assert: 保留分がsharedストアへの受け入れに回り、キューが空になる
        #expect(persistence.pendingShareMetadata.isEmpty)
        #expect(acceptedBatches.count == 1)
        #expect(acceptedBatches.first?.count == 1)
    }

    @Test func invitationIsAcceptedImmediatelyWhenStoresAreLoaded() async throws {
        // Arrange
        let persistence = PersistenceController(inMemory: true)
        let didLoad = await waitUntilLoaded(persistence)
        try #require(didLoad)

        var acceptedBatches: [[any ShareInvitationMetadata]] = []
        persistence.shareInvitationAcceptor = { metadata, _ in
            acceptedBatches.append(metadata)
        }

        // Act
        persistence.acceptShareInvitation(StubMetadata())

        // Assert: 保留を経由せず即座に受け入れる
        #expect(persistence.pendingShareMetadata.isEmpty)
        #expect(acceptedBatches.count == 1)
    }

    private func waitUntilLoaded(
        _ controller: PersistenceController,
        timeoutIterations: Int = 300
    ) async -> Bool {
        for _ in 0..<timeoutIterations {
            if controller.isStoreLoaded {
                return true
            }
            if controller.storeLoadError != nil {
                return false
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
        return false
    }
}
