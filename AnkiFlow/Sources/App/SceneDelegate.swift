import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        if let urlContext = connectionOptions.urlContexts.first {
            handleIncomingFile(url: urlContext.url)
        }
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let urlContext = URLContexts.first else { return }
        handleIncomingFile(url: urlContext.url)
    }

    private func handleIncomingFile(url: URL) {
        guard url.pathExtension.lowercased() == "apkg" else { return }
        NotificationCenter.default.post(
            name: .importAPKG,
            object: nil,
            userInfo: ["url": url]
        )
    }
}

extension Notification.Name {
    static let importAPKG = Notification.Name("importAPKG")
}
