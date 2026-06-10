import SwiftUI

struct WatchPlaceholderView: View {
    var body: some View {
        FreshFlowCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Apple Watch summary", systemImage: "applewatch")
                    .font(.headline)
                    .foregroundStyle(FreshFlowTheme.charcoal)
                Label("Shopping reminders", systemImage: "cart.fill")
                Label("Recipe alerts", systemImage: "bell.fill")
                Label("Inventory notifications", systemImage: "refrigerator.fill")
                Text("Compact reminders keep shopping and recipe tasks close at hand.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
    }
}
