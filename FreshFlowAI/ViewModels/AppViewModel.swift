import Foundation
import Observation
import SwiftData

@MainActor
@Observable
final class AppViewModel {
    var householdSize = 3
    var dietaryPreferences: [String] = ["Flexible", "Low waste"]
    var cookingFrequency = "Most nights"
    var shoppingFrequency = "Weekly"
    var foodWasteGoal = "Save GBP 40 per month"

    var selectedRecipeMode = "Quick meals"
    var generatedRecipes: [GeneratedRecipe] = []
    var shoppingRecommendations: [ShoppingRecommendation] = []
    var scannerReviewItems: [ScannerReviewItem] = []
    var savingsTrend: [SavingsTrendPoint] = [
        SavingsTrendPoint(label: "Jan", value: 18),
        SavingsTrendPoint(label: "Feb", value: 28),
        SavingsTrendPoint(label: "Mar", value: 36),
        SavingsTrendPoint(label: "Apr", value: 45),
        SavingsTrendPoint(label: "May", value: 52)
    ]
    var mealPlan: [MealPlanDay] = [
        MealPlanDay(day: "Mon", meal: "Spinach rice bowls", usesOwnedIngredients: ["Spinach", "Rice"]),
        MealPlanDay(day: "Tue", meal: "Fridge frittata", usesOwnedIngredients: ["Eggs", "Yogurt"]),
        MealPlanDay(day: "Wed", meal: "Leftover pasta bake", usesOwnedIngredients: ["Pasta sauce"])
    ]
    var lastWasteReport = WasteReportDraft(
        wasteRisk: 0.34,
        estimatedSavings: 42,
        suggestedActions: ["Cook spinach tonight", "Freeze berries", "Use yogurt in breakfast bowls"]
    )
    var lastVoiceIntent: VoiceCommandIntentDraft?
    var isLoading = false
    var errorMessage: String?
    var hasCompletedOnboarding = false

    @ObservationIgnored private let aiService: any FreshFlowAIProviding
    @ObservationIgnored private let voiceInputService: any VoiceInputService
    @ObservationIgnored private let voiceParser = VoiceCommandParserService()

    init(
        aiService: any FreshFlowAIProviding = LocalFreshFlowAIService(),
        voiceInputService: any VoiceInputService = NativeVoiceInputService()
    ) {
        self.aiService = aiService
        self.voiceInputService = voiceInputService
    }

    func seedIfNeeded(modelContext: ModelContext, inventory: [InventoryItem]) {
        guard inventory.isEmpty else { return }

        let calendar = Calendar.current
        let samples = [
            InventoryItem(
                itemName: "Baby spinach",
                quantity: "1 bag",
                category: .produce,
                estimatedExpiry: calendar.date(byAdding: .day, value: 2, to: .now) ?? .now,
                location: .fridge,
                estimatedValue: 3.5
            ),
            InventoryItem(
                itemName: "Greek yogurt",
                quantity: "1 tub",
                category: .dairy,
                estimatedExpiry: calendar.date(byAdding: .day, value: 5, to: .now) ?? .now,
                location: .fridge,
                estimatedValue: 4.2
            ),
            InventoryItem(
                itemName: "Wholegrain rice",
                quantity: "2 kg",
                category: .pantry,
                estimatedExpiry: calendar.date(byAdding: .day, value: 45, to: .now) ?? .now,
                location: .pantry,
                estimatedValue: 6.0
            ),
            InventoryItem(
                itemName: "Cooked lasagna",
                quantity: "2 portions",
                category: .leftovers,
                estimatedExpiry: calendar.date(byAdding: .day, value: 1, to: .now) ?? .now,
                location: .fridge,
                estimatedValue: 8.0
            )
        ]

        samples.forEach(modelContext.insert)
        modelContext.insert(HouseholdProfile(
            householdSize: householdSize,
            dietaryPreferences: dietaryPreferences,
            cookingFrequency: cookingFrequency,
            shoppingFrequency: shoppingFrequency,
            foodWasteGoal: foodWasteGoal
        ))
        modelContext.insert(SubscriptionState(plan: .free, isActive: false))
        try? modelContext.save()
    }

    func completeOnboarding(modelContext: ModelContext) {
        let profile = HouseholdProfile(
            householdSize: householdSize,
            dietaryPreferences: dietaryPreferences,
            cookingFrequency: cookingFrequency,
            shoppingFrequency: shoppingFrequency,
            foodWasteGoal: foodWasteGoal
        )
        modelContext.insert(profile)
        try? modelContext.save()
        hasCompletedOnboarding = true
    }

    func runScan(source: StorageLocation) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            scannerReviewItems = try await aiService.recognizeFood(from: ScanInput(source: source, imageReference: "food-review-session"))
        } catch {
            errorMessage = "FreshFlow AI could not complete the food review."
        }
    }

    func addReviewItem(_ reviewItem: ScannerReviewItem, modelContext: ModelContext) {
        modelContext.insert(InventoryItem(
            itemName: reviewItem.itemName,
            quantity: reviewItem.quantity,
            category: reviewItem.category,
            estimatedExpiry: reviewItem.estimatedExpiry,
            location: reviewItem.location,
            estimatedValue: 4.5
        ))
        try? modelContext.save()
    }

    func generateRecipes(from items: [InventoryItem], mode: String? = nil) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            generatedRecipes = try await aiService.generateRecipes(
                from: items,
                mode: mode ?? selectedRecipeMode,
                dietaryPreferences: dietaryPreferences
            )
        } catch {
            errorMessage = "Recipe generation is unavailable."
        }
    }

    func refreshInsights(from items: [InventoryItem]) async {
        do {
            lastWasteReport = try await aiService.createWasteReport(from: items)
            shoppingRecommendations = try await aiService.forecastRestockNeeds(from: items)
        } catch {
            errorMessage = "Insight refresh is unavailable."
        }
    }

    func generateShoppingList(from items: [InventoryItem], mealGoal: String) async {
        do {
            let list = try await aiService.generateShoppingList(from: items, mealGoal: mealGoal)
            shoppingRecommendations.insert(list, at: 0)
        } catch {
            errorMessage = "Shopping list generation is unavailable."
        }
    }

    func captureVoiceCommand(source: VoiceSourceScreen) async -> VoiceCommandIntentDraft? {
        isLoading = true
        defer { isLoading = false }

        do {
            let permission = await voiceInputService.requestPermissions()
            guard permission == .granted else {
                errorMessage = "Voice input needs microphone and speech recognition permission. Typed input remains available."
                return nil
            }

            let result = try await voiceInputService.startListening(source: source)
            let intent = voiceParser.parse(result)
            lastVoiceIntent = intent
            return intent
        } catch {
            errorMessage = (error as? LocalizedError)?.errorDescription ?? "Voice input could not start. Typed input remains available."
            return nil
        }
    }

    func parseTypedVoiceFallback(_ text: String, source: VoiceSourceScreen) -> VoiceCommandIntentDraft {
        let intent = voiceParser.parse(VoiceInputResult(transcript: text, confidence: 0.72, sourceScreen: source))
        lastVoiceIntent = intent
        return intent
    }

    func applyVoiceIntent(_ intent: VoiceCommandIntentDraft, modelContext: ModelContext, inventory: [InventoryItem]) {
        let session = VoiceInputSession(
            transcript: intent.rawTranscript,
            confidence: intent.confidence,
            parsedIntent: intent.intentType,
            sourceScreen: intent.sourceScreen
        )
        let storedIntent = VoiceCommandIntent(
            intentType: intent.intentType,
            rawTranscript: intent.rawTranscript,
            extractedItems: intent.extractedItems.map(\.itemName),
            requiresReview: true
        )
        modelContext.insert(session)
        modelContext.insert(storedIntent)

        switch intent.intentType {
        case .addInventoryItems, .addLeftover:
            for food in intent.extractedItems {
                modelContext.insert(InventoryItem(
                    itemName: food.itemName,
                    quantity: food.quantity,
                    category: food.category,
                    estimatedExpiry: food.estimatedExpiry,
                    location: food.location,
                    estimatedValue: 4.0
                ))
            }
        case .removeInventoryItem:
            if let first = intent.extractedItems.first,
               let match = inventory.first(where: { $0.itemName.localizedCaseInsensitiveContains(first.itemName) }) {
                modelContext.delete(match)
            }
        case .createShoppingList:
            modelContext.insert(ShoppingList(
                title: "Voice shopping list",
                items: intent.extractedItems.map(\.itemName).isEmpty ? ["pasta", "tomatoes", "basil"] : intent.extractedItems.map(\.itemName),
                budgetEstimate: 24
            ))
        case .generateRecipe:
            generatedRecipes.insert(GeneratedRecipe(
                title: "Voice Pantry Supper",
                ingredients: intent.extractedItems.map(\.itemName),
                instructions: [
                    "Check each ingredient independently before use.",
                    "Combine named ingredients with a pantry staple.",
                    "Cook fully and follow official food safety guidance."
                ],
                preparationTime: "20 min",
                shoppingGaps: ["fresh herbs"],
                mode: "Voice"
            ), at: 0)
        case .createMealPlan:
            mealPlan = [
                MealPlanDay(day: "Mon", meal: "Voice-planned pantry bowls", usesOwnedIngredients: ["Rice", "Greens"]),
                MealPlanDay(day: "Tue", meal: "Leftover refresh dinner", usesOwnedIngredients: ["Leftovers"]),
                MealPlanDay(day: "Wed", meal: "Budget pasta night", usesOwnedIngredients: ["Sauce"])
            ]
        case .showExpiringSoon, .openWasteReport, .updateInventoryItem, .unknown:
            break
        }

        try? modelContext.save()
    }
}
