// SushiGardenUITests/PromotionsUITests.swift
import XCTest

final class PromotionsUITests: XCTestCase {
    func test_showsBanners() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
        app.launch()
        app.buttons["tab.promotions"].tap()
        XCTAssertTrue(app.images["promo.b1"].waitForExistence(timeout: 5))
    }
}
