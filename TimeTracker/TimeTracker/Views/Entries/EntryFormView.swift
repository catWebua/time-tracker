import SwiftUI
import SwiftData

struct EntryFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var entry: TimeEntry?

    @Query(
        filter: #Predicate<Project> { !$0.isArchived },
        sort: \Project.createdAt,
        order: .reverse
    )
    private var projects: [Project]

    @State private var selectedProject: Project?
    @State private var taskDescription: String = ""
    @State private var startDate: Date = Date().addingTimeInterval(-3600)
    @State private var endDate: Date = Date()

    private var isEditing: Bool { entry != nil }
    private var isValid: Bool { selectedProject != nil && endDate > startDate }

    private var duration: TimeInterval {
        endDate.timeIntervalSince(startDate)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AuraBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Title
                        Text(isEditing ? "Редагувати" : "Новий запис")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal)
                            .padding(.top, 20)

                        VStack(spacing: 24) {
                            // Project Selector
                            VStack(alignment: .leading, spacing: 12) {
                                Text(LocalizedStringKey("ПРОЕКТ"))
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .tracking(1.5)
                                    .foregroundStyle(.white.opacity(0.3))
                                    .padding(.leading, 8)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(projects) { project in
                                            Button {
                                                selectedProject = project
                                            } label: {
                                                VStack(spacing: 8) {
                                                    Circle()
                                                        .fill(project.accentColor)
                                                        .frame(width: 32, height: 32)
                                                        .shadow(color: project.accentColor.opacity(0.3), radius: 4)
                                                        .overlay {
                                                            if selectedProject?.id == project.id {
                                                                Image(systemName: "checkmark")
                                                                    .font(.caption.bold())
                                                                    .foregroundStyle(.white)
                                                            }
                                                        }
                                                    
                                                    Text(project.name)
                                                        .font(.caption2.bold())
                                                        .foregroundStyle(selectedProject?.id == project.id ? .white : .white.opacity(0.4))
                                                        .lineLimit(1)
                                                }
                                                .frame(width: 80)
                                                .padding(.vertical, 12)
                                                .glassCard(cornerRadius: 16, opacity: selectedProject?.id == project.id ? 0.15 : 0.05)
                                                .overlay {
                                                    if selectedProject?.id == project.id {
                                                        RoundedRectangle(cornerRadius: 16)
                                                            .stroke(project.accentColor.opacity(0.5), lineWidth: 1)
                                                    }
                                                }
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal, 4)
                                }
                            }
                            .padding(.horizontal)

                            // Description
                            GlassInputGroup(title: "ОПИС РОБОТИ") {
                                GlassTextField("Що було зроблено?", text: $taskDescription)
                            }
                            .padding(.horizontal)

                            // Time Selection
                            GlassInputGroup(title: "ЧАС") {
                                VStack(spacing: 20) {
                                    DatePicker(LocalizedStringKey("Початок"), selection: $startDate)
                                        .tint(.purple)
                                    
                                    Divider().background(Color.white.opacity(0.1))
                                    
                                    DatePicker(LocalizedStringKey("Кінець"), selection: $endDate)
                                        .tint(.purple)
                                }
                            }
                            .padding(.horizontal)
                            
                            // Duration Summary
                            VStack(spacing: 8) {
                                Text("ТРИВАЛІСТЬ")
                                    .font(.system(size: 11, weight: .black, design: .rounded))
                                    .tracking(1.5)
                                    .foregroundStyle(.white.opacity(0.3))
                                
                                Text(DurationFormatter.formatted(duration))
                                    .font(.system(size: 32, weight: .bold, design: .monospaced))
                                    .foregroundStyle(duration > 0 ? .white : .red.opacity(0.8))
                                    .shadow(color: .purple.opacity(duration > 0 ? 0.3 : 0), radius: 10)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(24)
                            .glassCard(cornerRadius: 24, opacity: 0.1)
                            .padding(.horizontal)
                        }

                        // Actions
                        VStack(spacing: 12) {
                            Button {
                                save()
                            } label: {
                                Text(isEditing ? "Зберегти запис" : "Додати до історії")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glass(color: isValid ? .purple : .gray))
                            .disabled(!isValid)
                            
                            Button("Скасувати") { dismiss() }
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.4))
                                .padding(.vertical, 8)
                        }
                        .padding(.horizontal)
                        
                        Spacer(minLength: 120)
                    }
                }
            }
            .toolbar(.hidden)
            .onAppear {
                if let e = entry {
                    selectedProject = e.project
                    taskDescription = e.taskDescription
                    startDate = e.startedAt
                    endDate = e.endedAt ?? Date()
                } else if let first = projects.first {
                    selectedProject = first
                }
            }
        }
    }

    private func save() {
        let duration = endDate.timeIntervalSince(startDate)

        if let e = entry {
            e.project = selectedProject
            e.taskDescription = taskDescription
            e.startedAt = startDate
            e.endedAt = endDate
            e.durationSeconds = Int(duration)
        } else {
            let newEntry = TimeEntry(
                project: selectedProject,
                taskDescription: taskDescription,
                startedAt: startDate
            )
            newEntry.endedAt = endDate
            newEntry.durationSeconds = Int(duration)
            context.insert(newEntry)
        }

        try? context.save()
        dismiss()
    }
}
