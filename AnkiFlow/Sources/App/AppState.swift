import SwiftUI
import Combine

final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var selectedTheme: AppTheme
    @Published var currentUserId: UUID?

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.selectedTheme = AppTheme(rawValue: UserDefaults.standard.string(forKey: "selectedTheme") ?? "system") ?? .system
        self.currentUserId = UserDefaults.standard.object(forKey: "currentUserId") as? UUID
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    func setTheme(_ theme: AppTheme) {
        selectedTheme = theme
        UserDefaults.standard.set(theme.rawValue, forKey: "selectedTheme")
    }

    func save() {
    }
}

enum AppTheme: String, CaseIterable {
    case light
    case dark
    case system
}
