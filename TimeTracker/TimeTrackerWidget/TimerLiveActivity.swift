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
                .activityBackgroundTint(Color(red: 0.05, green: 0.03, blue: 0.12))
                .activitySystemActionForegroundColor(Color(hex: context.state.projectColorHex))

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
            // Neon vertical glowing line
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: context.state.projectColorHex))
                .frame(width: 4)
                .shadow(color: Color(hex: context.state.projectColorHex).opacity(0.8), radius: 4, x: 0, y: 0)

            VStack(alignment: .leading, spacing: 4) {
                Text(context.state.projectName.uppercased())
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white)
                    
                Text(context.attributes.taskDescription.isEmpty ? "ВІДСЛІДКОВУВАННЯ" : context.attributes.taskDescription.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()

            Text(timerInterval: context.state.startedAt...Date.distantFuture, countsDown: false)
                .font(.system(.title2, design: .monospaced, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(Color(hex: context.state.projectColorHex))
                .shadow(color: Color(hex: context.state.projectColorHex).opacity(0.5), radius: 8, x: 0, y: 0)
        }
        .padding()
    }
}
