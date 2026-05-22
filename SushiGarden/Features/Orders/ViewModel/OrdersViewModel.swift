// SushiGarden/Features/Orders/ViewModel/OrdersViewModel.swift
import Combine
import Foundation

@MainActor
final class OrdersViewModel: ObservableObject {
    @Published private(set) var orders: [Order] = []
    private let store: OrderStore
    private var cancellable: AnyCancellable?

    init(orders: OrderStore) {
        self.store = orders
        // Reload whenever a new order is saved to the store.
        cancellable = orders.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.load() }
    }

    func load() {
        orders = (try? store.allOrders()) ?? []
    }

    var isEmpty: Bool { orders.isEmpty }
}
