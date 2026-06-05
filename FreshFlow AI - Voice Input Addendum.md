# FreshFlow AI Voice Input Feature Addendum

Add a native voice input feature throughout FreshFlow AI so users can manage food inventory, recipes, groceries, leftovers, and meal plans hands-free.

## Core Voice Positioning

"Talk to your kitchen inventory."

Voice input should feel fast, private, family-friendly, and useful during real kitchen moments when the user's hands may be full.

## Voice Input Screens

Add voice input to:

- Dashboard quick action: Voice Command
- Add Grocery
- Pantry Inventory search and item creation
- AI Recipe Generator prompt input
- Smart Leftover Engine input
- Grocery Intelligence shopping list creation
- Meal Planning prompt input
- Receipt Scanner review corrections
- Settings voice preferences

## Supported Voice Commands

Support natural language commands such as:

- "Add two cartons of milk to the fridge."
- "I bought apples, rice, eggs, and yogurt."
- "What should I cook with chicken and spinach?"
- "Make a shopping list for pasta night."
- "Show items expiring soon."
- "Add leftover lasagna from today."
- "Plan budget meals for the week."
- "Remove expired bread."
- "Move strawberries to eat soon."

## Voice Input UX

Create a premium VoiceCommandSheet with:

- microphone button
- listening state
- animated waveform or pulse
- live transcription
- confidence indicator
- parsed intent preview
- confirm/edit before applying changes
- retry and cancel actions
- food safety reminder when voice results include freshness or expiry assumptions

Voice input must never silently mutate inventory without a user review step.

## Speech Architecture

Use native Apple speech architecture:

- Speech framework placeholder
- SFSpeechRecognizer authorization flow
- AVAudioEngine microphone capture placeholder
- AVAudioSession configuration placeholder
- on-device recognition when available
- fallback typed input when permission is denied
- clear privacy messaging before requesting microphone and speech recognition access

Mock voice input should be enabled by default for previews and simulator-friendly development.

## Voice Services

Create:

- VoiceInputService
- VoiceCommandParserService
- VoicePermissionService
- MockVoiceInputService
- RemoteVoiceIntentService placeholder

VoiceCommandParserService should map transcripts into app intents:

- addInventoryItems
- updateInventoryItem
- removeInventoryItem
- createShoppingList
- generateRecipe
- createMealPlan
- addLeftover
- showExpiringSoon
- openWasteReport

## Data Models

Add:

VoiceInputSession
- id
- transcript
- confidence
- parsedIntent
- createdAt
- sourceScreen

VoiceCommandIntent
- id
- intentType
- rawTranscript
- extractedItems
- requiresReview
- createdAt

VoiceExtractedFoodItem
- id
- itemName
- quantity
- category
- location
- estimatedExpiry
- confidence

## Backend Endpoint Extension

Extend the placeholder request payload:

```json
{
  "module": "voice_input",
  "transcript": "",
  "sourceScreen": "",
  "inventory": [],
  "dietaryPreferences": [],
  "locale": "en-US"
}
```

Extend the placeholder response payload:

```json
{
  "intentType": "",
  "extractedItems": [],
  "suggestedAction": "",
  "requiresReview": true,
  "confidence": 0
}
```

## Reusable Components

Add:

- VoiceInputButton
- VoiceCommandSheet
- LiveTranscriptView
- VoiceWaveformView
- ParsedVoiceIntentCard
- VoicePermissionView

## Technical Requirements

Add:

- Speech framework integration placeholder
- microphone permission handling
- speech recognition permission handling
- typed fallback for all voice-enabled flows
- simulator-safe mock transcripts
- accessibility labels for microphone controls
- localization-ready command parsing
- no always-listening behavior
- no background recording
- no voice data persistence unless the user confirms the command

## Privacy And Safety

Display clear privacy copy:

- voice input is optional
- microphone is only used while actively listening
- transcripts are shown for review before actions are applied
- users can use typed input instead

Safety behavior:

- voice commands can suggest food organization actions
- voice commands must not certify food safety
- expiry or freshness commands must show the existing FreshFlow food safety disclaimer

## Settings

Add voice preferences:

- enable voice input
- preferred voice language
- require confirmation before applying commands
- clear voice command history
- microphone permission status

## Updated Quick Actions

Dashboard quick actions should include:

- Scan Fridge
- Scan Pantry
- Add Grocery
- Voice Command
- Generate Recipe
- Shopping List
- Waste Report
