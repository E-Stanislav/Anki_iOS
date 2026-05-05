import SwiftUI

struct StudyHomeView: View {
    @StateObject private var viewModel = StudySessionViewModel()
    @State private var selectedDeckId: UUID?

    var body: some View {
        List {
            Section {
                DailyProgressCard(
                    reviewed: viewModel.todayReviewCount,
                    goal: viewModel.dailyGoal
                )
            }

            if !viewModel.decksWithReviewedToday.isEmpty {
                Section("Repeat Today") {
                    ForEach(viewModel.decksWithReviewedToday, id: \.deck.id) { deckWithCards in
                        StudyDeckRow(
                            deck: deckWithCards.deck,
                            dueCount: deckWithCards.dueCount,
                            remainingToday: remainingForToday(),
                            onStudy: {
                                viewModel.startRepeatSession(deckId: deckWithCards.deck.id)
                            },
                            buttonTitle: "Repeat",
                            isRepeatButton: true
                        )
                    }
                }
            }

            if !viewModel.decksWithDueCards.isEmpty {
                Section("Ready to Review") {
                    ForEach(viewModel.decksWithDueCards, id: \.deck.id) { deckWithCards in
                        StudyDeckRow(
                            deck: deckWithCards.deck,
                            dueCount: deckWithCards.dueCount,
                            remainingToday: remainingForToday(),
                            onStudy: {
                                viewModel.startSession(deckId: deckWithCards.deck.id)
                            },
                            buttonTitle: "Study"
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
        .onAppear {
            viewModel.loadTodayReviewCount()
            viewModel.loadDailyGoal()
            viewModel.loadDecks()
        }
        .fullScreenCover(isPresented: $viewModel.isSessionActive) {
            ReviewSessionView(viewModel: viewModel)
        }
        .sheet(item: $selectedDeckId) { deckId in
            if let deck = viewModel.allDecks.first(where: { $0.id == deckId }) {
                NavigationStack {
                    DeckDetailView(deck: deck)
                }
            }
        }
    }

    private func remainingForToday() -> Int {
        max(0, viewModel.dailyGoal - viewModel.todayReviewCount)
    }
}

extension UUID: @retroactive Identifiable {
    public var id: UUID { self }
}

struct DailyProgressCard: View {
    let reviewed: Int
    let goal: Int

    private var progress: Double {
        guard goal > 0 else { return 0 }
        return min(Double(reviewed) / Double(goal), 1.0)
    }

    private var remaining: Int {
        max(0, goal - reviewed)
    }

    private var isComplete: Bool {
        reviewed >= goal
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isComplete ? "Daily Goal Complete!" : "Today's Progress")
                        .font(.headline)
                        .foregroundColor(isComplete ? .green : .primary)

                    Text("\(reviewed)/\(goal) cards reviewed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                if isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title)
                        .foregroundColor(.green)
                } else {
                    Text("\(remaining) left")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }

            ProgressView(value: progress)
                .tint(isComplete ? .green : .accentColor)

            if !isComplete {
                Text("Keep going! You're \(Int(progress * 100))% of the way to your daily goal.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct StudyDeckRow: View {
    let deck: Deck
    let dueCount: Int
    let remainingToday: Int
    let onStudy: () -> Void
    var buttonTitle: String = "Study"
    var isRepeatButton: Bool = false

    private var displayCount: Int {
        min(dueCount, remainingToday)
    }

    private var shouldDisableButton: Bool {
        if isRepeatButton {
            return dueCount == 0
        }
        return dueCount == 0 || remainingToday <= 0
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(deck.name)
                    .font(.headline)
                Text("\(displayCount) cards available")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Button(buttonTitle, action: onStudy)
                .buttonStyle(.borderedProminent)
                .disabled(shouldDisableButton)
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
                            total: viewModel.totalCards,
                            dailyGoal: viewModel.dailyGoal,
                            todayCount: viewModel.todayReviewCount
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

    private struct CardContent {
        let topic: String
        let word: String
        let example: String
    }

    private func parseCardContent(_ content: String) -> CardContent {
        let lines = content.components(separatedBy: "\n").filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }

        // Формат: строка 1 = topic, строка 2 = word (перевод), строка 3+ = example
        let topic = lines.count > 0 ? lines[0] : ""
        let word = lines.count > 1 ? lines[1] : content
        let example = lines.count > 2 ? lines.dropFirst(2).joined(separator: "\n") : ""

        return CardContent(topic: topic, word: word, example: example)
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

            VStack(spacing: 16) {
                let content = parseCardContent(isAnswerRevealed ? card.back : card.front)
                if !content.topic.isEmpty {
                    Text(content.topic)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer()

                Text(content.word)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .opacity(swipeText.isEmpty ? 1 : 0.3)

                Spacer()

                if !content.example.isEmpty {
                    Text(content.example)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            .padding()
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
    let dailyGoal: Int
    let todayCount: Int

    private var remainingToday: Int {
        max(0, dailyGoal - todayCount)
    }

    private var effectiveTotal: Int {
        min(total, remainingToday)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text("\(current)/\(effectiveTotal)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("Goal: \(remainingToday) left today")
                    .font(.caption2)
                    .foregroundColor(.orange)
            }

            ProgressView(value: Double(current), total: Double(effectiveTotal))
                .tint(.accentColor)
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
