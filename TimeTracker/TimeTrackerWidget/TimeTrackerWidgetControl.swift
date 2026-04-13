import AppIntents
import SwiftUI
import WidgetKit
import SwiftData

@available(iOS 18.0, *)
struct TimeTrackerWidgetControl: ControlWidget {
    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: "catWebua.TimeTracker.TimeTrackerWidget.Control",
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "Таймер",
                isOn: value,
                action: ToggleTimerIntent()
            ) { isRunning in
                Label(isRunning ? "Зупинити" : "Запустити", systemImage: isRunning ? "stop.fill" : "play.fill")
            }
        }
        .displayName("Таймер FreelanceKit")
        .description("Швидкий запуск та зупинка таймера.")
    }
}

@available(iOS 18.0, *)
extension TimeTrackerWidgetControl {
    struct Provider: ControlValueProvider {
        var previewValue: Bool { false }

        func currentValue() async throws -> Bool {
            await MainActor.run {
                // Check if timer is running from Shared DataController
                let container = DataController.sharedContainer
                let context = container.mainContext
                let descriptor = FetchDescriptor<TimeEntry>(
                    predicate: #Predicate<TimeEntry> { $0.endedAt == nil }
                )
                let activeEntry = try? context.fetch(descriptor).first
                return activeEntry != nil
            }
        }
    }
}

// Minimal placeholder for the intent if not yet restored elsewhere
@available(iOS 18.0, *)
struct ToggleTimerIntent: SetValueIntent {
    static var title: LocalizedStringResource = "Перемкнути таймер"
    @Parameter(title: "Стан")
    var value: Bool

    func perform() async throws -> some IntentResult {
        // Logic will be handled by the main app or shared controller
        return .result()
    }
}
