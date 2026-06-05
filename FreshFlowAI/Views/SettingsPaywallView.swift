import SwiftData
import SwiftUI

struct SettingsView: View {
    var showPaywall: () -> Void
    var openVoiceInput: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var inventory: [InventoryItem]
    @State private var enableNotifications = true
    @State private var enableVoiceInput = true
    @State private var requireVoiceConfirmation = true
    @State private var preferredVoiceLanguage = "English (US)"
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                FreshFlowCard {
                    VStack(alignment: .leading, spacing: 14) {
                        SectionHeader(title: "Settings", subtitle: "Privacy, subscriptions, voice, and household preferences.")
                        UpgradeBanner(action: showPaywall)
                    }
                }

                FreshFlowCard {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Voice preferences")
                            .font(.headline)
                        Toggle("Enable voice input", isOn: $enableVoiceInput)
                        Toggle("Require confirmation before applying commands", isOn: $requireVoiceConfirmation)
                        Picker("Language", selection: $preferredVoiceLanguage) {
                            Text("English (US)").tag("English (US)")
                            Text("English (UK)").tag("English (UK)")
                        }
                        VoicePermissionView(state: enableVoiceInput ? .granted : .denied)
                        VoiceInputButton(title: "Try Voice", action: openVoiceInput)
                    }
                }

                FreshFlowCard {
                    VStack(alignment: .leading, spacing: 12) {
                        SettingsRow(title: "Subscription", value: "Free", systemImage: "sparkles")
                        SettingsRow(title: "Dietary preferences", value: "Flexible, Low waste", systemImage: "fork.knife")
                        SettingsRow(title: "Notification settings", value: enableNotifications ? "Enabled" : "Off", systemImage: "bell.fill")
                        Toggle("Shopping and expiry reminders", isOn: $enableNotifications)
                    }
                }

                FreshFlowCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Legal and safety")
                            .font(.headline)
                        SettingsRow(title: "Privacy Policy", value: "Placeholder", systemImage: "lock.shield.fill")
                        SettingsRow(title: "Terms", value: "Placeholder", systemImage: "doc.text.fill")
                        SafetyDisclaimerView()
                    }
                }

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete all inventory data", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .padding(20)
        }
        .background(FreshFlowTheme.pageGradient.ignoresSafeArea())
        .confirmationDialog("Delete all inventory data?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                inventory.forEach { modelContext.delete($0) }
                try? modelContext.save()
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}

private struct SettingsRow: View {
    var title: String
    var value: String
    var systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(.white)
                .frame(width: 34, height: 34)
                .background(FreshFlowTheme.sage, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(FreshFlowTheme.charcoal)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedPlan: SubscriptionPlan = .premiumYearly

    private let plans: [(SubscriptionPlan, String, String)] = [
        (.premiumMonthly, "Premium Monthly", "GBP 7.99"),
        (.premiumYearly, "Premium Yearly", "GBP 59.99"),
        (.familyMonthly, "Family Monthly", "GBP 14.99")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    FoodPhotographyPlaceholder(category: .produce, size: 100)
                    Text("Unlock FreshFlow Premium")
                        .font(.largeTitle.bold())
                        .foregroundStyle(FreshFlowTheme.charcoal)
                    Text("Unlimited inventory, AI fridge scans, recipes, waste analytics, pantry forecast, and premium reports.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    FreshFlowCard {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(plans.enumerated()), id: \.offset) { _, entry in
                                let plan = entry.0
                                let title = entry.1
                                let price = entry.2
                                Button {
                                    selectedPlan = plan
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading) {
                                            Text(title)
                                                .font(.headline)
                                            Text(price)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: selectedPlan == plan ? "checkmark.circle.fill" : "circle")
                                            .foregroundStyle(selectedPlan == plan ? FreshFlowTheme.deepSage : .secondary)
                                    }
                                    .padding(12)
                                    .background(selectedPlan == plan ? FreshFlowTheme.sage.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    FreshFlowCard {
                        VStack(alignment: .leading, spacing: 10) {
                            Label("Unlimited inventory", systemImage: "checkmark.seal.fill")
                            Label("AI fridge scans", systemImage: "camera.fill")
                            Label("Recipe generator", systemImage: "fork.knife")
                            Label("Waste analytics", systemImage: "chart.bar.fill")
                            Label("Pantry forecast", systemImage: "calendar.badge.clock")
                        }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(FreshFlowTheme.charcoal)
                    }

                    PremiumActionButton(title: "Continue with \(selectedPlan.rawValue)", systemImage: "sparkles") {
                        dismiss()
                    }
                }
                .padding(20)
            }
            .background(FreshFlowTheme.pageGradient.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}
