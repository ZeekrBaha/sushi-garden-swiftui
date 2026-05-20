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
        let root = UIHostingController(
            rootView: RegisterView(deps: deps) { [weak self] user in
                DispatchQueue.main.async { self?.showMain(user) }
            }
        )
        window?.rootViewController = root
    }

    private func showMain(_ user: UserProfile) {
        window?.rootViewController = RootTabBarController(deps: deps, user: user) { [weak self] in
            try? self?.deps.auth.signOut()
            DispatchQueue.main.async { self?.showAuth() }
        }
    }
}
