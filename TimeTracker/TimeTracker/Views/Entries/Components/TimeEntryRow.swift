import SwiftUI

struct TimeEntryRow: View {
    let entry: TimeEntry
    var showProjectName: Bool = true

    var body: some View {
        HStack(spacing: 16) {
            // Timeline Indicator
            VStack {
                Circle()
                    .fill(entry.project?.accentColor ?? .purple)
                    .frame(width: 8, height: 8)
                    .shadow(color: (entry.project?.accentColor ?? .purple).opacity(0.5), radius: 4)
                
                Rectangle()
                    .fill(LinearGradient(
                        colors: [(entry.project?.accentColor ?? .purple).opacity(0.3), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    ))
                    .frame(width: 1)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        if !entry.taskDescription.isEmpty {
                            Text(entry.taskDescription)
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        } else {
                            Text("Без опису")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                        
                        if showProjectName {
                            Text(entry.project?.name ?? AppLocalization.string("Без проекту"))
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(entry.project?.accentColor.opacity(0.8) ?? .secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(entry.formattedDuration)
                            .font(.system(size: 16, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white)
                        
                        if let endedAt = entry.endedAt {
                            Text("\(entry.startedAt.timeString()) – \(endedAt.timeString())")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(.white.opacity(0.3))
                        }
                    }
                }
                
                if entry.isBilled {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                        Text("ОПЛАЧЕНО")
                    }
                    .font(.system(size: 9, weight: .black, design: .rounded))
                    .foregroundStyle(.green.opacity(0.8))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .glassCard(cornerRadius: 6, opacity: 0.1)
                }
            }
            .padding(16)
            .glassCard(cornerRadius: 18, opacity: 0.08)
            .overlay {
                if entry.isBilled {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                } else {
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(Color.white.opacity(0.05), lineWidth: 1)
                }
            }
        }
    }
}
