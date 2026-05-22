// SushiGarden/App/SceneDelegate.swift
import UIKit
import SwiftUI

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    private lazy var deps = Dependencies()

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        // Unit tests: skip full routing to avoid Firebase crash in test host.
        guard !Self.isUnitTest else {
            window.rootViewController = UIViewController()
            window.makeKeyAndVisible()
            return
        }
        if let user = deps.auth.currentUser {
            showMain(user)
        } else {
            showAuth()
        }
        window.makeKeyAndVisible()
    }

    private static var isUnitTest: Bool {
        // Present in unit test runs; absent in UI test runs and normal app runs.
        ProcessInfo.processInfo.environment["XCTestBundlePath"] != nil
            && !ProcessInfo.processInfo.arguments.contains("-UITEST")
    }

    private func showAuth() {
        let startMode: AuthViewModel.Mode = ProcessInfo.processInfo.arguments.contains("-AUTH_LOGIN")
            ? .login : .register
        let root = UIHostingController(
            rootView: AuthContainerView(
                vm: AuthViewModel(auth: self.deps.auth, mode: startMode),
                onAuthenticated: { [weak self] user in
                    DispatchQueue.main.async { self?.showMain(user) }
                }
            )
        )
        window?.rootViewController = root
    }

    private func showMain(_ user: UserProfile) {
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-SHOW_TRACKING") {
            window?.rootViewController = UIHostingController(
                rootView: NavigationStack { TrackingView(deps: deps) }
                    .tint(AppColor.accent))
            return
        }
        if args.contains("-SHOW_CHECKOUT") {
            let product = deps.menu.allProducts.first!
            deps.cart.add(product)
            window?.rootViewController = UIHostingController(
                rootView: NavigationStack { CheckoutView(deps: deps, total: deps.cart.total + 152) }
                    .tint(AppColor.accent))
            return
        }
        if args.contains("-SHOW_DETAIL") {
            let product = deps.menu.allProducts.first!
            window?.rootViewController = UIHostingController(
                rootView: NavigationStack { ProductDetailView(product: product, cart: deps.cart) }
                    .tint(AppColor.accent))
            return
        }
        if args.contains("-SEEDED_ORDERS") {
            let now = Date()
            let o1 = Order(id: "seed1", createdAt: now.addingTimeInterval(-3600),
                           totalRub: 1947,
                           lines: [OrderLine(name: "Хикари", quantity: 2, priceRub: 620),
                                   OrderLine(name: "Лос-Анджелес", quantity: 1, priceRub: 707)])
            let o2 = Order(id: "seed2", createdAt: now.addingTimeInterval(-86400),
                           totalRub: 740,
                           lines: [OrderLine(name: "Осака маки", quantity: 1, priceRub: 740)])
            try? deps.orders.save(o1)
            try? deps.orders.save(o2)
        }
        if args.contains("-SEEDED_CART") {
            deps.menu.allProducts.prefix(2).forEach { deps.cart.add($0) }
        }
        window?.rootViewController = RootTabBarController(deps: deps, user: user) { [weak self] in
            try? self?.deps.auth.signOut()
            DispatchQueue.main.async { self?.showAuth() }
        }
    }
}
