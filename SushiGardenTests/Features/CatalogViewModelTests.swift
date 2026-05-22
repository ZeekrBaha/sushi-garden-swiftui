import XCTest
@testable import SushiGarden

@MainActor
final class CatalogViewModelTests: XCTestCase {
    func test_defaultsToRollsSelected() {
        let vm = CatalogViewModel(menu: MenuRepository(), cart: CartService())
        XCTAssertEqual(vm.selectedCategory, .rolls)
        XCTAssertFalse(vm.visibleProducts.isEmpty)
    }
    func test_selectingCategoryFiltersProducts() {
        let vm = CatalogViewModel(menu: MenuRepository(), cart: CartService())
        vm.select(.wok)
        XCTAssertTrue(vm.visibleProducts.allSatisfy { $0.category == .wok })
    }
    func test_addToCart_delegatesToService() {
        let cart = CartService()
        let vm = CatalogViewModel(menu: MenuRepository(), cart: cart)
        let p = vm.visibleProducts[0]
        vm.add(p)
        XCTAssertEqual(cart.quantity(of: p.id), 1)
    }
}
