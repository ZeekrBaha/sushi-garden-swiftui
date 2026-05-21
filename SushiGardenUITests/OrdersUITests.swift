import XCTest

final class OrdersUITests: XCTestCase {
    func test_placedOrderAppearsInOrdersTab() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
        app.launch()
        app.buttons["tab.catalog"].tap()
        app.buttons["catalog.card.la"].tap()
        app.buttons["detail.add"].tap()
        app.buttons["tab.cart"].tap()
        app.buttons["cart.checkout"].tap()
        app.textFields["checkout.name"].tap()
        app.typeText("Саша")
        app.textFields["checkout.phone"].tap()
        app.typeText("+79001234567")
        app.textFields["checkout.email"].tap()
        app.typeText("a@b.ru")
        app.buttons["checkout.confirm"].tap()
        _ = app.otherElements["tracking.courier"].waitForExistence(timeout: 8)
        app.buttons["tab.orders"].tap()
        XCTAssertTrue(app.otherElements["orders.list"].waitForExistence(timeout: 5))
    }
}
