import SwiftUI
import SwiftData

struct EntryListView: View {
    @Environment(\.modelContext) private var context

    @Query(
        filter: #Predicate<TimeEntry> { $0.endedAt != nil },
        sort: \TimeEntry.startedAt,
        order: .reverse
    )
    private var entries: [TimeEntry]

    @State private var showManualEntry = false
    @State private var billingFilter: BillingFilter = .all

    enum BillingFilter: String, CaseIterable {
        case all       = "Всі"
        case unbilled  = "Не оплачені"
        case billed    = "Оплачені"
    }

    private var filtered: [TimeEntry] {
        switch billingFilter {
        case .all:      return entries
        case .unbilled: return entries.filter { !$0.isBilled }
        case .billed:   return entries.filter { $0.isBilled }
        }
    }

    // Pre-computed grouped data to avoid inline filtering inside ForEach
    private var grouped: [(key: Date, entries: [TimeEntry])] {
        let dict = Dictionary(grouping: filtered) { $0.startedAt.startOfDay }
        return dict.sorted { $0.key > $1.key }
            .map { (key: $0.key, entries: $0.value) }
    }

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    // Skill: ContentUnavailableView for empty states (iOS 17+)
                    ContentUnavailableView {
                        Label("Немає записів", systemImage: "clock.badge.xmark")
                    } description: {
                        Text("Запусти таймер або додай запис вручну")
                    } actions: {
                        Button("Додати запис") { showManualEntry = true }
                            .buttonStyle(.borderedProminent)
                            .tint(.purple)
                    }
                } else {
                    entryList
                }
            }
            .navigationTitle("Записи")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showManualEntry = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
        }
        .sheet(isPresented: $showManualEntry) {
            EntryFormView()
        }
    }

    // MARK: - Entry List

    private var entryList: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: .sectionHeaders) {
                // Billing filter
                Picker("Фільтр", selection: $billingFilter) {
                    ForEach(BillingFilter.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.vertical, 12)

                if grouped.isEmpty {
                    ContentUnavailableView {
                        Label("Немає записів", systemImage: billingFilter == .billed ? "checkmark.circle" : "clock")
                    } description: {
                        Text(billingFilter == .billed ? "Ще нічого не позначено оплаченим" : "Всі записи вже оплачені")
                    }
                    .padding(.top, 40)
                } else {
                    ForEach(grouped, id: \.key) { group in
                        Section {
                            // Skill: ForEach with stable Identifiable identity
                            ForEach(group.entries) { entry in
                                EntryRow(entry: entry)
                                    .padding(.horizontal)
                                    .padding(.bottom, 8)
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        Button {
                                            withAnimation { toggleBilled(entry) }
                                        } label: {
                                            Label(
                                                entry.isBilled ? "Не оплачено" : "Оплачено",
                                                systemImage: entry.isBilled ? "xmark.circle" : "checkmark.circle"
                                            )
                                        }
                                        .tint(entry.isBilled ? .orange : .green)
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteEntry(entry)
                                        } label: {
                                            Label("Видалити", systemImage: "trash")
                                        }
                                    }
                            }
                        } header: {
                            dayHeader(for: group.key, entries: group.entries)
                        }
                    }
                }
            }
            .padding(.bottom)
        }
    }

    private func dayHeader(for date: Date, entries: [TimeEntry]) -> some View {
        HStack {
            Text(date.relativeLabel())
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)

            Spacer()

            let total = entries.reduce(0.0) { $0 + $1.duration }
            Text(DurationFormatter.short(total))
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(.purple)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(Color(.systemBackground))
    }

    // MARK: - Actions

    private func toggleBilled(_ entry: TimeEntry) {
        entry.isBilled.toggle()
        try? context.save()
    }

    private func deleteEntry(_ entry: TimeEntry) {
        context.delete(entry)
        try? context.save()
    }
}

// MARK: - Entry Row

struct EntryRow: View {
    let entry: TimeEntry

    var body: some View {
        HStack(spacing: 12) {
            if let project = entry.project {
                Circle()
                    .fill(project.accentColor)
                    .frame(width: 8, height: 8)
            }

            VStack(alignment: .leading, spacing: 3) {
                if !entry.taskDescription.isEmpty {
                    Text(entry.taskDescription)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                HStack(spacing: 6) {
                    if let project = entry.project {
                        Text(project.name)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    if let endedAt = entry.endedAt {
                        Text("·")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                        Text("\(entry.startedAt.timeString()) – \(endedAt.timeString())")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }

            Spacer()

            HStack(spacing: 8) {
                // Billing badge
                if entry.isBilled {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundStyle(.green)
                }

                Text(entry.formattedDuration)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .monospacedDigit()
            }
        }
        .padding(14)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    entry.isBilled ? Color.green.opacity(0.25) : Color.white.opacity(0.07),
                    lineWidth: 1
                )
        )
    }
}
