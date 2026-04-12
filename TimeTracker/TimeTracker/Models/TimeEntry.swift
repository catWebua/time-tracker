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

    // Phase 1: billing & tags fields
    var isBilled: Bool
    var tags: [String]

    init(
        project: Project? = nil,
        taskDescription: String = "",
        startedAt: Date = Date(),
        tags: [String] = []
    ) {
        self.id = UUID()
        self.project = project
        self.taskDescription = taskDescription
        self.startedAt = startedAt
        self.endedAt = nil
        self.durationSeconds = 0
        self.isBilled = false
        self.tags = tags
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
}
