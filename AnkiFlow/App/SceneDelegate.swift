import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = createTabBarController()
        window?.makeKeyAndVisible()
    }

    private func createTabBarController() -> UITabBarController {
        let tabBarController = UITabBarController()

        let decksNav = UINavigationController(rootViewController: DeckListViewController())
        decksNav.tabBarItem = UITabBarItem(
            title: "Decks",
            image: UIImage(systemName: "rectangle.stack"),
            selectedImage: UIImage(systemName: "rectangle.stack.fill")
        )

        let statsNav = UINavigationController(rootViewController: StatisticsViewController())
        statsNav.tabBarItem = UITabBarItem(
            title: "Statistics",
            image: UIImage(systemName: "chart.bar"),
            selectedImage: UIImage(systemName: "chart.bar.fill")
        )

        let settingsNav = UINavigationController(rootViewController: SettingsViewController())
        settingsNav.tabBarItem = UITabBarItem(
            title: "Settings",
            image: UIImage(systemName: "gearshape"),
            selectedImage: UIImage(systemName: "gearshape.fill")
        )

        tabBarController.viewControllers = [decksNav, statsNav, settingsNav]
        return tabBarController
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        handleIncomingFile(url: url)
    }

    private func handleIncomingFile(url: URL) {
        guard url.pathExtension.lowercased() == "apkg" else { return }

        let fileName = url.lastPathComponent
        let tempDir = FileManager.default.temporaryDirectory
        let destURL = tempDir.appendingPathComponent(fileName)

        try? FileManager.default.removeItem(at: destURL)
        try? FileManager.default.copyItem(at: url, to: destURL)

        NotificationCenter.default.post(
            name: .didReceiveApkgFile,
            object: nil,
            userInfo: ["url": destURL]
        )
    }
}

extension Notification.Name {
    static let didReceiveApkgFile = Notification.Name("didReceiveApkgFile")
}
