import SwiftUI
import SwiftData
import Observation

/// The main view model for the Timer screen, handling UI state and business logic.
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

    /// Starts a new time tracking session.
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
        
        // Delegate external side effects to ActivityManager
        ActivityManager.shared.startLiveActivity(for: entry)
        ActivityManager.shared.refreshWidgets()
    }

    /// Stops the current tracking session.
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
        
        // Delegate external side effects to ActivityManager
        ActivityManager.shared.endLiveActivity()
        ActivityManager.shared.refreshWidgets()
    }

    /// Restores the active entry from the database if one exists (e.g. after app restart).
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
            
            // Ensure Live Activity is in sync
            ActivityManager.shared.restoreActivityIfNeeded(activeEntry: entry)
        }
    }

    // MARK: - Private timer

    private func startTicking() {
        stopTicking()
        // We still use a Timer for UI updates, but the logic is now cleaner
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
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
