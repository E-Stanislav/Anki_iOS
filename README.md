# AnkiFlow

iOS-приложение для карточек с интервальным повторением (алгоритм SM-2) и импортом колод Anki (`.apkg`).

## Функции

- **Управление колодами** — создание, редактирование, удаление, избранное, архивирование
- **Повторение карточек** — SM-2 интервальное повторение с оценками Снова/Сложно/Хорошо/Легко
- **Импорт .apkg** — парсинг и импорт колод Anki (collection.anki21/anki20/anki2)
- **Жесты** — свайпы для ответа (настраиваемые действия)
- **Темы** — Светлая, Тёмная, Системная (авто)
- **Статистика** — отслеживание прогресса обучения
- **Уведомления** — ежедневные напоминания о повторении с настраиваемым временем
- **Резервное копирование** — экспорт в JSON/.apkg (UI готов)
- **Синхронизация** — UI для AnkiWeb (заглушка)
- **Поддержка медиа** — таблица для хранения файлов

## Стек

- SwiftUI + iOS 16.0+
- SQLite3 (нативный) — без внешних зависимостей
- Алгоритм планирования SM-2 (протокол для тестируемости)
- Нативный фреймворк Compression для распаковки zip

## Структура проекта

```
AnkiFlow/
├── Sources/
│   ├── App/              — AnkiFlowApp, AppState, SceneDelegate, ContentView
│   ├── Models/            — Card, Deck, Note, ReviewLog, Media
│   ├── Views/
│   │   ├── Home/          — HomeView, MainTabView, CreateDeckView, ImportView
│   │   ├── Deck/          — DeckDetailView
│   │   ├── Card/          — CardEditorView
│   │   ├── Review/        — StudySessionView, ReviewSessionView
│   │   ├── Stats/         — StatsView
│   │   ├── Settings/      — SettingsView, GestureSettingsView, NotificationSettingsView, BackupView, SyncSettingsView
│   │   └── Onboarding/    — OnboardingView
│   ├── ViewModels/        — HomeViewModel, StudySessionViewModel
│   └── Services/
│       ├── Storage/       — DatabaseService, CardRepository, DeckRepository, NoteRepository, ReviewLogRepository
│       ├── Import/        — ApkgImporter
│       ├── Scheduler/     — SM2Scheduler
│       └── Notifications/ — NotificationService
├── Resources/            — Info.plist, Assets.xcassets
└── AnkiFlowTests/         — Unit tests
```

## Архитектура

- **AppState** — глобальное состояние (тема, онбординг, userId)
- **Repository pattern** — CardRepository, DeckRepository, NoteRepository, ReviewLogRepository
- **SM2Scheduler** — чистая логика планирования, реализует SchedulerProtocol
- **Theme** — enum AppTheme с вычисляемым свойством colorScheme

## Ключевые паттерны

- SQLite3 с foreign keys (`PRAGMA foreign_keys = ON`)
- Версионирование схемы (schemaVersion = 4, bump для сброса БД)
- `@AppStorage` для настроек, `UserDefaults` для состояния приложения
- TDD — тесты в AnkiFlowTests.swift

## База данных (таблицы)

| Таблица | Описание |
|---------|----------|
| `decks` | Колода (id, name, parent_id, is_archived, is_favorite, new_cards_per_day, review_cards_per_day) |
| `notes` | Заметка (id, deck_id, note_type_id, fields JSON, tags JSON) |
| `cards` | Карточка (id, note_id, deck_id, template_index, front, back) |
| `card_schedules` | Расписание (card_id, status, due, interval, ease_factor, reps, lapses) |
| `note_types` | Тип заметки (id, name, fields JSON, templates JSON) |
| `review_logs` | Лог обзора (id, card_id, reviewed_at, rating, interval, ease_factor, time_taken) |
| `media_files` | Медиафайлы (id, note_id, filename, mime_type, size) |
| `import_jobs` | Джобы импорта (id, filename, status, total_items, processed_items, added_cards, errors) |
| `sync_state` | Состояние синхронизации (id, last_sync_at, pending_changes) |

## Сборка и запуск

```bash
xcodebuild -project AnkiFlow.xcodeproj -scheme AnkiFlow \
  -configuration Debug \
  -destination 'id=<DEVICE_ID>' build
```

## Тесты

```bash
xcodebuild -project AnkiFlow.xcodeproj -scheme AnkiFlowTests \
  -configuration Debug \
  -destination 'id=<DEVICE_ID>' test
```

## Планы / Идеи

### Высокий приоритет
- **Редактор карточек** — создание/редактирование карточек вручную
- **Поддержка медиа** — отображение изображений/аудио из импортированных колод
- **Поиск** — полнотекстовый поиск по карточкам
- **Полноценный экспорт** — JSON/.apkg экспорт

### Средний приоритет
- **Теги** — фильтрация по тегам, управление тегами
- **Иерархия колод** — поддержка подколод
- **Графики статистики** — визуальная тепловая карта, график удержания
- **AnkiWeb синхронизация** — полная реализация

### Низкий приоритет
- **Поддержка macOS/iPad** — Catalyst или отдельный таргет
- **Виджет** — виджет на домашнем экране
- **Apple Watch** — companion-приложение
- **Локализация** — поддержка i18n

## Текущие ограничения

- Тесты требуют development team signing (не запускаются из CLI)
- Нет unit-тестов для интервалов SM2Scheduler
- Увеличение schemaVersion пересоздаёт БД (нет миграции)
- Импорт .apkg удаляет HTML (без поддержки изображений/аудио в карточках)
- Экспорт .apkg не реализован (UI есть)
- Синхронизация — только UI-заглушка
