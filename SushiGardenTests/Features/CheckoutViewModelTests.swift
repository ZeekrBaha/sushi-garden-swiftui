import XCTest
@testable import SushiGarden

@MainActor
final class CheckoutViewModelTests: XCTestCase {
    private func filledCart() -> CartService {
        let c = CartService()
        c.add(Product(id: "la", name: "Лос-Анджелес", category: .rolls, priceRub: 707,
                      weightGrams: 285, imageName: "product_la", description: ""))
        return c
    }
    func test_summaryMath() {
        let vm = CheckoutViewModel(cart: filledCart(), orders: OrderStore(inMemory: true))
        XCTAssertEqual(vm.cartTotal, 707)
        XCTAssertEqual(vm.deliveryFee, 76)
        XCTAssertEqual(vm.serviceFee, 76)
        XCTAssertEqual(vm.total, 707 + 76 + 76)
    }
    func test_confirmDisabled_untilContactValid() {
        let vm = CheckoutViewModel(cart: filledCart(), orders: OrderStore(inMemory: true))
        XCTAssertFalse(vm.canConfirm)
        vm.name = "Саша"; vm.phone = "+7 900 123 45 67"; vm.email = "a@b.ru"
        XCTAssertTrue(vm.canConfirm)
    }
    func test_confirm_persistsOrder_andClearsCart() async throws {
        let cart = filledCart()
        let store = OrderStore(inMemory: true)
        let vm = CheckoutViewModel(cart: cart, orders: store)
        vm.name = "Саша"; vm.phone = "+7 900 123 45 67"; vm.email = "a@b.ru"
        await vm.confirm()
        XCTAssertTrue(cart.items.isEmpty)
        XCTAssertEqual(try store.allOrders().count, 1)
        XCTAssertTrue(vm.didConfirm)
    }
}
