import Foundation

@MainActor
final class Dependencies {
    let auth: AuthService
    let menu: MenuRepository
    let cart: CartService
    let orders: OrderStore
    let isUITest: Bool

    init(launchArguments: [String] = ProcessInfo.processInfo.arguments,
         menu: MenuRepository = MenuRepository(),
         cart: CartService? = nil,
         orders: OrderStore? = nil) {
        let uiTest = launchArguments.contains("-UITEST")
        self.isUITest = uiTest
        if uiTest {
            let seeded = launchArguments.contains("-SEEDED_AUTH")
                ? UserProfile(id: "u1", name: "Александр Новиков", email: "a@b.ru") : nil
            self.auth = FakeAuthService(seeded: seeded)
        } else {
            self.auth = FirebaseAuthService()
        }
        self.menu = menu
        self.cart = cart ?? CartService()
        self.orders = orders ?? OrderStore(inMemory: uiTest)
    }
}

// TEMP-STUB: replaced in Task 3.1
final class OrderStore {
    init(inMemory: Bool = false) {}
}
