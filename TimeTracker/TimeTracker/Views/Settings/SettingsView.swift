import SwiftUI

struct SettingsView: View {
    @Environment(NotificationManager.self) private var notificationManager

    // Reminder preferences
    @AppStorage("dailyReminderEnabled") private var dailyReminderEnabled = false
    @AppStorage("dailyReminderHour")    private var dailyReminderHour: Int = 9
    @AppStorage("dailyReminderMinute")  private var dailyReminderMinute: Int = 0

    // Long-running alert
    @AppStorage("longRunningEnabled")   private var longRunningEnabled = false
    @AppStorage("longRunningHours")     private var longRunningHours: Double = 4

    @State private var reminderTime = Date()
    @State private var showPermissionDeniedAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                AuraBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Title
                        Text("Налаштування")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal)
                            .padding(.top, 20)

                        VStack(spacing: 24) {
                            // MARK: - Notifications
                            GlassInputGroup(title: "СПОВІЩЕННЯ") {
                                VStack(spacing: 20) {
                                    if !notificationManager.isAuthorized {
                                        Button {
                                            Task {
                                                await notificationManager.requestPermission()
                                                if !notificationManager.isAuthorized {
                                                    showPermissionDeniedAlert = true
                                                }
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: "bell.badge.fill")
                                                Text("Дозволити сповіщення")
                                                Spacer()
                                                Image(systemName: "chevron.right")
                                                    .font(.caption)
                                            }
                                            .foregroundStyle(.purple)
                                            .padding(12)
                                            .background(Color.purple.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                                        }
                                    } else {
                                        Toggle(isOn: $dailyReminderEnabled) {
                                            Label("Щоденне нагадування", systemImage: "alarm.fill")
                                        }
                                        .tint(.purple)
                                        .onChange(of: dailyReminderEnabled) { _, enabled in
                                            if enabled {
                                                notificationManager.scheduleDailyReminder(
                                                    hour: dailyReminderHour,
                                                    minute: dailyReminderMinute
                                                )
                                            } else {
                                                notificationManager.cancelDailyReminder()
                                            }
                                        }

                                        if dailyReminderEnabled {
                                            DatePicker(
                                                "Час нагадування",
                                                selection: $reminderTime,
                                                displayedComponents: .hourAndMinute
                                            )
                                            .tint(.purple)
                                            .onChange(of: reminderTime) { _, newTime in
                                                let cal = Calendar.current
                                                let h = cal.component(.hour, from: newTime)
                                                let m = cal.component(.minute, from: newTime)
                                                dailyReminderHour   = h
                                                dailyReminderMinute = m
                                                notificationManager.scheduleDailyReminder(hour: h, minute: m)
                                            }
                                        }

                                        Divider().background(Color.white.opacity(0.1))

                                        Toggle(isOn: $longRunningEnabled) {
                                            Label("Таймер іде задовго", systemImage: "clock.badge.exclamationmark.fill")
                                        }
                                        .tint(.purple)
                                        .onChange(of: longRunningEnabled) { _, enabled in
                                            if enabled {
                                                notificationManager.scheduleLongRunningAlert(after: longRunningHours)
                                            } else {
                                                notificationManager.removeLongRunningAlert()
                                            }
                                        }

                                        if longRunningEnabled {
                                            Stepper(
                                                "Через \(Int(longRunningHours)) год.",
                                                value: $longRunningHours,
                                                in: 1...12,
                                                step: 1
                                            )
                                            .onChange(of: longRunningHours) { _, hours in
                                                notificationManager.scheduleLongRunningAlert(after: hours)
                                            }
                                        }
                                    }
                                }
                            }

                            // MARK: - Widget Instructions
                            GlassInputGroup(title: "ВІДЖЕТ") {
                                VStack(alignment: .leading, spacing: 16) {
                                    HStack {
                                        Image(systemName: "apps.iphone")
                                            .font(.title3)
                                            .foregroundStyle(.purple)
                                        Text("Додай на головний екран")
                                            .font(.headline)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 10) {
                                        instructionStep(n: "1", text: "Довго натисни на Home Screen")
                                        instructionStep(n: "2", text: "Натисни «+» у кутку")
                                        instructionStep(n: "3", text: "Знайди «FreelanceKit»")
                                        instructionStep(n: "4", text: "Вибери розмір та додай")
                                    }
                                }
                            }

                            // MARK: - About
                            GlassInputGroup(title: "ПРО ЗАСТОСУНОК") {
                                VStack(spacing: 16) {
                                    infoRow(label: "Версія", value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0", icon: "info.circle")
                                    infoRow(label: "Сховище", value: "SwiftData (локально)", icon: "database")
                                    infoRow(label: "iCloud Sync", value: "Незабаром", icon: "cloud.fill", active: false)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        Text("Made with 💜 for Freelancers")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.2))
                            .frame(maxWidth: .infinity)
                            .padding(.top, 20)
                        
                        Spacer(minLength: 120)
                    }
                }
            }
            .toolbar(.hidden)
            .onAppear {
                var comps = DateComponents()
                comps.hour   = dailyReminderHour
                comps.minute = dailyReminderMinute
                reminderTime = Calendar.current.date(from: comps) ?? Date()
                Task { await notificationManager.refreshStatus() }
            }
            .alert("Сповіщення заблоковані", isPresented: $showPermissionDeniedAlert) {
                Button("Налаштування") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("OK", role: .cancel) {}
            } message: {
                Text("Зайди в Налаштування iOS, щоб увімкнути сповіщення для FreelanceKit.")
            }
        }
    }

    private func instructionStep(n: String, text: String) -> some View {
        HStack(spacing: 12) {
            Text(n)
                .font(.system(size: 10, weight: .black))
                .foregroundStyle(.white)
                .frame(width: 18, height: 18)
                .background(Color.purple.opacity(0.3), in: Circle())
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private func infoRow(label: String, value: String, icon: String, active: Bool = true) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .foregroundStyle(active ? .white.opacity(0.8) : .white.opacity(0.3))
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundStyle(active ? .purple : .white.opacity(0.2))
        }
    }
}
