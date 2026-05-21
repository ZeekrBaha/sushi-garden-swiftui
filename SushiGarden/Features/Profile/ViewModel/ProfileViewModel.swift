// SushiGarden/Features/Profile/ViewModel/ProfileViewModel.swift
import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    let user: UserProfile
    @Published private(set) var recentOrders: [Order] = []
    private let orders: OrderStore

    init(user: UserProfile, orders: OrderStore) {
        self.user = user
        self.orders = orders
    }

    func load() {
        recentOrders = (try? orders.allOrders()) ?? []
    }
}
