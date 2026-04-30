import Foundation

final class CardBrowserViewModel {
    private let cardRepository = CardRepository.shared
    private let deck: Deck
    private var allCards: [Card] = []

    var cards: [Card] = []

    init(deck: Deck) {
        self.deck = deck
        loadCards()
    }

    private func loadCards() {
        allCards = cardRepository.fetchCardsByDeck(deckId: deck.id)
        cards = allCards
    }

    func search(query: String) {
        if query.isEmpty {
            cards = allCards
        } else {
            cards = cardRepository.searchCards(query: query, deckId: deck.id)
        }
    }

    func toggleSuspension(cardId: UUID) {
        _ = cardRepository.toggleSuspension(cardId: cardId)
    }
}
