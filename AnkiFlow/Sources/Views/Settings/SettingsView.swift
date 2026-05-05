import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @AppStorage("dailyGoal") private var dailyGoal = 20
    @State private var swipeGesturesEnabled = true
    @AppStorage("selectedTheme") private var selectedTheme = "system"
    @StateObject private var notificationWrapper = NotificationServiceWrapper()
    @State private var showingDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                Section("Appearance") {
                    Picker("Theme", selection: $selectedTheme) {
                        Text("Light").tag(AppTheme.light.rawValue)
                        Text("Dark").tag(AppTheme.dark.rawValue)
                        Text("System").tag(AppTheme.system.rawValue)
                    }
                }

                Section("Study") {
                    Stepper("Daily Goal: \(dailyGoal) cards", value: $dailyGoal, in: 5...100, step: 5)

                    Toggle("Swipe Gestures", isOn: $swipeGesturesEnabled)

                    NavigationLink {
                        GestureSettingsView()
                    } label: {
                        Text("Customize Gestures")
                    }
                }

                Section("Notifications") {
                    Toggle("Daily Reminder", isOn: $notificationsEnabled)
                        .onChange(of: notificationsEnabled) { newValue in
                            if newValue {
                                notificationWrapper.requestPermissionAndSchedule()
                            } else {
                                notificationWrapper.cancelAll()
                            }
                        }

                    if notificationsEnabled {
                        NavigationLink {
                            NotificationSettingsView()
                        } label: {
                            Text("Notification Settings")
                        }
                    }
                }

                Section("Data") {
                    NavigationLink {
                        BackupView()
                    } label: {
                        Label("Backup & Export", systemImage: "square.and.arrow.up")
                    }

                    NavigationLink {
                        SyncSettingsView()
                    } label: {
                        Label("Sync", systemImage: "arrow.triangle.2.circlepath")
                    }
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }

                    Link(destination: URL(string: "https://ankiflow.app/privacy")!) {
                        Text("Privacy Policy")
                    }

                    Link(destination: URL(string: "https://ankiflow.app/terms")!) {
                        Text("Terms of Service")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Text("Delete All Data")
                    }
                }

                Section {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .alert("Delete All Data?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    deleteAllData()
                }
            } message: {
                Text("This will permanently delete all your decks and cards. This action cannot be undone.")
            }
        }
    }

    private func deleteAllData() {
        let deckRepo = DeckRepository()
        deckRepo.deleteAll()
        UserDefaults.standard.removeObject(forKey: "hasCompletedOnboarding")
    }
}

struct GestureSettingsView: View {
    @AppStorage("gestureSwipeRight") private var swipeRight = "easy"
    @AppStorage("gestureSwipeLeft") private var swipeLeft = "good"
    @AppStorage("gestureSwipeUp") private var swipeUp = "tag"
    @AppStorage("gestureLongPress") private var longPress = "edit"

    let options = ["easy", "good", "hard", "again"]

    var body: some View {
        List {
            Section("Swipe Right") {
                Picker("Action", selection: $swipeRight) {
                    ForEach(options, id: \.self) { option in
                        Text(option.capitalized).tag(option)
                    }
                }
            }

            Section("Swipe Left") {
                Picker("Action", selection: $swipeLeft) {
                    ForEach(options, id: \.self) { option in
                        Text(option.capitalized).tag(option)
                    }
                }
            }

            Section("Swipe Up") {
                Picker("Action", selection: $swipeUp) {
                    Text("Mark as Favorite").tag("tag")
                    Text("Suspend").tag("suspend")
                }
            }

            Section("Long Press") {
                Picker("Action", selection: $longPress) {
                    Text("Edit Card").tag("edit")
                    Text("More Actions").tag("more")
                }
            }
        }
        .navigationTitle("Gestures")
    }
}

struct NotificationSettingsView: View {
    @AppStorage("notificationTimeInterval") private var notificationTimeInterval: TimeInterval = 0
    @AppStorage("streakNotifications") private var streakNotifications = true
    @StateObject private var notificationService = NotificationServiceWrapper()
    @State private var notificationTime = Date()

    private var storedTime: Date {
        if notificationTimeInterval == 0 {
            return Date()
        }
        return Date(timeIntervalSince1970: notificationTimeInterval)
    }

    var body: some View {
        List {
            Section("Reminder Time") {
                DatePicker(
                    "Daily Reminder",
                    selection: $notificationTime,
                    displayedComponents: .hourAndMinute
                )
                .onChange(of: notificationTime) { _ in
                    notificationService.scheduleDaily(time: notificationTime)
                }
            }

            Section("Types") {
                Toggle("Streak Reminders", isOn: $streakNotifications)
            }
        }
        .navigationTitle("Notifications")
        .onAppear {
            notificationTime = storedTime
            notificationService.scheduleDaily(time: notificationTime)
        }
    }
}

@MainActor
final class NotificationServiceWrapper: ObservableObject {
    private let service = NotificationService()

    func scheduleDaily(time: Date) {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: time)
        let minute = calendar.component(.minute, from: time)
        let timeInterval = time.timeIntervalSince1970
        UserDefaults.standard.set(timeInterval, forKey: "notificationTimeInterval")
        print("[NotificationServiceWrapper] scheduleDaily saving interval=\(timeInterval), hour=\(hour), minute=\(minute)")
        Task {
            let result = await service.scheduleDailyReminder(hour: hour, minute: minute)
            print("[NotificationServiceWrapper] scheduleDaily result: \(result)")
            let pending = await service.getPendingNotifications()
            print("[NotificationServiceWrapper] Pending notifications after schedule: \(pending.count)")
        }
    }

    func requestPermissionAndSchedule() {
        Task {
            print("[NotificationServiceWrapper] requestPermissionAndSchedule called")
            let granted = await service.requestPermission()
            print("[NotificationServiceWrapper] permission granted: \(granted)")
            if granted {
                let interval = UserDefaults.standard.double(forKey: "notificationTimeInterval")
                let time = interval == 0 ? Date() : Date(timeIntervalSince1970: interval)
                print("[NotificationServiceWrapper] scheduling with interval: \(interval), time: \(time)")
                scheduleDaily(time: time)
            }
        }
    }

    func cancelAll() {
        _ = service.cancelAllReminders()
    }
}

struct BackupView: View {
    @State private var isExporting = false

    var body: some View {
        List {
            Section("Export") {
                Button {
                    exportData(format: "json")
                } label: {
                    Label("Export as JSON", systemImage: "doc.text")
                }

                Button {
                    exportData(format: "apkg")
                } label: {
                    Label("Export as .apkg", systemImage: "doc.zipper")
                }
            }

            Section("Import") {
                Button {
                } label: {
                    Label("Import from Backup", systemImage: "square.and.arrow.down")
                }
            }
        }
        .navigationTitle("Backup")
    }

    private func exportData(format: String) {
        isExporting = true
    }
}

struct SyncSettingsView: View {
    @State private var syncEnabled = false
    @State private var lastSync: Date?

    var body: some View {
        List {
            Section {
                Toggle("Enable Sync", isOn: $syncEnabled)
            }

            if syncEnabled {
                Section("Status") {
                    if let lastSync = lastSync {
                        HStack {
                            Text("Last Sync")
                            Spacer()
                            Text(lastSync, style: .relative)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button("Sync Now") {
                    }
                    .disabled(true)
                }

                Section("Server") {
                    Text("AnkiWeb (optional)")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Sync")
    }
}
