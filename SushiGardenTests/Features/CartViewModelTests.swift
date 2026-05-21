import XCTest
@testable import SushiGarden

@MainActor
final class CartViewModelTests: XCTestCase {
    private func seededCart() -> CartService {
        let c = CartService()
        c.add(Product(id: "la", name: "Лос-Анджелес", category: .rolls, priceRub: 707,
                      weightGrams: 285, imageName: "product_la", description: ""))
        return c
    }
    func test_exposesItemsAndTotals() {
        let vm = CartViewModel(cart: seededCart(), menu: MenuRepository())
        XCTAssertEqual(vm.items.count, 1)
        XCTAssertEqual(vm.subtotal, 707)
        XCTAssertEqual(vm.addOns.count, 3)
    }
    func test_incrementDecrement() {
        let cart = seededCart()
        let vm = CartViewModel(cart: cart, menu: MenuRepository())
        vm.increment(vm.items[0])
        XCTAssertEqual(cart.quantity(of: "la"), 2)
        vm.decrement(vm.items[0]); vm.decrement(cart.items[0])
        XCTAssertTrue(cart.items.isEmpty)
    }
    func test_grandTotal_includesAddOns() {
        let cart = seededCart()
        let vm = CartViewModel(cart: cart, menu: MenuRepository())
        vm.toggle(MenuRepository().addOns[0])     // +60
        XCTAssertEqual(vm.grandTotal, 767)
    }
}
