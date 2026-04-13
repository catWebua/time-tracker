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
            ZStack {
                // Background is handled by ContentView
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title Header
                        HStack {
                            Text("Проекти")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Button {
                                showAddForm = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.purple)
                                    .symbolRenderingMode(.hierarchical)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)

                        if allProjects.isEmpty {
                            emptyState
                        } else {
                            projectGrid
                        }
                    }
                }
            }
            .toolbar(.hidden)
        }
        .sheet(isPresented: $showAddForm) {
            ProjectFormView()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 100)
            Image(systemName: "folder.badge.plus")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.1))
            Text("Немає проектів")
                .font(.title3.bold())
                .foregroundStyle(.white.opacity(0.4))
            Button("Створити проект") { showAddForm = true }
                .buttonStyle(.glass(color: .purple))
        }
        .frame(maxWidth: .infinity)
    }

    private var projectGrid: some View {
        LazyVStack(spacing: 16) {
            ForEach(activeProjects) { project in
                NavigationLink(destination: ProjectDetailView(project: project)) {
                    ProjectCard(project: project)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button { archiveProject(project) } label: {
                        Label("Архівувати", systemImage: "archivebox")
                    }
                    Button(role: .destructive) { deleteProject(project) } label: {
                        Label("Видалити", systemImage: "trash")
                    }
                }
            }

            if !archivedProjects.isEmpty {
                DisclosureGroup {
                    ForEach(archivedProjects) { project in
                        NavigationLink(destination: ProjectDetailView(project: project)) {
                            ProjectCard(project: project)
                                .opacity(0.6)
                        }
                        .buttonStyle(.plain)
                    }
                } label: {
                    Text("Архів (\(archivedProjects.count))")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white.opacity(0.3))
                }
                .padding(.top, 8)
                .accentColor(.white.opacity(0.3))
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 100) // Space for TabBar
    }

    private func archiveProject(_ project: Project) {
        project.isArchived = true
        try? context.save()
    }

    private func deleteProject(_ project: Project) {
        context.delete(project)
        try? context.save()
    }
}

// MARK: - Redesigned Project Card
private struct ProjectCard: View {
    let project: Project

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                // Project Icon / Initial
                ZStack {
                    Circle()
                        .fill(project.accentColor.opacity(0.15))
                        .frame(width: 44, height: 44)
                    
                    Text(project.name.prefix(1).uppercased())
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundStyle(project.accentColor)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(project.name)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                    
                    if !project.client.isEmpty {
                        Text(project.client)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(DurationFormatter.short(project.totalDuration))
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundStyle(.white)
                    
                    if project.hourlyRate > 0 {
                        Text(DurationFormatter.earnings(project.totalEarned, currency: project.currency))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(project.accentColor)
                    }
                }
            }
            
            // Subtle progress or divider
            Capsule()
                .fill(Color.white.opacity(0.05))
                .frame(height: 1)
        }
        .padding(16)
        .glassCard(cornerRadius: 20, opacity: 0.1)
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(
                    LinearGradient(
                        colors: [project.accentColor.opacity(0.4), .clear],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
    }
}
