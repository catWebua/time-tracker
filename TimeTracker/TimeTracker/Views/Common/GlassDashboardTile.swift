import SwiftUI

struct GlassDashboardTile: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(color)
                Text(LocalizedStringKey(title))
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.3))
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text(LocalizedStringKey(unit))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.3))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .glassCard(cornerRadius: 24, opacity: 0.1)
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(color.opacity(0.2), lineWidth: 1)
        }
    }
}
