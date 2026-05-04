import SwiftUI

struct CreateDeckView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var deckName = ""
    @State private var deckDescription = ""

    private let deckRepo = DeckRepository()

    var body: some View {
        NavigationStack {
            Form {
                Section("Deck Info") {
                    TextField("Deck Name", text: $deckName)
                    TextField("Description (optional)", text: $deckDescription)
                }
            }
            .navigationTitle("New Deck")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        createDeck()
                        dismiss()
                    }
                    .disabled(deckName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func createDeck() {
        let deck = Deck(
            name: deckName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: deckDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        deckRepo.save(deck)
    }
}
