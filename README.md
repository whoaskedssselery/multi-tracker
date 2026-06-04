# Multi-tracker

Personal fitness & productivity app — weight log, workouts (PPL), tasks, notes, and AI chat.

**Platforms:** iOS · Windows · Web *(coming soon)*

---

## Modules

| Module | Description |
|--------|-------------|
| **Home** | Dashboard: weight trend chart, active goals, streak counters, today's workout, pending tasks |
| **Train** | Weekly schedule · workout templates · set/rep logging with numpad · AI progress badge per exercise |
| **Tasks / Notes** | Task list with priority, due date, reminders · notes with search and pin |
| **AI Chat** | Groq LLM (llama-3.3-70b / deepseek-r1) · 4 independent context tabs |
| **Sync** | Optional Supabase cloud sync — snapshot LWW, works fully offline |
| **Settings** | Profile · light/dark/system theme · units (kg/lbs) · Groq API key · JSON export · data reset |

---

## Repository structure

```
multi-tracker/
  flutter/    — iOS + Windows native app (Flutter / Dart)
  web/        — Web app (coming soon)
```

---

## Flutter app

### Prerequisites

**All platforms**
- Flutter ≥ 3.24 · Dart ≥ 3.5

**Windows**
- Visual Studio 2022 — Desktop development with C++ workload

**iOS** *(build requires a Mac)*
- Xcode 15+
- CocoaPods: `sudo gem install cocoapods`
- SideStore or similar sideloading tool

### Quick start

```bash
cd flutter

# Install dependencies
flutter pub get

# Generate code (Drift ORM + Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Run on Windows
flutter run -d windows

# Run on iOS device (Mac only)
cd ios && pod install && cd ..
flutter run -d <device-id>
```

### Build for release

```bash
# Windows
flutter build windows --release

# iOS (Mac only)
cd ios && pod install && cd ..
flutter build ios --release --no-codesign
# Then archive in Xcode: Product → Archive → Distribute → Development
```

### Architecture

```
flutter/lib/
  app/          # Router, theme tokens (light + dark), Riverpod providers
  core/
    ai/         # GroqClient, ContextBuilder (DB → prompt)
    db/         # AppDatabase (Drift / SQLite WAL) — all tables and DAOs
    network/    # Dio HTTP client
    notifications/  # Local notifications (iOS)
    storage/    # SecureStorage wrapper (API key, sync timestamp)
    sync/       # Supabase LWW snapshot sync
  features/
    home/       # Dashboard
    train/      # Workout logger
    tasks/      # Tasks + Notes
    ai_chat/    # AI chat
    settings/   # Profile, theme, export
  shared/
    widgets/    # AdaptiveScaffold, AppModal, PageHeader
  l10n/         # Localisation (ru + en)
  main.dart     # Entry point
```

**State:** Riverpod · **DB:** Drift (SQLite WAL) · **AI:** Groq (OpenAI-compatible) · **Sync:** Supabase

### AI chat setup (optional)

1. [console.groq.com](https://console.groq.com) → API Keys → Create API key
2. In-app: **Settings → ИИ → Groq API Key** → paste → tap **Проверить**

The key is stored in the system keychain (iOS Keychain / Windows Credential Manager) and sent only to `api.groq.com`.

### Code generation

Run after changing DB tables, Riverpod providers, or localisations:

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

---

## Roadmap

- [ ] Web app (same feature set, Supabase backend)
- [ ] Android app
- [ ] Email confirmation via code on sign-up
