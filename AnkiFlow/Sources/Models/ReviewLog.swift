import Foundation

struct ReviewLog: Identifiable, Codable {
    let id: UUID
    let cardId: UUID
    let reviewedAt: Date
    let rating: ReviewRating
    let interval: Int
    let easeFactor: Double
    let timeTaken: TimeInterval

    init(
        id: UUID = UUID(),
        cardId: UUID,
        reviewedAt: Date = Date(),
        rating: ReviewRating,
        interval: Int,
        easeFactor: Double,
        timeTaken: TimeInterval
    ) {
        self.id = id
        self.cardId = cardId
        self.reviewedAt = reviewedAt
        self.rating = rating
        self.interval = interval
        self.easeFactor = easeFactor
        self.timeTaken = timeTaken
    }
}

enum ReviewRating: Int, Codable, CaseIterable {
    case again = 1
    case hard = 2
    case good = 3
    case easy = 4

    var displayName: String {
        switch self {
        case .again: return "Again"
        case .hard: return "Hard"
        case .good: return "Good"
        case .easy: return "Easy"
        }
    }
}
