import Foundation

struct ScanInput: Hashable {
    var source: StorageLocation
    var imageReference: String
}

protocol FoodRecognitionService {
    func recognizeFood(from input: ScanInput) async throws -> [ScannerReviewItem]
}

protocol ExpiryPredictionService {
    func predictStatus(for item: InventoryItem) -> FreshnessStatus
    func suggestedExpiry(for itemName: String, category: FoodCategory, purchaseDate: Date) -> Date
}

protocol RecipeGenerationService {
    func generateRecipes(from items: [InventoryItem], mode: String, dietaryPreferences: [String]) async throws -> [GeneratedRecipe]
}

protocol PantryForecastService {
    func forecastRestockNeeds(from items: [InventoryItem]) async throws -> [ShoppingRecommendation]
}

protocol WasteReductionService {
    func createWasteReport(from items: [InventoryItem]) async throws -> WasteReportDraft
}

protocol ShoppingListService {
    func generateShoppingList(from items: [InventoryItem], mealGoal: String) async throws -> ShoppingRecommendation
}

typealias FreshFlowAIProviding = FoodRecognitionService
    & ExpiryPredictionService
    & RecipeGenerationService
    & PantryForecastService
    & WasteReductionService
    & ShoppingListService

struct WasteReportDraft: Hashable {
    var wasteRisk: Double
    var estimatedSavings: Double
    var suggestedActions: [String]
}

struct LocalFreshFlowAIService: FreshFlowAIProviding {
    func recognizeFood(from input: ScanInput) async throws -> [ScannerReviewItem] {
        try await Task.sleep(for: .milliseconds(450))

        let calendar = Calendar.current
        let base: [(String, String, FoodCategory, Int, Double, String)] = [
            ("Baby spinach", "1 bag", .produce, 2, 0.93, "Keep dry in a sealed container with a paper towel."),
            ("Greek yogurt", "1 tub", .dairy, 5, 0.89, "Store on the middle fridge shelf."),
            ("Cooked rice", "2 portions", .leftovers, 1, 0.86, "Label leftovers and reheat thoroughly before eating."),
            ("Strawberries", "1 punnet", .produce, 2, 0.91, "Use soon or freeze for smoothies."),
            ("Pasta sauce", "1 jar", .pantry, 24, 0.84, "Refrigerate after opening.")
        ]

        return base.map { name, quantity, category, offset, confidence, suggestion in
            ScannerReviewItem(
                itemName: name,
                quantity: quantity,
                category: category,
                location: input.source,
                estimatedExpiry: calendar.date(byAdding: .day, value: offset, to: .now) ?? .now,
                confidence: confidence,
                storageSuggestion: suggestion
            )
        }
    }

    func predictStatus(for item: InventoryItem) -> FreshnessStatus {
        item.freshnessStatus
    }

    func suggestedExpiry(for itemName: String, category: FoodCategory, purchaseDate: Date) -> Date {
        let days: Int
        switch category {
        case .produce: days = itemName.localizedCaseInsensitiveContains("berry") ? 3 : 6
        case .dairy: days = 7
        case .meat: days = 2
        case .frozen: days = 45
        case .pantry: days = 30
        case .beverages: days = 14
        case .snacks: days = 21
        case .leftovers: days = 3
        }

        return Calendar.current.date(byAdding: .day, value: days, to: purchaseDate) ?? purchaseDate
    }

    func generateRecipes(from items: [InventoryItem], mode: String, dietaryPreferences: [String]) async throws -> [GeneratedRecipe] {
        try await Task.sleep(for: .milliseconds(350))
        let expiring = items.sorted { $0.daysUntilExpiry < $1.daysUntilExpiry }.prefix(5).map(\.itemName)
        let pantryNames = expiring.isEmpty ? ["spinach", "rice", "eggs"] : Array(expiring)
        let preferenceLine = dietaryPreferences.isEmpty ? "family-friendly" : dietaryPreferences.joined(separator: ", ")

        return [
            GeneratedRecipe(
                title: "Golden Pantry Frittata",
                ingredients: pantryNames.prefix(4).map { $0 },
                instructions: [
                    "Review ingredient quality and discard anything that appears unsafe.",
                    "Whisk eggs or a preferred binder with herbs.",
                    "Fold in chopped expiring ingredients and bake until set.",
                    "Serve with a simple salad or toasted bread."
                ],
                preparationTime: "25 min",
                shoppingGaps: ["eggs", "fresh herbs"],
                mode: mode
            ),
            GeneratedRecipe(
                title: "Low-Waste Rice Bowl",
                ingredients: pantryNames,
                instructions: [
                    "Warm grains and vegetables separately.",
                    "Add sauce, seeds, or yogurt for texture.",
                    "Use leftovers only when they have been stored and reheated safely."
                ],
                preparationTime: "18 min",
                shoppingGaps: ["sesame seeds"],
                mode: preferenceLine
            )
        ]
    }

    func forecastRestockNeeds(from items: [InventoryItem]) async throws -> [ShoppingRecommendation] {
        try await Task.sleep(for: .milliseconds(250))
        let lowPantry = items.filter { $0.categoryValue == .pantry }.prefix(3).map(\.itemName)
        return [
            ShoppingRecommendation(
                title: "Smart restock",
                items: lowPantry.isEmpty ? ["oats", "olive oil", "rice", "tinned tomatoes"] : Array(lowPantry),
                budgetEstimate: 26,
                reason: "Based on pantry coverage and upcoming meal plans."
            )
        ]
    }

    func createWasteReport(from items: [InventoryItem]) async throws -> WasteReportDraft {
        try await Task.sleep(for: .milliseconds(250))
        let risky = items.filter { $0.daysUntilExpiry <= 3 }
        let risk = min(1.0, Double(risky.count) / max(Double(items.count), 1.0))
        let value = risky.reduce(0) { $0 + $1.estimatedValue }
        return WasteReportDraft(
            wasteRisk: risk,
            estimatedSavings: value,
            suggestedActions: [
                "Cook the highest-risk item first.",
                "Freeze produce that will not be used within 48 hours.",
                "Generate a recipe from expiring ingredients."
            ]
        )
    }

    func generateShoppingList(from items: [InventoryItem], mealGoal: String) async throws -> ShoppingRecommendation {
        try await Task.sleep(for: .milliseconds(250))
        let gaps = mealGoal.localizedCaseInsensitiveContains("pasta")
            ? ["wholegrain pasta", "parmesan", "basil", "tomatoes"]
            : ["eggs", "greens", "lemons", "grain bowls"]

        return ShoppingRecommendation(
            title: "\(mealGoal.capitalized) list",
            items: gaps,
            budgetEstimate: 22,
            reason: "Prioritizes owned ingredients and fills only the likely gaps."
        )
    }
}

struct RemoteAIService: FreshFlowAIProviding {
    var endpoint = URL(string: "https://api.freshflow.app/freshflow-ai")
    private let local = LocalFreshFlowAIService()

    func recognizeFood(from input: ScanInput) async throws -> [ScannerReviewItem] {
        try await local.recognizeFood(from: input)
    }

    func predictStatus(for item: InventoryItem) -> FreshnessStatus {
        local.predictStatus(for: item)
    }

    func suggestedExpiry(for itemName: String, category: FoodCategory, purchaseDate: Date) -> Date {
        local.suggestedExpiry(for: itemName, category: category, purchaseDate: purchaseDate)
    }

    func generateRecipes(from items: [InventoryItem], mode: String, dietaryPreferences: [String]) async throws -> [GeneratedRecipe] {
        try await local.generateRecipes(from: items, mode: mode, dietaryPreferences: dietaryPreferences)
    }

    func forecastRestockNeeds(from items: [InventoryItem]) async throws -> [ShoppingRecommendation] {
        try await local.forecastRestockNeeds(from: items)
    }

    func createWasteReport(from items: [InventoryItem]) async throws -> WasteReportDraft {
        try await local.createWasteReport(from: items)
    }

    func generateShoppingList(from items: [InventoryItem], mealGoal: String) async throws -> ShoppingRecommendation {
        try await local.generateShoppingList(from: items, mealGoal: mealGoal)
    }
}
