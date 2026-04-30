import Foundation

enum AppConstants {
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let extraLarge: CGFloat = 20
        static let circular: CGFloat = 28
    }

    enum Animation {
        static let short: TimeInterval = 0.2
        static let medium: TimeInterval = 0.3
        static let long: TimeInterval = 0.4
    }

    enum StudySettings {
        static let defaultNewCardsPerDay = 20
        static let defaultMaxReviewsPerDay = 200
    }
}
