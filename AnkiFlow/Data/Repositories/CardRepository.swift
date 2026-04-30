import Foundation

final class CardRepository {
    static let shared = CardRepository()

    private init() {}

    func fetchCardsByDeck(deckId: UUID) -> [Card] {
        do {
            return try CardTable.fetchCardsByDeck(deckId: deckId)
        } catch {
            print("Error fetching cards: \(error)")
            return []
        }
    }

    func insertCard(_ card: Card) -> Bool {
        do {
            try CardTable.insertCard(card)
            return true
        } catch {
            print("Error inserting card: \(error)")
            return false
        }
    }

    func fetchDueCards(deckId: UUID) -> [Card] {
        do {
            return try ReviewTable.fetchDueCards(deckId: deckId)
        } catch {
            print("Error fetching due cards: \(error)")
            return []
        }
    }

    func getReview(cardId: UUID) -> Review? {
        do {
            return try ReviewTable.fetchReview(cardId: cardId)
        } catch {
            print("Error fetching review: \(error)")
            return nil
        }
    }

    func updateReview(_ review: Review) -> Bool {
        do {
            try ReviewTable.updateReview(review)
            return true
        } catch {
            print("Error updating review: \(error)")
            return false
        }
    }

    func searchCards(query: String, deckId: UUID) -> [Card] {
        do {
            return try CardTable.searchCards(query: query, deckId: deckId)
        } catch {
            print("Error searching cards: \(error)")
            return []
        }
    }

    func toggleSuspension(cardId: UUID) -> Bool {
        do {
            try CardTable.toggleSuspension(cardId: cardId)
            return true
        } catch {
            print("Error toggling suspension: \(error)")
            return false
        }
    }
}
