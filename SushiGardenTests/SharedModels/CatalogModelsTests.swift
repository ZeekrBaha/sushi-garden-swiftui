import XCTest
@testable import SushiGarden

final class CatalogModelsTests: XCTestCase {
    func test_product_fields() {
        let p = Product(id: "hikari", name: "Хикари", category: .rolls,
                        priceRub: 620, weightGrams: 255, imageName: "product_hikari",
                        description: "Описание")
        XCTAssertEqual(p.priceRub, 620)
        XCTAssertEqual(p.category, .rolls)
    }

    func test_cartItem_lineTotal() {
        let p = Product(id: "x", name: "X", category: .rolls, priceRub: 100,
                        weightGrams: 10, imageName: "i", description: "")
        let item = CartItem(product: p, quantity: 3)
        XCTAssertEqual(item.lineTotal, 300)
    }
}
