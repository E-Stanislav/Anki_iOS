import Foundation

final class DeckRepository {
    static let shared = DeckRepository()

    private init() {}

    func fetchAllDecks() -> [Deck] {
        do {
            return try DeckTable.fetchAllDecks()
        } catch {
            print("Error fetching decks: \(error)")
            return []
        }
    }

    func insertDeck(_ deck: Deck) -> Bool {
        do {
            try DeckTable.insertDeck(deck)
            return true
        } catch {
            print("Error inserting deck: \(error)")
            return false
        }
    }

    func deleteDeck(id: UUID) -> Bool {
        do {
            try CardTable.deleteCardsByDeck(deckId: id)
            try DeckTable.deleteDeck(id: id)
            return true
        } catch {
            print("Error deleting deck: \(error)")
            return false
        }
    }

    func updateDeck(_ deck: Deck) -> Bool {
        do {
            try DeckTable.updateDeck(deck)
            return true
        } catch {
            print("Error updating deck: \(error)")
            return false
        }
    }

    func getCardCount(deckId: UUID) -> Int {
        do {
            return try CardTable.getCardCount(deckId: deckId)
        } catch {
            print("Error getting card count: \(error)")
            return 0
        }
    }

    func getDueCount(deckId: UUID) -> Int {
        do {
            return try ReviewTable.getDueCount(deckId: deckId)
        } catch {
            print("Error getting due count: \(error)")
            return 0
        }
    }
}
