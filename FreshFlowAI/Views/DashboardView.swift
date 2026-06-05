import SwiftData
import SwiftUI

struct DashboardView: View {
    var viewModel: AppViewModel
    var showPaywall: () -> Void
    var openVoiceInput: () -> Void
    var selectTab: (AppTab) -> Void

    @Query(sort: \InventoryItem.estimatedExpiry, order: .forward) private var inventory: [InventoryItem]

    private var expiringSoon: [InventoryItem] {
        inventory.filter { $0.daysUntilExpiry <= 3 }
    }

    private var inventoryValue: Double {
        inventory.reduce(0) { $0 + $1.estimatedValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                dashboardHero

                UpgradeBanner(action: showPaywall)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                    MetricCard(title: "Expiring soon", value: "\(expiringSoon.count)", caption: "Use these first", systemImage: "clock.fill", tint: FreshFlowTheme.lemon)
                    MetricCard(title: "Money saved", value: "GBP 42", caption: "Estimated this month", systemImage: "sterlingsign.circle.fill", tint: FreshFlowTheme.sage)
                    MetricCard(title: "Inventory value", value: "GBP \(inventoryValue, specifier: "%.0f")", caption: "Tracked at home", systemImage: "refrigerator.fill", tint: FreshFlowTheme.sky)
                    MetricCard(title: "Subscription", value: "Free", caption: "Upgrade for unlimited AI", systemImage: "sparkles", tint: FreshFlowTheme.clay)
                }

                WasteRiskCard(risk: viewModel.lastWasteReport.wasteRisk, estimatedSavings: viewModel.lastWasteReport.estimatedSavings)

                SectionHeader(title: "Quick actions", subtitle: "Scan, speak, cook, and plan from one place.")
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    QuickActionButton(title: "Scan Fridge", systemImage: "camera.fill", tint: FreshFlowTheme.sage) { selectTab(.scan) }
                    QuickActionButton(title: "Scan Pantry", systemImage: "cabinet.fill", tint: FreshFlowTheme.sky) { selectTab(.scan) }
                    QuickActionButton(title: "Add Grocery", systemImage: "plus.circle.fill", tint: FreshFlowTheme.deepSage) { selectTab(.inventory) }
                    QuickActionButton(title: "Voice Command", systemImage: "mic.fill", tint: FreshFlowTheme.clay, action: openVoiceInput)
                    QuickActionButton(title: "Generate Recipe", systemImage: "fork.knife", tint: FreshFlowTheme.lemon) { selectTab(.recipes) }
                    QuickActionButton(title: "Shopping List", systemImage: "cart.fill", tint: FreshFlowTheme.blush) { selectTab(.insights) }
                    QuickActionButton(title: "Waste Report", systemImage: "chart.bar.fill", tint: FreshFlowTheme.sage) { selectTab(.insights) }
                }

                SectionHeader(title: "Eat first", subtitle: "Items with the highest waste risk.")
                if expiringSoon.isEmpty {
                    EmptyStateView(title: "No urgent items", message: "Your kitchen is looking calm. Add groceries or run a fridge scan.", systemImage: "leaf.circle")
                } else {
                    VStack(spacing: 12) {
                        ForEach(expiringSoon.prefix(3)) { item in
                            InventoryCard(item: item)
                        }
                    }
                }

                SectionHeader(title: "Recipe recommendations", subtitle: "Generated from expiring ingredients.")
                if viewModel.generatedRecipes.isEmpty {
                    PremiumActionButton(title: "Generate recipes from pantry", systemImage: "sparkles") {
                        Task { await viewModel.generateRecipes(from: inventory) }
                    }
                } else {
                    ForEach(viewModel.generatedRecipes.prefix(2)) { recipe in
                        RecipeCard(recipe: recipe)
                    }
                }

                SafetyDisclaimerView()
            }
            .padding(20)
        }
        .background(FreshFlowTheme.pageGradient.ignoresSafeArea())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                VoiceInputButton(title: "Voice", action: openVoiceInput)
            }
        }
        .task {
            await viewModel.refreshInsights(from: inventory)
        }
    }

    private var dashboardHero: some View {
        ZStack(alignment: .bottomLeading) {
            HStack {
                Spacer()
                FoodPhotographyPlaceholder(category: .produce, size: 154)
                    .padding(.trailing, 10)
            }
            VStack(alignment: .leading, spacing: 10) {
                Text("Know what to eat before it expires.")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(FreshFlowTheme.charcoal)
                    .frame(maxWidth: 260, alignment: .leading)
                Text("Turn food waste into savings.")
                    .font(.headline)
                    .foregroundStyle(FreshFlowTheme.deepSage)
                Text("FreshFlow is tracking \(inventory.count) kitchen items today.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, minHeight: 210, alignment: .bottomLeading)
        .background(.white.opacity(0.76), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
        .overlay(alignment: .topTrailing) {
            VoiceInputButton(title: "Ask") {
                openVoiceInput()
            }
            .padding(16)
        }
    }
}
