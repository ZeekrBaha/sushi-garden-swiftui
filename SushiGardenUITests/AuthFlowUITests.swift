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
        app.buttons["auth.password.visibility"].tap()
        app.textFields["auth.password"].tap()
        app.typeText("123456")
        app.switches["auth.consent"].tap()
        let submit = app.buttons["auth.submit"]
        submit.tap()
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

    func test_login_failure_showsErrorMessage() {
        let app = XCUIApplication()
        // -AUTH_LOGIN opens the Login sheet; FakeAuthService.signIn (not signUp) throws .invalidCredentials
        // -UITEST_AUTH_FAIL makes FakeAuthService.signIn throw .invalidCredentials
        app.launchArguments = ["-UITEST", "-AUTH_LOGIN", "-UITEST_AUTH_FAIL"]
        app.launch()
        app.textFields["auth.email"].tap()
        app.typeText("a@b.ru")
        app.buttons["auth.password.visibility"].tap()
        app.textFields["auth.password"].tap()
        app.typeText("123456")
        XCTAssertTrue(app.buttons["auth.submit"].waitForExistence(timeout: 3))
        app.buttons["auth.submit"].tap()
        // FakeAuthService throws .invalidCredentials → AuthViewModel maps to this Russian string
        XCTAssertTrue(app.staticTexts["Неверная почта или пароль"].waitForExistence(timeout: 5))
    }

    func test_logout_returnsToAuthScreen() {
        let app = XCUIApplication()
        app.launchArguments = ["-UITEST", "-SEEDED_AUTH"]
        app.launch()
        app.buttons["tab.profile"].tap()
        XCTAssertTrue(app.buttons["profile.logout"].waitForExistence(timeout: 5))
        app.buttons["profile.logout"].tap()
        // After logout, auth screen (email field) must appear
        XCTAssertTrue(app.textFields["auth.email"].waitForExistence(timeout: 5))
    }
}
