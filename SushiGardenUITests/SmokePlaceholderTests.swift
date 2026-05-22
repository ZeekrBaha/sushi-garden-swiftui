import XCTest
final class UISmokePlaceholderTests: XCTestCase {
    func test_launch() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertEqual(app.state, .runningForeground)
    }
}
