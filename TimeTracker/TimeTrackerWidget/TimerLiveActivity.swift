// MARK: - Live Activity + Dynamic Island
// Файл: TimeTrackerWidget/TimerLiveActivity.swift
//
// ⚠️  Цей файл автоматично додається якщо при створенні Widget Extension
//     поставити галочку "Include Live Activity"

import ActivityKit
import WidgetKit
import SwiftUI

// MARK: - Live Activity Widget

struct TimerLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerActivityAttributes.self) { context in
            // Lock Screen / Banner view
            lockScreenView(context: context)
                .activityBackgroundTint(Color(.systemBackground))

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded (long press)
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: context.state.projectColorHex))
                            .frame(width: 10, height: 10)
                        Text(context.state.projectName)
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: context.state.startedAt...Date.distantFuture, countsDown: false)
                        .font(.system(.title3, design: .monospaced, weight: .medium))
                        .foregroundStyle(Color(hex: context.state.projectColorHex))
                        .monospacedDigit()
                        .frame(maxWidth: 100)
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Label("Тікає", systemImage: "timer")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("Натисни для відкриття")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }

            } compactLeading: {
                // Small left indicator
                Circle()
                    .fill(Color(hex: context.state.projectColorHex))
                    .frame(width: 8, height: 8)

            } compactTrailing: {
                // Timer in compact trailing
                Text(timerInterval: context.state.startedAt...Date.distantFuture, countsDown: false)
                    .font(.system(.caption, design: .monospaced))
                    .monospacedDigit()
                    .frame(maxWidth: 50)

            } minimal: {
                // Minimal (two activities competing)
                Image(systemName: "timer")
                    .foregroundStyle(Color(hex: context.state.projectColorHex))
            }
            .widgetURL(URL(string: "freelancekit://timer"))
            .keylineTint(Color(hex: context.state.projectColorHex))
        }
    }

    @ViewBuilder
    private func lockScreenView(context: ActivityViewContext<TimerActivityAttributes>) -> some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.projectName)
                    .font(.headline)
                    .lineLimit(1)
                Text(context.attributes.taskDescription.isEmpty ? "Відслідковування часу" : context.attributes.taskDescription)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            Text(timerInterval: context.state.startedAt...Date.distantFuture, countsDown: false)
                .font(.system(.title2, design: .monospaced, weight: .medium))
                .monospacedDigit()
                .foregroundStyle(Color(hex: context.state.projectColorHex))
        }
        .padding()
    }
}
