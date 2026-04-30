import UIKit

extension UIColor {
    static let primary = UIColor(hex: "#6366F1")
    static let primaryDark = UIColor(hex: "#4F46E5")
    static let secondary = UIColor(hex: "#10B981")
    static let backgroundLight = UIColor(hex: "#F9FAFB")
    static let backgroundDark = UIColor(hex: "#111827")
    static let surfaceLight = UIColor(hex: "#FFFFFF")
    static let surfaceDark = UIColor(hex: "#1F2937")
    static let textPrimary = UIColor(hex: "#111827")
    static let textSecondary = UIColor(hex: "#6B7280")
    static let errorColor = UIColor(hex: "#EF4444")
    static let warningColor = UIColor(hex: "#F59E0B")

    convenience init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let g = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let b = CGFloat(rgb & 0x0000FF) / 255.0

        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }

    static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? dark : light
        }
    }
}
