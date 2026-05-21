import Foundation
import SwiftData

@MainActor
final class OrderStore {
    private let container: ModelContainer
    private var context: ModelContext { container.mainContext }

    init(inMemory: Bool = false) {
        let config = ModelConfiguration(isStoredInMemoryOnly: inMemory)
        // Force-try: a failed local store is unrecoverable and should crash early.
        container = try! ModelContainer(for: OrderEntity.self, configurations: config)
    }

    func save(_ order: Order) throws {
        let data = try JSONEncoder().encode(order.lines)
        context.insert(OrderEntity(id: order.id, createdAt: order.createdAt,
                                   totalRub: order.totalRub, linesData: data))
        try context.save()
    }

    func allOrders() throws -> [Order] {
        let descriptor = FetchDescriptor<OrderEntity>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)])
        return try context.fetch(descriptor).map { e in
            let lines = (try? JSONDecoder().decode([OrderLine].self, from: e.linesData)) ?? []
            return Order(id: e.id, createdAt: e.createdAt, totalRub: e.totalRub, lines: lines)
        }
    }
}
