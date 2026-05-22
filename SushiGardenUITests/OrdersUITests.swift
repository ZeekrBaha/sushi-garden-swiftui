import XCTest

final class OrdersUITests: XCTestCase {
    func test_seededOrder_canOpenDetail() {
        let app = XCUIApplication()
        // -SEEDED_ORDERS seeds two orders; -START_TAB=2 opens the Orders tab directly
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH", "-SEEDED_ORDERS", "-START_TAB=2"]
        app.launch()
        XCTAssertTrue(app.otherElements["orders.list"].waitForExistence(timeout: 5))
        // Tap the first order row
        let orderRow = app.buttons
            .matching(NSPredicate(format: "label BEGINSWITH 'Заказ №'"))
            .firstMatch
        XCTAssertTrue(orderRow.waitForExistence(timeout: 3))
        orderRow.tap()
        // OrderDetailView must appear with its list identifier
        XCTAssertTrue(app.otherElements["orders.detail.list"].waitForExistence(timeout: 5),
                      "OrderDetailView did not appear after tapping order row")
        // First seeded order contains "Хикари"
        XCTAssertTrue(
            app.staticTexts["Хикари"].waitForExistence(timeout: 3),
            "Expected 'Хикари' line in order detail"
        )
    }

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
        XCTAssertTrue(app.otherElements["tracking.courier"].waitForExistence(timeout: 8),
                      "Tracking view did not appear — order was likely not placed")
        app.buttons["tab.orders"].tap()
        XCTAssertTrue(app.otherElements["orders.list"].waitForExistence(timeout: 5))
        // Verify an actual order row (not just the container)
        let orderRow = app.staticTexts
            .matching(NSPredicate(format: "label BEGINSWITH 'Заказ №'"))
            .firstMatch
        XCTAssertTrue(orderRow.waitForExistence(timeout: 3),
                      "No order row found in orders list after placing an order")
    }
}
