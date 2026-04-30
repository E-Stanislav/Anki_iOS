import Foundation

final class DeckListViewModel {
    private let deckRepository = DeckRepository.shared

    var decks: [Deck] = []

    func loadDecks() {
        decks = deckRepository.fetchAllDecks()
    }

    func getCardCount(for deck: Deck) -> Int {
        return deckRepository.getCardCount(deckId: deck.id)
    }

    func getDueCount(for deck: Deck) -> Int {
        return deckRepository.getDueCount(deckId: deck.id)
    }

    func deleteDeck(_ deck: Deck) {
        _ = deckRepository.deleteDeck(id: deck.id)
        if let index = decks.firstIndex(where: { $0.id == deck.id }) {
            decks.remove(at: index)
        }
    }
}
