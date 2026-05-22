// SushiGardenUITests/ProfileUITests.swift
import XCTest

final class ProfileUITests: XCTestCase {
    func test_phone_fieldIsVisibleAndEditable() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
        app.launch()
        app.buttons["tab.profile"].tap()
        let phoneField = app.textFields["profile.phone"]
        XCTAssertTrue(phoneField.waitForExistence(timeout: 5),
                      "Phone text field must exist in ProfileView")
        phoneField.tap()
        app.typeText("+79001234567")
        XCTAssertEqual(phoneField.value as? String, "+79001234567")
    }

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
