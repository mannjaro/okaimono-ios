import Foundation
import Observation

@Observable
final class SaveErrorCenter {
    var message: String?

    func present(_ error: Error) {
        message = "データの保存に失敗しました。\n\(error.localizedDescription)"
    }

    func dismiss() {
        message = nil
    }
}
