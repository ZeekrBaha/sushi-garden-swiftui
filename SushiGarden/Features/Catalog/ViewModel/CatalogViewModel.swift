import Foundation

@MainActor
final class CatalogViewModel: ObservableObject {
    @Published var selectedCategory: Category = .rolls
    private let menu: MenuRepository
    private let cart: CartService

    init(menu: MenuRepository, cart: CartService) {
        self.menu = menu
        self.cart = cart
    }

    var categories: [Category] { Category.allCases }
    var visibleProducts: [Product] { menu.products(in: selectedCategory) }
    func select(_ c: Category) { selectedCategory = c }
    func add(_ p: Product) { cart.add(p) }
    func quantity(of p: Product) -> Int { cart.quantity(of: p.id) }
}
