import SwiftUI

// MARK: - Date helpers

extension Date {

    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }

    var startOfWeek: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.yearForWeekOfYear, .weekOfYear], from: self)
        return cal.date(from: comps) ?? self
    }

    var startOfMonth: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: self)
        return cal.date(from: comps) ?? self
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(self)
    }

    // Performance: static cached formatters — DateFormatter is expensive to allocate.
    // Creating one per cell-render caused O(n) allocations per scroll.
    private static let relativeDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "d MMMM"
        f.locale = Locale(identifier: "uk_UA")
        return f
    }()

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.timeStyle = .short
        return f
    }()

    func relativeLabel() -> String {
        if isToday { return "Сьогодні" }
        if isYesterday { return "Вчора" }
        return Date.relativeDateFormatter.string(from: self)
    }

    func timeString() -> String {
        Date.timeFormatter.string(from: self)
    }
}

// NOTE: Haptics are handled declaratively in views via .sensoryFeedback(_:trigger:) (iOS 17+).
// UIImpactFeedbackGenerator / UINotificationFeedbackGenerator are not used per swiftui-expert-skill guidelines.
