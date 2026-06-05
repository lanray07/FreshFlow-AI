import SwiftUI

struct WatchPlaceholderView: View {
    var body: some View {
        FreshFlowCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Apple Watch placeholder", systemImage: "applewatch")
                    .font(.headline)
                    .foregroundStyle(FreshFlowTheme.charcoal)
                Label("Shopping reminders", systemImage: "cart.fill")
                Label("Recipe alerts", systemImage: "bell.fill")
                Label("Inventory notifications", systemImage: "refrigerator.fill")
                Text("Add a watchOS companion target for shared shopping reminders and recipe alerts.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .font(.subheadline)
        }
    }
}
