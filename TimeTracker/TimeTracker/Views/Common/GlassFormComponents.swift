import SwiftUI

// MARK: - Glass Input Group
struct GlassInputGroup<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedStringKey(title))
                .font(.system(size: 11, weight: .black, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(.white.opacity(0.3))
                .padding(.leading, 8)
            
            content
                .padding(20)
                .glassCard(cornerRadius: 24, opacity: 0.08)
        }
    }
}

// MARK: - Glass TextField
struct GlassTextField: View {
    let placeholder: String
    @Binding var text: String
    
    init(_ placeholder: String, text: Binding<String>) {
        self.placeholder = placeholder
        self._text = text
    }
    
    var body: some View {
        TextField(LocalizedStringKey(placeholder), text: $text)
            .padding(14)
            .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
            .tint(.purple)
    }
}

// MARK: - Glass Input Row
struct GlassInputRow: View {
    let title: String
    @Binding var text: String
    let unit: String
    
    var body: some View {
        HStack {
            Text(LocalizedStringKey(title))
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
            Spacer()
            TextField("0", text: $text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 80)
                .padding(8)
                .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
            Text(LocalizedStringKey(unit))
                .font(.caption)
                .foregroundStyle(.white.opacity(0.3))
                .frame(width: 30, alignment: .leading)
        }
    }
}
