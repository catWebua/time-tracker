// MARK: - Widget Bundle
// Файл: TimeTrackerWidget/TimeTrackerWidgetBundle.swift
//
// ⚠️  ЯК ДОДАТИ WIDGET TARGET В XCODE:
// 1. File → New → Target
// 2. Обери "Widget Extension"
// 3. Назва: TimeTrackerWidget
// 4. Product Name: TimeTrackerWidget
// 5. Include Live Activity: ✅ (якщо хочеш Dynamic Island)
// 6. Finish
// 7. Скопіюй цей файл та TimerWidget.swift у новий target
// 8. У Build Settings обох targets: встанови DEVELOPMENT_TEAM → свій Apple ID

import WidgetKit
import SwiftUI
import SwiftData

@main
struct TimeTrackerWidgetBundle: WidgetBundle {
    var body: some Widget {
        TimerWidget()
        TimerLiveActivity()
    }
}

// MARK: - Widget Provider

struct TimerEntry: TimelineEntry {
    let date: Date
    let projectName: String?
    let projectColorHex: String?
    let isRunning: Bool
    let startedAt: Date?
    let displayTime: String
}

struct TimerWidgetProvider: TimelineProvider {
    typealias Entry = TimerEntry

    func placeholder(in context: Context) -> TimerEntry {
        TimerEntry(date: Date(), projectName: "Клієнт X", projectColorHex: "#A855F7",
                   isRunning: true, startedAt: Date(), displayTime: "01:24:37")
    }

    func getSnapshot(in context: Context, completion: @escaping (TimerEntry) -> Void) {
        Task { @MainActor in
            completion(currentEntry())
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerEntry>) -> Void) {
        Task { @MainActor in
            var entries: [TimerEntry] = []
            let current = currentEntry()
            entries.append(current)

            if current.isRunning {
                // Refresh every minute while running
                let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date())!
                completion(Timeline(entries: entries, policy: .after(nextUpdate)))
            } else {
                completion(Timeline(entries: entries, policy: .never))
            }
        }
    }

    @MainActor
    private func currentEntry() -> TimerEntry {
        let container = DataController.sharedContainer
        let context = container.mainContext
        let descriptor = FetchDescriptor<TimeEntry>(
            predicate: #Predicate<TimeEntry> { $0.endedAt == nil }
        )
        let activeEntry = try? context.fetch(descriptor).first
        let elapsed = activeEntry.map { Date().timeIntervalSince($0.startedAt) } ?? 0

        return TimerEntry(
            date: Date(),
            projectName: activeEntry?.project?.name,
            projectColorHex: activeEntry?.project?.colorHex,
            isRunning: activeEntry != nil,
            startedAt: activeEntry?.startedAt,
            displayTime: DurationFormatter.formatted(elapsed)
        )
    }
}

// MARK: - Timer Widget

struct TimerWidget: Widget {
    let kind: String = "TimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimerWidgetProvider()) { entry in
            TimerWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("FreelanceKit Таймер")
        .description("Дивись і керуй таймером прямо з Home Screen.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Views

struct TimerWidgetView: View {
    let entry: TimerEntry
    @Environment(\.widgetFamily) private var family

    var accentColor: Color {
        Color(hex: entry.projectColorHex ?? "#A855F7")
    }

    var body: some View {
        switch family {
        case .systemSmall: smallView
        default:           mediumView
        }
    }

    private var smallView: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Circle()
                    .fill(entry.isRunning ? accentColor : Color.secondary)
                    .frame(width: 8, height: 8)
                Text(entry.isRunning ? "Активний" : "Зупинено")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(entry.displayTime)
                .font(.system(.title2, design: .monospaced, weight: .medium))
                .minimumScaleFactor(0.7)

            if let name = entry.projectName {
                Text(name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Circle()
                        .fill(entry.isRunning ? accentColor : Color.secondary)
                        .frame(width: 8, height: 8)
                    Text(entry.isRunning ? "Таймер іде" : "Таймер зупинено")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(entry.displayTime)
                    .font(.system(.largeTitle, design: .monospaced, weight: .thin))
                    .minimumScaleFactor(0.6)

                if let name = entry.projectName {
                    Text(name)
                        .font(.subheadline)
                        .foregroundStyle(accentColor)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Deep link button to open app
            Link(destination: URL(string: "freelancekit://timer")!) {
                Image(systemName: entry.isRunning ? "stop.circle.fill" : "play.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(entry.isRunning ? .red : accentColor)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
