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
            ZStack {
                // Premium background matching the main view aesthetic
                MeshGradient(width: 3, height: 3, points: [
                    [0, 0], [0.5, 0], [1, 0],
                    [0, 0.5], [0.5, 0.5], [1, 0.5],
                    [0, 1], [0.5, 1], [1, 1]
                ], colors: [
                    .black, .black, .black,
                    .purple.opacity(0.12), .black, .blue.opacity(0.08),
                    .black, .black, .black
                ])
                .ignoresSafeArea()

                if projects.isEmpty {
                    emptyState
                } else {
                    projectList
                }
            }
            .navigationTitle("Оберіть проект")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Готово") { dismiss() }
                        .fontWeight(.bold)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(.clear) // Expert: Use clear background to let the custom mesh gradient shine
    }

    private var projectList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(projects) { project in
                    ProjectPickerRow(
                        project: project,
                        isSelected: selectedProject?.id == project.id
                    ) {
                        selectedProject = project
                        dismiss()
                    }
                    .primaryHaptic(trigger: selectedProject?.id)
                }
            }
            .padding()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 60))
                .foregroundStyle(.purple.gradient)
            Text("Немає проектів")
                .font(.headline)
            Text("Створіть свій перший проект у вкладці «Проекти»")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

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
                    .shadow(color: project.accentColor.opacity(0.5), radius: 6)

                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                    if !project.client.isEmpty {
                        Text(project.client)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(project.accentColor.gradient)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            // Use our new design system tokens
            .glassCard(cornerRadius: 18, opacity: isSelected ? 0.3 : 0.15, shadow: isSelected)
        }
        .buttonStyle(.plain)
    }
}
