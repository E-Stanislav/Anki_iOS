import Foundation
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var decks: [Deck] = []
    @Published var todayStats = TodayStats()
    @Published var showingImportPicker = false
    @Published var showingCreateDeck = false
    @Published var showingSearch = false
    @Published var selectedDeck: Deck?
    @Published var deckToDelete: Deck?

    private let deckRepo = DeckRepository()
    private let cardRepo = CardRepository()

    init() {
        loadData()
    }

    func loadData() {
        decks = deckRepo.getAll()
        if decks.isEmpty {
            createSampleDeck()
        }
        calculateTodayStats()
    }

    func refresh() {
        loadData()
    }

    func deleteDeck(_ deck: Deck) {
        deckRepo.delete(deck.id)
        loadData()
    }

    func createSampleDeck() {
        let sampleDeck = Deck(name: "Sample Deck", description: "Demo deck with sample cards")
        deckRepo.save(sampleDeck)

        let sampleCards = [
            Card(noteId: UUID(), deckId: sampleDeck.id, front: "Hello", back: "A greeting"),
            Card(noteId: UUID(), deckId: sampleDeck.id, front: "Goodbye", back: "A farewell"),
            Card(noteId: UUID(), deckId: sampleDeck.id, front: "Thank you", back: "An expression of gratitude")
        ]

        for card in sampleCards {
            cardRepo.save(card)
            let schedule = CardSchedule(cardId: card.id)
            cardRepo.saveSchedule(schedule)
        }

        decks = deckRepo.getAll()
    }

    private func calculateTodayStats() {
        var totalNew = 0
        var totalLearning = 0
        var totalReview = 0

        for deck in decks {
            if let stats = deckRepo.getStats(for: deck.id) {
                totalNew += stats.newCount
                totalLearning += stats.learningCount
                totalReview += stats.reviewCount
            }
        }

        todayStats.newCards = totalNew
        todayStats.learningCards = totalLearning
        todayStats.reviewCards = totalReview

        let total = totalNew + totalLearning + totalReview
        if total > 0 {
            todayStats.progress = Double(totalReview) / Double(total)
        } else {
            todayStats.progress = 0
        }
    }
}
