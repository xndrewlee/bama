import XCTest

/// Taps through the app like a person. Rename `__APP_NAME__` to the app's
/// name, and replace this flow with the story's.
final class AddItemUITests: XCTestCase {
    @MainActor
    func testAddItemShowsIt() throws {
        let app = XCUIApplication()
        // A fresh test store per run; UI tests never touch the app's real data.
        app.launchEnvironment["APP_STORE"] = "/tmp/__APP_NAME__-uitest-\(UUID().uuidString).store"
        app.launch()

        // On a compact width the sidebar comes first. Open the list.
        let allItems = app.buttons["All Items"]
        if allItems.waitForExistence(timeout: 5) { allItems.tap() }

        app.buttons["New Item"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["New Item"].firstMatch.waitForExistence(timeout: 5))
    }
}
