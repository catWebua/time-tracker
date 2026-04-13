import SwiftUI
import SwiftData

// MARK: - Status Badge
struct StatusBadgeView: View {
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(.green)
                .frame(width: 5, height: 5)
                .shadow(color: .green, radius: 3)
            Text("АКТИВНИЙ СЕАНС")
                .font(.system(size: 9, weight: .black, design: .rounded))
                .tracking(1.5)
                .foregroundStyle(.green.opacity(0.8))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .glassCard(cornerRadius: 100, opacity: 0.2, shadow: false) // Using new glass style
    }
}

// MARK: - Timer Clock
struct TimerClockView: View {
    let displayTime: String
    let isRunning: Bool
    let accentColor: Color
    let progress: Double
    
    private let size: CGFloat = 260
    private let lineWidth: CGFloat = 16
    
    private var timeParts: (days: String?, main: String, seconds: String) {
        let parts = displayTime.components(separatedBy: ":")
        if parts.count == 3 {
            let firstPart = parts[0]
            if firstPart.contains("д ") {
                let subParts = firstPart.components(separatedBy: "д ")
                return (subParts[0] + "д", subParts[1] + ":" + parts[1], parts[2])
            }
            return (nil, parts[0] + ":" + parts[1], parts[2])
        }
        return (nil, displayTime, "")
    }

    var body: some View {
        ZStack {
            // 1. Background Pulsing Glow
            if isRunning {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 280, height: 280)
                    .blur(radius: 50)
                    .overlay(
                        Circle()
                            .stroke(accentColor.opacity(0.2), lineWidth: 1)
                            .blur(radius: 2)
                    )
                    .phaseAnimator([0.92, 1.08]) { content, phase in
                        content.scaleEffect(phase)
                    } animation: { _ in
                        .easeInOut(duration: 4).repeatForever(autoreverses: true)
                    }
            }

            // Background Ring
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: lineWidth)
                .frame(width: size, height: size)
            
            // Progress Arc
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    AngularGradient(
                        colors: [accentColor.opacity(0.3), accentColor, accentColor.opacity(0.8)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(progress * 360 - 90)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .shadow(color: accentColor.opacity(0.5), radius: 15)
            
            // Central Multi-Level Time
            VStack(spacing: -2) {
                if let days = timeParts.days {
                    Text(days.uppercased())
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .foregroundStyle(accentColor)
                        .padding(.bottom, 2)
                }
                
                Text(timeParts.main)
                    .font(.system(size: 72, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                
                if !timeParts.seconds.isEmpty {
                    Text(timeParts.seconds)
                        .font(.system(size: 20, weight: .medium, design: .monospaced).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            
            // Floating Indicators
            GeometryReader { geo in
                let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                let radius = size / 2
                
                // End Point Bubble (Current Time)
                let endAngle = progress * 360 - 90
                let bubblePos = pointOnCircle(center: center, radius: radius, angleDegrees: endAngle)
                
                IndicatorBubble(text: displayTime)
                    .position(bubblePos)
                    .opacity(progress > 0.02 ? 1 : 0)
                
                // Percentage Bubble (Bottom Right of path)
                let percentPos = pointOnCircle(center: center, radius: radius, angleDegrees: 45)
                IndicatorBubble(text: "\(Int(progress * 100))%")
                    .position(percentPos)
                    .opacity(progress > 0 ? 0.8 : 0)
            }
            .frame(width: size + 60, height: size + 60)
        }
    }
    
    private func pointOnCircle(center: CGPoint, radius: CGFloat, angleDegrees: Double) -> CGPoint {
        let radians = angleDegrees * .pi / 180
        return CGPoint(
            x: center.x + radius * cos(radians),
            y: center.y + radius * sin(radians)
        )
    }
}

struct IndicatorBubble: View {
    let text: String
    
    var body: some View {
        Text(text)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundStyle(.white.opacity(0.8))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .glassCard(cornerRadius: 10, opacity: 0.15)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(.white.opacity(0.1), lineWidth: 0.5)
            )
            .shadow(color: .black.opacity(0.2), radius: 4)
    }
}

// MARK: - Modern Control Bar
struct ModernControlBar: View {
    let isRunning: Bool
    let accentColor: Color
    let onPlayPause: () -> Void
    let onSettings: () -> Void
    
    var body: some View {
        ZStack {
            // Main Play/Pause Button - Exactly Centered
            Button(action: onPlayPause) {
                ZStack {
                    Circle()
                        .fill(isRunning ? Color.red.opacity(0.15) : (accentColor.opacity(0.15)))
                        .frame(width: 86, height: 86)
                        .blur(radius: 20)
                    
                    Circle()
                        .fill(.white.opacity(0.03))
                        .frame(width: 72, height: 72)
                        .overlay(Circle().stroke(.white.opacity(0.1), lineWidth: 0.5))
                        .glassCard(cornerRadius: 36, opacity: 0.1)
                    
                    Image(systemName: isRunning ? "pause.fill" : "play.fill")
                        .font(.system(size: 26, weight: .black))
                        .foregroundStyle(isRunning ? .red : .white)
                        .symbolEffect(.bounce, value: isRunning)
                }
            }
            .buttonStyle(.plain)
        }
    }
}

struct ControlButton: View {
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(.white.opacity(0.05))
                    .frame(width: 52, height: 52)
                    .overlay(Circle().stroke(.white.opacity(0.08), lineWidth: 0.5))
                    .glassCard(cornerRadius: 26, opacity: 0.08)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Unified Context Card
struct UnifiedContextView: View {
    let selectedProject: Project?
    @Binding var taskDescription: String
    let isRunning: Bool
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Project Row
            Button(action: action) {
                HStack(spacing: 12) {
                    if let project = selectedProject {
                        Circle()
                            .fill(project.accentColor)
                            .frame(width: 8, height: 8)
                            .shadow(color: project.accentColor.opacity(0.5), radius: 4)
                        
                        Text(project.name.uppercased())
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .tracking(1.5)
                            .foregroundStyle(.white.opacity(0.9))
                        
                        Spacer()
                    } else {
                        Image(systemName: "folder.badge.plus")
                            .font(.system(size: 14))
                            .foregroundStyle(.white.opacity(0.4))
                        Text("ОБРАТИ ПРОЕКТ")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .tracking(1)
                            .foregroundStyle(.white.opacity(0.4))
                        Spacer()
                    }
                    
                    if !isRunning {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10, weight: .black))
                            .foregroundStyle(.white.opacity(0.2))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .disabled(isRunning)

            Divider()
                .background(Color.white.opacity(0.08))
                .padding(.horizontal, 20)

            // Task Row
            HStack(spacing: 12) {
                Image(systemName: "pencil.line")
                    .font(.system(size: 14))
                    .foregroundStyle(.white.opacity(0.3))
                
                if isRunning && !taskDescription.isEmpty {
                    Text(taskDescription)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white.opacity(0.8))
                } else {
                    TextField("Чим займаєшся?", text: $taskDescription)
                        .textFieldStyle(.plain)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundStyle(.white)
                        .disabled(isRunning)
                }
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .glassCard(cornerRadius: 24, opacity: 0.12)
    }
}

// MARK: - Goal Progress
struct GoalProgressView: View {
    let progress: Double
    let project: Project
    let currentDuration: TimeInterval
    
    var body: some View {
        let isDone = progress >= 1.0
        let barColor: Color = isDone ? .green : project.accentColor
        let goalDisplay = "\(Int(project.dailyGoalHours))г"

        VStack(spacing: 8) {
            HStack {
                Text(isDone ? "ЦІЛЬ ДОСЯГНУТА 🎉" : "ДЕННА ЦІЛЬ")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .tracking(1)
                    .foregroundStyle(.white.opacity(0.4))
                Spacer()
                Text("\(DurationFormatter.short(currentDuration)) / \(goalDisplay)")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundStyle(barColor)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                        .frame(height: 5)
                    Capsule()
                        .fill(barColor)
                        .frame(width: geo.size.width * progress, height: 5)
                }
            }
            .frame(height: 5)
        }
        .animation(.spring(response: 0.6), value: progress)
    }
}
