import Foundation

final class StatisticsViewModel {
    private let deckRepository = DeckRepository.shared

    var todayStudied: Int = 0
    var currentStreak: Int = 0
    var retentionRate: Int = 0
    var totalCards: Int = 0

    func loadStats() {
        let decks = deckRepository.fetchAllDecks()
        var cards = 0
        for deck in decks {
            cards += deckRepository.getCardCount(deckId: deck.id)
        }
        totalCards = cards

        todayStudied = UserDefaults.standard.integer(forKey: "todayStudied")
        currentStreak = UserDefaults.standard.integer(forKey: "currentStreak")

        let lastStudyDate = UserDefaults.standard.object(forKey: "lastStudyDate") as? Date
        if let lastDate = lastStudyDate {
            if !Calendar.current.isDateInToday(lastDate) {
                if Calendar.current.isDateInYesterday(lastDate) {
                } else {
                    currentStreak = 0
                    UserDefaults.standard.set(currentStreak, forKey: "currentStreak")
                }
            }
        }

        retentionRate = UserDefaults.standard.integer(forKey: "retentionRate")
        if retentionRate == 0 {
            retentionRate = 85
        }
    }
}
