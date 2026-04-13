import SwiftUI
import SwiftData

struct ProjectDetailView: View {
    @Bindable var project: Project
    @Environment(\.modelContext) private var context

    @State private var projectToEdit: Project?

    private var sortedEntries: [TimeEntry] {
        project.completedEntries.sorted { $0.startedAt > $1.startedAt }
    }

    private var todayDuration: TimeInterval {
        project.completedEntries
            .filter { Calendar.current.isDateInToday($0.startedAt) }
            .reduce(0) { $0 + $1.duration }
    }

    var body: some View {
        ZStack {
            // Background is global, but we can add a subtle project-color glow at the top
            ProjectAuraView(color: project.accentColor)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    // Custom Header
                    HStack(alignment: .firstTextBaseline) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(project.name)
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            if !project.client.isEmpty {
                                Text(project.client)
                                    .font(.headline)
                                    .foregroundStyle(project.accentColor.opacity(0.8))
                            }
                        }
                        
                        Spacer()
                        
                        Button {
                            projectToEdit = project
                        } label: {
                            Image(systemName: "square.and.pencil")
                                .font(.title3)
                                .foregroundStyle(.white)
                                .padding(12)
                                .glassCard(cornerRadius: 12, opacity: 0.15)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)

                    // Stats Grid
                    VStack(spacing: 16) {
                        HStack(spacing: 16) {
                            GlassDashboardTile(
                                title: "ВСЬОГО",
                                value: DurationFormatter.short(project.totalDuration),
                                unit: "год",
                                icon: "clock.fill",
                                color: project.accentColor
                            )
                            
                            GlassDashboardTile(
                                title: "СЕСІЙ",
                                value: "\(project.completedEntries.count)",
                                unit: "шт",
                                icon: "list.bullet",
                                color: .white
                            )
                        }
                        
                        if project.hourlyRate > 0 {
                            GlassDashboardTile(
                                title: "ЗАРОБЛЕНО",
                                value: String(format: "%.0f", project.totalEarned),
                                unit: project.currencySymbol,
                                icon: "banknote.fill",
                                color: .green
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Goals Section
                    VStack(spacing: 16) {
                        if let progress = project.budgetProgress {
                            ProjectBudgetCard(project: project, progress: progress)
                        }
                        
                        if project.dailyGoalHours > 0 {
                            ProjectDailyGoalCard(project: project, todayDuration: todayDuration)
                        }
                    }
                    .padding(.horizontal)

                    // Recent Entries
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("ОСТАННІ СЕСІЇ")
                                .font(.system(size: 11, weight: .black, design: .rounded))
                                .tracking(1.5)
                                .foregroundStyle(.white.opacity(0.4))
                            
                            Spacer()
                            
                            let unbilled = project.unbilledEntries.count
                            if unbilled > 0 {
                                Text("\(unbilled) НЕ ОПЛАЧЕНО")
                                    .font(.system(size: 9, weight: .black, design: .rounded))
                                    .foregroundStyle(.orange)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .glassCard(cornerRadius: 6, opacity: 0.1)
                            }
                        }
                        .padding(.horizontal)

                        if sortedEntries.isEmpty {
                            emptyEntriesState
                        } else {
                            VStack(spacing: 12) {
                                ForEach(sortedEntries.prefix(10)) { entry in
                                    TimeEntryRow(entry: entry, showProjectName: false)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    Spacer(minLength: 120)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(item: $projectToEdit) { editProject in
            ProjectFormView(project: editProject)
        }
    }

    private var emptyEntriesState: some View {
        VStack(spacing: 12) {
            Image(systemName: "timer")
                .font(.largeTitle)
                .foregroundStyle(.white.opacity(0.1))
            Text("Ще немає сесій")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .glassCard(cornerRadius: 24, opacity: 0.05)
        .padding(.horizontal)
    }
}

// MARK: - Subviews

struct ProjectAuraView: View {
    let color: Color
    
    var body: some View {
        GeometryReader { _ in
            ZStack {
                color.opacity(0.1)
                    .blur(radius: 100)
                    .offset(y: -200)
                
                Circle()
                    .fill(color.opacity(0.05))
                    .frame(width: 400, height: 400)
                    .blur(radius: 80)
                    .offset(x: 100, y: -150)
            }
        }
        .ignoresSafeArea()
    }
}

struct ProjectBudgetCard: View {
    let project: Project
    let progress: Double
    
    var body: some View {
        let isOver = progress >= 1.0
        let barColor = isOver ? Color.red : project.accentColor
        
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Бюджет", systemImage: isOver ? "exclamationmark.triangle.fill" : "chart.pie.fill")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(barColor)
                Spacer()
                Text("\(DurationFormatter.short(project.totalDuration)) / \(Int(project.estimatedHours))г")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                    Capsule()
                        .fill(barColor)
                        .frame(width: geo.size.width * min(progress, 1.0))
                        .shadow(color: barColor.opacity(0.3), radius: 6)
                }
            }
            .frame(height: 8)
            
            Text(isOver ? "Ліміт вичерпано" : "\(Int(project.estimatedHours - (project.totalDuration/3600)))г залишилось")
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(.white.opacity(0.3))
        }
        .padding(20)
        .glassCard(cornerRadius: 24, opacity: 0.1)
    }
}

struct ProjectDailyGoalCard: View {
    let project: Project
    let todayDuration: TimeInterval
    
    var body: some View {
        let goalSeconds = project.dailyGoalHours * 3600
        let progress = min(todayDuration / goalSeconds, 1.0)
        let isDone = todayDuration >= goalSeconds
        
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.05), lineWidth: 4)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        isDone ? Color.green : project.accentColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: (isDone ? Color.green : project.accentColor).opacity(0.3), radius: 4)
            }
            .frame(width: 48, height: 48)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(isDone ? "Ціль досягнута! 🎉" : "Денна ціль")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("\(DurationFormatter.short(todayDuration)) з \(Int(project.dailyGoalHours))г сьогодні")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
            }
            
            Spacer()
        }
        .padding(20)
        .glassCard(cornerRadius: 24, opacity: 0.1)
    }
}
