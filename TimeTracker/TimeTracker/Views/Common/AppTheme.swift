import SwiftUI

// MARK: - App Colors
enum AppTheme {
    static let backgroundBase = Color(hex: "0A050F")
    static let surfacePrimary = Color.white.opacity(0.12)
    static let accentPurple = Color(hex: "6A1B9A")
    static let accentIndigo = Color(hex: "3A1F5D")
    static let successGreen = Color.green
}

// Color extension removed here as it is now shared from Shared/Color+Hex.swift

// MARK: - Global Atmosphere
struct AuraBackground: View {
    var body: some View {
        AppTheme.backgroundBase
            .ignoresSafeArea()
    }
}
