import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            StudyTabView()
                .tabItem {
                    Label("Study", systemImage: "rectangle.stack")
                }

            CreateTabView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle")
                }

            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct StudyTabView: View {
    var body: some View {
        NavigationStack {
            StudyHomeView()
        }
    }
}

struct CreateTabView: View {
    var body: some View {
        NavigationStack {
            CreateHomeView()
        }
    }
}
