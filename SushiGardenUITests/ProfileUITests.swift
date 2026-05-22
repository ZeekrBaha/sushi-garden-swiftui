// SushiGardenUITests/ProfileUITests.swift
import XCTest

final class ProfileUITests: XCTestCase {
    func test_logout_returnsToAuth() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
        app.launch()
        app.buttons["tab.profile"].tap()
        XCTAssertTrue(app.staticTexts["profile.name"].waitForExistence(timeout: 5))
        app.buttons["profile.logout"].tap()
        XCTAssertTrue(app.buttons["auth.submit"].waitForExistence(timeout: 5))
    }
}
