import Foundation
import SwiftData

enum FoodCategory: String, CaseIterable, Codable, Identifiable, Hashable {
    case produce = "Produce"
    case dairy = "Dairy"
    case meat = "Meat"
    case frozen = "Frozen"
    case pantry = "Pantry"
    case beverages = "Beverages"
    case snacks = "Snacks"
    case leftovers = "Leftovers"

    var id: String { rawValue }
}

enum StorageLocation: String, CaseIterable, Codable, Identifiable, Hashable {
    case fridge = "Fridge"
    case freezer = "Freezer"
    case pantry = "Pantry"
    case counter = "Counter"

    var id: String { rawValue }
}

enum FreshnessStatus: String, CaseIterable, Codable, Hashable {
    case eatSoon = "Eat Soon"
    case safe = "Fresh"
    case longShelfLife = "Long Shelf Life"
    case wasteRisk = "Waste Risk"

    var urgencyScore: Double {
        switch self {
        case .wasteRisk: 0.92
        case .eatSoon: 0.68
        case .safe: 0.34
        case .longShelfLife: 0.14
        }
    }
}

enum SubscriptionPlan: String, CaseIterable, Codable, Hashable {
    case free = "Free"
    case premiumMonthly = "Premium Monthly"
    case premiumYearly = "Premium Yearly"
    case familyMonthly = "Family Monthly"
}

enum VoiceIntentType: String, CaseIterable, Codable, Identifiable, Hashable {
    case addInventoryItems
    case updateInventoryItem
    case removeInventoryItem
    case createShoppingList
    case generateRecipe
    case createMealPlan
    case addLeftover
    case showExpiringSoon
    case openWasteReport
    case unknown

    var id: String { rawValue }

    var title: String {
        switch self {
        case .addInventoryItems: "Add inventory"
        case .updateInventoryItem: "Update item"
        case .removeInventoryItem: "Remove item"
        case .createShoppingList: "Create shopping list"
        case .generateRecipe: "Generate recipe"
        case .createMealPlan: "Create meal plan"
        case .addLeftover: "Add leftover"
        case .showExpiringSoon: "Show expiring soon"
        case .openWasteReport: "Open waste report"
        case .unknown: "Review command"
        }
    }
}

enum VoiceSourceScreen: String, CaseIterable, Identifiable, Codable, Hashable {
    case dashboard = "Dashboard"
    case inventory = "Inventory"
    case scanner = "Scanner"
    case recipes = "Recipes"
    case groceries = "Groceries"
    case mealPlan = "Meal Plan"
    case leftovers = "Leftovers"
    case receipt = "Receipt"
    case settings = "Settings"

    var id: String { rawValue }
}

@Model
final class HouseholdProfile {
    @Attribute(.unique) var id: UUID
    var householdSize: Int
    var dietaryPreferences: [String]
    var cookingFrequency: String
    var shoppingFrequency: String
    var foodWasteGoal: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        householdSize: Int,
        dietaryPreferences: [String],
        cookingFrequency: String,
        shoppingFrequency: String,
        foodWasteGoal: String,
        createdAt: Date = .now
    ) {
        self.id = id
        self.householdSize = householdSize
        self.dietaryPreferences = dietaryPreferences
        self.cookingFrequency = cookingFrequency
        self.shoppingFrequency = shoppingFrequency
        self.foodWasteGoal = foodWasteGoal
        self.createdAt = createdAt
    }
}

@Model
final class InventoryItem {
    @Attribute(.unique) var id: UUID
    var itemName: String
    var quantity: String
    var category: String
    var purchaseDate: Date
    var estimatedExpiry: Date
    var location: String
    var estimatedValue: Double
    var createdAt: Date

    init(
        id: UUID = UUID(),
        itemName: String,
        quantity: String,
        category: FoodCategory,
        purchaseDate: Date = .now,
        estimatedExpiry: Date,
        location: StorageLocation,
        estimatedValue: Double = 4.50,
        createdAt: Date = .now
    ) {
        self.id = id
        self.itemName = itemName
        self.quantity = quantity
        self.category = category.rawValue
        self.purchaseDate = purchaseDate
        self.estimatedExpiry = estimatedExpiry
        self.location = location.rawValue
        self.estimatedValue = estimatedValue
        self.createdAt = createdAt
    }

    var categoryValue: FoodCategory {
        FoodCategory(rawValue: category) ?? .pantry
    }

    var locationValue: StorageLocation {
        StorageLocation(rawValue: location) ?? .pantry
    }

    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: .now, to: estimatedExpiry).day ?? 0
    }

    var freshnessStatus: FreshnessStatus {
        if daysUntilExpiry <= 0 { return .wasteRisk }
        if daysUntilExpiry <= 3 { return .eatSoon }
        if daysUntilExpiry >= 21 { return .longShelfLife }
        return .safe
    }
}

@Model
final class FridgeScan {
    @Attribute(.unique) var id: UUID
    var imageReference: String
    var identifiedItems: [String]
    var createdAt: Date

    init(id: UUID = UUID(), imageReference: String, identifiedItems: [String], createdAt: Date = .now) {
        self.id = id
        self.imageReference = imageReference
        self.identifiedItems = identifiedItems
        self.createdAt = createdAt
    }
}

@Model
final class Recipe {
    @Attribute(.unique) var id: UUID
    var title: String
    var ingredients: [String]
    var instructions: [String]
    var preparationTime: String
    var shoppingGaps: [String]
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        ingredients: [String],
        instructions: [String],
        preparationTime: String,
        shoppingGaps: [String],
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.ingredients = ingredients
        self.instructions = instructions
        self.preparationTime = preparationTime
        self.shoppingGaps = shoppingGaps
        self.createdAt = createdAt
    }
}

@Model
final class ShoppingList {
    @Attribute(.unique) var id: UUID
    var title: String
    var items: [String]
    var budgetEstimate: Double
    var createdAt: Date

    init(id: UUID = UUID(), title: String, items: [String], budgetEstimate: Double = 24, createdAt: Date = .now) {
        self.id = id
        self.title = title
        self.items = items
        self.budgetEstimate = budgetEstimate
        self.createdAt = createdAt
    }
}

@Model
final class WasteReport {
    @Attribute(.unique) var id: UUID
    var wasteRisk: Double
    var estimatedSavings: Double
    var suggestedActions: [String]
    var createdAt: Date

    init(id: UUID = UUID(), wasteRisk: Double, estimatedSavings: Double, suggestedActions: [String], createdAt: Date = .now) {
        self.id = id
        self.wasteRisk = wasteRisk
        self.estimatedSavings = estimatedSavings
        self.suggestedActions = suggestedActions
        self.createdAt = createdAt
    }
}

@Model
final class ReceiptScan {
    @Attribute(.unique) var id: UUID
    var extractedItems: [String]
    var createdAt: Date

    init(id: UUID = UUID(), extractedItems: [String], createdAt: Date = .now) {
        self.id = id
        self.extractedItems = extractedItems
        self.createdAt = createdAt
    }
}

@Model
final class SubscriptionState {
    @Attribute(.unique) var id: UUID
    var plan: String
    var isActive: Bool

    init(id: UUID = UUID(), plan: SubscriptionPlan = .free, isActive: Bool = false) {
        self.id = id
        self.plan = plan.rawValue
        self.isActive = isActive
    }
}

@Model
final class VoiceInputSession {
    @Attribute(.unique) var id: UUID
    var transcript: String
    var confidence: Double
    var parsedIntent: String
    var createdAt: Date
    var sourceScreen: String

    init(
        id: UUID = UUID(),
        transcript: String,
        confidence: Double,
        parsedIntent: VoiceIntentType,
        createdAt: Date = .now,
        sourceScreen: VoiceSourceScreen
    ) {
        self.id = id
        self.transcript = transcript
        self.confidence = confidence
        self.parsedIntent = parsedIntent.rawValue
        self.createdAt = createdAt
        self.sourceScreen = sourceScreen.rawValue
    }
}

@Model
final class VoiceCommandIntent {
    @Attribute(.unique) var id: UUID
    var intentType: String
    var rawTranscript: String
    var extractedItems: [String]
    var requiresReview: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        intentType: VoiceIntentType,
        rawTranscript: String,
        extractedItems: [String],
        requiresReview: Bool = true,
        createdAt: Date = .now
    ) {
        self.id = id
        self.intentType = intentType.rawValue
        self.rawTranscript = rawTranscript
        self.extractedItems = extractedItems
        self.requiresReview = requiresReview
        self.createdAt = createdAt
    }
}

struct ScannerReviewItem: Identifiable, Hashable {
    let id = UUID()
    var itemName: String
    var quantity: String
    var category: FoodCategory
    var location: StorageLocation
    var estimatedExpiry: Date
    var confidence: Double
    var storageSuggestion: String
}

struct GeneratedRecipe: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var ingredients: [String]
    var instructions: [String]
    var preparationTime: String
    var shoppingGaps: [String]
    var mode: String
}

struct ShoppingRecommendation: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var items: [String]
    var budgetEstimate: Double
    var reason: String
}

struct SavingsTrendPoint: Identifiable, Hashable {
    let id = UUID()
    var label: String
    var value: Double
}

struct MealPlanDay: Identifiable, Hashable {
    let id = UUID()
    var day: String
    var meal: String
    var usesOwnedIngredients: [String]
}

struct VoiceExtractedFoodItem: Identifiable, Hashable, Codable {
    var id = UUID()
    var itemName: String
    var quantity: String
    var category: FoodCategory
    var location: StorageLocation
    var estimatedExpiry: Date
    var confidence: Double
}

struct VoiceCommandIntentDraft: Identifiable, Hashable {
    let id = UUID()
    var intentType: VoiceIntentType
    var rawTranscript: String
    var extractedItems: [VoiceExtractedFoodItem]
    var suggestedAction: String
    var requiresReview: Bool
    var confidence: Double
    var sourceScreen: VoiceSourceScreen
}
