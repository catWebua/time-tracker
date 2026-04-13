import Foundation
import ActivityKit
import WidgetKit
import SwiftData

/// Manages the lifecycle of Live Activities and Widget updates.
@MainActor
final class ActivityManager {
    static let shared = ActivityManager()
    
    private var currentActivity: Activity<TimerActivityAttributes>?
    
    private init() {}
    
    /// Starts a new Live Activity for the given time entry.
    func startLiveActivity(for entry: TimeEntry) {
        // Clean up any existing activities to prevent duplicates
        endLiveActivity()
        
        let attributes = TimerActivityAttributes(taskDescription: entry.taskDescription)
        let initialState = TimerActivityAttributes.ContentState(
            startedAt: entry.startedAt,
            projectName: entry.project?.name ?? "Без назви",
            projectColorHex: entry.project?.colorHex ?? "#A855F7",
            isRunning: true
        )
        
        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: nil)
            )
            print("DEBUG: Live Activity started successfully")
        } catch {
            print("DEBUG: Error starting Live Activity: \(error.localizedDescription)")
        }
    }
    
    /// Ends all active Live Activities.
    func endLiveActivity() {
        Task {
            for activity in Activity<TimerActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
            currentActivity = nil
            print("DEBUG: All Live Activities ended")
        }
    }
    
    /// Forces all widgets to reload their timelines.
    func refreshWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    /// Restores a Live Activity if the app was restarted but a timer is still running.
    func restoreActivityIfNeeded(activeEntry: TimeEntry?) {
        guard let entry = activeEntry else {
            endLiveActivity()
            return
        }
        
        if Activity<TimerActivityAttributes>.activities.isEmpty {
            startLiveActivity(for: entry)
        }
    }
}
