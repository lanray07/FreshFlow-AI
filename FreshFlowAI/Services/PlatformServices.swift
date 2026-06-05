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

    private let productIDs = [
        "freshflow.premium.monthly",
        "freshflow.premium.yearly",
        "freshflow.family.monthly"
    ]

    func loadProducts() async {
        isLoading = true
        defer { isLoading = false }

        do {
            products = try await Product.products(for: productIDs)
        } catch {
            errorMessage = "StoreKit products are placeholders until App Store Connect products are configured."
        }
    }

    func refreshEntitlements() async {
        for await result in Transaction.currentEntitlements {
            if case let .verified(transaction) = result {
                if transaction.productID.contains("family") {
                    currentPlan = .familyMonthly
                } else if transaction.productID.contains("premium") {
                    currentPlan = .premiumMonthly
                }
            }
        }
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
