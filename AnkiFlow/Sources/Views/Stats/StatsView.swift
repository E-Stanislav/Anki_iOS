import SwiftUI

struct StatsView: View {
    @StateObject private var viewModel = StatsViewModel()
    @State private var selectedPeriod: StatsPeriod = .week

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(StatsPeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    StreakCard(streak: viewModel.stats.streak)

                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            StatCard(
                                title: "Reviews",
                                value: "\(viewModel.stats.totalReviews)",
                                icon: "checkmark.circle",
                                color: .green
                            )
                            StatCard(
                                title: "Retention",
                                value: "\(Int(viewModel.stats.retention * 100))%",
                                icon: "brain",
                                color: .blue
                            )
                        }

                        HStack(spacing: 16) {
                            StatCard(
                                title: "Avg Time",
                                value: formatTime(viewModel.stats.averageTime),
                                icon: "clock",
                                color: .orange
                            )
                            StatCard(
                                title: "Streak",
                                value: "\(viewModel.stats.streak)",
                                icon: "flame",
                                color: .red
                            )
                        }
                    }
                    .padding(.horizontal)

                    HeatmapCard(activities: viewModel.heatmapData)

                    HardestCardsCard(cards: viewModel.hardestCards)
                }
                .padding(.vertical)
            }
            .navigationTitle("Statistics")
            .refreshable {
                viewModel.loadStats()
            }
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        if interval < 60 {
            return "\(Int(interval))s"
        }
        let minutes = Int(interval) / 60
        return "\(minutes)m"
    }
}

struct StreakCard: View {
    let streak: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Current Streak")
                    .font(.headline)
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(streak)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.orange)
                    Text("days")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
            }

            Spacer()

            Image(systemName: "flame.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange.opacity(0.3))
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.title)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
}

struct HeatmapCard: View {
    let activities: [DayActivity]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)
    private let weekdays = ["S", "M", "T", "W", "T", "F", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity")
                .font(.headline)

            HStack(spacing: 4) {
                VStack(spacing: 4) {
                    ForEach(weekdays, id: \.self) { day in
                        Text(day)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(activities) { activity in
                        Rectangle()
                            .fill(colorForCount(activity.count))
                            .frame(width: 20, height: 20)
                            .cornerRadius(4)
                    }
                }
            }

            HStack {
                Text("Less")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                ForEach(0..<5) { level in
                    Rectangle()
                        .fill(colorForLevel(level))
                        .frame(width: 12, height: 12)
                        .cornerRadius(2)
                }
                Text("More")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }

    private func colorForCount(_ count: Int) -> Color {
        if count == 0 { return Color(.systemGray5) }
        if count < 5 { return Color.green.opacity(0.3) }
        if count < 10 { return Color.green.opacity(0.5) }
        if count < 20 { return Color.green.opacity(0.7) }
        return Color.green
    }

    private func colorForLevel(_ level: Int) -> Color {
        colorForCount(level * 5)
    }
}

struct HardestCardsCard: View {
    let cards: [Card]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hardest Cards")
                .font(.headline)

            if cards.isEmpty {
                Text("No cards reviewed yet")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(cards.prefix(5)) { card in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(card.front)
                            .font(.subheadline)
                            .lineLimit(1)
                        Text(card.back)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    Divider()
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

enum StatsPeriod: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
    case all = "All"
}

struct DayActivity: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
}

@MainActor
final class StatsViewModel: ObservableObject {
    @Published var stats = ReviewStats(totalReviews: 0, averageTime: 0, retention: 0, streak: 0)
    @Published var heatmapData: [DayActivity] = []
    @Published var hardestCards: [Card] = []

    private let reviewLogRepo = ReviewLogRepository()

    init() {
        loadStats()
    }

    func loadStats() {
        let calendar = Calendar.current
        let now = Date()
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!

        stats = reviewLogRepo.getStats(from: startOfWeek, to: now)
        loadHeatmap()
    }

    private func loadHeatmap() {
        let calendar = Calendar.current
        var activities: [DayActivity] = []

        for i in 0..<42 {
            if let date = calendar.date(byAdding: .day, value: -i, to: Date()) {
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                let count = Int.random(in: 0...25)
                activities.append(DayActivity(date: startOfDay, count: count))
            }
        }

        heatmapData = activities.reversed()
    }
}
