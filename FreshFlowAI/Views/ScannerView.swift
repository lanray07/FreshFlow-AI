import SwiftData
import SwiftUI

struct ScannerView: View {
    var viewModel: AppViewModel
    var openVoiceInput: () -> Void

    @Environment(\.modelContext) private var modelContext
    @State private var selectedSource: StorageLocation = .fridge
    @State private var showingReceiptScanner = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    SectionHeader(title: "Guided Food Scan", subtitle: "Review suggested pantry, fridge, and freezer items before adding them.")
                    VoiceInputButton(title: "Voice", action: openVoiceInput)
                }

                Picker("Scan source", selection: $selectedSource) {
                    Text("Fridge").tag(StorageLocation.fridge)
                    Text("Freezer").tag(StorageLocation.freezer)
                    Text("Pantry").tag(StorageLocation.pantry)
                }
                .pickerStyle(.segmented)

                CameraScannerView(source: selectedSource) {
                    Task { await viewModel.runScan(source: selectedSource) }
                }

                Button {
                    showingReceiptScanner = true
                } label: {
                    Label("Review Receipt Items", systemImage: "doc.text.viewfinder")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)

                if viewModel.isLoading {
                    FreshFlowCard {
                        HStack {
                            ProgressView()
                            Text("FreshFlow AI is identifying food, freshness, and storage suggestions.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                SectionHeader(title: "Review suggested items", subtitle: "Confirm or edit before adding inventory.")
                if viewModel.scannerReviewItems.isEmpty {
                    EmptyStateView(
                        title: "No scan results yet",
                        message: "Start a food review to prepare editable inventory suggestions.",
                        systemImage: "camera.viewfinder"
                    )
                } else {
                    ForEach(viewModel.scannerReviewItems) { item in
                        ScannerReviewCard(item: item) {
                            viewModel.addReviewItem(item, modelContext: modelContext)
                        }
                    }
                }

                SafetyDisclaimerView()
            }
            .padding(20)
        }
        .background(FreshFlowTheme.pageGradient.ignoresSafeArea())
        .sheet(isPresented: $showingReceiptScanner) {
            ReceiptScannerView()
        }
    }
}

private struct ScannerReviewCard: View {
    var item: ScannerReviewItem
    var addAction: () -> Void

    var body: some View {
        FreshFlowCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    FoodPhotographyPlaceholder(category: item.category, size: 58)
                    VStack(alignment: .leading, spacing: 5) {
                        Text(item.itemName)
                            .font(.headline)
                            .foregroundStyle(FreshFlowTheme.charcoal)
                        Text("\(item.quantity) - \(item.category.rawValue) - \(Int(item.confidence * 100))% confidence")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }

                Text(item.storageSuggestion)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                FreshnessMeter(
                    status: Calendar.current.dateComponents([.day], from: .now, to: item.estimatedExpiry).day ?? 0 <= 3 ? .eatSoon : .safe,
                    daysUntilExpiry: Calendar.current.dateComponents([.day], from: .now, to: item.estimatedExpiry).day ?? 0
                )

                Button(action: addAction) {
                    Label("Add to inventory", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}
