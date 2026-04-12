import SwiftUI
import SwiftData

struct TimerView: View {
    @Environment(\.modelContext) private var context
    @Environment(TimerViewModel.self) private var timerVM

    @Query(
        filter: #Predicate<Project> { !$0.isArchived },
        sort: \Project.createdAt,
        order: .reverse
    )
    private var projects: [Project]

    // Query all completed entries to compute daily goal progress
    @Query(
        filter: #Predicate<TimeEntry> { $0.endedAt != nil },
        sort: \TimeEntry.startedAt
    )
    private var completedEntries: [TimeEntry]

    @State private var showProjectPicker = false
    @State private var showNoProjectAlert = false

    // MARK: - Computed

    private var todayDurationForProject: TimeInterval {
        guard let project = timerVM.selectedProject else { return 0 }
        return completedEntries
            .filter { $0.project?.id == project.id && Calendar.current.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + $1.duration }
    }

    private var dailyGoalProgress: Double? {
        guard let project = timerVM.selectedProject, project.dailyGoalHours > 0 else { return nil }
        return min(todayDurationForProject / (project.dailyGoalHours * 3600), 1.0)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundGradient

                VStack(spacing: 0) {
                    Spacer()
                    projectSelector
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)

                    timerDisplay
                        .padding(.bottom, 24)

                    if timerVM.isRunning {
                        runningBadge
                            .padding(.bottom, 24)
                    }

                    taskDescriptionField
                        .padding(.horizontal, 20)
                        .padding(.bottom, 48)

                    Spacer()

                    startStopButton
                        .padding(.bottom, timerVM.selectedProject?.dailyGoalHours ?? 0 > 0 ? 24 : 48)
                        // Skill: sensoryFeedback(_:trigger:) replaces UIImpactFeedbackGenerator (iOS 17+)
                        .sensoryFeedback(.start, trigger: timerVM.isRunning) { old, new in !old && new }
                        .sensoryFeedback(.stop,  trigger: timerVM.isRunning) { old, new in  old && !new }

                    // Daily goal progress bar
                    if let progress = dailyGoalProgress,
                       let project = timerVM.selectedProject {
                        dailyGoalBar(progress: progress, project: project)
                            .padding(.horizontal, 28)
                            .padding(.bottom, 48)
                    }
                }
            }
            .navigationTitle("FreelanceKit")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showProjectPicker) {
            ProjectPickerSheet(selectedProject: selectedProjectBinding)
        }
        .alert("Оберіть проект", isPresented: $showNoProjectAlert) {
            Button("Обрати") { showProjectPicker = true }
            Button("Скасувати", role: .cancel) {}
        } message: {
            Text("Потрібно обрати проект перед стартом.")
        }
    }

    // MARK: - Subviews

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                Color.purple.opacity(0.08),
                Color(.systemBackground)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var projectSelector: some View {
        Button {
            guard !timerVM.isRunning else { return }
            showProjectPicker = true
        } label: {
            HStack(spacing: 12) {
                if let project = timerVM.selectedProject {
                    Circle()
                        .fill(project.accentColor)
                        .frame(width: 10, height: 10)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(project.name)
                            .font(.headline)
                            .foregroundStyle(.white)
                        if !project.client.isEmpty {
                            Text(project.client)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Image(systemName: "folder.badge.plus")
                        .foregroundStyle(.purple)
                    Text("Оберіть проект")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if !timerVM.isRunning {
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        timerVM.selectedProject?.accentColor.opacity(0.3) ?? Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .disabled(timerVM.isRunning)
    }

    private var timerDisplay: some View {
        Text(timerVM.displayTime)
            .font(.system(size: 72, weight: .thin, design: .monospaced))
            .foregroundStyle(timerVM.isRunning ? .white : .secondary)
            .contentTransition(.numericText())
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: timerVM.displayTime)
            .shadow(
                color: timerVM.isRunning ? Color.purple.opacity(0.3) : .clear,
                radius: 20
            )
    }

    private var runningBadge: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.green)
                .frame(width: 6, height: 6)
            Text("тікає")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(Color.green.opacity(0.1), in: Capsule())
        .overlay(Capsule().stroke(Color.green.opacity(0.2), lineWidth: 1))
    }

    // Skill: @Bindable for injected @Observable objects needing bindings (iOS 17+)
    @ViewBuilder
    private var taskDescriptionField: some View {
        @Bindable var vm = timerVM
        if !timerVM.isRunning {
            TextField("Що зараз робиш? (необов'язково)", text: $vm.taskDescription)
                .textFieldStyle(.plain)
                .padding(.horizontal, 20)
                .padding(.vertical, 14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        } else if let desc = timerVM.activeEntry?.taskDescription, !desc.isEmpty {
            Text(desc)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }

    private var startStopButton: some View {
        Button {
            if timerVM.isRunning {
                timerVM.stop(context: context)
            } else {
                if timerVM.selectedProject != nil {
                    timerVM.start(context: context)
                } else {
                    showNoProjectAlert = true
                }
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        timerVM.isRunning
                            ? LinearGradient(colors: [.red, Color(hex: "#FF6B6B")], startPoint: .top, endPoint: .bottom)
                            : LinearGradient(colors: [.purple, Color(hex: "#7C3AED")], startPoint: .top, endPoint: .bottom)
                    )
                    .frame(width: 96, height: 96)
                    .shadow(
                        color: (timerVM.isRunning ? Color.red : Color.purple).opacity(0.45),
                        radius: 24,
                        y: 8
                    )

                Image(systemName: timerVM.isRunning ? "stop.fill" : "play.fill")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(.white)
                    .offset(x: timerVM.isRunning ? 0 : 3)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(timerVM.isRunning ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: timerVM.isRunning)
    }

    // MARK: - Daily Goal Bar

    private func dailyGoalBar(progress: Double, project: Project) -> some View {
        let isDone = progress >= 1.0
        let barColor: Color = isDone ? .green : project.accentColor
        let elapsed = todayDurationForProject + (timerVM.isRunning ? Date().timeIntervalSince(timerVM.activeEntry?.startedAt ?? Date()) : 0)
        let elapsedDisplay = DurationFormatter.short(elapsed)
        let goalDisplay = "\(Int(project.dailyGoalHours))г"

        return VStack(spacing: 6) {
            HStack {
                Text(isDone ? "Ціль досягнута 🎉" : "Денна ціль")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(elapsedDisplay) / \(goalDisplay)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(barColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 5)
                    Capsule()
                        .fill(barColor)
                        .frame(width: geo.size.width * progress, height: 5)
                        .animation(.spring(response: 0.6), value: progress)
                }
            }
            .frame(height: 5)
        }
    }

    // MARK: - Helpers

    private var selectedProjectBinding: Binding<Project?> {
        Binding(
            get: { timerVM.selectedProject },
            set: { timerVM.selectedProject = $0 }
        )
    }
}
