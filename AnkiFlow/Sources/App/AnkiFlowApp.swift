import SwiftUI

@main
struct AnkiFlowApp: App {
    @StateObject private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            AppRootView(appState: appState)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background || phase == .inactive {
                appState.save()
            }
        }
    }
}

struct AppRootView: View {
    @ObservedObject var appState: AppState

    var body: some View {
        Group {
            if appState.hasCompletedOnboarding {
                MainTabView()
            } else {
                OnboardingView(appState: appState)
            }
        }
        .preferredColorScheme(appState.selectedTheme.colorScheme)
    }
}

final class NavigationState: ObservableObject {
    @Published var selectedTab: Tab = .home
    @Published var homePath: [HomeDestination] = []
    @Published var studyPath: [StudyDestination] = []

    enum Tab: String, CaseIterable {
        case home
        case study
        case create
        case stats
        case settings
    }

    enum HomeDestination: Hashable {
        case deck(UUID)
        case browse(UUID)
        case search
    }

    enum StudyDestination: Hashable {
        case session(UUID)
        case cardDetail(UUID)
    }
}
