import SwiftUI
import SwiftData
import Charts

struct ReportsView: View {
    @Environment(\.modelContext) private var context

    @Query(
        filter: #Predicate<TimeEntry> { $0.endedAt != nil },
        sort: \TimeEntry.startedAt,
        order: .reverse
    )
    private var allEntries: [TimeEntry]

    @Query(
        filter: #Predicate<Project> { !$0.isArchived },
        sort: \Project.name
    )
    private var projects: [Project]

    @State private var period: Period = .week

    enum Period: String, CaseIterable {
        case week  = "Тиждень"
        case month = "Місяць"
        case all   = "Весь"
    }

    private var filteredEntries: [TimeEntry] {
        let now = Date()
        return allEntries.filter { entry in
            switch period {
            case .week:  return entry.startedAt >= now.startOfWeek
            case .month: return entry.startedAt >= now.startOfMonth
            case .all:   return true
            }
        }
    }

    private var totalDuration: TimeInterval {
        filteredEntries.reduce(0) { $0 + $1.duration }
    }

    private var totalEarned: Double {
        filteredEntries.reduce(0) { sum, entry in
            guard let rate = entry.project?.hourlyRate, rate > 0 else { return sum }
            return sum + (entry.duration / 3600.0) * rate
        }
    }

    private var dailyData: [DayData] {
        let grouped = Dictionary(grouping: filteredEntries) { entry in
            Calendar.current.startOfDay(for: entry.startedAt)
        }
        return grouped.map { date, entries in
            DayData(date: date, hours: entries.reduce(0) { $0 + $1.duration } / 3600.0)
        }
        .sorted { $0.date < $1.date }
    }

    private var projectData: [ProjectData] {
        let grouped = Dictionary(grouping: filteredEntries) { $0.project?.id ?? UUID() }
        return grouped.compactMap { _, entries -> ProjectData? in
            guard let project = entries.first?.project else { return nil }
            let total = entries.reduce(0) { $0 + $1.duration }
            return ProjectData(project: project, duration: total)
        }
        .sorted { $0.duration > $1.duration }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background is global
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Custom Header
                        HStack {
                            Text("Звіти")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            ShareLink(
                                item: CSVExporter.createReport(entries: filteredEntries, periodName: period.rawValue),
                                preview: SharePreview("Звіт (\(period.rawValue))", image: Image(systemName: "chart.bar.doc.horizontal"))
                            ) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.title3)
                                    .foregroundStyle(.purple)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)

                        // Custom Segmented Picker
                        Picker("Період", selection: $period) {
                            ForEach(Period.allCases, id: \.self) { p in
                                Text(p.rawValue).tag(p)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)

                        if allEntries.isEmpty {
                            emptyState
                        } else {
                            dashboardContent
                        }
                    }
                    .padding(.bottom, 120) // Bottom tab bar margin
                }
            }
            .toolbar(.hidden)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 100)
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.1))
            Text("Немає даних")
                .font(.title3.bold())
                .foregroundStyle(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity)
    }

    private var dashboardContent: some View {
        VStack(spacing: 24) {
            // Main Stats
            HStack(spacing: 16) {
                GlassDashboardTile(
                    title: "ГОДИНИ",
                    value: String(format: "%.1f", totalDuration / 3600),
                    unit: "год",
                    icon: "clock.fill",
                    color: .purple
                )
                
                GlassDashboardTile(
                    title: "ДОХІД",
                    value: String(format: "%.0f", totalEarned),
                    unit: projects.first?.currencySymbol ?? "₴",
                    icon: "banknote.fill",
                    color: .green
                )
            }
            .padding(.horizontal)

            // Chart Section
            VStack(alignment: .leading, spacing: 16) {
                Text("ДИНАМІКА РОБОТИ")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.horizontal)

                BarChartView(data: dailyData)
                    .frame(height: 180)
                    .padding(20)
                    .glassCard(cornerRadius: 24, opacity: 0.1)
                    .padding(.horizontal)
            }

            // Project Breakdown
            VStack(alignment: .leading, spacing: 16) {
                Text("РОЗПОДІЛ ПО ПРОЕКТАХ")
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1.5)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.horizontal)

                VStack(spacing: 12) {
                    ForEach(projectData) { item in
                        ProjectBreakdownRow(item: item, totalDuration: totalDuration)
                    }
                }
                .padding(20)
                .glassCard(cornerRadius: 24, opacity: 0.08)
                .padding(.horizontal)
            }
        }
    }
}

// MARK: - Enhanced Bar Chart
struct BarChartView: View {
    let data: [DayData]

    var body: some View {
        Chart(data) { item in
            BarMark(
                x: .value("День", item.date, unit: .day),
                y: .value("Годин", item.hours)
            )
            .foregroundStyle(
                LinearGradient(
                    colors: [.purple, .blue.opacity(0.5)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .cornerRadius(6)
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .day)) { _ in
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    .foregroundStyle(Color.white.opacity(0.3))
                    .font(.system(size: 10, weight: .bold))
            }
        }
        .chartYAxis {
            AxisMarks { value in
                AxisValueLabel {
                    if let h = value.as(Double.self) {
                        Text("\(Int(h))г")
                            .foregroundStyle(Color.white.opacity(0.2))
                    }
                }
            }
        }
    }
}

// MARK: - Project Breakdown Row
struct ProjectBreakdownRow: View {
    let item: ProjectData
    let totalDuration: TimeInterval

    private var fraction: Double {
        totalDuration > 0 ? item.duration / totalDuration : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(item.project.accentColor)
                    .frame(width: 8, height: 8)
                
                Text(item.project.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.8))
                
                Spacer()
                
                Text(DurationFormatter.short(item.duration))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.05))
                        .frame(height: 6)
                    Capsule()
                        .fill(item.project.accentColor)
                        .frame(width: geo.size.width * fraction, height: 6)
                        .shadow(color: item.project.accentColor.opacity(0.3), radius: 4)
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Data Models Extensions
struct DayData: Identifiable {
    var id: Date { date }
    let date: Date
    let hours: Double
}

struct ProjectData: Identifiable {
    var id: UUID { project.id }
    let project: Project
    let duration: TimeInterval
}
