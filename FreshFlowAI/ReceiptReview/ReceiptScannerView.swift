import SwiftData
import SwiftUI

struct ReceiptScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var extractedItems = ["Apples", "Eggs", "Greek yogurt", "Rice"]
    @State private var isScanning = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    FreshFlowCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Image(systemName: "doc.text.viewfinder")
                                .font(.largeTitle)
                                .foregroundStyle(FreshFlowTheme.deepSage)
                            Text("Receipt Item Review")
                                .font(.title2.bold())
                            Text("Add or edit grocery items from a receipt, then save the reviewed list to your pantry inventory.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    PremiumActionButton(title: isScanning ? "Preparing items..." : "Suggest Common Groceries", systemImage: "text.viewfinder") {
                        isScanning = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                            extractedItems = ["Apples", "Eggs", "Greek yogurt", "Rice", "Tomatoes"]
                            isScanning = false
                        }
                    }

                    SectionHeader(title: "Review extracted items", subtitle: "Correct receipt items before adding them.")
                    ForEach(extractedItems.indices, id: \.self) { index in
                        TextField("Item", text: Binding(
                            get: { extractedItems[index] },
                            set: { extractedItems[index] = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                    }

                    Button {
                        modelContext.insert(ReceiptScan(extractedItems: extractedItems))
                        for item in extractedItems {
                            modelContext.insert(InventoryItem(
                                itemName: item,
                                quantity: "1",
                                category: item.localizedCaseInsensitiveContains("yogurt") ? .dairy : .pantry,
                                estimatedExpiry: Calendar.current.date(byAdding: .day, value: 7, to: .now) ?? .now,
                                location: .pantry,
                                estimatedValue: 3
                            ))
                        }
                        try? modelContext.save()
                        dismiss()
                    } label: {
                        Label("Add reviewed receipt items", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    SafetyDisclaimerView(compact: true)
                }
                .padding(20)
            }
            .background(FreshFlowTheme.pageGradient.ignoresSafeArea())
            .navigationTitle("Receipt Review")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
