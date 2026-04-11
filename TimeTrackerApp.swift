import SwiftUI
import SwiftData

@main
struct TimeTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Project.self, TimeEntry.self])
    }
}
