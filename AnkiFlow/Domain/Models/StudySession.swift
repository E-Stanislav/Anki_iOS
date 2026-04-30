import Foundation

struct StudySession: Identifiable, Codable {
    let id: UUID
    let deckId: UUID
    let date: Date
    var cardsStudied: Int
    var correctCount: Int

    init(id: UUID = UUID(), deckId: UUID, date: Date = Date(), cardsStudied: Int = 0, correctCount: Int = 0) {
        self.id = id
        self.deckId = deckId
        self.date = date
        self.cardsStudied = cardsStudied
        self.correctCount = correctCount
    }
}
