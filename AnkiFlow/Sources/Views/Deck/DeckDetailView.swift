import SwiftUI

struct DeckDetailView: View {
    let deck: Deck
    @StateObject private var viewModel: DeckDetailViewModel
    @State private var showingStudy = false
    @State private var showingAddCard = false

    init(deck: Deck) {
        self.deck = deck
        self._viewModel = StateObject(wrappedValue: DeckDetailViewModel(deck: deck))
    }

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Text(deck.name)
                        .font(.title)
                        .fontWeight(.bold)

                    if !deck.description.isEmpty {
                        Text(deck.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Section("Stats") {
                HStack {
                    StatItem(title: "New", value: viewModel.stats.newCount, color: .blue)
                    StatItem(title: "Learning", value: viewModel.stats.learningCount, color: .orange)
                    StatItem(title: "Review", value: viewModel.stats.reviewCount, color: .green)
                }
            }

            Section("Actions") {
                Button {
                    showingStudy = true
                } label: {
                    Label("Study Now", systemImage: "play.fill")
                }
                .disabled(viewModel.stats.dueToday == 0)

                Button {
                    showingAddCard = true
                } label: {
                    Label("Add Card", systemImage: "plus")
                }
            }

            Section("Cards") {
                ForEach(viewModel.cards) { card in
                    CardRowView(card: card)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteCard(card)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
        }
        .navigationTitle("Deck")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingStudy) {
            ReviewSessionView(viewModel: viewModel.sessionViewModel)
        }
        .sheet(isPresented: $showingAddCard) {
            AddCardSheet(deckId: deck.id) {
                viewModel.refresh()
            }
        }
    }
}

struct StatItem: View {
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

struct CardRowView: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(card.front)
                .font(.headline)
                .lineLimit(1)
            Text(card.back)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
    }
}

struct AddCardSheet: View {
    let deckId: UUID
    let onSave: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var front = ""
    @State private var back = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Front") {
                    TextEditor(text: $front)
                        .frame(minHeight: 100)
                }
                Section("Back") {
                    TextEditor(text: $back)
                        .frame(minHeight: 100)
                }
            }
            .navigationTitle("Add Card")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveCard()
                        dismiss()
                    }
                    .disabled(front.isEmpty || back.isEmpty)
                }
            }
        }
    }

    private func saveCard() {
        let card = Card(
            noteId: UUID(),
            deckId: deckId,
            front: front.trimmingCharacters(in: .whitespacesAndNewlines),
            back: back.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        CardRepository().save(card)

        let schedule = CardSchedule(cardId: card.id)
        CardRepository().saveSchedule(schedule)

        onSave()
    }
}

@MainActor
final class DeckDetailViewModel: ObservableObject {
    @Published var stats: DeckStats
    @Published var cards: [Card] = []
    @Published var sessionViewModel = StudySessionViewModel()

    private let deck: Deck
    private let deckRepo = DeckRepository()
    private let cardRepo = CardRepository()

    init(deck: Deck) {
        self.deck = deck
        self.stats = deckRepo.getStats(for: deck.id) ?? DeckStats(
            deckId: deck.id,
            newCount: 0,
            learningCount: 0,
            reviewCount: 0,
            totalCount: 0,
            dueToday: 0
        )
        loadCards()
    }

    func loadCards() {
        cards = cardRepo.getAll(for: deck.id)
    }

    func refresh() {
        stats = deckRepo.getStats(for: deck.id) ?? stats
        loadCards()
    }

    func deleteCard(_ card: Card) {
        cardRepo.delete(card.id)
        refresh()
    }
}
