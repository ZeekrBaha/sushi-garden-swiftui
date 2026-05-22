import XCTest

final class CatalogUITests: XCTestCase {
    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
        app.launch()
        return app
    }

    func test_catalogShowsCardsAndSwitchesCategory() {
        let app = launch()
        app.buttons["tab.catalog"].tap()
        XCTAssertTrue(app.otherElements["catalog.grid"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["catalog.card.hikari"].exists)
        app.buttons["catalog.category.WOK"].tap()
        XCTAssertTrue(app.buttons["catalog.card.wok_udon"].waitForExistence(timeout: 3))
    }

    func test_addToCartFromCard_updatesCartBadgeFlow() {
        let app = launch()
        app.buttons["tab.catalog"].tap()
        app.buttons["catalog.card.hikari"].tap()   // opens detail
        app.buttons["detail.add"].tap()
        app.buttons["tab.cart"].tap()
        XCTAssertTrue(app.otherElements["cart.list"].waitForExistence(timeout: 5))
    }
}
