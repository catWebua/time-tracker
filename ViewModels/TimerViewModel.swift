import SwiftUI
import SwiftData
import Observation

// Skill: @Observable classes must be marked @MainActor for thread safety with SwiftUI.
@Observable
@MainActor
final class TimerViewModel {

    // MARK: - State
    var displayTime: String = "00:00:00"
    var isRunning: Bool = false
    var activeEntry: TimeEntry?
    var selectedProject: Project?
    var taskDescription: String = ""

    // MARK: - Private
    private var timer: Timer?

    // MARK: - Public API

    func start(context: ModelContext) {
        guard let project = selectedProject else { return }

        let entry = TimeEntry(
            project: project,
            taskDescription: taskDescription,
            startedAt: Date()
        )
        context.insert(entry)
        try? context.save()

        activeEntry = entry
        isRunning = true
        startTicking()
        // Haptic feedback is handled declaratively in the view via .sensoryFeedback()
    }

    func stop(context: ModelContext) {
        guard let entry = activeEntry else { return }

        let now = Date()
        entry.endedAt = now
        entry.durationSeconds = Int(now.timeIntervalSince(entry.startedAt))
        try? context.save()

        activeEntry = nil
        isRunning = false
        taskDescription = ""
        displayTime = "00:00:00"
        stopTicking()
    }

    /// Відновлює активний таймер після перезапуску застосунку
    func restoreActiveEntry(from context: ModelContext) {
        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate<TimeEntry> { entry in
                entry.endedAt == nil
            }
        )
        if let entry = try? context.fetch(descriptor).first {
            activeEntry = entry
            selectedProject = entry.project
            isRunning = true
            startTicking()
        }
    }

    // MARK: - Private timer

    private func startTicking() {
        stopTicking()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.tick()
        }
        timer?.fire()
    }

    private func stopTicking() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard let entry = activeEntry else { return }
        displayTime = DurationFormatter.formatted(Date().timeIntervalSince(entry.startedAt))
    }
}
