import XCTest
@testable import SushiGarden

final class FakeAuthServiceTests: XCTestCase {
    func test_signUp_setsCurrentUser() async throws {
        let svc = FakeAuthService()
        let user = try await svc.signUp(email: "a@b.ru", password: "123456", name: "Саша")
        XCTAssertEqual(user.email, "a@b.ru")
        XCTAssertEqual(svc.currentUser?.name, "Саша")
    }
    func test_signIn_failsForUnknownWhenConfigured() async {
        let svc = FakeAuthService(shouldFail: true)
        do { _ = try await svc.signIn(email: "x@y.ru", password: "123456"); XCTFail("expected throw") }
        catch { XCTAssertTrue(error is AuthError) }
    }
    func test_signOut_clearsUser() async throws {
        let svc = FakeAuthService()
        _ = try await svc.signUp(email: "a@b.ru", password: "123456", name: "Саша")
        try svc.signOut()
        XCTAssertNil(svc.currentUser)
    }
    func test_seededSession_startsSignedIn() {
        let svc = FakeAuthService(seeded: UserProfile(id: "u1", name: "Александр Новиков", email: "a@b.ru"))
        XCTAssertNotNil(svc.currentUser)
    }
}
