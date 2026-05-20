import UIKit
import SwiftUI

final class RootTabBarController: UITabBarController {
    init(deps: Dependencies, user: UserProfile, onLogout: @escaping () -> Void) {
        super.init(nibName: nil, bundle: nil)
        view.accessibilityIdentifier = A11y.Tabs.bar

        func tab<V: View>(_ view: V, title: String, system: String, id: String) -> UIViewController {
            let host = UIHostingController(rootView: view)
            host.tabBarItem = UITabBarItem(title: title, image: UIImage(systemName: system), tag: 0)
            host.tabBarItem.accessibilityIdentifier = id
            return host
        }

        viewControllers = [
            tab(CatalogView(deps: deps), title: Strings.Tabs.catalog, system: "square.grid.2x2", id: A11y.Tabs.catalog),
            tab(PromotionsView(deps: deps), title: Strings.Tabs.promotions, system: "tag", id: A11y.Tabs.promotions),
            tab(OrdersView(deps: deps), title: Strings.Tabs.orders, system: "clock", id: A11y.Tabs.orders),
            tab(CartView(deps: deps), title: Strings.Tabs.cart, system: "bag", id: A11y.Tabs.cart),
            tab(ProfileView(deps: deps, user: user, onLogout: onLogout), title: Strings.Tabs.profile, system: "person", id: A11y.Tabs.profile),
        ]
        tabBar.barTintColor = UIColor(AppColor.tabBar)
        tabBar.tintColor = .white
        tabBar.unselectedItemTintColor = UIColor(AppColor.inactive)
    }

    required init?(coder: NSCoder) { fatalError() }
}
