import SwiftData
import SwiftUI

@main
struct FreshFlowAIApp: App {
    var body: some Scene {
        WindowGroup {
            AppRootView()
        }
        .modelContainer(for: [
            HouseholdProfile.self,
            InventoryItem.self,
            FridgeScan.self,
            Recipe.self,
            ShoppingList.self,
            WasteReport.self,
            ReceiptScan.self,
            SubscriptionState.self,
            VoiceInputSession.self,
            VoiceCommandIntent.self
        ])
    }
}
