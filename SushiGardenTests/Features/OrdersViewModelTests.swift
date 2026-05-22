// SushiGardenTests/Features/OrdersViewModelTests.swift
import XCTest
@testable import SushiGarden

@MainActor
final class OrdersViewModelTests: XCTestCase {
    func test_loadsOrders() throws {
        let store = OrderStore(inMemory: true)
        try store.save(Order(id: "o1", createdAt: Date(), totalRub: 1699,
                             lines: [OrderLine(name: "Хикари", quantity: 1, priceRub: 620)]))
        let vm = OrdersViewModel(orders: store)
        vm.load()
        XCTAssertEqual(vm.orders.count, 1)
        XCTAssertFalse(vm.isEmpty)
    }

    func test_emptyState() {
        let vm = OrdersViewModel(orders: OrderStore(inMemory: true))
        vm.load()
        XCTAssertTrue(vm.isEmpty)
    }
}
