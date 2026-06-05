import SwiftUI

enum FreshFlowTheme {
    static let cream = Color(red: 0.98, green: 0.96, blue: 0.90)
    static let porcelain = Color(red: 0.99, green: 0.98, blue: 0.95)
    static let sage = Color(red: 0.45, green: 0.61, blue: 0.49)
    static let deepSage = Color(red: 0.20, green: 0.36, blue: 0.27)
    static let charcoal = Color(red: 0.13, green: 0.14, blue: 0.13)
    static let clay = Color(red: 0.72, green: 0.42, blue: 0.33)
    static let lemon = Color(red: 0.94, green: 0.78, blue: 0.36)
    static let sky = Color(red: 0.45, green: 0.63, blue: 0.76)
    static let blush = Color(red: 0.88, green: 0.58, blue: 0.52)

    static let pageGradient = LinearGradient(
        colors: [porcelain, cream, Color.white],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let freshGradient = LinearGradient(
        colors: [sage, deepSage],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

extension View {
    func premiumCardStyle() -> some View {
        padding(18)
            .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(.white.opacity(0.72), lineWidth: 1)
            }
            .shadow(color: FreshFlowTheme.charcoal.opacity(0.08), radius: 22, x: 0, y: 12)
    }
}
