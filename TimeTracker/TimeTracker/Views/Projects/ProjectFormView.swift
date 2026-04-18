import SwiftUI
import SwiftData

@MainActor
struct ProjectFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    // Edit mode
    var project: Project?

    @State private var name: String = ""
    @State private var client: String = ""
    @State private var hourlyRate: String = ""
    @State private var currency: String = "UAH"
    @State private var selectedColor: String = "#A855F7"
    @State private var estimatedHours: String = ""
    @State private var dailyGoalHours: String = ""
    
    // UI State
    @State private var errorMessage: String? 
    @State private var showError = false

    private let presetColors = [
        "#A855F7", "#7C3AED", "#3B82F6", "#0EA5E9",
        "#10B981", "#84CC16", "#F59E0B", "#EF4444",
        "#EC4899", "#F43F5E", "#06B6D4", "#8B5CF6"
    ]

    private var isEditing: Bool { project != nil }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                AuraBackground()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        // Title
                        Text(isEditing ? "Редагувати" : "Новий проект")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                            .padding(.horizontal)
                            .padding(.top, 20)

                        VStack(spacing: 24) {
                            // Section: Main
                            GlassInputGroup(title: "ОСНОВНЕ") {
                                VStack(spacing: 16) {
                                    GlassTextField("Назва проекту*", text: $name)
                                    GlassTextField("Клієнт (необов'язково)", text: $client)
                                }
                            }
                            
                            // Section: Color
                            GlassInputGroup(title: "КОЛІР ПРОЕКТУ") {
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                                    ForEach(presetColors, id: \.self) { hex in
                                        Button {
                                            selectedColor = hex
                                        } label: {
                                            Circle()
                                                .fill(Color(hex: hex))
                                                .frame(width: 32, height: 32)
                                                .overlay(
                                                    Circle()
                                                        .stroke(.white, lineWidth: selectedColor == hex ? 2 : 0)
                                                        .padding(2)
                                                )
                                                .scaleEffect(selectedColor == hex ? 1.2 : 1.0)
                                                .shadow(color: Color(hex: hex).opacity(selectedColor == hex ? 0.4 : 0), radius: 6)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.vertical, 8)
                            }

                            // Section: Billing
                            GlassInputGroup(title: "ПОГОДИННА СТАВКА") {
                                HStack(spacing: 12) {
                                    GlassTextField("0", text: $hourlyRate)
                                        .keyboardType(.decimalPad)
                                    
                                    Picker("", selection: $currency) {
                                        Text("UAH").tag("UAH")
                                        Text("USD").tag("USD")
                                    }
                                    .pickerStyle(.menu)
                                    .glassCard(cornerRadius: 12, opacity: 0.1)
                                }
                            }
                            
                            // Section: Planning
                            GlassInputGroup(title: "ПЛАНУВАННЯ") {
                                VStack(spacing: 16) {
                                    GlassInputRow(title: "Бюджет годин", text: $estimatedHours, unit: "год")
                                    GlassInputRow(title: "Денна ціль", text: $dailyGoalHours, unit: "год")
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Action Buttons
                        VStack(spacing: 12) {
                            Button {
                                save()
                            } label: {
                                Text(isEditing ? "Зберегти зміни" : "Створити проект")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.glass(color: isValid ? Color(hex: selectedColor) : .gray))
                            .disabled(!isValid)
                            
                            Button {
                                dismiss()
                            } label: {
                                Text("Скасувати")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.4))
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                        
                        Spacer(minLength: 50)
                    }
                }
            }
            .toolbar(.hidden)
            .onAppear {
                if let p = project {
                    name = p.name
                    client = p.client
                    hourlyRate = p.hourlyRate > 0 ? String(format: "%.0f", p.hourlyRate) : ""
                    currency = p.currency
                    selectedColor = p.colorHex
                    estimatedHours = p.estimatedHours > 0 ? String(format: "%.0f", p.estimatedHours) : ""
                    dailyGoalHours = p.dailyGoalHours > 0 ? String(format: "%.0f", p.dailyGoalHours) : ""
                }
            }
            .alert("Помилка", isPresented: $showError) {
                Button("OK") {}
            } message: {
                Text(errorMessage ?? "Невідома помилка")
            }
        }
    }

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let rate  = Double(hourlyRate.replacingOccurrences(of: ",", with: ".")) ?? 0
        let budget = Double(estimatedHours.replacingOccurrences(of: ",", with: ".")) ?? 0
        let daily  = Double(dailyGoalHours.replacingOccurrences(of: ",", with: ".")) ?? 0

        if let p = project {
            p.name           = trimmedName
            p.client         = client.trimmingCharacters(in: .whitespacesAndNewlines)
            p.hourlyRate     = rate
            p.currency       = currency
            p.colorHex       = selectedColor
            p.estimatedHours = budget
            p.dailyGoalHours = daily
        } else {
            let newProject = Project(
                name: trimmedName,
                client: client.trimmingCharacters(in: .whitespacesAndNewlines),
                colorHex: selectedColor,
                hourlyRate: rate,
                currency: currency,
                estimatedHours: budget,
                dailyGoalHours: daily
            )
            context.insert(newProject)
        }

        do {
            try context.save()
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}

