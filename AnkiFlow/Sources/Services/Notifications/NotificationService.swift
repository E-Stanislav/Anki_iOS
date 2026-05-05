import Foundation
import UserNotifications

final class NotificationService {
    private let center = UNUserNotificationCenter.current()

    func isAuthorized() -> Bool {
        var authorized = false
        let semaphore = DispatchSemaphore(value: 0)
        center.getNotificationSettings { settings in
            authorized = settings.authorizationStatus == .authorized
            semaphore.signal()
        }
        semaphore.wait()
        return authorized
    }

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            print("[NotificationService] Permission result: \(granted)")
            return granted
        } catch {
            print("[NotificationService] Permission error: \(error)")
            return false
        }
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async -> Bool {
        print("[NotificationService] scheduleDailyReminder called with hour=\(hour), minute=\(minute)")

        let existingIdentifiers = ["daily-reminder"]
        center.removePendingNotificationRequests(withIdentifiers: existingIdentifiers)

        let content = UNMutableNotificationContent()
        content.title = "AnkiFlow"
        content.body = "Time to review your flashcards!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute
        dateComponents.second = 0
        dateComponents.timeZone = TimeZone.current

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily-reminder",
            content: content,
            trigger: trigger
        )

        print("[NotificationService] Creating notification with identifier 'daily-reminder', trigger at \(hour):\(minute) local time")

        do {
            try await center.add(request)
            print("[NotificationService] Notification scheduled successfully")
            return true
        } catch {
            print("[NotificationService] Failed to schedule notification: \(error)")
            return false
        }
    }

    func scheduleStreakReminder() async -> Bool {
        let content = UNMutableNotificationContent()
        content.title = "Keep your streak!"
        content.body = "Don't forget to study today"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = 18
        dateComponents.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "streak-reminder",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            return true
        } catch {
            return false
        }
    }

    func cancelAllReminders() -> Bool {
        print("[NotificationService] cancelAllReminders called")
        center.removeAllPendingNotificationRequests()
        return true
    }

    func cancelReminder(identifier: String) -> Bool {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        return true
    }

    func getPendingNotifications() async -> [UNNotificationRequest] {
        let pending = await center.pendingNotificationRequests()
        print("[NotificationService] Pending notifications count: \(pending.count)")
        for req in pending {
            print("[NotificationService] Pending: id=\(req.identifier), trigger=\(String(describing: req.trigger))")
        }
        return pending
    }
}
