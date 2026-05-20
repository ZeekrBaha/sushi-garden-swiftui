import XCTest

final class AuthFlowUITests: XCTestCase {
    func test_register_thenLandsOnCatalogTab() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST"]   // FakeAuth, not seeded -> starts on Auth screen
        app.launch()
        app.textFields["auth.name"].tap()
        app.typeText("Саша")
        app.textFields["auth.email"].tap()
        app.typeText("a@b.ru")
        app.secureTextFields["auth.password"].tap()
        app.typeText("123456")
        app.switches["auth.consent"].tap()
        app.buttons["auth.submit"].tap()
        XCTAssertTrue(app.otherElements["tabbar"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["tab.catalog"].exists)
    }

    func test_toggleToLogin() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST"]
        app.launch()
        app.buttons["auth.toggleMode"].tap()
        XCTAssertTrue(app.staticTexts["Войти"].exists)
    }
}
