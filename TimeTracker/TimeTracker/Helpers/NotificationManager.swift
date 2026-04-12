import Foundation
import UserNotifications

@Observable
@MainActor
final class NotificationManager {

    // MARK: - State

    var isAuthorized: Bool = false

    // MARK: - Init

    init() {
        Task { await refreshStatus() }
    }

    // MARK: - Public API

    func requestPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
        } catch {
            isAuthorized = false
        }
    }

    func refreshStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    /// Schedule a daily reminder at a specific time.
    func scheduleDailyReminder(hour: Int, minute: Int) {
        removeNotification(id: NotificationID.daily)

        let content = UNMutableNotificationContent()
        content.title = "FreelanceKit"
        content.body = "Не забудь запустити таймер!"
        content.sound = .default

        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        let request = UNNotificationRequest(
            identifier: NotificationID.daily,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    /// Schedule a one-time alert if timer has been running longer than `hours`.
    func scheduleLongRunningAlert(after hours: Double) {
        removeNotification(id: NotificationID.longRunning)

        let content = UNMutableNotificationContent()
        content.title = "Таймер ще тікає ⏱"
        content.body = "Ти відслідковуєш час вже \(Int(hours)) год. — може час зупинитись?"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: hours * 3600,
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: NotificationID.longRunning,
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    func removeLongRunningAlert() {
        removeNotification(id: NotificationID.longRunning)
    }

    func cancelDailyReminder() {
        removeNotification(id: NotificationID.daily)
    }

    // MARK: - Private

    private func removeNotification(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    // MARK: - Notification IDs

    enum NotificationID {
        static let daily       = "com.timetracker.daily"
        static let longRunning = "com.timetracker.longrunning"
    }
}
