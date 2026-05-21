import Foundation

@MainActor
final class CheckoutViewModel: ObservableObject {
    @Published var name = ""
    @Published var phone = ""
    @Published var email = ""
    @Published private(set) var didConfirm = false

    private let cart: CartService
    private let orders: OrderStore

    init(cart: CartService, orders: OrderStore) {
        self.cart = cart
        self.orders = orders
    }

    let deliveryFee = 76
    let serviceFee = 76
    var subtotal: Int { cart.subtotal + cart.addOnsTotal }
    var total: Int { subtotal + deliveryFee + serviceFee }

    var canConfirm: Bool {
        !cart.items.isEmpty
            && FieldValidators.isNonEmpty(name)
            && FieldValidators.isValidPhone(phone)
            && FieldValidators.isValidEmail(email)
    }

    func confirm() async {
        guard canConfirm else { return }
        let lines = cart.items.map {
            OrderLine(name: $0.product.name, quantity: $0.quantity, priceRub: $0.product.priceRub)
        }
        let order = Order(id: UUID().uuidString, createdAt: Date(), totalRub: total, lines: lines)
        do {
            try orders.save(order)
            cart.clear()
            didConfirm = true
        } catch {
            didConfirm = false
        }
    }
}
