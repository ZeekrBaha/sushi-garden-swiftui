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

    func test_emptyCart_checkoutButtonDisabled() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
        app.launch()
        app.buttons["tab.cart"].tap()
        // Wait for the button to render before checking its state
        XCTAssertTrue(app.buttons["cart.checkout"].waitForExistence(timeout: 5))
        // No items added — checkout button must be disabled
        XCTAssertFalse(app.buttons["cart.checkout"].isEnabled)
    }

    func test_stepperIncrement_updatesQuantity() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH", "-SEEDED_CART"]
        app.launch()
        app.buttons["tab.cart"].tap()
        XCTAssertTrue(app.otherElements["cart.list"].waitForExistence(timeout: 5))
        // Seeded cart has hikari (qty 1) and la (qty 1)
        let qtyLabel = app.staticTexts["cart.item.hikari.qty"]
        XCTAssertTrue(qtyLabel.waitForExistence(timeout: 3))
        XCTAssertEqual(qtyLabel.label, "1")
        app.buttons["cart.item.hikari.increment"].tap()
        let incrementExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == '2'"), object: qtyLabel)
        wait(for: [incrementExpectation], timeout: 3)

        app.buttons["cart.item.hikari.decrement"].tap()
        let decrementExpectation = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == '1'"), object: qtyLabel)
        wait(for: [decrementExpectation], timeout: 3)
    }

    func test_addonToggle_changesCheckoutButtonTotal() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH", "-SEEDED_CART"]
        app.launch()
        app.buttons["tab.cart"].tap()
        XCTAssertTrue(app.otherElements["cart.list"].waitForExistence(timeout: 5))
        let checkoutBtn = app.buttons["cart.checkout"]
        let labelBefore = checkoutBtn.label
        // Toggle wasabi add-on (60 ₽)
        XCTAssertTrue(app.buttons["cart.addon.wasabi"].waitForExistence(timeout: 3))
        app.buttons["cart.addon.wasabi"].tap()
        // Checkout button label embeds the total — it must change
        XCTAssertNotEqual(checkoutBtn.label, labelBefore)
    }
}
