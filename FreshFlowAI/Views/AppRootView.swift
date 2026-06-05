import SwiftData
import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case inventory = "Inventory"
    case scan = "Scan"
    case recipes = "Recipes"
    case insights = "Insights"
    case settings = "Settings"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .dashboard: "house.fill"
        case .inventory: "refrigerator.fill"
        case .scan: "camera.viewfinder"
        case .recipes: "fork.knife"
        case .insights: "chart.line.uptrend.xyaxis"
        case .settings: "gearshape.fill"
        }
    }
}

struct AppRootView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InventoryItem.estimatedExpiry, order: .forward) private var inventory: [InventoryItem]
    @State private var viewModel = AppViewModel()
    @State private var selectedTab: AppTab = .dashboard
    @State private var activeVoiceSource: VoiceSourceScreen?
    @State private var showingOnboarding = true
    @State private var showingPaywall = false

    var body: some View {
        TabView(selection: $selectedTab) {
            ForEach(AppTab.allCases) { tab in
                NavigationStack {
                    content(for: tab)
                        .navigationTitle(tab.rawValue)
                        .navigationBarTitleDisplayMode(.large)
                }
                .tabItem {
                    Label(tab.rawValue, systemImage: tab.systemImage)
                }
                .tag(tab)
            }
        }
        .tint(FreshFlowTheme.deepSage)
        .background(FreshFlowTheme.pageGradient)
        .sheet(isPresented: $showingOnboarding) {
            OnboardingView(viewModel: viewModel)
                .interactiveDismissDisabled()
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView()
        }
        .sheet(item: $activeVoiceSource) { source in
            VoiceCommandSheet(sourceScreen: source, viewModel: viewModel, inventory: inventory)
                .presentationDetents([.large])
        }
        .task {
            viewModel.seedIfNeeded(modelContext: modelContext, inventory: inventory)
            await viewModel.refreshInsights(from: inventory)
        }
        .onChange(of: viewModel.hasCompletedOnboarding) { _, completed in
            if completed {
                showingOnboarding = false
            }
        }
    }

    @ViewBuilder
    private func content(for tab: AppTab) -> some View {
        switch tab {
        case .dashboard:
            DashboardView(
                viewModel: viewModel,
                showPaywall: { showingPaywall = true },
                openVoiceInput: { activeVoiceSource = .dashboard },
                selectTab: { selectedTab = $0 }
            )
        case .inventory:
            InventoryView(
                openVoiceInput: { activeVoiceSource = .inventory }
            )
        case .scan:
            ScannerView(
                viewModel: viewModel,
                openVoiceInput: { activeVoiceSource = .scanner }
            )
        case .recipes:
            RecipeHubView(
                viewModel: viewModel,
                openVoiceInput: { source in activeVoiceSource = source }
            )
        case .insights:
            InsightsHubView(
                viewModel: viewModel,
                openVoiceInput: { source in activeVoiceSource = source }
            )
        case .settings:
            SettingsView(
                showPaywall: { showingPaywall = true },
                openVoiceInput: { activeVoiceSource = .settings }
            )
        }
    }
}
