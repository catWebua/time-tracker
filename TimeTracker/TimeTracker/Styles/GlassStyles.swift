import SwiftUI

/// A view modifier that applies a premium glassmorphism effect.
struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat
    var opacity: Double
    var shadow: Bool
    
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Main glass material
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial.opacity(opacity))
                    
                    // Subtle light border
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(
                                colors: [.white.opacity(0.3), .white.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            // Expert Rule: Use compositingGroup before clipping layered views to avoid antialiasing fringes
            .compositingGroup()
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .shadow(
                color: Color.black.opacity(shadow ? 0.15 : 0),
                radius: 12,
                x: 0,
                y: 8
            )
    }
}

extension View {
    /// Applies a glassmorphism card style to the view.
    /// - Parameters:
    ///   - cornerRadius: The roundness of the corners.
    ///   - opacity: The base opacity of the glass material.
    ///   - shadow: Whether to apply a subtle elevation shadow.
    func glassCard(cornerRadius: CGFloat = 24, opacity: Double = 0.4, shadow: Bool = true) -> some View {
        self.modifier(GlassCardModifier(cornerRadius: cornerRadius, opacity: opacity, shadow: shadow))
    }
}

/// A premium button style with glass accents and haptic-ready animations.
struct GlassButtonStyle: ButtonStyle {
    var color: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .padding(.horizontal, 28)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    if configuration.isPressed {
                        color.brightness(-0.1)
                    } else {
                        color
                    }
                    
                    // Glass highlight overlay
                    RoundedRectangle(cornerRadius: 18)
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.2), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.35, dampingFraction: 0.7), value: configuration.isPressed)
            .shadow(color: color.opacity(0.4), radius: 15, x: 0, y: 10)
    }
}

extension ButtonStyle where Self == GlassButtonStyle {
    static func glass(color: Color = .purple) -> GlassButtonStyle {
        GlassButtonStyle(color: color)
    }
}

// MARK: - iOS 18 Sensory Feedback Sugar
extension View {
    /// Applies a standard haptic feedback for primary actions.
    func primaryHaptic<T: Equatable>(trigger: T) -> some View {
        self.sensoryFeedback(.impact(weight: .medium, intensity: 0.8), trigger: trigger)
    }
}
