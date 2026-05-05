import SwiftUI
import Combine

final class AppState: ObservableObject {
    @Published var hasCompletedOnboarding: Bool
    @Published var selectedTheme: AppTheme {
        didSet {
            UserDefaults.standard.set(selectedTheme.rawValue, forKey: "selectedTheme")
        }
    }
    @Published var currentUserId: UUID?

    private var cancellables = Set<AnyCancellable>()

    init() {
        self.hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
        self.selectedTheme = AppTheme(rawValue: UserDefaults.standard.string(forKey: "selectedTheme") ?? "system") ?? .system
        self.currentUserId = UserDefaults.standard.object(forKey: "currentUserId") as? UUID

        setupThemeObserver()
    }

    private func setupThemeObserver() {
        NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)
            .sink { [weak self] _ in
                guard let self = self else { return }
                let storedTheme = AppTheme(rawValue: UserDefaults.standard.string(forKey: "selectedTheme") ?? "system") ?? .system
                if self.selectedTheme != storedTheme {
                    self.selectedTheme = storedTheme
                }
            }
            .store(in: &cancellables)
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }

    func setTheme(_ theme: AppTheme) {
        selectedTheme = theme
    }

    func save() {
    }
}

enum AppTheme: String, CaseIterable {
    case light
    case dark
    case system

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }
}
