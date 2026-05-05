import UIKit
import UserNotifications

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        UNUserNotificationCenter.current().delegate = self

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

extension SceneDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("[NotificationService] willPresent notification: \(notification.request.identifier)")
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("[NotificationService] didReceive response for: \(response.notification.request.identifier)")
        completionHandler()
    }
}

extension Notification.Name {
    static let importAPKG = Notification.Name("importAPKG")
}
