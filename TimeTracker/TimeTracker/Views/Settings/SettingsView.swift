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
            Form {
                // MARK: - Notifications
                Section {
                    if !notificationManager.isAuthorized {
                        Button {
                            Task {
                                await notificationManager.requestPermission()
                                if !notificationManager.isAuthorized {
                                    showPermissionDeniedAlert = true
                                }
                            }
                        } label: {
                            Label("Дозволити сповіщення", systemImage: "bell.badge")
                                .foregroundStyle(.purple)
                        }
                    } else {
                        Toggle(isOn: $dailyReminderEnabled) {
                            Label("Щоденне нагадування", systemImage: "alarm")
                        }
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
                            .onChange(of: reminderTime) { _, newTime in
                                let cal = Calendar.current
                                let h = cal.component(.hour, from: newTime)
                                let m = cal.component(.minute, from: newTime)
                                dailyReminderHour   = h
                                dailyReminderMinute = m
                                notificationManager.scheduleDailyReminder(hour: h, minute: m)
                            }
                        }

                        Toggle(isOn: $longRunningEnabled) {
                            Label("Таймер іде задовго", systemImage: "clock.badge.exclamationmark")
                        }
                        .onChange(of: longRunningEnabled) { _, enabled in
                            if enabled {
                                notificationManager.scheduleLongRunningAlert(after: longRunningHours)
                            } else {
                                notificationManager.removeLongRunningAlert()
                            }
                        }

                        if longRunningEnabled {
                            Stepper(
                                "Сповіщення через \(Int(longRunningHours)) год.",
                                value: $longRunningHours,
                                in: 1...12,
                                step: 1
                            )
                            .onChange(of: longRunningHours) { _, hours in
                                notificationManager.scheduleLongRunningAlert(after: hours)
                            }
                        }
                    }
                } header: {
                    Text("Сповіщення")
                } footer: {
                    Text("Нагадування, щоб не забути запустити або зупинити таймер.")
                }

                // MARK: - Widget Instructions
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Додати віджет на Home Screen", systemImage: "apps.iphone")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Text("""
                        1. Довго натисни на Home Screen
                        2. Натисни «+» (верхній лівий)
                        3. Знайди «FreelanceKit»
                        4. Вибери розмір віджету та додай
                        """)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Віджет")
                } footer: {
                    Text("Для цього потрібно додати Widget Extension у Xcode (інструкція у README).")
                }

                // MARK: - About
                Section {
                    HStack {
                        Text("Версія")
                        Spacer()
                        Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("Сховище")
                        Spacer()
                        Text("SwiftData (локально)")
                            .foregroundStyle(.secondary)
                    }
                    HStack {
                        Text("iCloud Sync")
                        Spacer()
                        Text("Незабаром")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Про застосунок")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .navigationTitle("Налаштування")
            .onAppear {
                // Restore time picker to stored values
                var comps = DateComponents()
                comps.hour   = dailyReminderHour
                comps.minute = dailyReminderMinute
                reminderTime = Calendar.current.date(from: comps) ?? Date()
                // Refresh auth status
                Task { await notificationManager.refreshStatus() }
            }
            .alert("Сповіщення заблоковані", isPresented: $showPermissionDeniedAlert) {
                Button("Відкрити Налаштування") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Скасувати", role: .cancel) {}
            } message: {
                Text("Дозвіл на сповіщення заблоковано. Відкрий Налаштування → Сповіщення → FreelanceKit.")
            }
        }
    }
}
