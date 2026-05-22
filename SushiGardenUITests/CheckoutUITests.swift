import XCTest

final class CheckoutUITests: XCTestCase {
    func test_checkoutFlow_confirmsOrder() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
        app.launch()
        app.buttons["tab.catalog"].tap()
        XCTAssertTrue(app.buttons["catalog.card.la"].waitForExistence(timeout: 5))
        app.buttons["catalog.card.la"].tap()
        XCTAssertTrue(app.buttons["detail.add"].waitForExistence(timeout: 5))
        app.buttons["detail.add"].tap()
        app.buttons["tab.cart"].tap()
        XCTAssertTrue(app.buttons["cart.checkout"].waitForExistence(timeout: 5))
        app.buttons["cart.checkout"].tap()

        let nameField = app.textFields["checkout.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap(); app.typeText("Саша")
        app.textFields["checkout.phone"].tap(); app.typeText("+79001234567")
        app.textFields["checkout.email"].tap(); app.typeText("a@b.ru")
        nameField.tap() // dismiss keyboard

        XCTAssertTrue(app.buttons["checkout.confirm"].isEnabled,
                      "Confirm must be enabled after valid form entry")
        app.buttons["checkout.confirm"].tap()

        // Tracking view must appear after confirming
        XCTAssertTrue(app.otherElements["tracking.map"].waitForExistence(timeout: 10),
                      "TrackingView did not appear after checkout confirm")
    }
}
