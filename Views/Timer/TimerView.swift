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

    @State private var showProjectPicker = false
    @State private var showNoProjectAlert = false

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
                        .padding(.bottom, 48)
                        // Skill: sensoryFeedback(_:trigger:) replaces UIImpactFeedbackGenerator (iOS 17+)
                        .sensoryFeedback(.start, trigger: timerVM.isRunning) { old, new in
                            !old && new
                        }
                        .sensoryFeedback(.stop, trigger: timerVM.isRunning) { old, new in
                            old && !new
                        }
                }
            }
            .navigationTitle("FreelanceKit")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showProjectPicker) {
            ProjectPickerSheet(selectedProject: selectedProjectBinding)
        }
        // Skill: modern alert API with actions builder
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
            // Skill: animation(_:value:) must include the value parameter
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
        // Skill: animation(_:value:) includes value; scoped narrow to this button
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: timerVM.isRunning)
    }

    // MARK: - Helpers

    private var selectedProjectBinding: Binding<Project?> {
        Binding(
            get: { timerVM.selectedProject },
            set: { timerVM.selectedProject = $0 }
        )
    }
}
