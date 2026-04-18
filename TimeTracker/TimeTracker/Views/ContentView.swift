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
            TabView(selection: $selectedTab) {
                TimerView()
                    .tag(0)
                
                ProjectListView()
                    .tag(1)
                
                EntryListView()
                    .tag(2)
                
                ReportsView()
                    .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(.easeInOut, value: selectedTab)
            .ignoresSafeArea(.keyboard, edges: .bottom)
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
