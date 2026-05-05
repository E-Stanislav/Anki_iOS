import SwiftUI

struct CreateHomeView: View {
    @State private var showingEditor = false
    @State private var viewModel = CardEditorViewModel()
    @State private var selectedCardForEdit: Card?

    var body: some View {
        List {
            Section("Quick Create") {
                Button {
                    viewModel.reset()
                    viewModel.quickCreateMode = true
                    showingEditor = true
                } label: {
                    Label("Quick Card", systemImage: "bolt.fill")
                }

                Button {
                    viewModel.reset()
                    viewModel.quickCreateMode = false
                    showingEditor = true
                } label: {
                    Label("Advanced Card", systemImage: "square.stack.3d.up")
                }
            }

            Section("Recent Cards") {
                if viewModel.recentCards.isEmpty {
                    Text("No cards yet")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(viewModel.recentCards) { card in
                        Button {
                            selectedCardForEdit = card
                            viewModel.loadCardForEditing(card)
                            showingEditor = true
                        } label: {
                            CardPreviewRow(card: card)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                viewModel.deleteCard(card.id)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Create")
        .fullScreenCover(isPresented: $showingEditor) {
            CardEditorView(viewModel: $viewModel, isPresented: $showingEditor)
        }
        .onAppear {
            viewModel.loadData()
        }
    }
}

struct CardPreviewRow: View {
    let card: Card

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(card.front)
                .font(.headline)
                .lineLimit(1)
            Text(card.back)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
    }
}

struct CardEditorView: View {
    @Binding var viewModel: CardEditorViewModel
    @Binding var isPresented: Bool
    @FocusState private var focusedField: EditorField?

    enum EditorField {
        case front
        case back
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Front") {
                    TextEditor(text: $viewModel.front)
                        .frame(minHeight: 100)
                        .focused($focusedField, equals: .front)
                }

                Section("Back") {
                    TextEditor(text: $viewModel.back)
                        .frame(minHeight: 100)
                        .focused($focusedField, equals: .back)
                }

                if !viewModel.quickCreateMode {
                    Section("Deck") {
                        Picker("Deck", selection: $viewModel.selectedDeckId) {
                            ForEach(viewModel.decks) { deck in
                                Text(deck.name).tag(deck.id)
                            }
                        }
                    }

                    Section("Tags") {
                        TextField("Tags (comma separated)", text: $viewModel.tagsText)
                    }
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Card" : (viewModel.quickCreateMode ? "Quick Card" : "New Card"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        viewModel.saveCard()
                        isPresented = false
                    }
                    .disabled(!viewModel.canSave)
                }
            }
        }
    }
}

@MainActor
final class CardEditorViewModel: ObservableObject {
    @Published var front = ""
    @Published var back = ""
    @Published var selectedDeckId: UUID?
    @Published var tagsText = ""
    @Published var quickCreateMode = true
    @Published var recentCards: [Card] = []
    @Published var decks: [Deck] = []
    var editingCardId: UUID?

    private let cardRepo = CardRepository()
    private let deckRepo = DeckRepository()

    var canSave: Bool {
        !front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedDeckId != nil
    }

    var isEditing: Bool {
        editingCardId != nil
    }

    func loadData() {
        loadDecks()
        loadRecentCards()
    }

    func loadDecks() {
        decks = deckRepo.getAll()
        if decks.isEmpty {
            let defaultDeck = Deck(name: "My Deck", description: "")
            deckRepo.save(defaultDeck)
            decks = [defaultDeck]
        }
        if selectedDeckId == nil, let first = decks.first {
            selectedDeckId = first.id
        }
    }

    func loadRecentCards() {
        guard let deckId = decks.first?.id else { return }
        let allCards = cardRepo.getAll(for: deckId)
        recentCards = Array(allCards.prefix(10))
    }

    func saveCard() {
        guard let deckId = selectedDeckId else {
            print("DEBUG saveCard: selectedDeckId is nil!")
            return
        }

        if let cardId = editingCardId, let existingCard = cardRepo.getById(cardId) {
            var updatedCard = existingCard
            updatedCard.front = front.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedCard.back = back.trimmingCharacters(in: .whitespacesAndNewlines)
            updatedCard.deckId = deckId
            updatedCard.updatedAt = Date()
            cardRepo.save(updatedCard)
        } else {
            let card = Card(
                noteId: UUID(),
                deckId: deckId,
                front: front.trimmingCharacters(in: .whitespacesAndNewlines),
                back: back.trimmingCharacters(in: .whitespacesAndNewlines)
            )
            cardRepo.save(card)
            let schedule = CardSchedule(cardId: card.id)
            cardRepo.saveSchedule(schedule)
        }

        front = ""
        back = ""
        editingCardId = nil
        loadRecentCards()
    }

    func deleteCard(_ cardId: UUID) {
        cardRepo.delete(cardId)
        loadRecentCards()
    }

    func loadCardForEditing(_ card: Card) {
        editingCardId = card.id
        front = card.front
        back = card.back
        selectedDeckId = card.deckId
    }

    func reset() {
        front = ""
        back = ""
        tagsText = ""
        editingCardId = nil
    }
}
