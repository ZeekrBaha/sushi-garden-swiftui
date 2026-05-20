import XCTest
@testable import SushiGarden

@MainActor
final class AuthViewModelTests: XCTestCase {
    func test_registerDisabled_untilValidAndConsent() {
        let vm = AuthViewModel(auth: FakeAuthService(), mode: .register)
        vm.name = "Саша"; vm.email = "a@b.ru"; vm.password = "123456"
        XCTAssertFalse(vm.canSubmit)        // consent off
        vm.consent = true
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
}
