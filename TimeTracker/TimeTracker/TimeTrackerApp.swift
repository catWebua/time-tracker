import SwiftUI
import SwiftData

@main
struct TimeTrackerApp: App {

    @State private var timerVM = TimerViewModel()
    @State private var notificationManager = NotificationManager()
    @AppStorage(AppLanguage.storageKey) private var appLanguage = AppLanguage.ukrainian.rawValue

    private var currentLanguage: AppLanguage {
        AppLanguage(rawValue: appLanguage) ?? .ukrainian
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .id(appLanguage)
                .environment(timerVM)
                .environment(notificationManager)
                .environment(\.locale, currentLanguage.locale)
        }
        .modelContainer(DataController.sharedContainer)
    }
}
