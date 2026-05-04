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

    private let deckRepo = DeckRepository()
    private let cardRepo = CardRepository()

    init() {
        loadData()
    }

    func loadData() {
        decks = deckRepo.getAll()
        calculateTodayStats()
    }

    func refresh() {
        loadData()
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
