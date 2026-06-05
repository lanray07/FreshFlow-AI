import SwiftData
import SwiftUI

struct VoiceInputButton: View {
    var title: String = "Voice Command"
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: "mic.fill")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(FreshFlowTheme.deepSage, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Start voice input")
    }
}

struct VoiceCommandSheet: View {
    var sourceScreen: VoiceSourceScreen
    var viewModel: AppViewModel
    var inventory: [InventoryItem]

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var phase: VoiceListeningPhase = .idle
    @State private var typedFallback = ""
    @State private var intent: VoiceCommandIntentDraft?
    @State private var pulse = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Talk to your kitchen inventory")
                            .font(.largeTitle.bold())
                            .foregroundStyle(FreshFlowTheme.charcoal)
                        Text("FreshFlow listens only while this sheet is active. Review every command before it changes your data.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    microphonePanel

                    if let intent {
                        ParsedVoiceIntentCard(intent: intent)
                        SafetyDisclaimerView(compact: true)
                        PremiumActionButton(title: "Apply reviewed command", systemImage: "checkmark.circle.fill") {
                            viewModel.applyVoiceIntent(intent, modelContext: modelContext, inventory: inventory)
                            dismiss()
                        }
                    } else {
                        typedFallbackPanel
                    }
                }
                .padding(20)
            }
            .background(FreshFlowTheme.pageGradient.ignoresSafeArea())
            .navigationTitle(sourceScreen.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }

    private var microphonePanel: some View {
        FreshFlowCard {
            VStack(spacing: 18) {
                Button {
                    Task { await listen() }
                } label: {
                    ZStack {
                        Circle()
                            .fill(FreshFlowTheme.sage.opacity(pulse ? 0.18 : 0.08))
                            .frame(width: pulse ? 132 : 106, height: pulse ? 132 : 106)
                        Circle()
                            .fill(FreshFlowTheme.freshGradient)
                            .frame(width: 88, height: 88)
                        Image(systemName: phase == .listening ? "waveform" : "mic.fill")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.white)
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Record voice command")

                VoiceWaveformView(isActive: phase == .listening || phase == .processing)

                Text(statusText)
                    .font(.headline)
                    .foregroundStyle(FreshFlowTheme.charcoal)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var typedFallbackPanel: some View {
        FreshFlowCard {
            VStack(alignment: .leading, spacing: 12) {
                Label("Typed fallback", systemImage: "keyboard")
                    .font(.headline)
                    .foregroundStyle(FreshFlowTheme.charcoal)
                TextField("Example: Add apples and yogurt to the fridge", text: $typedFallback, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(2...4)
                Button {
                    intent = viewModel.parseTypedVoiceFallback(typedFallback, source: sourceScreen)
                    phase = .readyForReview
                } label: {
                    Label("Review typed command", systemImage: "arrow.up.circle.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(typedFallback.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
    }

    private var statusText: String {
        switch phase {
        case .idle:
            "Tap the microphone to start"
        case .requestingPermission:
            "Checking microphone and speech permissions"
        case .listening:
            "Listening now"
        case .processing:
            "Parsing your command"
        case .readyForReview:
            "Ready for review"
        case .failed(let message):
            message
        }
    }

    private func listen() async {
        phase = .requestingPermission
        phase = .listening
        let parsed = await viewModel.captureVoiceCommand(source: sourceScreen)
        if let parsed {
            intent = parsed
            phase = .readyForReview
        } else {
            phase = .failed(viewModel.errorMessage ?? "Voice input is unavailable. Use typed fallback.")
        }
    }
}

struct LiveTranscriptView: View {
    var transcript: String

    var body: some View {
        Text(transcript.isEmpty ? "Transcript will appear here." : transcript)
            .font(.body)
            .foregroundStyle(transcript.isEmpty ? .secondary : FreshFlowTheme.charcoal)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(.white.opacity(0.72), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

struct VoiceWaveformView: View {
    var isActive: Bool

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0..<18, id: \.self) { index in
                Capsule()
                    .fill(isActive ? FreshFlowTheme.sage : Color.secondary.opacity(0.25))
                    .frame(width: 4, height: isActive ? CGFloat(12 + (index % 5) * 6) : 10)
                    .animation(.easeInOut(duration: 0.45).repeatForever().delay(Double(index) * 0.02), value: isActive)
            }
        }
        .frame(height: 44)
        .accessibilityHidden(true)
    }
}

struct ParsedVoiceIntentCard: View {
    var intent: VoiceCommandIntentDraft

    var body: some View {
        FreshFlowCard {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label(intent.intentType.title, systemImage: "sparkles")
                        .font(.headline)
                        .foregroundStyle(FreshFlowTheme.charcoal)
                    Spacer()
                    Text("\(Int(intent.confidence * 100))%")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(FreshFlowTheme.deepSage)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(FreshFlowTheme.sage.opacity(0.14), in: Capsule())
                }

                LiveTranscriptView(transcript: intent.rawTranscript)

                Text(intent.suggestedAction)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !intent.extractedItems.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Detected items")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
                        ForEach(intent.extractedItems) { item in
                            HStack {
                                Text(item.itemName)
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text(item.category.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

struct VoicePermissionView: View {
    var state: VoicePermissionState

    var body: some View {
        Label(state.title, systemImage: state == .granted ? "mic.circle.fill" : "mic.slash")
            .font(.footnote.weight(.semibold))
            .foregroundStyle(state == .granted ? FreshFlowTheme.deepSage : FreshFlowTheme.clay)
            .padding(10)
            .background(.white.opacity(0.74), in: Capsule())
    }
}
