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
            let shouldFail = launchArguments.contains("-UITEST_AUTH_FAIL")
            self.auth = FakeAuthService(seeded: seeded, shouldFail: shouldFail)
            // Reset persisted UI state for clean test runs
            UserDefaults.standard.removeObject(forKey: "sg.profile.phone")
        } else {
            self.auth = FirebaseAuthService()
        }
        self.menu = menu
        self.cart = cart ?? CartService()
        self.orders = orders ?? OrderStore(inMemory: uiTest)
    }
}
