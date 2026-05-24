# Multi-tracker

Personal fitness & productivity app — weight log, workouts (PPL), tasks, AI insights (Gemini).

Platforms: **iOS** (via AltStore free dev account) · **Windows** (native)

---

## Prerequisites

### All platforms
- Flutter ≥ 3.22 — [install](https://docs.flutter.dev/get-started/install)
- Dart ≥ 3.3

### iOS (requires a Mac)
- Xcode 15+ (from Mac App Store)
- CocoaPods: `sudo gem install cocoapods`
- AltStore on iPhone — [altstore.io](https://altstore.io)
- Run `flutter doctor` and fix any issues

### Windows
- Visual Studio 2022 with **Desktop development with C++** workload
- Windows 10/11 SDK

---

## Getting started

```bash
# 1. Install dependencies
flutter pub get

# 2. Generate code (Drift, Riverpod, Freezed)
dart run build_runner build --delete-conflicting-outputs

# 3. Run on Windows
flutter run -d windows

# 4. Run on iOS simulator (Mac only)
flutter run -d "iPhone 16"
```

---

## Build for iOS (AltStore sideload)

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select **Runner** target → **Signing & Capabilities**
3. Set **Team** to your Personal Team (Apple ID)
4. Set **Bundle Identifier** to something unique, e.g. `com.yourname.multitracker`
5. In terminal:
   ```bash
   flutter build ios --release --no-codesign
   ```
6. In Xcode: **Product → Archive** → **Distribute App → Development**
7. Locate the `.ipa` in `~/Library/Developer/Xcode/Archives/…`
8. Open **AltStore** on your Mac → **My Apps** → drag the `.ipa`

> Note: Free dev accounts expire every 7 days — re-sign via AltStore.

---

## Gemini API key

1. Go to [aistudio.google.com](https://aistudio.google.com)
2. Click **Get API key** → **Create API key in new project**
3. Copy the key
4. In the app: **Settings → AI → Gemini API Key** → paste and tap **Verify**

The key is stored in the system keychain (iOS Keychain / Windows Credential Manager) via `flutter_secure_storage`. It is never sent anywhere except directly to `generativelanguage.googleapis.com`.

---

## Architecture

```
lib/
  app/          # Router, MaterialApp, theme tokens
  core/         # DB (Drift), AI client, notifications, storage, export
  features/     # Feature-first: home, train, tasks, ai_chat, settings
  shared/       # Design-system widgets (AppButton, AppCard, …)
  l10n/         # ARB files (ru + en)
  main.dart
```

State: **Riverpod** with code-gen  
DB: **Drift** (SQLite, WAL mode, migrations)  
AI: **Gemini REST** (gemini-2.0-flash, fallback gemini-1.5-flash)

---

## Development phases

| Phase | Scope |
|-------|-------|
| 1 ✅ | Skeleton: DB, notifications, AI client, router, theme |
| 2 | Home — weight log, goals, SVG chart, streaks |
| 3 | Train — weekly grid, workout modal, numpad, AI badge |
| 4 | Tasks — reminders, recurrence, Notes with Markdown |
| 5 | AI Chat — Gemini, context filter, citation cards |
| 6 | Settings — profile, theme, units, export, reset |
