// SushiGardenTests/Features/ProfileViewModelTests.swift
import XCTest
@testable import SushiGarden

@MainActor
final class ProfileViewModelTests: XCTestCase {
    func test_exposesUserAndRecentOrders() throws {
        let store = OrderStore(inMemory: true)
        try store.save(Order(id: "o1", createdAt: Date(), totalRub: 100, lines: []))
        let user = UserProfile(id: "u1", name: "Александр Новиков", email: "a@b.ru")
        let vm = ProfileViewModel(user: user, orders: store)
        vm.load()
        XCTAssertEqual(vm.user.name, "Александр Новиков")
        XCTAssertEqual(vm.recentOrders.count, 1)
    }
}
