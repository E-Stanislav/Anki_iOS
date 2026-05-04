import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                TodayOverviewCard(stats: viewModel.todayStats)

                QuickActionsCard(
                    onImport: { viewModel.showingImportPicker = true },
                    onCreateDeck: { viewModel.showingCreateDeck = true }
                )

                DeckListSection(
                    decks: viewModel.decks,
                    onDeckTap: { deck in
                        viewModel.selectedDeck = deck
                    }
                )
            }
            .padding()
        }
        .navigationTitle("AnkiFlow")
        .refreshable {
            viewModel.refresh()
        }
        .sheet(isPresented: $viewModel.showingImportPicker) {
            ImportPickerView()
        }
        .sheet(isPresented: $viewModel.showingCreateDeck) {
            CreateDeckView()
        }
        .sheet(item: $viewModel.selectedDeck) { deck in
            NavigationStack {
                DeckDetailView(deck: deck)
            }
        }
    }
}

struct TodayOverviewCard: View {
    let stats: TodayStats

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Today")
                .font(.headline)

            HStack(spacing: 16) {
                StatBox(title: "New", value: stats.newCards, color: .blue)
                StatBox(title: "Learning", value: stats.learningCards, color: .orange)
                StatBox(title: "Review", value: stats.reviewCards, color: .green)
            }

            ProgressView(value: stats.progress)
                .tint(.accentColor)

            Text("\(Int(stats.progress * 100))% complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }
}

struct StatBox: View {
    let title: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuickActionsCard: View {
    let onImport: () -> Void
    let onCreateDeck: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            QuickActionButton(
                icon: "square.and.arrow.down",
                title: "Import",
                action: onImport
            )
            QuickActionButton(
                icon: "plus.rectangle.on.rectangle",
                title: "Create Deck",
                action: onCreateDeck
            )
        }
    }
}

struct QuickActionButton: View {
    let icon: String
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct DeckListSection: View {
    let decks: [Deck]
    let onDeckTap: (Deck) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Decks")
                .font(.headline)

            if decks.isEmpty {
                EmptyStateView(
                    icon: "rectangle.on.rectangle.slash",
                    title: "No Decks Yet",
                    message: "Create a deck or import one to get started"
                )
            } else {
                ForEach(decks) { deck in
                    DeckRowView(deck: deck)
                        .onTapGesture {
                            onDeckTap(deck)
                        }
                }
            }
        }
    }
}

struct DeckRowView: View {
    let deck: Deck

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.name)
                    .font(.headline)
                if !deck.description.isEmpty {
                    Text(deck.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }
}

struct TodayStats {
    var newCards: Int = 0
    var learningCards: Int = 0
    var reviewCards: Int = 0
    var progress: Double = 0
}
