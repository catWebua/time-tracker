import Foundation

enum DurationFormatter {

    /// "01:24:37" or "1д 02:15:30"
    static func formatted(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval))
        let d = total / 86400
        let h = (total % 86400) / 3600
        let m = (total % 3600) / 60
        let s = total % 60
        
        if d > 0 {
            return String(format: AppLocalization.string("%dд %02d:%02d:%02d"), d, h, m, s)
        }
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    /// "1г 24хв", "37с" or "5д 12г"
    static func short(_ interval: TimeInterval) -> String {
        let total = Int(max(0, interval))
        let d = total / 86400
        let h = (total % 86400) / 3600
        let m = (total % 3600) / 60
        let s = total % 60

        if d > 0 {
            return h > 0 ? AppLocalization.string("\(d)д \(h)г") : AppLocalization.string("\(d)д")
        } else if h > 0 {
            return m > 0 ? AppLocalization.string("\(h)г \(m)хв") : AppLocalization.string("\(h)г")
        } else if m > 0 {
            return AppLocalization.string("\(m)хв")
        } else {
            return AppLocalization.string("\(s)с")
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
