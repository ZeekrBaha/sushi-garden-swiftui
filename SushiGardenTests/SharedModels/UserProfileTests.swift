import XCTest
@testable import SushiGarden

final class UserProfileTests: XCTestCase {
    func test_init_storesFields() {
        let u = UserProfile(id: "u1", name: "Александр Новиков", email: "a@b.ru")
        XCTAssertEqual(u.id, "u1")
        XCTAssertEqual(u.name, "Александр Новиков")
        XCTAssertEqual(u.email, "a@b.ru")
    }
}
