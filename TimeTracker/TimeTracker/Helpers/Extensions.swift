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

    func relativeLabel() -> String {
        if isToday { return AppLocalization.string("Сьогодні") }
        if isYesterday { return AppLocalization.string("Вчора") }

        return formatted(
            .dateTime
                .day()
                .month(.wide)
                .locale(AppLanguage.current.locale)
        )
    }

    func timeString() -> String {
        formatted(
            Date.FormatStyle(date: .omitted, time: .shortened)
                .locale(AppLanguage.current.locale)
        )
    }
}

// NOTE: Haptics are handled declaratively in views via .sensoryFeedback(_:trigger:) (iOS 17+).
// UIImpactFeedbackGenerator / UINotificationFeedbackGenerator are not used per swiftui-expert-skill guidelines.
