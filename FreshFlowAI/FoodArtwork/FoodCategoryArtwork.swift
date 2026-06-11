import SwiftUI

struct FoodCategoryArtwork: View {
    var category: FoodCategory
    var size: CGFloat = 72

    private var palette: [Color] {
        switch category {
        case .produce: [FreshFlowTheme.sage, FreshFlowTheme.lemon]
        case .dairy: [FreshFlowTheme.sky, .white]
        case .meat: [FreshFlowTheme.blush, FreshFlowTheme.clay]
        case .frozen: [FreshFlowTheme.sky, FreshFlowTheme.sage]
        case .pantry: [FreshFlowTheme.lemon, FreshFlowTheme.clay]
        case .beverages: [FreshFlowTheme.sky, FreshFlowTheme.deepSage]
        case .snacks: [FreshFlowTheme.lemon, FreshFlowTheme.blush]
        case .leftovers: [FreshFlowTheme.clay, FreshFlowTheme.sage]
        }
    }

    private var symbol: String {
        switch category {
        case .produce: "carrot.fill"
        case .dairy: "cup.and.saucer.fill"
        case .meat: "fork.knife"
        case .frozen: "snowflake"
        case .pantry: "shippingbox.fill"
        case .beverages: "waterbottle.fill"
        case .snacks: "takeoutbag.and.cup.and.straw.fill"
        case .leftovers: "refrigerator.fill"
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing))
            Circle()
                .fill(.white.opacity(0.28))
                .frame(width: size * 0.62, height: size * 0.62)
                .offset(x: size * 0.25, y: -size * 0.22)
            Image(systemName: symbol)
                .font(.system(size: size * 0.36, weight: .bold))
                .foregroundStyle(.white)
        }
        .frame(width: size, height: size)
        .shadow(color: palette.first?.opacity(0.24) ?? .clear, radius: 10, x: 0, y: 6)
        .accessibilityHidden(true)
    }
}
