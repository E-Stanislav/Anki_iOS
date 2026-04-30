import Foundation

final class SettingsViewModel {
    private let userDefaults = UserDefaults.standard

    private let newCardsPerDayKey = "newCardsPerDay"
    private let maxReviewsPerDayKey = "maxReviewsPerDay"

    var newCardsPerDay: Int {
        let value = userDefaults.integer(forKey: newCardsPerDayKey)
        return value > 0 ? value : AppConstants.StudySettings.defaultNewCardsPerDay
    }

    var maxReviewsPerDay: Int {
        let value = userDefaults.integer(forKey: maxReviewsPerDayKey)
        return value > 0 ? value : AppConstants.StudySettings.defaultMaxReviewsPerDay
    }

    func setNewCardsPerDay(_ value: Int) {
        userDefaults.set(value, forKey: newCardsPerDayKey)
    }

    func setMaxReviewsPerDay(_ value: Int) {
        userDefaults.set(value, forKey: maxReviewsPerDayKey)
    }
}
