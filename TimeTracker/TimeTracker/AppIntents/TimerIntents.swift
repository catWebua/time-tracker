import AppIntents
import SwiftData

// MARK: - Start Timer Intent

struct StartTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Старт таймер"
    static var description = IntentDescription("Запускає таймер для останнього обраного проекту у FreelanceKit")

    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Project.self, TimeEntry.self)
        let context = container.mainContext

        // Find last used project (most recent active entry's project)
        let sortBy = [SortDescriptor<TimeEntry>(\.startedAt, order: .reverse)]
        let descriptor = FetchDescriptor<TimeEntry>(sortBy: sortBy)
        
        let lastEntry = try context.fetch(descriptor).first
        
        let project: Project?
        if let entryProject = lastEntry?.project {
            project = entryProject
        } else {
            let projectDescriptor = FetchDescriptor<Project>()
            project = try context.fetch(projectDescriptor).first
        }
        
        guard let finalProject = project else {
            return .result(dialog: "Спочатку створи проект у FreelanceKit")
        }

        // Create new entry
        let entry = TimeEntry(project: finalProject, startedAt: Date())
        context.insert(entry)
        try context.save()

        return .result(dialog: "Таймер запущено для «\(finalProject.name)»")
    }
}

// MARK: - Stop Timer Intent

struct StopTimerIntent: AppIntent {
    static var title: LocalizedStringResource = "Стоп таймер"
    static var description = IntentDescription("Зупиняє активний таймер у FreelanceKit")

    static var openAppWhenRun = false

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let container = try ModelContainer(for: Project.self, TimeEntry.self)
        let context = container.mainContext

        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate<TimeEntry> { $0.endedAt == nil }
        )
        
        let activeEntries = try context.fetch(descriptor)
        guard let activeEntry = activeEntries.first else {
            return .result(dialog: "Активного таймера немає")
        }

        let now = Date()
        activeEntry.endedAt = now
        activeEntry.durationSeconds = Int(now.timeIntervalSince(activeEntry.startedAt))
        try context.save()

        let duration = DurationFormatter.short(Double(activeEntry.durationSeconds))
        let projectName = activeEntry.project?.name ?? "проект"
        return .result(dialog: "Таймер зупинено. Відпрацьовано \(duration) для «\(projectName)»")
    }
}

// MARK: - App Shortcuts Provider

struct TimeTrackerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartTimerIntent(),
            phrases: [
                "Старт таймер \(.applicationName)",
                "Почати відслідковувати час в \(.applicationName)",
                "Запусти таймер \(.applicationName)"
            ],
            shortTitle: "Старт таймер",
            systemImageName: "play.circle"
        )
        AppShortcut(
            intent: StopTimerIntent(),
            phrases: [
                "Стоп таймер \(.applicationName)",
                "Зупинити таймер в \(.applicationName)",
                "Стоп \(.applicationName)"
            ],
            shortTitle: "Стоп таймер",
            systemImageName: "stop.circle"
        )
    }
}
