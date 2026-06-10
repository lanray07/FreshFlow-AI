import Foundation
import Observation
import StoreKit
import SwiftUI
import UIKit
import UserNotifications

@MainActor
@Observable
final class SubscriptionStore {
    var products: [Product] = []
    var currentPlan: SubscriptionPlan = .free
    var isLoading = false
    var errorMessage: String?

    private let productIDByPlan: [SubscriptionPlan: String] = [
        .premiumMonthly: "freshflow.premium.monthly",
        .premiumYearly: "freshflow.premium.yearly",
        .familyMonthly: "freshflow.family.monthly"
    ]

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: Array(productIDByPlan.values))
            products.sort { $0.displayName < $1.displayName }
            errorMessage = nil
        } catch {
            errorMessage = "Subscriptions are temporarily unavailable. Please try again later."
        }
    }

    func displayPrice(for plan: SubscriptionPlan, fallback: String) -> String {
        product(for: plan)?.displayPrice ?? fallback
    }

    func purchase(_ plan: SubscriptionPlan) async {
        guard let product = product(for: plan) else {
            errorMessage = "This subscription is not available yet. Please try again later."
            return
        }

        isLoading = true
        defer { isLoading = false }

        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    currentPlan = subscriptionPlan(for: transaction.productID)
                    await transaction.finish()
                    errorMessage = nil
                case .unverified(_, _):
                    errorMessage = "Apple could not verify this purchase."
                }
            case .pending:
                errorMessage = "Purchase is pending approval."
            case .userCancelled:
                break
            @unknown default:
                errorMessage = "Purchase could not be completed."
            }
        } catch {
            errorMessage = "Purchase could not be completed."
        }
    }

    func restorePurchases() async {
        isLoading = true
        defer { isLoading = false }

        do {
            try await AppStore.sync()
            await refreshEntitlements()
            errorMessage = nil
        } catch {
            errorMessage = "Purchases could not be restored."
        }
    }

    func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case let .verified(transaction) = result {
                currentPlan = subscriptionPlan(for: transaction.productID)
            }
        }
    }

    private func product(for plan: SubscriptionPlan) -> Product? {
        guard let productID = productIDByPlan[plan] else { return nil }
        return products.first { $0.id == productID }
    }

    private func subscriptionPlan(for productID: String) -> SubscriptionPlan {
        productIDByPlan.first { $0.value == productID }?.key ?? .free
    }
}

struct NotificationScheduler {
    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func scheduleExpiryReminder(for item: InventoryItem) async {
        let content = UNMutableNotificationContent()
        content.title = "\(item.itemName) needs attention"
        content.body = "FreshFlow AI estimates this item may expire soon. Verify food safety independently."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
        let request = UNNotificationRequest(identifier: item.id.uuidString, content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }
}

struct ReportExportService {
    func makeWasteReportPDF(items: [InventoryItem], savings: Double) -> Data {
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(x: 0, y: 0, width: 612, height: 792))
        return renderer.pdfData { context in
            context.beginPage()
            let title = "FreshFlow AI Waste Report"
            let body = "Estimated savings: GBP \(String(format: "%.2f", savings))\nItems tracked: \(items.count)\nFreshness estimates are informational only."
            title.draw(at: CGPoint(x: 48, y: 48), withAttributes: [
                .font: UIFont.boldSystemFont(ofSize: 26),
                .foregroundColor: UIColor.label
            ])
            body.draw(in: CGRect(x: 48, y: 96, width: 520, height: 240), withAttributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.secondaryLabel
            ])
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    var items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
