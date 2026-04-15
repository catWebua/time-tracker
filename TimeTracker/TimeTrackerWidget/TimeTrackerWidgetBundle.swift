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
                .containerBackground(for: .widget) {
                    ZStack {
                        Color(red: 0.05, green: 0.03, blue: 0.12)
                        
                        LinearGradient(
                            colors: [Color(hex: entry.projectColorHex ?? "#A855F7").opacity(0.3), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    }
                }
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
                    .shadow(color: entry.isRunning ? accentColor : .clear, radius: 4)
                Text(entry.isRunning ? "АКТИВНО" : "ЗУПИНЕНО")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Text(entry.displayTime)
                .font(.system(.title2, design: .monospaced, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: accentColor.opacity(0.5), radius: 4, x: 0, y: 0)
                .minimumScaleFactor(0.7)

            if let name = entry.projectName {
                Text(name.uppercased())
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .foregroundStyle(accentColor)
                    .tracking(1)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            // Neon vertical glowing line
            RoundedRectangle(cornerRadius: 4)
                .fill(accentColor)
                .frame(width: 4)
                .shadow(color: accentColor.opacity(0.8), radius: 4, x: 0, y: 0)
                
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Circle()
                        .fill(entry.isRunning ? accentColor : Color.secondary)
                        .frame(width: 8, height: 8)
                        .shadow(color: entry.isRunning ? accentColor : .clear, radius: 4)
                    Text(entry.isRunning ? "ТАЙМЕР ЗАПУЩЕНО" : "ЗУПИНЕНО")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.5))
                }

                Text(entry.displayTime)
                    .font(.system(.largeTitle, design: .monospaced, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: accentColor.opacity(0.5), radius: 6, x: 0, y: 0)
                    .minimumScaleFactor(0.6)

                if let name = entry.projectName {
                    Text(name.uppercased())
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundStyle(accentColor)
                        .tracking(1)
                        .lineLimit(1)
                }
            }

            Spacer()

            // Deep link button to open app
            Link(destination: URL(string: "freelancekit://timer")!) {
                ZStack {
                    Circle()
                        .fill(entry.isRunning ? Color.red.opacity(0.2) : accentColor.opacity(0.2))
                        .frame(width: 50, height: 50)
                        
                    Image(systemName: entry.isRunning ? "stop.fill" : "play.fill")
                        .font(.system(size: 20, weight: .black))
                        .foregroundStyle(entry.isRunning ? Color.red : accentColor)
                        .shadow(color: entry.isRunning ? Color.red : accentColor, radius: 4)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }
}
