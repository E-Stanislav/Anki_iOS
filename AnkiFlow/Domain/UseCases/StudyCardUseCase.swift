import Foundation

final class StudyCardUseCase {
    private let cardRepository = CardRepository.shared
    private let spacedRepetition = SpacedRepetition()

    func fetchDueCards(deckId: UUID) -> [Card] {
        return cardRepository.fetchDueCards(deckId: deckId)
    }

    func processAnswer(card: Card, quality: Int) -> Review {
        guard let currentReview = cardRepository.getReview(cardId: card.id) else {
            let newReview = Review(cardId: card.id)
            return spacedRepetition.calculateNextReview(review: newReview, quality: quality)
        }

        let updatedReview = spacedRepetition.calculateNextReview(review: currentReview, quality: quality)
        _ = cardRepository.updateReview(updatedReview)

        return updatedReview
    }
}
