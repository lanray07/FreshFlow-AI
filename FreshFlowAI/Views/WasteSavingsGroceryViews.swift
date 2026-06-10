import SwiftData
import SwiftUI

struct InsightsHubView: View {
    var viewModel: AppViewModel
    var openVoiceInput: (VoiceSourceScreen) -> Void

    @Query(sort: \InventoryItem.estimatedExpiry, order: .forward) private var inventory: [InventoryItem]
    @State private var selectedView = "Waste"

    private let views = ["Waste", "Savings", "Groceries", "Forecast", "Share"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    SectionHeader(title: "Waste Risk Dashboard", subtitle: "Forecast risk, savings, and restock needs.")
                    VoiceInputButton(title: "Voice") { openVoiceInput(.groceries) }
                }

                Picker("Insights", selection: $selectedView) {
                    ForEach(views, id: \.self) { view in
                        Text(view).tag(view)
                    }
                }
                .pickerStyle(.segmented)

                switch selectedView {
                case "Waste":
                    WasteRiskDashboardView(viewModel: viewModel, inventory: inventory)
                case "Savings":
                    SavingsDashboardView(viewModel: viewModel, inventory: inventory)
                case "Groceries":
                    GroceryIntelligenceView(viewModel: viewModel, inventory: inventory, openVoiceInput: { openVoiceInput(.groceries) })
                case "Forecast":
                    PantryForecastView(viewModel: viewModel)
                default:
                    ShareableSavingsCardsView()
                }

                WidgetPlaceholderView()
                WatchPlaceholderView()
            }
            .padding(20)
        }
        .background(FreshFlowTheme.pageGradient.ignoresSafeArea())
        .task {
            await viewModel.refreshInsights(from: inventory)
        }
    }
}

struct WasteRiskDashboardView: View {
    var viewModel: AppViewModel
    var inventory: [InventoryItem]

    private var expiring24: [InventoryItem] {
        inventory.filter { $0.daysUntilExpiry <= 1 }
    }

    private var expiring3Days: [InventoryItem] {
        inventory.filter { $0.daysUntilExpiry <= 3 }
    }

    var body: some View {
        VStack(spacing: 16) {
            WasteRiskCard(risk: viewModel.lastWasteReport.wasteRisk, estimatedSavings: viewModel.lastWasteReport.estimatedSavings)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
                MetricCard(title: "Within 24 hours", value: "\(expiring24.count)", caption: "Highest urgency", systemImage: "timer", tint: FreshFlowTheme.blush)
                MetricCard(title: "Within 3 days", value: "\(expiring3Days.count)", caption: "Plan meals around these", systemImage: "calendar", tint: FreshFlowTheme.lemon)
            }

            FreshFlowCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Suggested actions")
                        .font(.headline)
                    ForEach(viewModel.lastWasteReport.suggestedActions, id: \.self) { action in
                        Label(action, systemImage: "checkmark.seal.fill")
                            .font(.subheadline)
                            .foregroundStyle(FreshFlowTheme.charcoal)
                    }
                }
            }
            SafetyDisclaimerView(compact: true)
        }
    }
}

struct SavingsDashboardView: View {
    var viewModel: AppViewModel
    var inventory: [InventoryItem]

    private var inventoryValue: Double {
        inventory.reduce(0) { $0 + $1.estimatedValue }
    }

    var body: some View {
        VStack(spacing: 16) {
            SavingsCard(saved: viewModel.lastWasteReport.estimatedSavings, inventoryValue: inventoryValue)
            AnalyticsChartCard(title: "Monthly waste reduction", points: viewModel.savingsTrend)
            ShareCardPreview(saved: viewModel.lastWasteReport.estimatedSavings, impact: "Small kitchen habits, visible savings.")
        }
    }
}

struct GroceryIntelligenceView: View {
    var viewModel: AppViewModel
    var inventory: [InventoryItem]
    var openVoiceInput: () -> Void

    @State private var mealGoal = "pasta night"

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            FreshFlowCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        SectionHeader(title: "Grocery Intelligence", subtitle: "Lists, replenishment, budgets, and gaps.")
                        VoiceInputButton(title: "Voice", action: openVoiceInput)
                    }
                    TextField("Meal or shopping goal", text: $mealGoal)
                        .textFieldStyle(.roundedBorder)
                    PremiumActionButton(title: "Generate shopping list", systemImage: "cart.badge.plus") {
                        Task { await viewModel.generateShoppingList(from: inventory, mealGoal: mealGoal) }
                    }
                }
            }

            if viewModel.shoppingRecommendations.isEmpty {
                EmptyStateView(title: "No list yet", message: "Generate a list that fills gaps without duplicating food you already own.", systemImage: "cart")
            } else {
                ForEach(viewModel.shoppingRecommendations) { recommendation in
                    ShoppingListCard(recommendation: recommendation)
                }
            }
        }
    }
}

struct PantryForecastView: View {
    var viewModel: AppViewModel

    var body: some View {
        VStack(spacing: 16) {
            FreshFlowCard {
                VStack(alignment: .leading, spacing: 12) {
                    Label("AI Pantry Forecast", systemImage: "calendar.badge.clock")
                        .font(.headline)
                        .foregroundStyle(FreshFlowTheme.charcoal)
                    Text("Predict when food will run out, what to restock, and future waste risk.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    FlowTagList(items: ["Restock oats", "Use spinach", "Freeze berries", "Plan rice bowls"], tint: FreshFlowTheme.sage)
                }
            }
            FreshFlowCard {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Household sharing")
                        .font(.headline)
                    Label("Family members", systemImage: "person.2.fill")
                    Label("Shared inventory", systemImage: "refrigerator.fill")
                    Label("Shared shopping lists", systemImage: "cart.fill")
                }
                .font(.subheadline)
                .foregroundStyle(FreshFlowTheme.charcoal)
            }
        }
    }
}

struct ShareableSavingsCardsView: View {
    @State private var showingShare = false

    var body: some View {
        VStack(spacing: 16) {
            ShareCardPreview(saved: 42, impact: "Reduced waste, smarter meals, fewer forgotten groceries.")
            Button {
                showingShare = true
            } label: {
                Label("Share savings card", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .sheet(isPresented: $showingShare) {
            ShareSheet(items: ["I saved GBP 42 with FreshFlow AI. Know what to eat before it expires."])
        }
    }
}
