import Foundation

final class SpacedRepetition {
    struct SM2Result {
        let easeFactor: Double
        let interval: Int
        let dueDate: Date
    }

    func calculateNextReview(review: Review, quality: Int) -> Review {
        let q = Double(max(0, min(3, quality)))

        var newEaseFactor = review.easeFactor
        var newInterval: Int

        if q < 2.0 {
            newInterval = 1
        } else {
            switch review.interval {
            case 0:
                newInterval = 1
            case 1:
                newInterval = 6
            default:
                newInterval = Int(round(Double(review.interval) * newEaseFactor))
            }
        }

        newEaseFactor = newEaseFactor + (0.1 - (3.0 - q) * (0.08 + (3.0 - q) * 0.02))
        newEaseFactor = max(1.3, newEaseFactor)

        let dueDate = Calendar.current.date(byAdding: .day, value: newInterval, to: Date()) ?? Date()

        return Review(
            id: review.id,
            cardId: review.cardId,
            easeFactor: newEaseFactor,
            interval: newInterval,
            dueDate: dueDate,
            lastReviewed: Date()
        )
    }
}
