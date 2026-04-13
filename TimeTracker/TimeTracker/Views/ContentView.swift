import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(TimerViewModel.self) private var timerVM

    @State private var selectedTab = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            // 1. Global Background
            AuraBackground()
            
            // 2. Main content switch
            ZStack {
                switch selectedTab {
                case 0:
                    TimerView()
                case 1:
                    ProjectListView()
                case 2:
                    EntryListView()
                case 3:
                    ReportsView()
                default:
                    TimerView()
                }
            }
            .transition(.opacity.combined(with: .scale(scale: 0.98)))
            .id(selectedTab)
            .safeAreaInset(edge: .bottom) {
                GlassTabBar(selectedTab: $selectedTab)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            timerVM.restoreActiveEntry(from: context)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Project.self, TimeEntry.self], inMemory: true)
        .environment(TimerViewModel())
}
