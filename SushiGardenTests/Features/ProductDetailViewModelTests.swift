// SushiGardenTests/Features/ProductDetailViewModelTests.swift
import XCTest
@testable import SushiGarden

@MainActor
final class ProductDetailViewModelTests: XCTestCase {
    private let p = Product(id: "hikari", name: "Хикари", category: .rolls, priceRub: 620,
                            weightGrams: 255, imageName: "product_hikari", description: "d")
    func test_quantityStartsAtOne_andSteps() {
        let vm = ProductDetailViewModel(product: p, cart: CartService())
        XCTAssertEqual(vm.quantity, 1)
        vm.increment()
        XCTAssertEqual(vm.quantity, 2)
        vm.decrement()
        vm.decrement()
        XCTAssertEqual(vm.quantity, 1) // floor at 1
    }
    func test_addToCart_addsQuantity() {
        let cart = CartService()
        let vm = ProductDetailViewModel(product: p, cart: cart)
        vm.increment()       // qty 2
        vm.addToCart()
        XCTAssertEqual(cart.quantity(of: "hikari"), 2)
    }
}
