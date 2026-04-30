import Foundation

final class CardStudyViewModel {
    private let studyUseCase = StudyCardUseCase()
    private let deck: Deck
    private var dueCards: [Card] = []
    private var currentIndex = 0
    private var correctCount = 0
    private(set) var cardsStudied = 0

    init(deck: Deck) {
        self.deck = deck
        loadDueCards()
    }

    private func loadDueCards() {
        dueCards = studyUseCase.fetchDueCards(deckId: deck.id)
        dueCards.shuffle()
    }

    func nextCard() -> Card? {
        guard currentIndex < dueCards.count else { return nil }
        let card = dueCards[currentIndex]
        return card
    }

    func answerCard(quality: Int) {
        guard currentIndex < dueCards.count else { return }
        let card = dueCards[currentIndex]
        _ = studyUseCase.processAnswer(card: card, quality: quality)

        cardsStudied += 1
        if quality >= 2 {
            correctCount += 1
        }

        currentIndex += 1
    }

    var progressText: String {
        return "\(currentIndex + 1) of \(dueCards.count)"
    }

    var accuracy: Int {
        guard cardsStudied > 0 else { return 0 }
        return Int((Double(correctCount) / Double(cardsStudied)) * 100)
    }

    var deckName: String {
        return deck.name
    }
}
