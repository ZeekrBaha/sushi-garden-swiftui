import XCTest
@testable import SushiGarden

@MainActor
final class CartServiceTests: XCTestCase {
    private func product(_ id: String, _ price: Int) -> Product {
        Product(id: id, name: id, category: .rolls, priceRub: price,
                weightGrams: 1, imageName: "i", description: "")
    }
    func test_add_increasesQuantity() {
        let c = CartService()
        c.add(product("a", 100))
        c.add(product("a", 100))
        XCTAssertEqual(c.items.first?.quantity, 2)
    }
    func test_remove_decrementsAndDrops() {
        let c = CartService()
        c.add(product("a", 100))
        c.decrement(productID: "a")
        XCTAssertTrue(c.items.isEmpty)
    }
    func test_subtotal_andAddOns() {
        let c = CartService()
        c.add(product("a", 100))
        c.setQuantity(productID: "a", to: 2)  // 200
        c.toggleAddOn(AddOn(id: "wasabi", name: "Васаби", priceRub: 60))
        XCTAssertEqual(c.subtotal, 200)
        XCTAssertEqual(c.addOnsTotal, 60)
        XCTAssertEqual(c.total, 260)
    }
    func test_toggleAddOn_removesOnSecondTap() {
        let c = CartService()
        let ao = AddOn(id: "wasabi", name: "Васаби", priceRub: 60)
        c.toggleAddOn(ao)
        c.toggleAddOn(ao)
        XCTAssertEqual(c.addOnsTotal, 0)
    }
    func test_clear_emptiesCart() {
        let c = CartService()
        c.add(product("a", 100))
        c.toggleAddOn(AddOn(id: "wasabi", name: "Васаби", priceRub: 60))
        c.clear()
        XCTAssertTrue(c.items.isEmpty)
        XCTAssertTrue(c.selectedAddOns.isEmpty)
    }
    func test_itemCount() {
        let c = CartService()
        c.add(product("a", 100))
        c.add(product("b", 200))
        c.setQuantity(productID: "a", to: 3)
        XCTAssertEqual(c.itemCount, 4)
    }
}
