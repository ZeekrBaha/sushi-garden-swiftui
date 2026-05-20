import XCTest
@testable import SushiGarden

final class DependenciesTests: XCTestCase {
    func test_uiTestFlag_usesFakeAuth() {
        let deps = Dependencies(launchArguments: ["-UITEST"])
        XCTAssertTrue(deps.auth is FakeAuthService)
    }
    func test_default_usesFirebaseAuth() {
        let deps = Dependencies(launchArguments: [])
        XCTAssertTrue(deps.auth is FirebaseAuthService)
    }
    func test_uiTest_seedsSignedInUserWhenRequested() {
        let deps = Dependencies(launchArguments: ["-UITEST", "-SEEDED_AUTH"])
        XCTAssertNotNil(deps.auth.currentUser)
    }
}
