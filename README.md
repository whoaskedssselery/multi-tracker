# Multi-tracker

Личное приложение для фитнеса и продуктивности — вес, тренировки (PPL), задачи, заметки и ИИ-чат.

**Платформы:** iOS · Windows · Web

Все данные синхронизируются между устройствами через Supabase (необязательно — приложение полностью работает офлайн).

---

## Разделы

| Раздел | Что внутри |
|--------|------------|
| **Главная** | Дашборд: график веса, цели, серии (стрики), задачи |
| **Тренировки** | Недельное расписание · программы (шаблоны) · журнал подходов/повторов · история по дням |
| **Задачи / Заметки** | Задачи с приоритетом, датой и напоминанием · заметки с поиском и закреплением |
| **ИИ-чат** | Groq LLM (llama-3.3-70b / deepseek-r1) · контекст по весу/тренировкам/задачам |
| **Синхронизация** | Облако Supabase — снимок данных по принципу LWW, работает офлайн |
| **Настройки** | Профиль · тема (светлая/тёмная/системная) · единицы (кг/lbs) · ключ Groq · экспорт JSON · сброс данных |

---

## Структура репозитория

```
multi-tracker/
  flutter/    — нативное приложение iOS + Windows (Flutter / Dart)
  web/        — веб-приложение (Vite + React + TypeScript, SPA)
```

---

## Веб-приложение (web/)

**Стек:** Vite · React 19 · TypeScript · React Router · Zustand · SCSS-модули · framer-motion · Supabase · Recharts.
Архитектура — Feature-Sliced Design: `src/{shared,entities,features,widgets,app}`, единый алиас `@/` → `src/`.

### Запуск

```bash
cd web
npm install
npm run dev
```

Откроется на **http://localhost:3000**.

> ⚠️ Если после переезда с прошлой версии в браузере «пропали стили» или ошибки `Unexpected token '<'` — это старый service worker от предыдущей сборки.
> Открой DevTools → **Application → Storage → Clear site data** (или вкладка **Service Workers → Unregister**), затем обнови страницу. Новый воркер чистит кеш сам.

### Сборка

```bash
cd web
npm run build      # результат в web/dist (статика — заливается на любой хостинг)
npm run preview    # локальный предпросмотр прод-сборки
```

### Переменные окружения

Файл `web/.env.local`:

```
VITE_SUPABASE_URL=https://<project>.supabase.co
VITE_SUPABASE_ANON_KEY=<publishable/anon-ключ>
```

Используется только **публичный** anon/publishable ключ. Секретный (service) ключ в вебе не нужен и не должен попадать в код.

---

## Нативное приложение (flutter/)

### Требования

- Flutter ≥ 3.24 · Dart ≥ 3.5
- **Windows:** Visual Studio 2022 (нагрузка «Разработка классических приложений на C++»)
- **iOS:** сборка только на Mac — Xcode 15+, CocoaPods (`sudo gem install cocoapods`), и инструмент сайдлоада (SideStore / AltStore)

### Запуск

```bash
cd flutter
flutter pub get

# Кодогенерация (Drift ORM + Riverpod)
dart run build_runner build --delete-conflicting-outputs

# Windows
flutter run -d windows

# iOS (только на Mac)
cd ios && pod install && cd ..
flutter run -d <device-id>
```

### Сборка релиза

```bash
# Windows
flutter build windows --release

# iOS (только на Mac)
cd ios && pod install && cd ..
flutter build ios --release --no-codesign
# Затем в Xcode: Product → Archive → Distribute → Development
```

iOS-IPA также собирается в GitHub Actions автоматически при пуше тега `vX.Y.Z` (см. вкладку Releases).

### Архитектура

```
flutter/lib/
  app/          # роутер, тема (светлая + тёмная), провайдеры Riverpod
  core/
    ai/         # GroqClient, ContextBuilder (БД → промпт)
    db/         # AppDatabase (Drift / SQLite WAL) — таблицы и DAO
    network/    # HTTP-клиент Dio
    notifications/  # локальные уведомления (iOS)
    storage/    # SecureStorage (ключ API, метка синхронизации)
    sync/       # синхронизация Supabase (снимок, LWW)
  features/     # home · train · tasks · ai_chat · settings
  shared/widgets/
  l10n/         # локализация (ru + en)
  main.dart
```

**State:** Riverpod · **БД:** Drift (SQLite WAL) · **ИИ:** Groq · **Синхронизация:** Supabase

После изменения таблиц БД, провайдеров или локализаций:

```bash
dart run build_runner build --delete-conflicting-outputs
flutter gen-l10n
```

---

## Настройка ИИ-чата (необязательно)

1. [console.groq.com](https://console.groq.com) → API Keys → создать ключ.
2. В приложении: **Настройки → ИИ → Groq API Key** → вставить.

Ключ хранится локально (на нативе — в системном хранилище ключей, в вебе — в localStorage) и отправляется только на `api.groq.com`.

---

## Синхронизация и данные

- Источник правды в облаке — таблица `app_state` в Supabase (один JSON-снимок на пользователя, стратегия Last-Write-Wins).
- Полный сброс облака: в Supabase → **SQL Editor** → `delete from app_state;`
- Сброс локальных данных на устройстве: **Настройки → Сбросить данные**.

---

## Планы

- [ ] Android
- [ ] Подтверждение email кодом при регистрации
