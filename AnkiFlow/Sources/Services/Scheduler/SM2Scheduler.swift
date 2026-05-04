import Foundation

protocol SchedulerProtocol {
    func schedule(card: Card, schedule: CardSchedule, rating: ReviewRating) -> CardSchedule
}

final class SM2Scheduler: SchedulerProtocol {
    private let minimumEaseFactor = 1.3
    private let initialEaseFactor = 2.5

    func schedule(card: Card, schedule: CardSchedule, rating: ReviewRating) -> CardSchedule {
        var newSchedule = schedule
        newSchedule.reps += 1

        switch rating {
        case .again:
            newSchedule = handleAgain(card: card, schedule: newSchedule)
        case .hard:
            newSchedule = handleHard(card: card, schedule: newSchedule)
        case .good:
            newSchedule = handleGood(card: card, schedule: newSchedule)
        case .easy:
            newSchedule = handleEasy(card: card, schedule: newSchedule)
        }

        return newSchedule
    }

    private func handleAgain(card: Card, schedule: CardSchedule) -> CardSchedule {
        var newSchedule = schedule
        newSchedule.status = .learning
        newSchedule.interval = 0
        newSchedule.due = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
        newSchedule.lapses += 1
        newSchedule.easeFactor = max(minimumEaseFactor, schedule.easeFactor - 0.2)
        newSchedule.reps = 0
        return newSchedule
    }

    private func handleHard(card: Card, schedule: CardSchedule) -> CardSchedule {
        var newSchedule = schedule
        let interval: Int

        if schedule.interval == 0 {
            interval = 1
        } else if schedule.interval < 2 {
            interval = schedule.interval * 2
        } else {
            interval = Int(Double(schedule.interval) * 1.2)
        }

        newSchedule.interval = interval
        newSchedule.due = Calendar.current.date(byAdding: .day, value: interval, to: Date())!
        newSchedule.easeFactor = max(minimumEaseFactor, schedule.easeFactor - 0.15)
        return newSchedule
    }

    private func handleGood(card: Card, schedule: CardSchedule) -> CardSchedule {
        var newSchedule = schedule
        let interval: Int

        if schedule.interval == 0 {
            interval = 1
        } else if schedule.interval == 1 {
            interval = 6
        } else {
            interval = Int(Double(schedule.interval) * schedule.easeFactor)
        }

        newSchedule.interval = interval
        newSchedule.status = schedule.interval == 0 ? .learning : .review
        newSchedule.due = Calendar.current.date(byAdding: .day, value: interval, to: Date())!
        return newSchedule
    }

    private func handleEasy(card: Card, schedule: CardSchedule) -> CardSchedule {
        var newSchedule = schedule
        let interval: Int

        if schedule.interval == 0 {
            interval = 4
        } else {
            interval = Int(Double(schedule.interval) * schedule.easeFactor * 1.3)
        }

        newSchedule.interval = interval
        newSchedule.status = .review
        newSchedule.due = Calendar.current.date(byAdding: .day, value: interval, to: Date())!
        newSchedule.easeFactor = schedule.easeFactor + 0.15
        return newSchedule
    }

    func getInitialSchedule(for cardId: UUID) -> CardSchedule {
        CardSchedule(cardId: cardId)
    }

    func previewIntervals(card: Card, schedule: CardSchedule) -> [ReviewRating: Int] {
        return [
            .again: 1,
            .hard: schedule.interval == 0 ? 1 : (schedule.interval < 2 ? schedule.interval * 2 : Int(Double(schedule.interval) * 1.2)),
            .good: schedule.interval == 0 ? 1 : (schedule.interval == 1 ? 6 : Int(Double(schedule.interval) * schedule.easeFactor)),
            .easy: schedule.interval == 0 ? 4 : Int(Double(schedule.interval) * schedule.easeFactor * 1.3)
        ]
    }
}
