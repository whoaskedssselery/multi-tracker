# multi-tracker

Монорепо: Flutter приложение (iOS + Windows) + Web (в разработке). Трекер веса, тренировок, задач, заметок с синхронизацией Supabase.

## Структура монорепо

```
multi-tracker/
  flutter/    — iOS + Windows приложение (Flutter / Dart)
  web/        — веб-приложение (пока пустая папка-заглушка)
```

## Codegraph — использовать вместо чтения файлов

Codegraph находится в `.codegraph/` корня репо и индексирует весь проект (flutter + web когда появится). После добавления нового кода в `web/` — запустить `npx @colbymchenry/codegraph sync` из корня.

Перед тем как читать файлы для поиска символов, определений или зависимостей — запроси codegraph:

```
mcp__codegraph__codegraph_search  — найти класс/метод/функцию по имени
mcp__codegraph__codegraph_node    — подробности об узле (где определён, откуда вызывается)
mcp__codegraph__codegraph_callers — кто вызывает данный символ
mcp__codegraph__codegraph_callees — что вызывает данный символ
mcp__codegraph__codegraph_files   — структура файлов проекта
mcp__codegraph__codegraph_explore — обзор модуля/директории
```

## Структура проекта

```
flutter/lib/
  main.dart                     — точка входа, AppDatabase singleton, прокси
  app/
    app.dart                    — MaterialApp + тема
    router.dart                 — GoRouter (/, /train, /tasks, /ai, /settings)
    providers/providers.dart    — все Riverpod провайдеры
    theme/                      — цвета, типографика, радиусы, отступы
  core/
    db/database.dart            — Drift ORM, все таблицы, DAOs, exportSnapshot/importSnapshot
    sync/sync_service.dart      — Supabase LWW snapshot sync, SyncController
    sync/supabase_config.dart   — URL/ключи Supabase
    ai/groq_client.dart         — Groq AI клиент
    notifications/              — iOS уведомления
    storage/secure_storage.dart — FlutterSecureStorage (Groq key, lastSyncTs)
  features/
    home/                       — Главная (вес, цели, стрики) — iOS + Desktop layout
    tasks/                      — Задачи + Заметки (один экран с табом)
    train/                      — Тренировки (WeekGrid + логирование)
    ai_chat/                    — AI чат через Groq
    settings/                   — Настройки, синхронизация
  shared/
    widgets/adaptive_scaffold.dart — боковая панель (desktop) / bottom bar (mobile)
    widgets/app_modal.dart         — showAppModal helper
    widgets/page_header.dart       — AppPageHeader / IosPageHeader
```

## Ключевые паттерны

**Database** — Drift ORM, глобальный синглтон `database` из `main.dart`. Все операции через методы `AppDatabase`.

**State** — Riverpod. Провайдеры в `app/providers/providers.dart`. Основные: `notesProvider`, `tasksProvider`, `weightEntriesProvider`, `syncControllerProvider`.

**Sync** — `SyncService` (LWW snapshot через один row Supabase). `SyncController` — Riverpod notifier, управляет жизненным циклом синхронизации, авто-пуш с дебаунсом 3с, пулл при resume.

**iOS vs Desktop** — `Platform.isIOS` разделяет layout. Mobile = `_MobileLayout` (bottom nav bar), Desktop = `_DesktopLayout` (sidebar 260px). Мобильный редактор заметок — `_MobileNoteEditorView` внутри `tasks_screen.dart`.

**Адаптивный scaffold** — `AdaptiveScaffold` в `shared/widgets/adaptive_scaffold.dart`, переключается по ширине экрана (`kDesktopBreakpoint`).

## iOS специфика

- Заметки встроены в TasksScreen (вкладка Notes), не отдельный роут
- Редактор заметок: `_MobileNoteEditorView` — `_flush()` вызывается в `onChanged`, `dispose()`, и явно из кнопки «Назад»
- SideStore / AltStore: приложение распространяется через sideloading
- iOS Keychain переживает переустановку — `lastSyncTs` сохраняется между установками

## Известные исправленные баги

- **Sync при переустановке iOS**: `reconcile()` теперь всегда делает pull если локальный DB пустой, а на Supabase есть данные (независимо от Keychain timestamp)
- **Кнопка «Готово» в редакторе заметок**: добавлен `_flush()` перед unfocus и отступ от кнопки Delete для предотвращения случайного нажатия
