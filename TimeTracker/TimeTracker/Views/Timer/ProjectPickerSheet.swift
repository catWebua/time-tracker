import SwiftUI
import SwiftData

struct ProjectPickerSheet: View {
    @Binding var selectedProject: Project?
    @Environment(\.dismiss) private var dismiss

    @Query(
        filter: #Predicate<Project> { !$0.isArchived },
        sort: \Project.createdAt,
        order: .reverse
    )
    private var projects: [Project]

    var body: some View {
        NavigationStack {
            Group {
                if projects.isEmpty {
                    emptyState
                } else {
                    projectList
                }
            }
            .navigationTitle("Оберіть проект")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private var projectList: some View {
        ScrollView {
            LazyVStack(spacing: 10) {
                ForEach(projects) { project in
                    ProjectPickerRow(
                        project: project,
                        isSelected: selectedProject?.id == project.id
                    ) {
                        selectedProject = project
                        dismiss()
                    }
                    // Skill: declarative sensoryFeedback instead of UIKit generators
                    .sensoryFeedback(.selection, trigger: selectedProject?.id)
                }
            }
            .padding()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.purple)
            Text("Немає проектів")
                .font(.headline)
            Text("Спочатку створіть проект у вкладці «Проекти»")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

// MARK: - Row (extracted to fix "unable to type-check expression" compiler error)

private struct ProjectPickerRow: View {
    let project: Project
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                Circle()
                    .fill(project.accentColor)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                    if !project.client.isEmpty {
                        Text(project.client)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.purple)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
            .overlay(rowBorder)
        }
        .buttonStyle(.plain)
    }

    private var rowBorder: some View {
        let color: Color = isSelected ? Color.purple.opacity(0.5) : Color.white.opacity(0.07)
        return RoundedRectangle(cornerRadius: 14).stroke(color, lineWidth: 1)
    }
}
