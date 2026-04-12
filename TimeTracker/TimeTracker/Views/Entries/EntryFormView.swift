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

    var body: some View {
        NavigationStack {
            Form {
                Section("Проект") {
                    if projects.isEmpty {
                        Text("Спочатку створіть проект")
                            .foregroundStyle(.secondary)
                    } else {
                        Picker("Проект", selection: $selectedProject) {
                            Text("Не вибрано").tag(Optional<Project>.none)
                            ForEach(projects) { project in
                                HStack {
                                    Circle()
                                        .fill(project.accentColor)
                                        .frame(width: 8, height: 8)
                                    Text(project.name)
                                }
                                .tag(Optional(project))
                            }
                        }
                    }
                }

                Section("Опис") {
                    TextField("Що робив?", text: $taskDescription)
                }

                Section("Час") {
                    DatePicker("Початок", selection: $startDate)
                    DatePicker("Кінець", selection: $endDate)
                    HStack {
                        Text("Тривалість")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(DurationFormatter.formatted(endDate.timeIntervalSince(startDate)))
                            .foregroundStyle(.purple)
                            .monospacedDigit()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(isEditing ? "Редагувати" : "Новий запис")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Зберегти" : "Додати") { save() }
                        .fontWeight(.semibold)
                        .disabled(!isValid)
                }
            }
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
