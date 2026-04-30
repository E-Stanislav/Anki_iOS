import Foundation

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }

    var endOfDay: Date {
        var components = DateComponents()
        components.day = 1
        components.second = -1
        return Calendar.current.date(byAdding: components, to: startOfDay) ?? self
    }

    func daysFrom(_ date: Date) -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.day], from: date.startOfDay, to: self.startOfDay)
        return components.day ?? 0
    }

    var isToday: Bool {
        return Calendar.current.isDateInToday(self)
    }

    var isTomorrow: Bool {
        return Calendar.current.isDateInTomorrow(self)
    }

    func formattedRelative() -> String {
        if isToday {
            return "Today"
        } else if isTomorrow {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: self)
        }
    }
}
