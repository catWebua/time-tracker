import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var context

    @State private var projectToEdit: Project?

    private var sortedEntries: [TimeEntry] {
        project.completedEntries.sorted { $0.startedAt > $1.startedAt }
    }

    /// Today's total seconds for this project
    private var todayDuration: TimeInterval {
        project.completedEntries
            .filter { Calendar.current.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                statsCard

                if let progress = project.budgetProgress {
                    budgetCard(progress: progress)
                }

                if project.dailyGoalHours > 0 {
                    dailyGoalCard
                }

                if sortedEntries.isEmpty {
                    emptyEntries
                } else {
                    entriesSection
                }
            }
            .padding()
        }
        .navigationTitle(project.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    projectToEdit = project
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.title3)
                }
            }
        }
        .sheet(item: $projectToEdit) { editProject in
            ProjectFormView(project: editProject)
        }
    }

    // MARK: - Stats Card

    private var statsCard: some View {
        HStack(spacing: 0) {
            statItem(
                value: DurationFormatter.short(project.totalDuration),
                label: "Всього часу",
                icon: "clock.fill"
            )

            Divider()
                .overlay(Color.white.opacity(0.1))
                .frame(maxHeight: 60)

            statItem(
                value: "\(project.completedEntries.count)",
                label: "Сесій",
                icon: "list.bullet"
            )

            if project.hourlyRate > 0 {
                Divider()
                    .overlay(Color.white.opacity(0.1))
                    .frame(maxHeight: 60)

                statItem(
                    value: project.formattedEarned,
                    label: "Зароблено",
                    icon: "banknote.fill",
                    accentColor: project.accentColor
                )
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
    }

    private func statItem(value: String, label: String, icon: String, accentColor: Color = .purple) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.footnote)
                .foregroundStyle(accentColor)
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Budget Card

    private func budgetCard(progress: Double) -> some View {
        let isOver = progress >= 1.0
        let isWarning = progress >= 0.8 && !isOver
        let barColor: Color = isOver ? .red : isWarning ? .orange : project.accentColor

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: isOver ? "exclamationmark.triangle.fill" : "chart.bar.fill")
                    .foregroundStyle(barColor)
                Text("Бюджет годин")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(DurationFormatter.short(project.totalDuration)) / \(Int(project.estimatedHours))г")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 8)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor)
                        .frame(width: geo.size.width * progress, height: 8)
                        // Skill: animation(_:value:) includes value parameter
                        .animation(.spring(response: 0.5), value: progress)
                }
            }
            .frame(height: 8)

            if isOver {
                Text("Бюджет перевищено!")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if isWarning {
                Text("Залишилось менше 20% бюджету")
                    .font(.caption)
                    .foregroundStyle(.orange)
            } else {
                Text("\(Int((1 - progress) * project.estimatedHours))г залишилось")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(barColor.opacity(0.3), lineWidth: 1)
        )
    }

    // MARK: - Daily Goal Card

    private var dailyGoalCard: some View {
        let goalSeconds = project.dailyGoalHours * 3600
        let progress = min(todayDuration / goalSeconds, 1.0)
        let isDone = todayDuration >= goalSeconds

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(isDone ? Color.green : project.accentColor, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: progress)
            }
            .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(isDone ? "Денна ціль досягнута! 🎉" : "Денна ціль")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                Text("\(DurationFormatter.short(todayDuration)) з \(Int(project.dailyGoalHours))г сьогодні")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isDone ? Color.green.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Entries

    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Сесії")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Spacer()
                let unbilled = project.unbilledEntries.count
                if unbilled > 0 {
                    Text("\(unbilled) не оплачено")
                        .font(.caption)
                        .foregroundStyle(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Color.orange.opacity(0.12), in: Capsule())
                }
            }
            .padding(.horizontal, 4)

            ForEach(sortedEntries) { entry in
                entryRow(entry)
            }
        }
    }

    private func entryRow(_ entry: TimeEntry) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 3) {
                if !entry.taskDescription.isEmpty {
                    Text(entry.taskDescription)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                }
                Text(entry.startedAt.relativeLabel())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 8) {
                if entry.isBilled {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }
                Text(entry.formattedDuration)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
        }
        .padding(14)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(entry.isBilled ? Color.green.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }

    // Skill: ContentUnavailableView for empty states (iOS 17+)
    private var emptyEntries: some View {
        ContentUnavailableView {
            Label("Немає сесій", systemImage: "timer")
        } description: {
            Text("Запусти таймер для цього проекту")
        }
        .padding(.top, 20)
    }
}
