import Foundation

@MainActor
final class CartService: ObservableObject {
    @Published private(set) var items: [CartItem] = []
    @Published private(set) var selectedAddOns: [AddOn] = []

    func add(_ product: Product) {
        if let idx = items.firstIndex(where: { $0.product.id == product.id }) {
            items[idx].quantity += 1
        } else {
            items.append(CartItem(product: product, quantity: 1))
        }
    }

    func decrement(productID: String) {
        guard let idx = items.firstIndex(where: { $0.product.id == productID }) else { return }
        if items[idx].quantity > 1 {
            items[idx].quantity -= 1
        } else {
            items.remove(at: idx)
        }
    }

    func setQuantity(productID: String, to qty: Int) {
        guard qty > 0 else { decrement(productID: productID); return }
        if let idx = items.firstIndex(where: { $0.product.id == productID }) {
            items[idx].quantity = qty
        }
    }

    func quantity(of productID: String) -> Int {
        items.first(where: { $0.product.id == productID })?.quantity ?? 0
    }

    func toggleAddOn(_ addOn: AddOn) {
        if let idx = selectedAddOns.firstIndex(where: { $0.id == addOn.id }) {
            selectedAddOns.remove(at: idx)
        } else {
            selectedAddOns.append(addOn)
        }
    }

    func clear() {
        items = []
        selectedAddOns = []
    }

    var subtotal: Int { items.reduce(0) { $0 + $1.lineTotal } }
    var addOnsTotal: Int { selectedAddOns.reduce(0) { $0 + $1.priceRub } }
    var total: Int { subtotal + addOnsTotal }
    var itemCount: Int { items.reduce(0) { $0 + $1.quantity } }
}
