import Foundation
import Combine

@MainActor
final class StudySessionViewModel: ObservableObject {
    @Published var isSessionActive = false
    @Published var isPaused = false
    @Published var currentCard: Card?
    @Published var isAnswerRevealed = false
    @Published var currentIndex = 0
    @Published var totalCards = 0
    @Published var previewIntervals: [ReviewRating: Int] = [:]
    @Published var sessionStats = SessionStats()
    @Published var decksWithDueCards: [DeckWithDueCards] = []
    @Published var allDecks: [Deck] = []

    private var dueCards: [Card] = []
    private var sessionStartTime: Date?
    private var cardStartTime: Date?
    private let deckRepo = DeckRepository()
    private let cardRepo = CardRepository()
    private let scheduler = SM2Scheduler()
    private let reviewLogRepo = ReviewLogRepository()

    init() {
        loadDecks()
    }

    func loadDecks() {
        allDecks = deckRepo.getAll()
        decksWithDueCards = allDecks.compactMap { deck in
            let dueCards = cardRepo.getDueCards(for: deck.id, limit: 1000)
            if dueCards.isEmpty { return nil }
            return DeckWithDueCards(deck: deck, dueCount: dueCards.count)
        }
    }

    func startSession(deckId: UUID) {
        dueCards = cardRepo.getDueCards(for: deckId, limit: 100)
        totalCards = dueCards.count
        currentIndex = 0
        sessionStats = SessionStats()
        sessionStartTime = Date()
        isSessionActive = true
        isPaused = false

        showNextCard()
    }

    func showNextCard() {
        guard currentIndex < dueCards.count else {
            currentCard = nil
            return
        }

        currentCard = dueCards[currentIndex]
        isAnswerRevealed = false
        cardStartTime = Date()

        if let card = currentCard {
            let schedule = cardRepo.getSchedule(for: card.id) ?? scheduler.getInitialSchedule(for: card.id)
            previewIntervals = scheduler.previewIntervals(card: card, schedule: schedule)
        }
    }

    func revealAnswer() {
        isAnswerRevealed = true
    }

    func answerCard(rating: ReviewRating) {
        guard let card = currentCard else { return }

        let timeTaken = cardStartTime.map { Date().timeIntervalSince($0) } ?? 0
        sessionStats.totalTime += timeTaken
        sessionStats.cardsReviewed += 1

        if rating != .again {
            sessionStats.correctCount += 1
        }

        var schedule = cardRepo.getSchedule(for: card.id) ?? scheduler.getInitialSchedule(for: card.id)
        schedule = scheduler.schedule(card: card, schedule: schedule, rating: rating)
        cardRepo.saveSchedule(schedule)

        let log = ReviewLog(
            cardId: card.id,
            rating: rating,
            interval: schedule.interval,
            easeFactor: schedule.easeFactor,
            timeTaken: timeTaken
        )
        reviewLogRepo.save(log)

        currentIndex += 1
        showNextCard()
    }

    func pauseSession() {
        isPaused.toggle()
    }

    func endSession() {
        isSessionActive = false
        currentCard = nil
    }
}

struct DeckWithDueCards {
    let deck: Deck
    let dueCount: Int
}
