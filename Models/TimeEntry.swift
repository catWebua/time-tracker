import Foundation
import SwiftData

@Model
final class TimeEntry {
    var id: UUID
    var project: Project?
    var taskDescription: String
    var startedAt: Date
    var endedAt: Date?
    var durationSeconds: Int

    init(
        project: Project? = nil,
        taskDescription: String = "",
        startedAt: Date = Date()
    ) {
        self.id = UUID()
        self.project = project
        self.taskDescription = taskDescription
        self.startedAt = startedAt
        self.endedAt = nil
        self.durationSeconds = 0
    }

    // MARK: - Computed

    var isActive: Bool { endedAt == nil }

    var duration: TimeInterval {
        if let endedAt {
            return endedAt.timeIntervalSince(startedAt)
        }
        return Date().timeIntervalSince(startedAt)
    }

    var formattedDuration: String {
        DurationFormatter.formatted(duration)
    }

    var formattedShort: String {
        DurationFormatter.short(duration)
    }

    var dayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: startedAt)
    }
}
