import Foundation
import SwiftData
import SwiftUI

@Model
final class Project {
    var id: UUID
    var name: String
    var client: String
    var colorHex: String
    var hourlyRate: Double
    var currency: String
    var isArchived: Bool
    var createdAt: Date

    // Phase 1: budget & goal fields
    var estimatedHours: Double   // 0 = no budget set
    var dailyGoalHours: Double   // 0 = no daily goal

    @Relationship(deleteRule: .cascade)
    var entries: [TimeEntry] = []

    init(
        name: String,
        client: String = "",
        colorHex: String = "#A855F7",
        hourlyRate: Double = 0,
        currency: String = "UAH",
        estimatedHours: Double = 0,
        dailyGoalHours: Double = 0
    ) {
        self.id = UUID()
        self.name = name
        self.client = client
        self.colorHex = colorHex
        self.hourlyRate = hourlyRate
        self.currency = currency
        self.isArchived = false
        self.createdAt = Date()
        self.estimatedHours = estimatedHours
        self.dailyGoalHours = dailyGoalHours
    }

    // MARK: - Computed

    var completedEntries: [TimeEntry] {
        entries.filter { $0.endedAt != nil }
    }

    var unbilledEntries: [TimeEntry] {
        completedEntries.filter { !$0.isBilled }
    }

    var totalDuration: TimeInterval {
        completedEntries.reduce(0) { $0 + $1.duration }
    }

    var unbilledDuration: TimeInterval {
        unbilledEntries.reduce(0) { $0 + $1.duration }
    }

    var totalEarned: Double {
        guard hourlyRate > 0 else { return 0 }
        return (totalDuration / 3600.0) * hourlyRate
    }

    var unbilledEarned: Double {
        guard hourlyRate > 0 else { return 0 }
        return (unbilledDuration / 3600.0) * hourlyRate
    }

    var accentColor: Color {
        Color(hex: colorHex)
    }

    var currencySymbol: String {
        currency == "UAH" ? "₴" : "$"
    }

    var formattedEarned: String {
        String(format: "\(currencySymbol)%.0f", totalEarned)
    }

    /// Budget progress 0.0–1.0. nil if no budget set.
    var budgetProgress: Double? {
        guard estimatedHours > 0 else { return nil }
        return min(totalDuration / (estimatedHours * 3600), 1.0)
    }
}
