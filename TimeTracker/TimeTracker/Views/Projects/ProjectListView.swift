import SwiftUI
import SwiftData

struct ProjectListView: View {
    @Environment(\.modelContext) private var context

    @Query(sort: \Project.createdAt, order: .reverse)
    private var allProjects: [Project]

    @State private var showAddForm = false

    private var activeProjects: [Project] { allProjects.filter { !$0.isArchived } }
    private var archivedProjects: [Project] { allProjects.filter { $0.isArchived } }

    var body: some View {
        NavigationStack {
            Group {
                if allProjects.isEmpty {
                    ContentUnavailableView {
                        Label("Немає проектів", systemImage: "folder.badge.plus")
                    } description: {
                        Text("Додай свій перший проект щоб почати трекати час")
                    } actions: {
                        Button("Додати проект") { showAddForm = true }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                    }
                } else {
                    projectList
                }
            }
            .navigationTitle("Проекти")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddForm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(isPresented: $showAddForm) {
            ProjectFormView()
        }
    }

    // MARK: - Project List

    private var projectList: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(activeProjects) { project in
                    // NavigationLink(destination:) — стабільний, без Hashable/Sendable вимог
                    NavigationLink(destination: ProjectDetailView(project: project)) {
                        ProjectCard(project: project)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            archiveProject(project)
                        } label: {
                            Label("Архівувати", systemImage: "archivebox")
                        }
                        Button(role: .destructive) {
                            deleteProject(project)
                        } label: {
                            Label("Видалити", systemImage: "trash")
                        }
                    }
                }

                if !archivedProjects.isEmpty {
                    DisclosureGroup("Архів (\(archivedProjects.count))") {
                        ForEach(archivedProjects) { project in
                            NavigationLink(destination: ProjectDetailView(project: project)) {
                                ProjectCard(project: project)
                                    .opacity(0.6)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .tint(.secondary)
                    .padding(.top, 8)
                }
            }
            .padding()
        }
    }

    // MARK: - Actions

    private func archiveProject(_ project: Project) {
        project.isArchived = true
        try? context.save()
    }

    private func deleteProject(_ project: Project) {
        context.delete(project)
        try? context.save()
    }
}

// MARK: - Project Card

private struct ProjectCard: View {
    let project: Project

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 6)
                .fill(project.accentColor)
                .frame(width: 4)
                .frame(maxHeight: .infinity)

            VStack(alignment: .leading, spacing: 4) {
                Text(project.name)
                    .font(.headline)
                    .foregroundStyle(.white)
                if !project.client.isEmpty {
                    Text(project.client)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(DurationFormatter.short(project.totalDuration))
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                if project.hourlyRate > 0 {
                    Text(DurationFormatter.earnings(project.totalEarned, currency: project.currency))
                        .font(.caption)
                        .foregroundStyle(.purple)
                }
            }

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}
