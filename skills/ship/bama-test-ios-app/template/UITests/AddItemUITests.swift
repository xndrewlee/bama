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

        // A compact width opens on the selected page's list. To open another
        // page, tap app.buttons["BackButton"] first, then the page.
        XCTAssertTrue(app.navigationBars["All Items"].waitForExistence(timeout: 5))

        app.buttons["New Item"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["New Item"].firstMatch.waitForExistence(timeout: 5))
    }
}
