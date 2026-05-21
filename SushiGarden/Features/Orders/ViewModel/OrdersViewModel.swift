// SushiGarden/Features/Orders/ViewModel/OrdersViewModel.swift
import Foundation

@MainActor
final class OrdersViewModel: ObservableObject {
    @Published private(set) var orders: [Order] = []
    private let store: OrderStore

    init(orders: OrderStore) {
        self.store = orders
    }

    func load() {
        orders = (try? store.allOrders()) ?? []
    }

    var isEmpty: Bool { orders.isEmpty }
}
