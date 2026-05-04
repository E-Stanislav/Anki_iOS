import Foundation

protocol ReviewLogRepositoryProtocol {
    func getAll(for cardId: UUID) -> [ReviewLog]
    func getRecent(limit: Int) -> [ReviewLog]
    func getStats(from: Date, to: Date) -> ReviewStats
    func save(_ log: ReviewLog)
}

struct ReviewStats {
    var totalReviews: Int
    var averageTime: TimeInterval
    var retention: Double
    var streak: Int
}

final class ReviewLogRepository: ReviewLogRepositoryProtocol {
    private let db = DatabaseService.shared

    func getAll(for cardId: UUID) -> [ReviewLog] {
        let rows = db.query(
            "SELECT * FROM review_logs WHERE card_id = ? ORDER BY reviewed_at DESC",
            parameters: [cardId.uuidString]
        )
        return rows.compactMap { decodeReviewLog(from: $0) }
    }

    func getRecent(limit: Int) -> [ReviewLog] {
        let rows = db.query(
            "SELECT * FROM review_logs ORDER BY reviewed_at DESC LIMIT ?",
            parameters: [limit]
        )
        return rows.compactMap { decodeReviewLog(from: $0) }
    }

    func getStats(from: Date, to: Date) -> ReviewStats {
        let rows = db.query(
            """
            SELECT * FROM review_logs
            WHERE reviewed_at >= ? AND reviewed_at <= ?
            """,
            parameters: [from.timeIntervalSince1970, to.timeIntervalSince1970]
        )

        let logs = rows.compactMap { decodeReviewLog(from: $0) }
        let totalReviews = logs.count
        let averageTime = logs.isEmpty ? 0 : logs.map { $0.timeTaken }.reduce(0, +) / Double(totalReviews)

        let correctCount = logs.filter { $0.rating != .again }.count
        let retention = totalReviews > 0 ? Double(correctCount) / Double(totalReviews) : 0

        let streak = calculateStreak()

        return ReviewStats(
            totalReviews: totalReviews,
            averageTime: averageTime,
            retention: retention,
            streak: streak
        )
    }

    func save(_ log: ReviewLog) {
        let sql = """
        INSERT INTO review_logs (id, card_id, reviewed_at, rating, interval, ease_factor, time_taken)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """
        db.execute(sql, parameters: [
            log.id.uuidString,
            log.cardId.uuidString,
            log.reviewedAt.timeIntervalSince1970,
            log.rating.rawValue,
            log.interval,
            log.easeFactor,
            log.timeTaken
        ])
    }

    private func decodeReviewLog(from row: [String: Any]) -> ReviewLog? {
        guard let idString = row["id"] as? String,
              let id = UUID(uuidString: idString),
              let cardIdString = row["card_id"] as? String,
              let cardId = UUID(uuidString: cardIdString),
              let reviewedAt = row["reviewed_at"] as? Double,
              let ratingInt = row["rating"] as? Int,
              let rating = ReviewRating(rawValue: ratingInt),
              let interval = row["interval"] as? Int,
              let easeFactor = row["ease_factor"] as? Double,
              let timeTaken = row["time_taken"] as? Double else {
            return nil
        }

        return ReviewLog(
            id: id,
            cardId: cardId,
            reviewedAt: Date(timeIntervalSince1970: reviewedAt),
            rating: rating,
            interval: interval,
            easeFactor: easeFactor,
            timeTaken: timeTaken
        )
    }

    private func calculateStreak() -> Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        while true {
            let nextDay = calendar.date(byAdding: .day, value: 1, to: currentDate)!
            let hasReviews = db.query(
                """
                SELECT COUNT(*) as count FROM review_logs
                WHERE reviewed_at >= ? AND reviewed_at < ?
                """,
                parameters: [currentDate.timeIntervalSince1970, nextDay.timeIntervalSince1970]
            ).first?["count"] as? Int ?? 0

            if hasReviews > 0 {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate)!
            } else {
                break
            }
        }

        return streak
    }
}
