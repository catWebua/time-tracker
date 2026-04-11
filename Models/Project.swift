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

    @Relationship(deleteRule: .cascade)
    var entries: [TimeEntry] = []

    init(
        name: String,
        client: String = "",
        colorHex: String = "#A855F7",
        hourlyRate: Double = 0,
        currency: String = "UAH"
    ) {
        self.id = UUID()
        self.name = name
        self.client = client
        self.colorHex = colorHex
        self.hourlyRate = hourlyRate
        self.currency = currency
        self.isArchived = false
        self.createdAt = Date()
    }

    // MARK: - Computed

    var completedEntries: [TimeEntry] {
        entries.filter { $0.endedAt != nil }
    }

    var totalDuration: TimeInterval {
        completedEntries.reduce(0) { $0 + $1.duration }
    }

    var totalEarned: Double {
        guard hourlyRate > 0 else { return 0 }
        return (totalDuration / 3600.0) * hourlyRate
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
}

// MARK: - Hashable (required for value-based NavigationLink)

extension Project: Hashable {
    static func == (lhs: Project, rhs: Project) -> Bool {
        lhs.persistentModelID == rhs.persistentModelID
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(persistentModelID)
    }
}
