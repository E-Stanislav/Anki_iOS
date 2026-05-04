import SwiftUI

struct CreateHomeView: View {
    @Binding var showingEditor: Bool
    @StateObject private var viewModel: CardEditorViewModel
    @State private var selectedDeckId: UUID?

    init(showingEditor: Binding<Bool>) {
        self._showingEditor = showingEditor
        self._viewModel = StateObject(wrappedValue: CardEditorViewModel())
    }

    var body: some View {
        List {
            Section("Quick Create") {
                Button {
                    viewModel.quickCreateMode = true
                    showingEditor = true
                } label: {
                    Label("Quick Card", systemImage: "bolt.fill")
                }

                Button {
                    viewModel.quickCreateMode = false
                    showingEditor = true
                } label: {
                    Label("Advanced Card", systemImage: "square.stack.3d.up")
                }
            }

            Section("Recent Cards") {
                ForEach(viewModel.recentCards) { card in
                    CardPreviewRow(card: card)
                }
            }
        }
        .navigationTitle("Create")
        .fullScreenCover(isPresented: $showingEditor) {
            CardEditorView(viewModel: viewModel, isPresented: $showingEditor)
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
    @ObservedObject var viewModel: CardEditorViewModel
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
            .navigationTitle(viewModel.quickCreateMode ? "Quick Card" : "New Card")
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

    private let cardRepo = CardRepository()
    private let deckRepo = DeckRepository()

    var canSave: Bool {
        !front.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !back.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        selectedDeckId != nil
    }

    init() {
        loadDecks()
        loadRecentCards()
    }

    func loadDecks() {
        decks = deckRepo.getAll()
        if selectedDeckId == nil, let first = decks.first {
            selectedDeckId = first.id
        }
    }

    func loadRecentCards() {
    }

    func saveCard() {
        guard let deckId = selectedDeckId else { return }

        let card = Card(
            noteId: UUID(),
            deckId: deckId,
            front: front.trimmingCharacters(in: .whitespacesAndNewlines),
            back: back.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        cardRepo.save(card)

        let schedule = CardSchedule(cardId: card.id)
        cardRepo.saveSchedule(schedule)

        front = ""
        back = ""
    }

    func reset() {
        front = ""
        back = ""
        tagsText = ""
    }
}
