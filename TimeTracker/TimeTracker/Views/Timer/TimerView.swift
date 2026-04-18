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
    @State private var showSettings = false

    // MARK: - Computed

    private var todayDurationForProject: TimeInterval {
        guard let project = timerVM.selectedProject else { return 0 }
        return completedEntries
            .filter { $0.project?.id == project.id && Calendar.current.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + $1.duration }
    }

    private var dailyGoalProgress: Double? {
        guard let project = timerVM.selectedProject, project.dailyGoalHours > 0 else { return nil }
        let total = todayDurationForProject + (timerVM.isRunning ? Date().timeIntervalSince(timerVM.activeEntry?.startedAt ?? Date()) : 0)
        return min(total / (project.dailyGoalHours * 3600), 1.0)
    }

    private var timeRemaining: TimeInterval? {
        guard let project = timerVM.selectedProject, project.dailyGoalHours > 0 else { return nil }
        let goal = project.dailyGoalHours * 3600
        let total = todayDurationForProject + (timerVM.isRunning ? Date().timeIntervalSince(timerVM.activeEntry?.startedAt ?? Date()) : 0)
        return max(goal - total, 0)
    }

    @State private var feedbackTrigger = false

    var body: some View {
        @Bindable var vm = timerVM
        
        NavigationStack {
            ZStack {
                // Content
                VStack(spacing: 0) {
                    customHeader
                    
                    Spacer()
                    
                    // Main Timer Section
                    TimerClockView(
                        displayTime: timerVM.displayTime,
                        isRunning: timerVM.isRunning,
                        accentColor: timerVM.selectedProject?.accentColor ?? .cyan,
                        progress: dailyGoalProgress ?? 0
                    )
                    .padding(.bottom, 40)
                    
                    // Stats Section
                    VStack(spacing: 8) {
                        if let project = timerVM.selectedProject {
                            let currentTotal = todayDurationForProject + (timerVM.isRunning ? Date().timeIntervalSince(timerVM.activeEntry?.startedAt ?? Date()) : 0)
                            HStack(spacing: 12) {
                                statsColumn(title: "СЬОГОДНІ", value: DurationFormatter.formatted(currentTotal), color: Color(hex: "BF5AF2"))
                                
                                Text("/")
                                    .foregroundStyle(.white.opacity(0.1))
                                    .padding(.top, 10)
                                
                                statsColumn(title: "ЦІЛЬ", value: DurationFormatter.formatted(project.dailyGoalHours * 3600), color: .white.opacity(0.4))
                            }
                            
                            Button {
                                showProjectPicker = true
                            } label: {
                                HStack(spacing: 8) {
                                    Text(project.name)
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 18, weight: .heavy))
                                        .foregroundStyle(project.accentColor)
                                }
                                .foregroundStyle(.white)
                            }
                            .buttonStyle(.plain)
                            
                            if let remaining = timeRemaining {
                                Text("залишилось \(DurationFormatter.formatted(remaining))")
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            
                            if !timerVM.taskDescription.isEmpty {
                                Text(timerVM.taskDescription)
                                    .font(.system(size: 14, weight: .medium, design: .rounded))
                                    .foregroundStyle(.white.opacity(0.3))
                                    .padding(.top, 4)
                            }

                        } else {
                            projectPickerButton
                        }
                    }
                    .padding(.bottom, 40)

                    Spacer()

                    // Modern Control Bar
                    ModernControlBar(
                        isRunning: timerVM.isRunning,
                        accentColor: timerVM.selectedProject?.accentColor ?? .cyan,
                        onPlayPause: {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                handleStartStop()
                            }
                        },
                        onSettings: {
                            showSettings = true
                        }
                    )
                    .padding(.bottom, 100)
                }
                .safeAreaPadding(.top)
            }
            .toolbar(.hidden)
            .sheet(isPresented: $showProjectPicker) {
                ProjectPickerSheet(selectedProject: selectedProjectBinding)
            }
            .alert("Оберіть проект", isPresented: $showNoProjectAlert) {
                Button("Обрати") { showProjectPicker = true }
                Button("Скасувати", role: .cancel) {}
            } message: {
                Text("Потрібно обрати проект перед стартом.")
            }
            .sheet(isPresented: $showSettings) {
                SettingsView()
            }
            .sensoryFeedback(.warning, trigger: feedbackTrigger)
        }
    }

    private func statsColumn(title: String, value: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(LocalizedStringKey(title))
                .font(.system(size: 8, weight: .black))
                .tracking(1)
                .foregroundStyle(.white.opacity(0.3))
            Text(value)
                .foregroundStyle(color)
                .font(.system(size: 16, weight: .bold, design: .monospaced))
        }
    }

    private var projectPickerButton: some View {
        Button {
            showProjectPicker = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .bold))
                Text("Оберіть проект")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Color(hex: "BF5AF2"))
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background {
                Capsule()
                    .fill(Color(hex: "BF5AF2").opacity(0.1))
                    .overlay(Capsule().stroke(Color(hex: "BF5AF2").opacity(0.3), lineWidth: 1))
            }
            .shadow(color: Color(hex: "BF5AF2").opacity(0.4), radius: 10)
        }
        .buttonStyle(.plain)
    }

    private var customHeader: some View {
        HStack {
            Spacer()
            
            VStack(spacing: 4) {
                Text("РОБОЧА СЕСІЯ")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.3))
                
                Text(timerVM.selectedProject?.name ?? AppLocalization.string("Кільце Прогресу"))
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
            }
            
            Spacer()
        }
        .overlay(alignment: .trailing) {
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: "BF5AF2"))
                    .shadow(color: Color(hex: "BF5AF2").opacity(0.3), radius: 5)
            }
            .padding(.trailing, 24)
        }
        .padding(.top, 20)
    }

    private func handleStartStop() {
        if timerVM.isRunning {
            timerVM.stop(context: context)
        } else {
            if timerVM.selectedProject != nil {
                timerVM.start(context: context)
            } else {
                feedbackTrigger.toggle()
                showNoProjectAlert = true
            }
        }
    }

    private var selectedProjectBinding: Binding<Project?> {
        Binding(
            get: { timerVM.selectedProject },
            set: { timerVM.selectedProject = $0 }
        )
    }
}
