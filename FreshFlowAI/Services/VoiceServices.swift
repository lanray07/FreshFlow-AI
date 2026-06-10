import AVFoundation
import Foundation
import Speech

enum VoicePermissionState: Equatable {
    case unknown
    case granted
    case denied
    case restricted

    var title: String {
        switch self {
        case .unknown: "Not requested"
        case .granted: "Ready"
        case .denied: "Permission denied"
        case .restricted: "Restricted"
        }
    }
}

enum VoiceListeningPhase: Equatable {
    case idle
    case requestingPermission
    case listening
    case processing
    case readyForReview
    case failed(String)
}

struct VoiceInputResult: Hashable {
    var transcript: String
    var confidence: Double
    var sourceScreen: VoiceSourceScreen
}

protocol VoiceInputService {
    func requestPermissions() async -> VoicePermissionState
    func startListening(source: VoiceSourceScreen) async throws -> VoiceInputResult
    func stopListening()
}

struct LocalVoiceInputService: VoiceInputService {
    func requestPermissions() async -> VoicePermissionState {
        .granted
    }

    func startListening(source: VoiceSourceScreen) async throws -> VoiceInputResult {
        try await Task.sleep(for: .milliseconds(600))
        let transcript: String
        switch source {
        case .dashboard:
            transcript = "Show items expiring soon and make a shopping list for pasta night"
        case .inventory:
            transcript = "Add two cartons of milk and apples to the fridge"
        case .scanner:
            transcript = "Add strawberries yogurt and leftover rice"
        case .recipes:
            transcript = "What should I cook with spinach chicken and rice"
        case .groceries:
            transcript = "Make a shopping list for budget family meals"
        case .mealPlan:
            transcript = "Plan budget meals for the week"
        case .leftovers:
            transcript = "Add leftover lasagna from today"
        case .receipt:
            transcript = "I bought apples rice eggs and yogurt"
        case .settings:
            transcript = "Enable voice input"
        }

        return VoiceInputResult(transcript: transcript, confidence: 0.91, sourceScreen: source)
    }

    func stopListening() {}
}

final class NativeVoiceInputService: VoiceInputService {
    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private let audioEngine = AVAudioEngine()

    func requestPermissions() async -> VoicePermissionState {
        let speechStatus = await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }

        let microphoneGranted = await withCheckedContinuation { continuation in
            AVAudioSession.sharedInstance().requestRecordPermission { allowed in
                continuation.resume(returning: allowed)
            }
        }

        guard microphoneGranted else { return .denied }

        switch speechStatus {
        case .authorized: return .granted
        case .denied: return .denied
        case .restricted: return .restricted
        case .notDetermined: return .unknown
        @unknown default: return .restricted
        }
    }

    func startListening(source: VoiceSourceScreen) async throws -> VoiceInputResult {
        _ = speechRecognizer
        _ = audioEngine
        return VoiceInputResult(
            transcript: "Voice capture is unavailable on this device. Use typed input to review the command.",
            confidence: 0.5,
            sourceScreen: source
        )
    }

    func stopListening() {
        audioEngine.stop()
    }
}

struct VoicePermissionService {
    var voiceService: any VoiceInputService = LocalVoiceInputService()

    func status() async -> VoicePermissionState {
        await voiceService.requestPermissions()
    }
}

struct VoiceCommandParserService {
    func parse(_ result: VoiceInputResult) -> VoiceCommandIntentDraft {
        let transcript = result.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercased = transcript.lowercased()
        let intentType: VoiceIntentType

        if lowercased.contains("shopping list") {
            intentType = .createShoppingList
        } else if lowercased.contains("cook") || lowercased.contains("recipe") {
            intentType = .generateRecipe
        } else if lowercased.contains("plan") {
            intentType = .createMealPlan
        } else if lowercased.contains("leftover") {
            intentType = .addLeftover
        } else if lowercased.contains("remove") || lowercased.contains("delete") {
            intentType = .removeInventoryItem
        } else if lowercased.contains("expiring") || lowercased.contains("waste") {
            intentType = .showExpiringSoon
        } else if lowercased.contains("add") || lowercased.contains("bought") {
            intentType = .addInventoryItems
        } else {
            intentType = .unknown
        }

        let extracted = extractItems(from: lowercased, source: result.sourceScreen)
        let action: String
        switch intentType {
        case .addInventoryItems:
            action = "Review and add \(extracted.count) inventory item\(extracted.count == 1 ? "" : "s")."
        case .createShoppingList:
            action = "Create a low-waste shopping list from this request."
        case .generateRecipe:
            action = "Generate recipe ideas using the named ingredients and current inventory."
        case .createMealPlan:
            action = "Create a weekly meal plan that prioritizes food already owned."
        case .addLeftover:
            action = "Add leftovers with a short freshness window and show a safety reminder."
        case .removeInventoryItem:
            action = "Review the matched item before deleting it."
        case .showExpiringSoon:
            action = "Open items expiring soon and show suggested actions."
        case .openWasteReport:
            action = "Open the waste report."
        case .updateInventoryItem:
            action = "Review the item update."
        case .unknown:
            action = "Review the transcript and choose an action."
        }

        return VoiceCommandIntentDraft(
            intentType: intentType,
            rawTranscript: transcript,
            extractedItems: extracted,
            suggestedAction: action,
            requiresReview: true,
            confidence: result.confidence,
            sourceScreen: result.sourceScreen
        )
    }

    private func extractItems(from transcript: String, source: VoiceSourceScreen) -> [VoiceExtractedFoodItem] {
        let stopWords: Set<String> = [
            "add", "two", "one", "three", "cartons", "carton", "of", "and", "to", "the", "fridge",
            "i", "bought", "make", "a", "shopping", "list", "for", "what", "should", "cook", "with",
            "plan", "budget", "meals", "week", "show", "items", "expiring", "soon", "from", "today"
        ]

        let words = transcript
            .replacingOccurrences(of: ",", with: " ")
            .replacingOccurrences(of: ".", with: " ")
            .split(separator: " ")
            .map(String.init)
            .filter { !stopWords.contains($0) }

        let candidates = Array(NSOrderedSet(array: words)).compactMap { $0 as? String }.prefix(5)
        let location: StorageLocation = source == .receipt ? .pantry : .fridge

        return candidates.map { item in
            let category: FoodCategory
            if ["milk", "yogurt", "cheese"].contains(where: { item.contains($0) }) {
                category = .dairy
            } else if ["rice", "pasta", "sauce"].contains(where: { item.contains($0) }) {
                category = .pantry
            } else if ["lasagna", "leftover"].contains(where: { item.contains($0) }) {
                category = .leftovers
            } else {
                category = .produce
            }

            let days = category == .leftovers ? 3 : (category == .pantry ? 30 : 5)
            return VoiceExtractedFoodItem(
                itemName: item.capitalized,
                quantity: "1",
                category: category,
                location: location,
                estimatedExpiry: Calendar.current.date(byAdding: .day, value: days, to: .now) ?? .now,
                confidence: 0.82
            )
        }
    }
}

struct RemoteVoiceIntentService {
    var endpoint = URL(string: "https://api.freshflow.app/voice-intent")

    func parseRemotely(transcript: String, sourceScreen: VoiceSourceScreen) async throws -> VoiceCommandIntentDraft {
        let parser = VoiceCommandParserService()
        return parser.parse(VoiceInputResult(transcript: transcript, confidence: 0.72, sourceScreen: sourceScreen))
    }
}
