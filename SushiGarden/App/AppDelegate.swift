// SushiGarden/App/AppDelegate.swift
import UIKit
import FirebaseCore

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        FontLoader.registerAll()
        let isUITest = ProcessInfo.processInfo.arguments.contains("-UITEST")
        // Only configure Firebase when a real plist is present and not under UI tests.
        if !isUITest, Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil {
            FirebaseApp.configure()
        }
        return true
    }
    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }
}
