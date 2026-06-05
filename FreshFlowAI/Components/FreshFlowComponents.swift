import Charts
import SwiftUI

struct FreshFlowCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .premiumCardStyle()
    }
}

struct PremiumActionButton: View {
    var title: String
    var systemImage: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(FreshFlowTheme.freshGradient, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct QuickActionButton: View {
    var title: String
    var systemImage: String
    var tint: Color = FreshFlowTheme.sage
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(width: 38, height: 38)
                    .background(tint, in: RoundedRectangle(cornerRadius: 13, style: .continuous))
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FreshFlowTheme.charcoal)
                    .lineLimit(2)
                    .minimumScaleFactor(0.82)
            }
            .frame(maxWidth: .infinity, minHeight: 92, alignment: .topLeading)
            .padding(14)
            .background(.white.opacity(0.78), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

struct SectionHeader: View {
    var title: String
    var subtitle: String?
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(FreshFlowTheme.charcoal)
                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(FreshFlowTheme.deepSage)
            }
        }
    }
}

struct MetricCard: View {
    var title: String
    var value: String
    var caption: String
    var systemImage: String
    var tint: Color

    var body: some View {
        FreshFlowCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: systemImage)
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(tint, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    Spacer()
                }
                Text(value)
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(FreshFlowTheme.charcoal)
                Text(title)
                    .font(.headline)
                    .foregroundStyle(FreshFlowTheme.charcoal)
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct FreshnessMeter: View {
    var status: FreshnessStatus
    var daysUntilExpiry: Int

    private var tint: Color {
        switch status {
        case .longShelfLife: FreshFlowTheme.sky
        case .safe: FreshFlowTheme.sage
        case .eatSoon: FreshFlowTheme.lemon
        case .wasteRisk: FreshFlowTheme.blush
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(status.rawValue)
                    .font(.caption.weight(.bold))
                Spacer()
                Text(daysUntilExpiry <= 0 ? "today" : "\(daysUntilExpiry)d")
                    .font(.caption.monospacedDigit())
            }
            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule().fill(tint.opacity(0.18))
                    Capsule()
                        .fill(tint)
                        .frame(width: max(12, proxy.size.width * status.urgencyScore))
                }
            }
            .frame(height: 8)
        }
        .foregroundStyle(FreshFlowTheme.charcoal)
    }
}

struct InventoryCard: View {
    var item: InventoryItem

    var body: some View {
        HStack(spacing: 14) {
            FoodPhotographyPlaceholder(category: item.categoryValue, size: 58)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(item.itemName)
                        .font(.headline)
                        .foregroundStyle(FreshFlowTheme.charcoal)
                    Spacer()
                    Text(item.quantity)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                Text("\(item.category) - \(item.location)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                FreshnessMeter(status: item.freshnessStatus, daysUntilExpiry: item.daysUntilExpiry)
            }
        }
        .padding(14)
        .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct RecipeCard: View {
    var recipe: GeneratedRecipe

    var body: some View {
        FreshFlowCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    FoodPhotographyPlaceholder(category: .produce, size: 52)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(recipe.title)
                            .font(.headline)
                            .foregroundStyle(FreshFlowTheme.charcoal)
                        Text("\(recipe.preparationTime) - \(recipe.mode)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                FlowTagList(items: recipe.ingredients, tint: FreshFlowTheme.sage)
                Text(recipe.instructions.first ?? "Use owned ingredients first.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                if !recipe.shoppingGaps.isEmpty {
                    Label("Gaps: \(recipe.shoppingGaps.joined(separator: ", "))", systemImage: "cart")
                        .font(.caption)
                        .foregroundStyle(FreshFlowTheme.deepSage)
                }
            }
        }
    }
}

struct WasteRiskCard: View {
    var risk: Double
    var estimatedSavings: Double

    var body: some View {
        FreshFlowCard {
            HStack(spacing: 18) {
                Gauge(value: risk) {
                    Text("Risk")
                } currentValueLabel: {
                    Text("\(Int(risk * 100))%")
                }
                .gaugeStyle(.accessoryCircularCapacity)
                .tint(risk > 0.6 ? FreshFlowTheme.blush : FreshFlowTheme.sage)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Food Waste Risk Score")
                        .font(.headline)
                        .foregroundStyle(FreshFlowTheme.charcoal)
                    Text("Estimated preventable value: GBP \(estimatedSavings, specifier: "%.0f")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("Freshness estimates are informational only.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

struct SavingsCard: View {
    var saved: Double
    var inventoryValue: Double

    var body: some View {
        FreshFlowCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Turn food waste into savings", systemImage: "leaf.circle.fill")
                    .font(.headline)
                    .foregroundStyle(FreshFlowTheme.deepSage)
                HStack {
                    VStack(alignment: .leading) {
                        Text("GBP \(saved, specifier: "%.0f")")
                            .font(.title.bold())
                        Text("saved this month")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("GBP \(inventoryValue, specifier: "%.0f")")
                            .font(.title3.bold())
                        Text("inventory value")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .foregroundStyle(FreshFlowTheme.charcoal)
        }
    }
}

struct ShoppingListCard: View {
    var recommendation: ShoppingRecommendation

    var body: some View {
        FreshFlowCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label(recommendation.title, systemImage: "cart.fill")
                        .font(.headline)
                    Spacer()
                    Text("GBP \(recommendation.budgetEstimate, specifier: "%.0f")")
                        .font(.subheadline.weight(.bold))
                }
                FlowTagList(items: recommendation.items, tint: FreshFlowTheme.sky)
                Text(recommendation.reason)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .foregroundStyle(FreshFlowTheme.charcoal)
        }
    }
}

struct AnalyticsChartCard: View {
    var title: String
    var points: [SavingsTrendPoint]

    var body: some View {
        FreshFlowCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(FreshFlowTheme.charcoal)
                Chart(points) { point in
                    BarMark(
                        x: .value("Month", point.label),
                        y: .value("Saved", point.value)
                    )
                    .foregroundStyle(FreshFlowTheme.freshGradient)
                    .cornerRadius(6)
                }
                .frame(height: 180)
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
            }
        }
    }
}

struct ShareCardPreview: View {
    var saved: Double
    var impact: String

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("FreshFlow AI")
                .font(.caption.weight(.bold))
                .foregroundStyle(FreshFlowTheme.deepSage)
            Text("I prevented GBP \(saved, specifier: "%.0f") of food waste this month.")
                .font(.title2.weight(.bold))
                .foregroundStyle(FreshFlowTheme.charcoal)
                .fixedSize(horizontal: false, vertical: true)
            Text(impact)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            HStack {
                Image(systemName: "leaf.fill")
                Text("Know what to eat before it expires.")
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle(FreshFlowTheme.deepSage)
        }
        .padding(22)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FreshFlowTheme.pageGradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white, lineWidth: 1)
        }
    }
}

struct UpgradeBanner: View {
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .foregroundStyle(.white)
                    .frame(width: 34, height: 34)
                    .background(FreshFlowTheme.deepSage, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 3) {
                    Text("Unlock FreshFlow Premium")
                        .font(.headline)
                    Text("Unlimited scans, AI recipes, pantry forecast, and waste analytics.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
            }
            .foregroundStyle(FreshFlowTheme.charcoal)
            .padding(16)
            .background(.white.opacity(0.82), in: RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct EmptyStateView: View {
    var title: String
    var message: String
    var systemImage: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.largeTitle)
                .foregroundStyle(FreshFlowTheme.sage)
            Text(title)
                .font(.headline)
                .foregroundStyle(FreshFlowTheme.charcoal)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .premiumCardStyle()
    }
}

struct SafetyDisclaimerView: View {
    var compact = false

    var body: some View {
        Label {
            Text(compact
                ? "Freshness estimates are informational only."
                : "FreshFlow AI is a food organization tool. Verify food safety independently and follow official food safety guidance.")
        } icon: {
            Image(systemName: "exclamationmark.shield.fill")
        }
        .font(compact ? .caption : .footnote)
        .foregroundStyle(FreshFlowTheme.clay)
        .padding(12)
        .background(FreshFlowTheme.clay.opacity(0.10), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct FlowTagList: View {
    var items: [String]
    var tint: Color

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(FreshFlowTheme.charcoal)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .background(tint.opacity(0.14), in: Capsule())
            }
        }
    }
}
