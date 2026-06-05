import SwiftData
import SwiftUI

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    var viewModel: AppViewModel

    @State private var selectedPreferences: Set<String> = ["Low waste"]
    @State private var goalIndex = 1

    private let preferences = ["Flexible", "Vegetarian", "High protein", "Budget", "Low waste", "Family meals"]
    private let goals = ["Reduce waste", "Save GBP 40/month", "Cook more at home", "Simplify groceries"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    hero

                    FreshFlowCard {
                        VStack(alignment: .leading, spacing: 18) {
                            SectionHeader(title: "Household profile", subtitle: "FreshFlow personalizes waste risk, recipes, and shopping reminders.")

                            Stepper("Household size: \(viewModel.householdSize)", value: Binding(
                                get: { viewModel.householdSize },
                                set: { viewModel.householdSize = $0 }
                            ), in: 1...8)

                            Picker("Cooking", selection: Binding(
                                get: { viewModel.cookingFrequency },
                                set: { viewModel.cookingFrequency = $0 }
                            )) {
                                Text("A few nights").tag("A few nights")
                                Text("Most nights").tag("Most nights")
                                Text("Meal prep").tag("Meal prep")
                            }
                            .pickerStyle(.segmented)

                            Picker("Shopping", selection: Binding(
                                get: { viewModel.shoppingFrequency },
                                set: { viewModel.shoppingFrequency = $0 }
                            )) {
                                Text("Weekly").tag("Weekly")
                                Text("Twice weekly").tag("Twice weekly")
                                Text("Monthly").tag("Monthly")
                            }
                            .pickerStyle(.segmented)
                        }
                    }

                    FreshFlowCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Dietary preferences")
                                .font(.headline)
                            FlowTagSelection(options: preferences, selection: $selectedPreferences)
                        }
                    }

                    FreshFlowCard {
                        VStack(alignment: .leading, spacing: 16) {
                            Picker("Food waste goal", selection: $goalIndex) {
                                ForEach(goals.indices, id: \.self) { index in
                                    Text(goals[index]).tag(index)
                                }
                            }
                            .pickerStyle(.wheel)
                            SavingsCard(saved: 42, inventoryValue: 126)
                        }
                    }

                    SafetyDisclaimerView()

                    PremiumActionButton(title: "Create my FreshFlow dashboard", systemImage: "sparkles") {
                        viewModel.dietaryPreferences = Array(selectedPreferences)
                        viewModel.foodWasteGoal = goals[goalIndex]
                        viewModel.completeOnboarding(modelContext: modelContext)
                    }
                }
                .padding(20)
            }
            .background(FreshFlowTheme.pageGradient.ignoresSafeArea())
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 18) {
            FoodPhotographyPlaceholder(category: .produce, size: 94)
            Text("FreshFlow AI")
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(FreshFlowTheme.charcoal)
            Text("Know what to eat before it expires.")
                .font(.title3.weight(.semibold))
                .foregroundStyle(FreshFlowTheme.deepSage)
            Text("Turn food waste into savings with intelligent pantry tracking, recipe ideas, and grocery planning.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private struct FlowTagSelection: View {
    var options: [String]
    @Binding var selection: Set<String>

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 104), spacing: 8)], alignment: .leading, spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isSelected = selection.contains(option)
                Button {
                    if isSelected {
                        selection.remove(option)
                    } else {
                        selection.insert(option)
                    }
                } label: {
                    Text(option)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(isSelected ? .white : FreshFlowTheme.charcoal)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(isSelected ? FreshFlowTheme.sage : Color.white.opacity(0.7), in: Capsule())
                }
                .buttonStyle(.plain)
            }
        }
    }
}
