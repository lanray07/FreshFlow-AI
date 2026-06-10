import SwiftUI

struct WidgetPlaceholderView: View {
    var body: some View {
        FreshFlowCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Widget summary", systemImage: "rectangle.inset.filled")
                    .font(.headline)
                    .foregroundStyle(FreshFlowTheme.charcoal)
                FlowTagList(items: ["Expiring soon", "Shopping list", "Recipe suggestion", "Pantry summary"], tint: FreshFlowTheme.sky)
                Text("Quick summaries help households spot expiring food and shopping priorities.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
