import SwiftUI

struct GlassTabBar: View {
    @Binding var selectedTab: Int
    
    private let tabs = [
        (0, "Таймер", "timer"),
        (1, "Проекти", "folder"),
        (2, "Записи", "list.bullet"),
        (3, "Звіти", "chart.bar")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs, id: \.0) { index, title, icon in
                Spacer()
                TabButton(index: index, selectedTab: $selectedTab, title: title, icon: icon)
                Spacer()
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background {
            Capsule()
                .fill(.ultraThinMaterial.opacity(0.3))
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                .overlay {
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .clear, .white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
        .sensoryFeedback(.selection, trigger: selectedTab)
    }
}

private struct TabButton: View {
    let index: Int
    @Binding var selectedTab: Int
    let title: String
    let icon: String
    
    var body: some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = index
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: selectedTab == index ? (icon == "timer" ? "stopwatch.fill" : (icon == "list.bullet" ? "list.clipboard.fill" : "\(icon).fill")) : icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(selectedTab == index ? Color(hex: "BF5AF2") : .white.opacity(0.25))
                    .frame(height: 28)
                    .shadow(color: selectedTab == index ? Color(hex: "BF5AF2").opacity(0.4) : .clear, radius: 8)
                
                Text(LocalizedStringKey(title))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(selectedTab == index ? Color(hex: "BF5AF2") : .white.opacity(0.2))
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        VStack {
            Spacer()
            GlassTabBar(selectedTab: .constant(0))
        }
    }
}
