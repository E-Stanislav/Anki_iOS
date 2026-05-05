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
            return granted
        } catch {
            return false
        }
    }

    func scheduleDailyReminder(hour: Int, minute: Int) async -> Bool {
        let content = UNMutableNotificationContent()
        content.title = "AnkiFlow"
        content.body = "Time to review your flashcards!"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "daily-reminder-\(hour)-\(minute)",
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
        center.removeAllPendingNotificationRequests()
        return true
    }

    func cancelReminder(identifier: String) -> Bool {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        return true
    }
}
