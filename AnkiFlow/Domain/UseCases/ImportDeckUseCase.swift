import Foundation

final class ImportDeckUseCase {
    private let apkgParser = ApkgParser()
    private let deckRepository = DeckRepository.shared
    private let cardRepository = CardRepository.shared

    enum ImportError: Error {
        case invalidFile
        case parseError
        case saveError
    }

    func execute(url: URL, progressHandler: ((Double) -> Void)? = nil) throws -> Deck {
        let parsedDecks = try apkgParser.parse(url: url, progressHandler: progressHandler)

        guard let parsedDeck = parsedDecks.first else {
            throw ImportError.parseError
        }

        let deck = Deck(name: parsedDeck.name)
        guard deckRepository.insertDeck(deck) else {
            throw ImportError.saveError
        }

        for cardData in parsedDeck.cards {
            let card = Card(
                deckId: deck.id,
                front: cardData.front,
                back: cardData.back,
                tags: cardData.tags
            )
            _ = cardRepository.insertCard(card)
        }

        return deck
    }
}
