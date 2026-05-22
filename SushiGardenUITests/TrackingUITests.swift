import XCTest

final class TrackingUITests: XCTestCase {
    func test_trackingShowsCourierCard_afterCheckout() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
        app.launch()

        // Navigate to catalog and add item to cart
        app.buttons["tab.catalog"].tap()
        XCTAssertTrue(app.buttons["catalog.card.la"].waitForExistence(timeout: 5))
        app.buttons["catalog.card.la"].tap()
        XCTAssertTrue(app.buttons["detail.add"].waitForExistence(timeout: 5))
        app.buttons["detail.add"].tap()

        // Go to cart then checkout
        app.buttons["tab.cart"].tap()
        XCTAssertTrue(app.buttons["cart.checkout"].waitForExistence(timeout: 5))
        app.buttons["cart.checkout"].tap()

        // Fill checkout form fields
        let nameField = app.textFields["checkout.name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText("Саша")

        let phoneField = app.textFields["checkout.phone"]
        phoneField.tap()
        phoneField.typeText("+79001234567")

        let emailField = app.textFields["checkout.email"]
        emailField.tap()
        emailField.typeText("a@b.ru")

        // Tap name field to move focus away from email field
        nameField.tap()

        // Confirm button should now be enabled
        let confirmButton = app.buttons["checkout.confirm"]
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        XCTAssertTrue(confirmButton.isEnabled, "Confirm button must be enabled after valid form entry")
        confirmButton.tap()

        // TrackingView map should appear first
        XCTAssertTrue(app.otherElements["tracking.map"].waitForExistence(timeout: 10),
                      "TrackingView map did not appear after checkout confirm")

        // Courier card should also be visible
        XCTAssertTrue(app.otherElements["tracking.courier"].waitForExistence(timeout: 5),
                      "Courier card not found in TrackingView")
    }
}
