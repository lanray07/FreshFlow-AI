# FreshFlow AI

FreshFlow AI is a premium SwiftUI iOS app for pantry, fridge, and food inventory management.

Core positioning: "Know what to eat before it expires."

The app helps households reduce food waste, save money, generate meals from existing ingredients, track pantry inventory, predict expiry risk, and plan groceries. It is built as an offline-friendly SwiftUI app with SwiftData persistence and mock AI enabled by default.

## Included

- SwiftUI app shell with `TabView` and `NavigationStack`
- MVVM-style app state with service injection
- SwiftData persistence models
- Mock AI services for food recognition, expiry prediction, recipes, pantry forecast, waste reduction, and shopping lists
- Native voice input architecture with mock transcripts, typed fallback, permission handling placeholders, and review-before-apply behavior
- Camera and computer vision architecture placeholder
- OCR receipt scanning architecture placeholder
- StoreKit 2 subscription scaffolding
- Swift Charts savings and waste analytics
- Local notifications scaffold
- Native share sheet and PDF report export scaffold
- WidgetKit and Apple Watch placeholders
- Food safety disclaimer surfaces

## Safety

FreshFlow AI is a food organization and meal suggestion tool. It does not provide medical nutrition advice, diagnose health conditions, certify food safety, or replace official food safety guidance. Freshness and expiry estimates are informational only.

## Open In Xcode

Open `FreshFlowAI.xcodeproj` on macOS with Xcode 15 or newer, then run the `FreshFlowAI` scheme on an iOS 17+ simulator.

This repository was scaffolded from Windows, so Xcode compilation could not be run locally in this environment.

## GitHub Xcode Release

The `.github/workflows/ios-xcode-release.yml` workflow builds the shared `FreshFlowAI` scheme on a GitHub-hosted macOS runner, archives the iOS app, exports an App Store Connect IPA, and uploads it with App Store Connect API-key authentication.

Required GitHub secrets are `APPLE_TEAM_ID`, `APP_STORE_CONNECT_KEY_ID`, `APP_STORE_CONNECT_ISSUER_ID`, and either `APP_STORE_CONNECT_PRIVATE_KEY` or `APP_STORE_CONNECT_PRIVATE_KEY_BASE64`. The workflow also accepts common aliases shown in the workflow file, including `APP_STORE_CONNECT_API_KEY`, `APPSTORE_API_KEY`, and `ASC_API_KEY` for the `.p8` private key. Optional signing secrets are supported for a distribution certificate and provisioning profile, but the default path uses Xcode automatic signing with App Store Connect API authentication.
