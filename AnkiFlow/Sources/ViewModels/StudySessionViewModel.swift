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
    @Published var decksWithReviewedToday: [DeckWithDueCards] = []
    @Published var allDecks: [Deck] = []
    @Published var dailyGoal: Int = 20
    @Published var todayReviewCount: Int = 0

    private var dueCards: [Card] = []
    private var sessionStartTime: Date?
    private var cardStartTime: Date?
    private var isRepeatSession: Bool = false
    private let deckRepo = DeckRepository()
    private let cardRepo = CardRepository()
    private let scheduler = SM2Scheduler()
    private let reviewLogRepo = ReviewLogRepository()

    init() {
        loadDailyGoal()
        loadTodayReviewCount()
        loadDecks()
    }

    func loadDailyGoal() {
        dailyGoal = UserDefaults.standard.integer(forKey: "dailyGoal")
        if dailyGoal == 0 {
            dailyGoal = 20
        }
    }

    func loadTodayReviewCount() {
        todayReviewCount = reviewLogRepo.getTodayReviewCount()
    }

    func loadDecks() {
        allDecks = deckRepo.getAll()
        decksWithDueCards = allDecks.compactMap { deck in
            let dueCards = cardRepo.getDueCards(for: deck.id, limit: 1000)
            if dueCards.isEmpty { return nil }
            return DeckWithDueCards(deck: deck, dueCount: dueCards.count)
        }
        decksWithReviewedToday = allDecks.compactMap { deck in
            let reviewedToday = cardRepo.getCardsReviewedToday(for: deck.id, limit: 1000)
            if reviewedToday.isEmpty { return nil }
            return DeckWithDueCards(deck: deck, dueCount: reviewedToday.count)
        }
    }

    func startSession(deckId: UUID) {
        let remainingCards = dailyGoal - todayReviewCount
        let effectiveLimit = min(remainingCards, 100)
        dueCards = cardRepo.getDueCards(for: deckId, limit: effectiveLimit)
        totalCards = dueCards.count
        currentIndex = 0
        sessionStats = SessionStats()
        sessionStartTime = Date()
        isSessionActive = true
        isPaused = false
        isRepeatSession = false

        showNextCard()
    }

    func startRepeatSession(deckId: UUID) {
        let reviewedToday = cardRepo.getCardsReviewedToday(for: deckId, limit: 100)
        dueCards = reviewedToday
        totalCards = reviewedToday.count
        currentIndex = 0
        sessionStats = SessionStats()
        sessionStartTime = Date()
        isSessionActive = true
        isPaused = false
        isRepeatSession = true

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

        if !isRepeatSession {
            todayReviewCount += 1
        }

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
