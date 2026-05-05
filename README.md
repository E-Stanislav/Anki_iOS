# AnkiFlow

iOS-приложение для карточек с интервальным повторением (алгоритм SM-2) и импортом колод Anki (`.apkg`).

## Функции

- **Управление колодами** — создание, редактирование, удаление
- **Повторение карточек** — SM-2 интервальное повторение с оценками Снова/Сложно/Хорошо/Легко
- **Импорт .apkg** — парсинг и импорт колод Anki (протестировано 225+ карточек)
- **Темы** — Светлая, Тёмная, Системная (авто)
- **Статистика** — отслеживание прогресса обучения
- **Уведомления** — ежедневные напоминания о повторении

## Стек

- SwiftUI + iOS 16.0+
- SQLite3 (нативный) — без внешних зависимостей
- Алгоритм планирования SM-2
- Нативный фреймворк Compression для распаковки zip

## Структура проекта

```
AnkiFlow/
├── Sources/
│   ├── App/           — AppState, точка входа, навигация
│   ├── Models/         — Card, Deck, Note, ReviewLog, Media
│   ├── Views/          — SwiftUI представления (Home, Deck, Card, Review, Stats, Settings, Onboarding)
│   ├── ViewModels/     — HomeViewModel, StudySessionViewModel
│   ├── Services/
│   │   ├── Storage/    — DatabaseService, CardRepository, DeckRepository, ReviewLogRepository
│   │   ├── Import/     — ApkgImporter
│   │   ├── Scheduler/  — SM2Scheduler
│   │   └── Notifications/
│   └── Extensions/, Utilities/, Resources/
└── AnkiFlowTests/
```

## Архитектура

- **AppState** — глобальное состояние (тема, онбординг, userId)
- **Repository pattern** — CardRepository, DeckRepository абстрагируют доступ к БД
- **SM2Scheduler** — чистая логика планирования, протокол для тестируемости
- **Theme** — enum AppTheme с вычисляемым свойством colorScheme, применяется через preferredColorScheme

## Ключевые паттерны

- SQLite3 с foreign keys (`PRAGMA foreign_keys = ON`)
- Версионирование схемы для миграций (увеличение schemaVersion принудительно пересоздаёт БД)
- `@AppStorage` для настроек, `UserDefaults` для состояния приложения
- TDD — тесты в AnkiFlowTests.swift (DeckRepository, CardRepository, ApkgImporter, NotificationService)

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
- **Синхронизация** — поддержка AnkiWeb (UI заглушка есть в SyncSettingsView)
- **Редактор карточек** — создание/редактирование карточек вручную (CardEditorView есть, но не завершён)
- **Поддержка медиа** — отображение изображений/аудио из импортированных колод
- **Поиск** — полнотекстовый поиск по карточкам
- **Резервное копирование/Экспорт** — JSON/.apkg экспорт (UI есть, логика не реализована)

### Средний приоритет
- **Теги** — фильтрация по тегам, управление тегами
- **Иерархия колод** — поддержка подколод
- **Пользовательские типы карточек** — определение собственных шаблонов
- **Графики статистики** — визуальная тепловая карта, график удержания
- **Настройка жестов** — полная настройка жестов (частично есть UI)

### Низкий приоритет
- **Поддержка macOS/iPad** — Catalyst или отдельный таргет
- **Виджет** — виджет на домашнем экране для ежедневного повторения
- **Apple Watch** — companion-приложение для быстрого повторения
- **Локализация** — поддержка i18n

## Текущие ограничения

- Тесты требуют development team signing (не запускаются из CLI)
- Нет unit-тестов для интервалов SM2Scheduler
- Нет пути миграции — увеличение схемы пересоздаёт БД (потеря данных)
- Импорт .apkg удаляет весь HTML (пока без поддержки изображений/аудио)
- Действия жестов (easy/good/hard/again) захардкожены, не настраиваются для колоды