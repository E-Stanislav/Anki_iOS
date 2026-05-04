import SwiftUI

struct StudyHomeView: View {
    @StateObject private var viewModel = StudySessionViewModel()
    @State private var selectedDeckId: UUID?

    var body: some View {
        List {
            if !viewModel.decksWithDueCards.isEmpty {
                Section("Ready to Review") {
                    ForEach(viewModel.decksWithDueCards, id: \.deck.id) { deckWithCards in
                        StudyDeckRow(
                            deck: deckWithCards.deck,
                            dueCount: deckWithCards.dueCount,
                            onStudy: {
                                viewModel.startSession(deckId: deckWithCards.deck.id)
                            }
                        )
                    }
                }
            }

            Section("All Decks") {
                ForEach(viewModel.allDecks) { deck in
                    DeckRowView(deck: deck)
                        .onTapGesture {
                            selectedDeckId = deck.id
                        }
                }
            }
        }
        .navigationTitle("Study")
        .fullScreenCover(isPresented: $viewModel.isSessionActive) {
            ReviewSessionView(viewModel: viewModel)
        }
    }
}

struct StudyDeckRow: View {
    let deck: Deck
    let dueCount: Int
    let onStudy: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.name)
                    .font(.headline)
                Text("\(dueCount) cards due")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button("Study", action: onStudy)
                .buttonStyle(.borderedProminent)
        }
    }
}

struct ReviewSessionView: View {
    @ObservedObject var viewModel: StudySessionViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingExitConfirmation = false
    @State private var dragOffset: CGSize = .zero
    @State private var predictedRating: ReviewRating?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground)
                    .ignoresSafeArea()

                if let currentCard = viewModel.currentCard {
                    VStack(spacing: 0) {
                        SessionProgressBar(
                            current: viewModel.currentIndex,
                            total: viewModel.totalCards
                        )

                        Spacer()

                        FlashcardView(
                            card: currentCard,
                            isAnswerRevealed: viewModel.isAnswerRevealed,
                            offset: dragOffset,
                            predictedRating: predictedRating,
                            onTap: { viewModel.revealAnswer() }
                        )
                        .gesture(swipeGesture)

                        Spacer()

                        if viewModel.isAnswerRevealed {
                            AnswerButtonsView(
                                intervals: viewModel.previewIntervals,
                                onRating: { rating in
                                    viewModel.answerCard(rating: rating)
                                }
                            )
                        } else {
                            Button("Show Answer") {
                                viewModel.revealAnswer()
                            }
                            .buttonStyle(.borderedProminent)
                            .padding()
                        }
                    }
                } else {
                    SessionCompleteView(
                        stats: viewModel.sessionStats,
                        onDismiss: { dismiss() }
                    )
                }
            }
            .navigationTitle("Study Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Exit") {
                        showingExitConfirmation = true
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        viewModel.pauseSession()
                    } label: {
                        Image(systemName: viewModel.isPaused ? "play.fill" : "pause.fill")
                    }
                }
            }
            .alert("Exit Session?", isPresented: $showingExitConfirmation) {
                Button("Continue", role: .cancel) {}
                Button("Exit", role: .destructive) {
                    viewModel.endSession()
                    dismiss()
                }
            } message: {
                Text("Your progress will be saved.")
            }
        }
    }

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                dragOffset = value.translation
                predictedRating = calculateRating(from: value.translation)
            }
            .onEnded { value in
                let threshold: CGFloat = 100
                let verticalThreshold: CGFloat = 80

                if value.translation.width > threshold {
                    triggerHaptic(.medium)
                    viewModel.answerCard(rating: .easy)
                } else if value.translation.width < -threshold {
                    if abs(value.translation.height) > verticalThreshold {
                        triggerHaptic(.light)
                    } else {
                        triggerHaptic(.medium)
                        viewModel.answerCard(rating: .good)
                    }
                }
                dragOffset = .zero
                predictedRating = nil
            }
    }

    private func calculateRating(from offset: CGSize) -> ReviewRating? {
        let threshold: CGFloat = 100
        if offset.width > threshold {
            return .easy
        } else if offset.width < -threshold {
            return .good
        }
        return nil
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

struct FlashcardView: View {
    let card: Card
    let isAnswerRevealed: Bool
    var offset: CGSize = .zero
    var predictedRating: ReviewRating?

    let onTap: () -> Void

    private var swipeColor: Color {
        guard let rating = predictedRating else { return .clear }
        switch rating {
        case .easy: return .green.opacity(0.3)
        case .good: return .orange.opacity(0.3)
        default: return .clear
        }
    }

    private var swipeText: String {
        guard let rating = predictedRating else { return "" }
        switch rating {
        case .easy: return "Easy"
        case .good: return "Good"
        default: return ""
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.secondarySystemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)

            RoundedRectangle(cornerRadius: 20)
                .fill(swipeColor)

            if !swipeText.isEmpty {
                VStack {
                    Text(swipeText)
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(swipeColor == .green.opacity(0.3) ? .green : .orange)
                    Text("\(predictedRating != nil ? "Release to confirm" : "")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            VStack {
                Spacer()

                Text(isAnswerRevealed ? card.back : card.front)
                    .font(.title)
                    .multilineTextAlignment(.center)
                    .padding()
                    .opacity(swipeText.isEmpty ? 1 : 0.3)

                Spacer()
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: 400)
        .offset(x: offset.width, y: 0)
        .rotationEffect(.degrees(offset.width / 20))
        .animation(.interactiveSpring(), value: offset)
        .onTapGesture {
            if !isAnswerRevealed {
                onTap()
            }
        }
    }
}

struct SessionProgressBar: View {
    let current: Int
    let total: Int

    var body: some View {
        VStack(spacing: 8) {
            ProgressView(value: Double(current), total: Double(total))
                .tint(.accentColor)

            Text("\(current)/\(total)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct AnswerButtonsView: View {
    let intervals: [ReviewRating: Int]
    let onRating: (ReviewRating) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach([ReviewRating.again, .hard, .good, .easy], id: \.self) { rating in
                RatingButton(
                    rating: rating,
                    interval: intervals[rating] ?? 0,
                    action: { onRating(rating) }
                )
            }
        }
        .padding()
    }
}

struct RatingButton: View {
    let rating: ReviewRating
    let interval: Int
    let action: () -> Void

    private var color: Color {
        switch rating {
        case .again: return .red
        case .hard: return .orange
        case .good: return .green
        case .easy: return .blue
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(rating.displayName)
                    .font(.caption)
                Text("\(interval)d")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(8)
        }
    }
}

struct SessionCompleteView: View {
    let stats: SessionStats
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            Text("Session Complete!")
                .font(.title)
                .fontWeight(.bold)

            VStack(spacing: 8) {
                Text("Cards reviewed: \(stats.cardsReviewed)")
                Text("Correct: \(stats.correctCount)")
                Text("Time: \(formatTime(stats.totalTime))")
            }
            .foregroundColor(.secondary)

            Button("Done", action: onDismiss)
                .buttonStyle(.borderedProminent)
                .padding(.top)
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

struct SessionStats {
    var cardsReviewed: Int = 0
    var correctCount: Int = 0
    var totalTime: TimeInterval = 0
}
