import SwiftData
import SwiftUI

struct RecipeHubView: View {
    var viewModel: AppViewModel
    var openVoiceInput: (VoiceSourceScreen) -> Void

    @Query(sort: \InventoryItem.estimatedExpiry, order: .forward) private var inventory: [InventoryItem]
    @State private var selectedMode = "Quick meals"

    private let modes = ["Quick meals", "Family meals", "Healthy meals", "Budget meals", "Leftovers mode"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    SectionHeader(title: "AI Recipe Generator", subtitle: "Meals from ingredients you already own.")
                    VoiceInputButton(title: "Voice") { openVoiceInput(.recipes) }
                }

                Picker("Mode", selection: $selectedMode) {
                    ForEach(modes, id: \.self) { mode in
                        Text(mode).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                FoodPhotographyPlaceholder(category: .produce, size: 96)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)

                PremiumActionButton(title: "Generate \(selectedMode)", systemImage: "sparkles") {
                    Task { await viewModel.generateRecipes(from: inventory, mode: selectedMode) }
                }

                if viewModel.generatedRecipes.isEmpty {
                    EmptyStateView(
                        title: "Ready for recipe ideas",
                        message: "Generate meals from expiring ingredients, pantry staples, and household preferences.",
                        systemImage: "fork.knife.circle"
                    )
                } else {
                    ForEach(viewModel.generatedRecipes) { recipe in
                        RecipeCard(recipe: recipe)
                    }
                }

                LeftoverEngineView(openVoiceInput: { openVoiceInput(.leftovers) })
                MealPlanningView(viewModel: viewModel, openVoiceInput: { openVoiceInput(.mealPlan) })
                SafetyDisclaimerView()
            }
            .padding(20)
        }
        .background(FreshFlowTheme.pageGradient.ignoresSafeArea())
    }
}

struct LeftoverEngineView: View {
    var openVoiceInput: () -> Void

    @State private var leftovers = "Cooked rice, roasted vegetables"
    @State private var ideas = [
        "Turn rice into a fried rice bowl with eggs and greens.",
        "Fold roasted vegetables into a frittata.",
        "Freeze extra portions if they will not be eaten soon."
    ]

    var body: some View {
        FreshFlowCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionHeader(title: "Smart Leftover Engine", subtitle: "Reuse ideas and storage suggestions.")
                    VoiceInputButton(title: "Voice", action: openVoiceInput)
                }
                TextField("Leftovers or cooked meals", text: $leftovers, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
                Button {
                    ideas = [
                        "Transform \(leftovers) into a warm grain bowl.",
                        "Add herbs, yogurt, or a sauce for a fresh texture.",
                        "Verify storage time and reheat thoroughly before eating."
                    ]
                } label: {
                    Label("Generate leftover ideas", systemImage: "arrow.triangle.2.circlepath")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                VStack(alignment: .leading, spacing: 8) {
                    ForEach(ideas, id: \.self) { idea in
                        Label(idea, systemImage: "leaf.fill")
                            .font(.subheadline)
                            .foregroundStyle(FreshFlowTheme.charcoal)
                    }
                }
            }
        }
    }
}

struct MealPlanningView: View {
    var viewModel: AppViewModel
    var openVoiceInput: () -> Void

    var body: some View {
        FreshFlowCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    SectionHeader(title: "Meal Planning", subtitle: "Weekly plans that prioritize owned ingredients.")
                    VoiceInputButton(title: "Voice", action: openVoiceInput)
                }

                ForEach(viewModel.mealPlan) { day in
                    HStack(alignment: .top, spacing: 12) {
                        Text(day.day)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 42, height: 42)
                            .background(FreshFlowTheme.deepSage, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(day.meal)
                                .font(.headline)
                                .foregroundStyle(FreshFlowTheme.charcoal)
                            Text("Uses: \(day.usesOwnedIngredients.joined(separator: ", "))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(FreshFlowTheme.sage.opacity(0.10), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
    }
}
