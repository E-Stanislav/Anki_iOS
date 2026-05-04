import SwiftUI

struct OnboardingView: View {
    @ObservedObject var appState: AppState
    @State private var currentPage = 0

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                OnboardingPageView(
                    title: "Welcome to AnkiFlow",
                    subtitle: "Master any subject with spaced repetition",
                    imageName: "brain.head.profile",
                    description: "AnkiFlow helps you remember anything efficiently using proven spaced repetition techniques."
                )
                .tag(0)

                OnboardingPageView(
                    title: "Swipe to Learn",
                    subtitle: "Fast and intuitive",
                    imageName: "hand.draw",
                    description: "Swipe right if you know it, swipe left if you don't."
                )
                .tag(1)

                OnboardingPageView(
                    title: "Import Your Decks",
                    subtitle: "Bring your Anki collection",
                    imageName: "square.and.arrow.down",
                    description: "Import .apkg files from AnkiWeb or create your own decks."
                )
                .tag(2)

                OnboardingPageView(
                    title: "Track Progress",
                    subtitle: "See your improvement",
                    imageName: "chart.line.uptrend.xyaxis",
                    description: "Monitor your learning streak, retention rate, and daily progress."
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            VStack(spacing: 24) {
                PageIndicator(currentPage: $currentPage, totalPages: 4)

                if currentPage == 3 {
                    VStack(spacing: 12) {
                        Button {
                            appState.completeOnboarding()
                        } label: {
                            Text("Get Started")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                } else {
                    HStack {
                        Spacer()
                        Button("Skip") {
                            appState.completeOnboarding()
                        }
                        .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .background(Color(.systemBackground))
    }
}

struct OnboardingPageView: View {
    let title: String
    let subtitle: String
    let imageName: String
    let description: String

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: imageName)
                .font(.system(size: 80))
                .foregroundColor(.accentColor)

            VStack(spacing: 12) {
                Text(title)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(subtitle)
                    .font(.title2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .padding()
    }
}

struct PageIndicator: View {
    @Binding var currentPage: Int
    let totalPages: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalPages, id: \.self) { index in
                Circle()
                    .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
}
