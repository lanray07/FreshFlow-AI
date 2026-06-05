import SwiftUI

struct WidgetPlaceholderView: View {
    var body: some View {
        FreshFlowCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("WidgetKit placeholder", systemImage: "rectangle.inset.filled")
                    .font(.headline)
                    .foregroundStyle(FreshFlowTheme.charcoal)
                FlowTagList(items: ["Expiring soon", "Shopping list", "Recipe suggestion", "Pantry summary"], tint: FreshFlowTheme.sky)
                Text("Add a WidgetKit extension target when the app shell is moved into a full Xcode workspace.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
