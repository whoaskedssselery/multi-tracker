# Multi-tracker

Personal fitness & productivity app — weight log, workouts (PPL), tasks, notes, and AI chat powered by Groq.

**Platforms:** iOS (via AltStore free dev account) · Windows (native)

---

## Features

| Module | What it does |
|--------|-------------|
| **Home** | Dashboard: weight trend chart, active goals, streak counter, today's workout plan, pending tasks |
| **Train** | Weekly grid · workout templates (PPL or custom) · set/rep logging with numpad · AI badge per exercise |
| **Tasks / Notes** | Task list with priority, due date, reminders, recurrence · two-panel notes with pin & search |
| **AI Chat** | Groq LLM (llama-3.3-70b / DeepSeek-R1) · 4 independent context tabs (All / Train / Weight / Tasks) · Enter to send |
| **Settings** | Profile · light/dark/system theme · units (kg/lbs) · Groq API key · export JSON & CSV · data reset |

---

## Prerequisites

### All platforms
- Flutter ≥ 3.24 — [install](https://docs.flutter.dev/get-started/install)
- Dart ≥ 3.5

### Windows
- Visual Studio 2022 with **Desktop development with C++** workload
- Windows 10/11 SDK

### iOS (requires a Mac for build)
- Xcode 15+ (Mac App Store)
- CocoaPods: `sudo gem install cocoapods`
- AltStore on iPhone — [altstore.io](https://altstore.io)

---

## Getting started

```bash
# 1. Install dependencies
flutter pub get

# 2. Generate code (Drift, Riverpod)
dart run build_runner build --delete-conflicting-outputs

# 3. Run on Windows
flutter run -d windows

# 4. Run on iOS device / simulator (Mac only)
cd ios && pod install && cd ..
flutter run -d "iPhone 16"
```

---

## Groq API key (AI chat)

1. Go to [console.groq.com](https://console.groq.com) → **API Keys** → **Create API key**
2. Copy the key
3. In the app: **Settings → ИИ → Groq API Key** → paste and tap **Проверить**

The key is stored in the system keychain (iOS Keychain / Windows Credential Manager) via `flutter_secure_storage`. It is sent only to `api.groq.com` — never logged or stored elsewhere.

Available models (selectable in Settings):
- `llama-3.3-70b-versatile` *(default — fast, accurate)*
- `llama-3.1-8b-instant` *(lightweight)*
- `deepseek-r1-distill-llama-70b` *(reasoning model, `<think>` blocks stripped automatically)*

---

## Build for iOS (AltStore sideload)

```bash
# On Mac, from the project root:
cd ios && pod install && cd ..
flutter build ios --release --no-codesign
```

Then in Xcode:
1. Open `ios/Runner.xcworkspace`
2. **Runner target → Signing & Capabilities** → set your Personal Team & a unique Bundle ID (e.g. `com.yourname.multitracker`)
3. **Product → Archive → Distribute App → Development**
4. Drag the resulting `.ipa` into **AltStore → My Apps** on your Mac

> Free dev certificates expire every 7 days — re-sign via AltStore.

---

## Architecture

```
lib/
  app/          # MaterialApp, GoRouter shell, theme tokens (light + dark)
  core/
    ai/         # GroqClient (OpenAI-compatible), ContextBuilder (DB -> prompt)
    db/         # AppDatabase (Drift / SQLite WAL), all DAO methods
    network/    # Dio provider with retry interceptor (debug-only logger)
    notifications/ # flutter_local_notifications (iOS only)
    storage/    # flutter_secure_storage wrapper (API key)
  features/
    home/       # Dashboard screen
    train/      # Weekly grid + workout logger
    tasks/      # Task list + embedded Notes pane (IndexedStack)
    ai_chat/    # Chat screen with per-filter independent histories
    settings/   # Profile, theme, export, reset
  shared/
    widgets/    # AdaptiveScaffold (mobile bottom bar + desktop sidebar)
  l10n/         # ARB files (ru + en)
  main.dart     # DB init, proxy detection, ProviderScope
```

**State:** Riverpod with code-gen (`@riverpod`)  
**DB:** Drift (SQLite, WAL mode, schema migrations)  
**AI:** Groq REST via Dio (OpenAI-compatible `/v1/chat/completions`)  
**Fonts:** Inter (UI) + JetBrains Mono (numbers) via `google_fonts`

---

## Development

```bash
# Re-run code generation after changing DB tables or providers
dart run build_runner build --delete-conflicting-outputs

# Analyze
flutter analyze

# Release build (Windows)
flutter build windows --release
```
