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

    private var grouped: [(key: Date, entries: [TimeEntry])] {
        let dict = Dictionary(grouping: filtered) { $0.startedAt.startOfDay }
        return dict.sorted { $0.key > $1.key }
            .map { (key: $0.key, entries: $0.value) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background is handled by ContentView
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Custom Large Header
                        HStack {
                            Text("Записи")
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Button {
                                showManualEntry = true
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.purple)
                                    .symbolRenderingMode(.hierarchical)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 20)
                        .padding(.bottom, 12)

                        // Billing Filter Segmented Control
                        Picker(LocalizedStringKey("Фільтр"), selection: $billingFilter) {
                            ForEach(BillingFilter.allCases, id: \.self) { f in
                                Text(LocalizedStringKey(f.rawValue)).tag(f)
                            }
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        .padding(.bottom, 24)

                        if entries.isEmpty {
                            emptyState
                        } else if grouped.isEmpty {
                            noResultsState
                        } else {
                            timelineContent
                        }
                    }
                }
                .safeAreaPadding(.top)
                .safeAreaPadding(.bottom, 100)
            }
            .toolbar(.hidden)
        }
        .sheet(isPresented: $showManualEntry) {
            EntryFormView()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 100)
            Image(systemName: "clock.badge.xmark")
                .font(.system(size: 64))
                .foregroundStyle(.white.opacity(0.1))
            Text("Немає записів")
                .font(.title3.bold())
                .foregroundStyle(.white.opacity(0.4))
            Button("Додати запис") { showManualEntry = true }
                .buttonStyle(.glass(color: .purple))
        }
        .frame(maxWidth: .infinity)
    }
    
    private var noResultsState: some View {
        VStack(spacing: 12) {
            Spacer(minLength: 100)
            Text("Нічого не знайдено")
                .font(.headline)
                .foregroundStyle(.white.opacity(0.3))
        }
        .frame(maxWidth: .infinity)
    }

    private var timelineContent: some View {
        VStack(spacing: 32) {
            ForEach(grouped, id: \.key) { group in
                VStack(alignment: .leading, spacing: 16) {
                    // Day Header
                    HStack {
                        Text(group.key.relativeLabel().uppercased())
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(.white.opacity(0.4))
                        
                        Spacer()
                        
                        let total = group.entries.reduce(0.0) { $0 + $1.duration }
                        Text(DurationFormatter.short(total))
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .glassCard(cornerRadius: 8, opacity: 0.1)
                    }
                    .padding(.horizontal)
                    
                    // Entries for this day
                    VStack(spacing: 12) {
                        ForEach(group.entries) { entry in
                            TimeEntryRow(entry: entry)
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    Button {
                                        withAnimation { toggleBilled(entry) }
                                    } label: {
                                        Label(
                                            LocalizedStringKey(entry.isBilled ? "Не оплачено" : "Оплачено"),
                                            systemImage: entry.isBilled ? "xmark.circle" : "checkmark.circle"
                                        )
                                    }
                                    .tint(entry.isBilled ? .orange : .green)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteEntry(entry)
                                    } label: {
                                        Label(LocalizedStringKey("Видалити"), systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 100)
    }

    private func toggleBilled(_ entry: TimeEntry) {
        entry.isBilled.toggle()
        try? context.save()
    }

    private func deleteEntry(_ entry: TimeEntry) {
        context.delete(entry)
        try? context.save()
    }
}
