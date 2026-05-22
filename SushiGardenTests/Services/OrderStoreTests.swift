// SushiGardenTests/Services/OrderStoreTests.swift
import XCTest
@testable import SushiGarden

@MainActor
final class OrderStoreTests: XCTestCase {
    func test_saveAndList() throws {
        let store = OrderStore(inMemory: true)
        let order = Order(id: "o1", createdAt: .init(timeIntervalSince1970: 0),
                          totalRub: 1699,
                          lines: [OrderLine(name: "Хикари", quantity: 2, priceRub: 620)])
        try store.save(order)
        let all = try store.allOrders()
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.totalRub, 1699)
        XCTAssertEqual(all.first?.lines.count, 1)
    }
    func test_ordersSortedNewestFirst() throws {
        let store = OrderStore(inMemory: true)
        try store.save(Order(id: "a", createdAt: .init(timeIntervalSince1970: 1), totalRub: 1, lines: []))
        try store.save(Order(id: "b", createdAt: .init(timeIntervalSince1970: 2), totalRub: 2, lines: []))
        XCTAssertEqual(try store.allOrders().first?.id, "b")
    }
}
