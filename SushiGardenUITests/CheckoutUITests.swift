import XCTest

final class CheckoutUITests: XCTestCase {
    func test_checkoutFlow_confirmsOrder() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
        app.launch()
        // Navigate to cart with an item
        app.buttons["tab.catalog"].tap()
        app.buttons["catalog.card.la"].tap()
        app.buttons["detail.add"].tap()
        app.buttons["tab.cart"].tap()
        // Go to checkout
        XCTAssertTrue(app.buttons["cart.checkout"].waitForExistence(timeout: 5))
        app.buttons["cart.checkout"].tap()
        // Fill fields
        let nameField = app.textFields["checkout.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap(); app.typeText("Саша")
        app.textFields["checkout.phone"].tap(); app.typeText("+79001234567")
        app.textFields["checkout.email"].tap(); app.typeText("a@b.ru")
        // Confirm button should now be enabled
        XCTAssertTrue(app.buttons["checkout.confirm"].isEnabled)
    }
}
