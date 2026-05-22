import XCTest

final class CartUITests: XCTestCase {
    func test_addItem_thenSeeItInCart_andCheckoutEnabled() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
        app.launch()
        app.buttons["tab.catalog"].tap()
        app.buttons["catalog.card.la"].tap()
        app.buttons["detail.add"].tap()
        app.buttons["tab.cart"].tap()
        XCTAssertTrue(app.otherElements["cart.list"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Лос-Анджелес"].exists)
        XCTAssertTrue(app.buttons["cart.checkout"].isEnabled)
    }
}
