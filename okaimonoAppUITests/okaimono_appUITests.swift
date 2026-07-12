import XCTest
import UIKit

final class okaimono_appUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    /// 起動〜リスト作成〜詳細タブ表示までのスモークテスト。
    /// 材料追加〜カート操作は Simulator 上の SwiftUI TextField 入力が不安定なため手動確認とする。
    @MainActor
    func testCreateListMenuIngredientAndToggleCart() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        let addListButton = app.buttons["add-list-button"]
        XCTAssertTrue(addListButton.waitForExistence(timeout: 8), "リスト追加ボタンが見つかりません")
        addListButton.tap()

        let nameField = app.textFields["名前"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3), "リスト名入力欄が見つかりません")
        enterText("UITestList", into: nameField, using: app)
        app.alerts.buttons["追加"].tap()

        let listRow = app.descendants(matching: .any)["shopping-list-row"].firstMatch
        XCTAssertTrue(listRow.waitForExistence(timeout: 5), "作成したリスト行が見つかりません")
        listRow.tap()

        XCTAssertTrue(app.tabBars.buttons["献立"].waitForExistence(timeout: 5), "献立タブが見つかりません")
        XCTAssertTrue(app.tabBars.buttons["買い物リスト"].exists, "買い物リストタブが見つかりません")
        XCTAssertTrue(app.textFields["add-menu-field"].waitForExistence(timeout: 5), "献立追加欄が見つかりません")

        app.tabBars.buttons["買い物リスト"].tap()
        XCTAssertTrue(
            app.staticTexts["買うものがありません"].waitForExistence(timeout: 5)
                || app.navigationBars["買い物リスト"].waitForExistence(timeout: 2),
            "買い物リスト画面へ遷移できません"
        )
    }

    @MainActor
    func testListAndMenuDeletionCanBeUndoneWithoutConfirmation() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-ui-testing"]
        app.launch()

        createList(named: "UndoList", in: app)

        let listRow = app.descendants(matching: .any)["shopping-list-row"].firstMatch
        XCTAssertTrue(listRow.waitForExistence(timeout: 5))
        listRow.swipeLeft()
        app.buttons["削除"].tap()

        let undoButton = app.buttons["undo-delete-button"]
        XCTAssertTrue(undoButton.waitForExistence(timeout: 3), "リスト削除後に取り消し操作が表示されません")
        XCTAssertFalse(app.alerts.firstMatch.exists, "削除確認ポップアップが表示されています")
        undoButton.tap()
        XCTAssertTrue(listRow.waitForExistence(timeout: 5), "取り消し後にリストが復元されません")

        listRow.tap()
        let menuField = app.textFields["add-menu-field"]
        XCTAssertTrue(menuField.waitForExistence(timeout: 5))
        enterText("UndoMenu", into: menuField, using: app)
        app.buttons["confirm-add-menu-button"].tap()

        let menuRow = app.descendants(matching: .any)["menu-row"].firstMatch
        XCTAssertTrue(menuRow.waitForExistence(timeout: 5))
        menuRow.swipeLeft()
        app.buttons["削除"].tap()

        XCTAssertTrue(undoButton.waitForExistence(timeout: 3), "献立削除後に取り消し操作が表示されません")
        XCTAssertFalse(app.alerts.firstMatch.exists, "削除確認ポップアップが表示されています")
        undoButton.tap()
        XCTAssertTrue(menuRow.waitForExistence(timeout: 5), "取り消し後に献立が復元されません")
    }

    @MainActor
    private func enterText(_ text: String, into field: XCUIElement, using app: XCUIApplication) {
        field.tap()
        UIPasteboard.general.string = text
        field.press(forDuration: 1.0)
        let paste = app.menuItems["Paste"].firstMatch
        if paste.waitForExistence(timeout: 2) {
            paste.tap()
            return
        }
        field.typeText(text)
    }

    @MainActor
    private func createList(named name: String, in app: XCUIApplication) {
        let addListButton = app.buttons["add-list-button"]
        XCTAssertTrue(addListButton.waitForExistence(timeout: 8))
        addListButton.tap()

        let nameField = app.textFields["名前"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        enterText(name, into: nameField, using: app)
        app.alerts.buttons["追加"].tap()
    }
}
