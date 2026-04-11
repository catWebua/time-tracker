import Foundation

enum DurationFormatter {

    /// "01:24:37"
    static func formatted(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    /// "1г 24хв" або "37с"
    static func short(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval))
        let h = total / 3600
        let m = (total % 3600) / 60
        let s = total % 60

        if h > 0 {
            return m > 0 ? "\(h)г \(m)хв" : "\(h)г"
        } else if m > 0 {
            return "\(m)хв"
        } else {
            return "\(s)с"
        }
    }

    /// Форматує дохід з валютним символом
    static func earnings(_ amount: Double, currency: String) -> String {
        let symbol = currency == "UAH" ? "₴" : "$"
        if amount >= 1000 {
            return String(format: "\(symbol)%.0f", amount)
        }
        return String(format: "\(symbol)%.2f", amount)
    }
}
