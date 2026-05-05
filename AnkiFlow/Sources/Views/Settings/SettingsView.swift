import SwiftUI

struct SettingsView: View {
    @State private var notificationsEnabled = true
    @State private var dailyGoal = 20
    @State private var swipeGesturesEnabled = true
    @AppStorage("selectedTheme") private var selectedTheme = "system"

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
                    Stepper("Daily Goal: \(dailyGoal)", value: $dailyGoal, in: 5...100, step: 5)

                    Toggle("Swipe Gestures", isOn: $swipeGesturesEnabled)

                    NavigationLink {
                        GestureSettingsView()
                    } label: {
                        Text("Customize Gestures")
                    }
                }

                Section("Notifications") {
                    Toggle("Daily Reminder", isOn: $notificationsEnabled)

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
                    } label: {
                        Text("Delete All Data")
                    }
                }
            }
            .navigationTitle("Settings")
        }
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
    @State private var notificationTime = Date()
    @AppStorage("streakNotifications") private var streakNotifications = true

    var body: some View {
        List {
            Section("Reminder Time") {
                DatePicker(
                    "Daily Reminder",
                    selection: $notificationTime,
                    displayedComponents: .hourAndMinute
                )
            }

            Section("Types") {
                Toggle("Streak Reminders", isOn: $streakNotifications)
            }
        }
        .navigationTitle("Notifications")
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
