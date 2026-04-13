import SwiftUI
import SwiftData

@main
struct TimeTrackerApp: App {

    @State private var timerVM = TimerViewModel()
    @State private var notificationManager = NotificationManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(timerVM)
                .environment(notificationManager)
        }
        .modelContainer(DataController.sharedContainer)
    }
}
