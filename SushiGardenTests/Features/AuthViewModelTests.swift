import XCTest
@testable import SushiGarden

@MainActor
final class AuthViewModelTests: XCTestCase {
    func test_registerEnabled_whenFieldsAreValid() {
        let vm = AuthViewModel(auth: FakeAuthService(), mode: .register)
        vm.name = "Саша"; vm.email = "a@b.ru"; vm.password = "123456"
        vm.consent = true   // ← consent required for registration
        XCTAssertTrue(vm.canSubmit)
    }
    func test_loginDisabled_untilValid() {
        let vm = AuthViewModel(auth: FakeAuthService(), mode: .login)
        vm.email = "a@b.ru"; vm.password = "12345"
        XCTAssertFalse(vm.canSubmit)
        vm.password = "123456"
        XCTAssertTrue(vm.canSubmit)
    }
    func test_submit_success_setsAuthenticated() async {
        let vm = AuthViewModel(auth: FakeAuthService(), mode: .login)
        vm.email = "a@b.ru"; vm.password = "123456"
        await vm.submit()
        if case .authenticated = vm.state {} else { XCTFail("expected authenticated") }
    }
    func test_submit_failure_setsError() async {
        let vm = AuthViewModel(auth: FakeAuthService(shouldFail: true), mode: .login)
        vm.email = "a@b.ru"; vm.password = "123456"
        await vm.submit()
        if case .error = vm.state {} else { XCTFail("expected error") }
    }
    func test_register_disabled_whenConsentFalse() {
        let vm = AuthViewModel(auth: FakeAuthService(), mode: .register)
        vm.name = "Саша"; vm.email = "a@b.ru"; vm.password = "123456"
        // consent defaults to false — canSubmit must be false
        XCTAssertFalse(vm.canSubmit)
    }
    func test_register_canSubmit_togglesWithConsent() {
        let vm = AuthViewModel(auth: FakeAuthService(), mode: .register)
        vm.name = "Саша"; vm.email = "a@b.ru"; vm.password = "123456"
        XCTAssertFalse(vm.canSubmit, "should be false without consent")
        vm.consent = true
        XCTAssertTrue(vm.canSubmit, "should be true once consent is given")
    }
}
