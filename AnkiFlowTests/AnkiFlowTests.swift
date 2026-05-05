import XCTest
@testable import AnkiFlow

final class AnkiFlowTests: XCTestCase {

    private var deckRepository: DeckRepository!
    private var cardRepository: CardRepository!
    private var testDeck: Deck!

    override func setUp() {
        super.setUp()
        deckRepository = DeckRepository()
        cardRepository = CardRepository()

        deckRepository.deleteAll()

        testDeck = Deck(name: "Test Deck", description: "Test Description")
        deckRepository.save(testDeck)
    }

    override func tearDown() {
        deckRepository.deleteAll()
        super.tearDown()
    }

    func testDeckCreation() {
        let decks = deckRepository.getAll()
        XCTAssertFalse(decks.isEmpty, "Deck should be created")
        XCTAssertEqual(decks.first?.name, "Test Deck")
    }

    func testDeckRetrieval() {
        let retrievedDeck = deckRepository.getById(testDeck.id)
        XCTAssertNotNil(retrievedDeck, "Deck should be retrievable by ID")
        XCTAssertEqual(retrievedDeck?.name, "Test Deck")
    }

    func testDeckDeletion() {
        deckRepository.delete(testDeck.id)

        let retrievedDeck = deckRepository.getById(testDeck.id)
        XCTAssertNil(retrievedDeck, "Deck should be deleted")
    }

    func testCardCreation() {
        let card = Card(
            noteId: UUID(),
            deckId: testDeck.id,
            front: "Test Front",
            back: "Test Back"
        )
        cardRepository.save(card)

        let cards = cardRepository.getAll(for: testDeck.id)
        XCTAssertFalse(cards.isEmpty, "Card should be created")
        XCTAssertEqual(cards.first?.front, "Test Front")
        XCTAssertEqual(cards.first?.back, "Test Back")
    }

    func testCardScheduleCreation() {
        let card = Card(
            noteId: UUID(),
            deckId: testDeck.id,
            front: "Front",
            back: "Back"
        )
        cardRepository.save(card)

        let schedule = CardSchedule(cardId: card.id)
        cardRepository.saveSchedule(schedule)

        let retrievedSchedule = cardRepository.getSchedule(for: card.id)
        XCTAssertNotNil(retrievedSchedule, "Schedule should be created")
        XCTAssertEqual(retrievedSchedule?.status, .new)
    }

    func testGetDueCards() {
        let card = Card(
            noteId: UUID(),
            deckId: testDeck.id,
            front: "Front",
            back: "Back"
        )
        cardRepository.save(card)

        let schedule = CardSchedule(cardId: card.id)
        cardRepository.saveSchedule(schedule)

        let dueCards = cardRepository.getDueCards(for: testDeck.id, limit: 100)
        XCTAssertFalse(dueCards.isEmpty, "Should have due cards")
    }

    func testCardDeletion() {
        let card = Card(
            noteId: UUID(),
            deckId: testDeck.id,
            front: "Front",
            back: "Back"
        )
        cardRepository.save(card)

        let schedule = CardSchedule(cardId: card.id)
        cardRepository.saveSchedule(schedule)

        cardRepository.delete(card.id)

        let retrievedCard = cardRepository.getById(card.id)
        XCTAssertNil(retrievedCard, "Card should be deleted")

        let retrievedSchedule = cardRepository.getSchedule(for: card.id)
        XCTAssertNil(retrievedSchedule, "Schedule should be deleted")
    }

    func testDeckDeletionCascadesToCards() {
        let card = Card(
            noteId: UUID(),
            deckId: testDeck.id,
            front: "Front",
            back: "Back"
        )
        cardRepository.save(card)

        let schedule = CardSchedule(cardId: card.id)
        cardRepository.saveSchedule(schedule)

        deckRepository.delete(testDeck.id)

        let cards = cardRepository.getAll(for: testDeck.id)
        XCTAssertTrue(cards.isEmpty, "Cards should be deleted when deck is deleted")

        let retrievedSchedule = cardRepository.getSchedule(for: card.id)
        XCTAssertNil(retrievedSchedule, "Schedules should be deleted too")
    }

    func testMultipleDecks() {
        let deck2 = Deck(name: "Second Deck", description: "")
        deckRepository.save(deck2)

        let decks = deckRepository.getAll()
        XCTAssertEqual(decks.count, 2, "Should have 2 decks")
    }

    func testMultipleCardsInDeck() {
        for i in 0..<5 {
            let card = Card(
                noteId: UUID(),
                deckId: testDeck.id,
                front: "Front \(i)",
                back: "Back \(i)"
            )
            cardRepository.save(card)
        }

        let cards = cardRepository.getAll(for: testDeck.id)
        XCTAssertEqual(cards.count, 5, "Should have 5 cards")
    }

    func testDeckStatsCalculation() {
        let card1 = Card(noteId: UUID(), deckId: testDeck.id, front: "Front 1", back: "Back 1")
        let card2 = Card(noteId: UUID(), deckId: testDeck.id, front: "Front 2", back: "Back 2")
        cardRepository.save(card1)
        cardRepository.save(card2)

        let schedule1 = CardSchedule(cardId: card1.id)
        let schedule2 = CardSchedule(cardId: card2.id, status: .learning, due: Date())
        cardRepository.saveSchedule(schedule1)
        cardRepository.saveSchedule(schedule2)

        let stats = deckRepository.getStats(for: testDeck.id)
        XCTAssertNotNil(stats)
        XCTAssertEqual(stats?.totalCount, 2)
    }

    func testApkgImport() async throws {
        let testBundle = Bundle(for: type(of: self))
        guard let apkgURL = testBundle.url(forResource: "English A2 - Everyday + IT", withExtension: "apkg") else {
            let projectDir = URL(fileURLWithPath: "/Users/stanislave/Documents/Projects/Anki_iOS")
            let fileURL = projectDir.appendingPathComponent("English A2 - Everyday + IT.apkg")
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path), "APKG file should exist at \(fileURL.path)")

            let importer = ApkgImporter()
            deckRepository.deleteAll()

            let result = try await importer.importFile(at: fileURL, options: ImportOptions())

            XCTAssertGreaterThan(result.totalCards, 0, "Should import some cards")
            XCTAssertGreaterThan(result.addedCards, 0, "Should add some cards")
            XCTAssertTrue(result.errors.isEmpty, "Should have no errors, got: \(result.errors.joined(separator: ", "))")

let decks = deckRepository.getAll()
        XCTAssertFalse(decks.isEmpty, "Should have imported a deck")

        let cards = cardRepository.getAll(for: decks.first!.id)
        XCTAssertFalse(cards.isEmpty, "Imported deck should have cards")

        if let firstCard = cards.first {
            XCTAssertFalse(firstCard.front.isEmpty, "First card front should not be empty")
            XCTAssertFalse(firstCard.back.isEmpty, "First card back should not be empty")
            let frontHasHTML = firstCard.front.contains("<") && firstCard.front.contains(">")
            XCTAssertFalse(frontHasHTML, "Front should not contain HTML, got: \(firstCard.front)")
        }

        return
    }

        let importer = ApkgImporter()
        deckRepository.deleteAll()

        let result = try await importer.importFile(at: apkgURL, options: ImportOptions())

        XCTAssertGreaterThan(result.totalCards, 0, "Should import some cards")
        XCTAssertGreaterThan(result.addedCards, 0, "Should add some cards")

        let decks = deckRepository.getAll()
        XCTAssertFalse(decks.isEmpty, "Should have imported a deck")

        let cards = cardRepository.getAll(for: decks.first!.id)
        XCTAssertFalse(cards.isEmpty, "Imported deck should have cards")

        if let firstCard = cards.first {
            XCTAssertFalse(firstCard.front.isEmpty, "First card front should not be empty")
            XCTAssertFalse(firstCard.back.isEmpty, "First card back should not be empty")
            let frontHasHTML = firstCard.front.contains("<") && firstCard.front.contains(">")
            XCTAssertFalse(frontHasHTML, "Front should not contain HTML")
        }
    }

    func testNotificationServicePermissionRequest() async {
        let service = NotificationService()

        let granted = await service.requestPermission()
        XCTAssertTrue(granted, "Permission should be granted")

        let authorized = service.isAuthorized()
        XCTAssertTrue(authorized, "Should be authorized after permission request")
    }

    func testNotificationServiceScheduleDailyReminder() async {
        let service = NotificationService()
        await service.requestPermission()

        var scheduled = await service.scheduleDailyReminder(hour: 9, minute: 0)
        XCTAssertTrue(scheduled, "Should schedule daily reminder")

        scheduled = await service.scheduleDailyReminder(hour: 20, minute: 30)
        XCTAssertTrue(scheduled, "Should schedule evening reminder")
    }

    func testNotificationServiceCancelAllReminders() async {
        let service = NotificationService()
        await service.requestPermission()

        await service.scheduleDailyReminder(hour: 9, minute: 0)

        let cancelled = service.cancelAllReminders()
        XCTAssertTrue(cancelled, "Should cancel all reminders")
    }

    // MARK: - Theme Tests

    func testAppThemeLight() {
        let theme = AppTheme.light
        XCTAssertEqual(theme.rawValue, "light")
    }

    func testAppThemeDark() {
        let theme = AppTheme.dark
        XCTAssertEqual(theme.rawValue, "dark")
    }

    func testAppThemeSystem() {
        let theme = AppTheme.system
        XCTAssertEqual(theme.rawValue, "system")
    }

    func testAppThemeRawValueParsing() {
        XCTAssertEqual(AppTheme(rawValue: "light"), .light)
        XCTAssertEqual(AppTheme(rawValue: "dark"), .dark)
        XCTAssertEqual(AppTheme(rawValue: "system"), .system)
        XCTAssertNil(AppTheme(rawValue: "invalid"))
    }

    func testAppStateSetAndRetrieveTheme() {
        let state = AppState()

        state.setTheme(.light)
        XCTAssertEqual(state.selectedTheme, .light)

        state.setTheme(.dark)
        XCTAssertEqual(state.selectedTheme, .dark)

        state.setTheme(.system)
        XCTAssertEqual(state.selectedTheme, .system)
    }

    func testAppStatePersistsThemeToUserDefaults() {
        let state = AppState()

        state.setTheme(.dark)
        let stored = UserDefaults.standard.string(forKey: "selectedTheme")
        XCTAssertEqual(stored, "dark")
    }

    func testAppStateInitialThemeFromUserDefaults() {
        UserDefaults.standard.set("dark", forKey: "selectedTheme")
        let state = AppState()
        XCTAssertEqual(state.selectedTheme, .dark)

        UserDefaults.standard.set("light", forKey: "selectedTheme")
        let state2 = AppState()
        XCTAssertEqual(state2.selectedTheme, .light)
    }

    func testAppStateDefaultsToSystemTheme() {
        UserDefaults.standard.removeObject(forKey: "selectedTheme")
        let state = AppState()
        XCTAssertEqual(state.selectedTheme, .system)
    }
}
