import SwiftUI
import SwiftData

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

    private let presetColors = [
        "#A855F7", "#7C3AED", "#3B82F6", "#0EA5E9",
        "#10B981", "#84CC16", "#F59E0B", "#EF4444",
        "#EC4899", "#F43F5E", "#06B6D4", "#8B5CF6"
    ]

    private var isEditing: Bool { project != nil }
    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                // Назва та клієнт
                Section {
                    TextField("Назва проекту", text: $name)
                    TextField("Клієнт (необов'язково)", text: $client)
                } header: {
                    Text("Основне")
                }

                // Колір
                Section {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 12) {
                        ForEach(presetColors, id: \.self) { hex in
                            Button {
                                selectedColor = hex
                                Haptics.impact(.light)
                            } label: {
                                Circle()
                                    .fill(Color(hex: hex))
                                    .frame(width: 36, height: 36)
                                    .overlay(
                                        Circle()
                                            .stroke(.white, lineWidth: selectedColor == hex ? 2.5 : 0)
                                            .padding(3)
                                    )
                                    .scaleEffect(selectedColor == hex ? 1.15 : 1.0)
                                    .animation(.spring(response: 0.25), value: selectedColor)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.vertical, 6)
                } header: {
                    Text("Колір")
                }

                // Ставка
                Section {
                    HStack {
                        TextField("0", text: $hourlyRate)
                            .keyboardType(.decimalPad)

                        Picker("", selection: $currency) {
                            Text("₴ UAH").tag("UAH")
                            Text("$ USD").tag("USD")
                        }
                        .pickerStyle(.menu)
                    }
                } header: {
                    Text("Погодинна ставка")
                } footer: {
                    Text("Залиш 0 якщо не рахуєш гроші")
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemBackground))
            .navigationTitle(isEditing ? "Редагувати" : "Новий проект")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Скасувати") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Зберегти" : "Додати") {
                        save()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let p = project {
                    name = p.name
                    client = p.client
                    hourlyRate = p.hourlyRate > 0 ? String(format: "%.0f", p.hourlyRate) : ""
                    currency = p.currency
                    selectedColor = p.colorHex
                }
            }
        }
    }

    private func save() {
        let rate = Double(hourlyRate.replacingOccurrences(of: ",", with: ".")) ?? 0

        if let p = project {
            p.name = name.trimmingCharacters(in: .whitespaces)
            p.client = client.trimmingCharacters(in: .whitespaces)
            p.hourlyRate = rate
            p.currency = currency
            p.colorHex = selectedColor
        } else {
            let newProject = Project(
                name: name.trimmingCharacters(in: .whitespaces),
                client: client.trimmingCharacters(in: .whitespaces),
                colorHex: selectedColor,
                hourlyRate: rate,
                currency: currency
            )
            context.insert(newProject)
        }

        try? context.save()
        Haptics.success()
        dismiss()
    }
}
