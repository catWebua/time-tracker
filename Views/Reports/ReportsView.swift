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
        case week = "Тиждень"
        case month = "Місяць"
        case all = "Весь час"
    }

    // MARK: - Filtered Data

    private var filteredEntries: [TimeEntry] {
        let now = Date()
        return allEntries.filter { entry in
            guard let start = entry.startedAt as Date? else { return false }
            switch period {
            case .week:
                return start >= now.startOfWeek
            case .month:
                return start >= now.startOfMonth
            case .all:
                return true
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
            ScrollView {
                VStack(spacing: 20) {

                    // Period picker
                    Picker("Період", selection: $period) {
                        ForEach(Period.allCases, id: \.self) { p in
                            Text(p.rawValue).tag(p)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Summary cards
                    summarySection

                    // Bar chart
                    if !dailyData.isEmpty {
                        barChartSection
                    }

                    // Project breakdown
                    if !projectData.isEmpty {
                        projectBreakdownSection
                    }

                    if filteredEntries.isEmpty {
                        emptyState
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Звіти")
        }
    }

    // MARK: - Summary Cards

    private var summarySection: some View {
        HStack(spacing: 12) {
            summaryCard(
                title: "Год. відпрацьовано",
                value: String(format: "%.1f", totalDuration / 3600),
                unit: "год",
                icon: "clock.fill",
                color: .purple
            )

            if totalEarned > 0 {
                summaryCard(
                    title: "Зароблено",
                    value: String(format: "%.0f", totalEarned),
                    unit: projects.first?.currencySymbol ?? "₴",
                    icon: "banknote.fill",
                    color: .green
                )
            } else {
                summaryCard(
                    title: "Сесій",
                    value: "\(filteredEntries.count)",
                    unit: "сес.",
                    icon: "timer",
                    color: .blue
                )
            }
        }
        .padding(.horizontal)
    }

    private func summaryCard(title: String, value: String, unit: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                Text(unit)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.2), lineWidth: 1))
    }

    // MARK: - Bar Chart

    private var barChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("По днях")
                .font(.headline)
                .padding(.horizontal)

            Chart(dailyData) { item in
                BarMark(
                    x: .value("День", item.date, unit: .day),
                    y: .value("Годин", item.hours)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, Color(hex: "#7C3AED")],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { value in
                    AxisValueLabel(format: .dateTime.weekday(.abbreviated), centered: true)
                        .foregroundStyle(Color.secondary)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisValueLabel {
                        if let h = value.as(Double.self) {
                            Text("\(Int(h))г")
                                .foregroundStyle(Color.secondary)
                        }
                    }
                }
            }
            .frame(height: 180)
            .padding(.horizontal)
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .padding(.horizontal)
    }

    // MARK: - Project Breakdown

    private var projectBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("По проектах")
                .font(.headline)
                .padding(.horizontal, 16)

            ForEach(projectData.prefix(6)) { item in
                projectBreakdownRow(item)
            }
        }
        .padding(.vertical, 16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.white.opacity(0.08), lineWidth: 1))
        .padding(.horizontal)
    }

    private func projectBreakdownRow(_ item: ProjectData) -> some View {
        let fraction = totalDuration > 0 ? item.duration / totalDuration : 0
        return HStack(spacing: 12) {
            Circle()
                .fill(item.project.accentColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.project.name)
                        .font(.subheadline)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(DurationFormatter.short(item.duration))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .monospacedDigit()
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)
                        RoundedRectangle(cornerRadius: 3)
                            .fill(item.project.accentColor)
                            .frame(width: geo.size.width * fraction, height: 6)
                    }
                }
                .frame(height: 6)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Empty

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Немає даних за цей період")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 40)
    }
}

// MARK: - Data Models

private struct DayData: Identifiable {
    let id = UUID()
    let date: Date
    let hours: Double
}

private struct ProjectData: Identifiable {
    let id = UUID()
    let project: Project
    let duration: TimeInterval
}
