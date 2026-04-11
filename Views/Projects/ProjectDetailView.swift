import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var context

    // Skill: .sheet(item:) for model-based sheet presentation (preferred over boolean flag)
    // Set to `project` to show, nil to dismiss — avoids separate boolean state
    @State private var projectToEdit: Project?

    private var sortedEntries: [TimeEntry] {
        project.completedEntries.sorted { $0.startedAt > $1.startedAt }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                statsCard

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
                    // Skill: set item to trigger .sheet(item:)
                    projectToEdit = project
                } label: {
                    Image(systemName: "pencil.circle")
                        .font(.title3)
                }
            }
        }
        // Skill: .sheet(item:) — automatically tied to model identity, no extra boolean needed
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

    // MARK: - Entries

    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Сесії")
                .font(.headline)
                .foregroundStyle(.secondary)
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
            Text(entry.formattedDuration)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.white)
                .monospacedDigit()
        }
        .padding(14)
        .background(Color.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12))
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
