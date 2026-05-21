import Foundation
import Combine

@MainActor
final class CartViewModel: ObservableObject {
    @Published private(set) var items: [CartItem] = []
    @Published private(set) var selectedAddOns: [AddOn] = []
    let addOns: [AddOn]
    private let cart: CartService
    private var bag = Set<AnyCancellable>()

    init(cart: CartService, menu: MenuRepository) {
        self.cart = cart
        self.addOns = menu.addOns
        cart.$items.assign(to: &$items)
        cart.$selectedAddOns.assign(to: &$selectedAddOns)
    }
    func increment(_ item: CartItem) { cart.add(item.product) }
    func decrement(_ item: CartItem) { cart.decrement(productID: item.id) }
    func toggle(_ addOn: AddOn) { cart.toggleAddOn(addOn) }
    func isSelected(_ addOn: AddOn) -> Bool { selectedAddOns.contains(addOn) }
    var subtotal: Int { cart.subtotal }
    var addOnsTotal: Int { cart.addOnsTotal }
    var grandTotal: Int { cart.subtotal + cart.addOnsTotal }
    var isEmpty: Bool { items.isEmpty }
}
