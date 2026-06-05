import SwiftData
import SwiftUI

struct InventoryView: View {
    var openVoiceInput: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \InventoryItem.estimatedExpiry, order: .forward) private var inventory: [InventoryItem]
    @State private var searchText = ""
    @State private var selectedCategory: FoodCategory?
    @State private var showingAddItem = false

    private var filteredInventory: [InventoryItem] {
        inventory.filter { item in
            let matchesSearch = searchText.isEmpty || item.itemName.localizedCaseInsensitiveContains(searchText)
            let matchesCategory = selectedCategory == nil || item.categoryValue == selectedCategory
            return matchesSearch && matchesCategory
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                HStack {
                    SectionHeader(title: "Pantry Inventory", subtitle: "\(inventory.count) tracked items")
                    VoiceInputButton(title: "Voice", action: openVoiceInput)
                }

                TextField("Search pantry, fridge, freezer", text: $searchText)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityLabel("Search inventory")

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        CategoryChip(title: "All", isSelected: selectedCategory == nil) {
                            selectedCategory = nil
                        }
                        ForEach(FoodCategory.allCases) { category in
                            CategoryChip(title: category.rawValue, isSelected: selectedCategory == category) {
                                selectedCategory = category
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }

                PremiumActionButton(title: "Add Grocery", systemImage: "plus.circle.fill") {
                    showingAddItem = true
                }

                if filteredInventory.isEmpty {
                    EmptyStateView(
                        title: "No matching items",
                        message: "Add groceries manually, scan a storage area, scan a receipt, or use voice input.",
                        systemImage: "tray"
                    )
                } else {
                    VStack(spacing: 12) {
                        ForEach(filteredInventory) { item in
                            InventoryCard(item: item)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        modelContext.delete(item)
                                        try? modelContext.save()
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }

                SafetyDisclaimerView(compact: true)
            }
            .padding(20)
        }
        .background(FreshFlowTheme.pageGradient.ignoresSafeArea())
        .sheet(isPresented: $showingAddItem) {
            AddInventoryItemSheet()
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddItem = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add grocery")
            }
        }
    }
}

private struct CategoryChip: View {
    var title: String
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? .white : FreshFlowTheme.charcoal)
                .padding(.horizontal, 13)
                .padding(.vertical, 8)
                .background(isSelected ? FreshFlowTheme.deepSage : Color.white.opacity(0.72), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct AddInventoryItemSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var name = ""
    @State private var quantity = "1"
    @State private var category: FoodCategory = .produce
    @State private var location: StorageLocation = .fridge
    @State private var expiry = Calendar.current.date(byAdding: .day, value: 5, to: .now) ?? .now
    @State private var value = 4.5

    var body: some View {
        NavigationStack {
            Form {
                Section("Food item") {
                    TextField("Item name", text: $name)
                    TextField("Quantity", text: $quantity)
                    Picker("Category", selection: $category) {
                        ForEach(FoodCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    Picker("Location", selection: $location) {
                        ForEach(StorageLocation.allCases) { location in
                            Text(location.rawValue).tag(location)
                        }
                    }
                    DatePicker("Estimated expiry", selection: $expiry, displayedComponents: .date)
                    Stepper("Value: GBP \(value, specifier: "%.0f")", value: $value, in: 0...80, step: 1)
                }

                Section {
                    SafetyDisclaimerView(compact: true)
                }
            }
            .navigationTitle("Add Grocery")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        modelContext.insert(InventoryItem(
                            itemName: name.isEmpty ? "New grocery" : name,
                            quantity: quantity,
                            category: category,
                            estimatedExpiry: expiry,
                            location: location,
                            estimatedValue: value
                        ))
                        try? modelContext.save()
                        dismiss()
                    }
                }
            }
        }
    }
}
