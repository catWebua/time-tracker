import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var context
    @Environment(TimerViewModel.self) private var timerVM

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TimerView()
                .tabItem {
                    Label("Таймер", systemImage: selectedTab == 0 ? "timer.circle.fill" : "timer")
                }
                .tag(0)

            ProjectListView()
                .tabItem {
                    Label("Проекти", systemImage: selectedTab == 1 ? "folder.fill" : "folder")
                }
                .tag(1)

            EntryListView()
                .tabItem {
                    Label("Записи", systemImage: selectedTab == 2 ? "list.bullet.circle.fill" : "list.bullet")
                }
                .tag(2)

            ReportsView()
                .tabItem {
                    Label("Звіти", systemImage: selectedTab == 3 ? "chart.bar.fill" : "chart.bar")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Налаштування", systemImage: selectedTab == 4 ? "gearshape.fill" : "gearshape")
                }
                .tag(4)
        }
        .tint(.purple)
        .preferredColorScheme(.dark)
        .onAppear {
            timerVM.restoreActiveEntry(from: context)
        }
    }
}
