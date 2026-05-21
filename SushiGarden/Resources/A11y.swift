// SushiGarden/Resources/A11y.swift
enum A11y {
    enum Auth {
        static let nameField = "auth.name"
        static let emailField = "auth.email"
        static let passwordField = "auth.password"
        static let passwordVisibility = "auth.password.visibility"
        static let submit = "auth.submit"
        static let toggleMode = "auth.toggleMode"
        static let consentToggle = "auth.consent"
    }
    enum Tabs {
        static let bar = "tabbar"
        static let catalog = "tab.catalog"
        static let promotions = "tab.promotions"
        static let orders = "tab.orders"
        static let cart = "tab.cart"
        static let profile = "tab.profile"
    }
    enum Catalog {
        static let grid = "catalog.grid"
        static func card(_ id: String) -> String { "catalog.card.\(id)" }
        static func category(_ name: String) -> String { "catalog.category.\(name)" }
    }
    enum Detail {
        static let addToCart = "detail.add"
        static let stepperPlus = "detail.plus"
        static let stepperMinus = "detail.minus"
        static let quantity = "detail.qty"
    }
    enum Cart {
        static let list = "cart.list"
        static let checkout = "cart.checkout"
        static let total = "cart.total"
        static func addon(_ id: String) -> String { "cart.addon.\(id)" }
    }
    enum Checkout {
        static let name = "checkout.name"
        static let phone = "checkout.phone"
        static let email = "checkout.email"
        static let confirm = "checkout.confirm"
    }
    enum Tracking { static let map = "tracking.map"; static let courier = "tracking.courier" }
    enum Orders { static let list = "orders.list"; static let empty = "orders.empty" }
    enum Profile { static let logout = "profile.logout"; static let name = "profile.name" }
}
