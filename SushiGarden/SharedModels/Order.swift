import Foundation
import SwiftData

@Model
final class OrderEntity {
    @Attribute(.unique) var id: String
    var createdAt: Date
    var totalRub: Int
    var linesData: Data           // encoded [OrderLine]
    init(id: String, createdAt: Date, totalRub: Int, linesData: Data) {
        self.id = id; self.createdAt = createdAt; self.totalRub = totalRub; self.linesData = linesData
    }
}

struct OrderLine: Codable, Equatable, Hashable {
    let name: String
    let quantity: Int
    let priceRub: Int
}

struct Order: Identifiable, Equatable {
    let id: String
    let createdAt: Date
    let totalRub: Int
    let lines: [OrderLine]
}
