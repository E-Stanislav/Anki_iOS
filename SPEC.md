# AnkiFlow - iOS Anki Cards App Specification

## 1. Project Overview

- **Project Name**: AnkiFlow
- **Bundle Identifier**: com.ankiflow.app
- **Core Functionality**: A modern iOS flashcard app that supports Anki's .apkg file format for import, allowing users to study using spaced repetition
- **Target Users**: Students, language learners, professionals who use spaced repetition for learning
- **iOS Version Support**: iOS 15.0+
- **UI Framework**: UIKit with SnapKit for Auto Layout

---

## 2. UI/UX Specification

### Screen Structure

1. **DeckListViewController** - Main screen showing all imported decks
2. **CardStudyViewController** - Flashcard study interface with flip animation
3. **CardBrowserViewController** - Browse and manage cards within a deck
4. **ImportViewController** - Import .apkg files from Files app or URL
5. **SettingsViewController** - App settings and preferences
6. **StatisticsViewController** - Study statistics and progress

### Navigation Structure

```
UITabBarController
├── Tab 1: Decks (UINavigationController)
│   ├── DeckListViewController
│   ├── CardBrowserViewController (push)
│   └── CardStudyViewController (push)
├── Tab 2: Statistics (UINavigationController)
│   └── StatisticsViewController
└── Tab 3: Settings (UINavigationController)
    └── SettingsViewController
```

### Visual Design

#### Color Palette
- **Primary**: #6366F1 (Indigo) - Main accent color
- **Primary Dark**: #4F46E5 - Pressed states
- **Secondary**: #10B981 (Emerald) - Success, correct answers
- **Background**: #F9FAFB (Light) / #111827 (Dark)
- **Surface**: #FFFFFF (Light) / #1F2937 (Dark)
- **Text Primary**: #111827 (Light) / #F9FAFB (Dark)
- **Text Secondary**: #6B7280
- **Error**: #EF4444 - Wrong answers
- **Warning**: #F59E0B - Due cards

#### Typography
- **Font Family**: SF Pro (system font)
- **Large Title**: 34pt Bold
- **Title 1**: 28pt Bold
- **Title 2**: 22pt Bold
- **Title 3**: 20pt Semibold
- **Headline**: 17pt Semibold
- **Body**: 17pt Regular
- **Callout**: 16pt Regular
- **Subhead**: 15pt Regular
- **Footnote**: 13pt Regular
- **Caption**: 12pt Regular

#### Spacing System (8pt Grid)
- **xs**: 4pt
- **sm**: 8pt
- **md**: 16pt
- **lg**: 24pt
- **xl**: 32pt
- **xxl**: 48pt

### Views & Components

#### DeckCell (UICollectionViewCell)
- Deck icon/emoji (top-left, 40x40pt)
- Deck name (Headline, truncated to 2 lines)
- Card count label (Footnote, Text Secondary)
- Due count badge (Caption, Warning color, circular background)
- Progress bar (4pt height, Primary color)
- Corner radius: 16pt
- Shadow: 0, 2pt, 8pt blur, #000000 10% opacity

#### FlashcardView
- Front/Back content area with centered text
- Tap to flip animation (0.4s, horizontal flip)
- Corner radius: 20pt
- Shadow: 0, 4pt, 16pt blur, #000000 15% opacity
- Background: Surface color
- Min height: 300pt

#### AnswerButtons
- "Again" button - Error color background, white text
- "Hard" button - Warning color background, white text
- "Good" button - Primary color background, white text
- "Easy" button - Secondary color background, white text
- Height: 50pt, Corner radius: 12pt
- Horizontal stack with 12pt spacing

#### ImportButton
- Floating action button style
- Primary color background
- SF Symbol "plus" icon (24pt, white)
- Size: 56x56pt
- Corner radius: 28pt (circular)
- Shadow: 0, 4pt, 12pt blur, Primary color 30% opacity
- Position: Bottom right, 24pt from edges

---

## 3. Functionality Specification

### Core Features

#### F1: Deck Management (Priority: High)
- View list of all imported decks
- Display deck name, total cards, due cards, completion percentage
- Delete deck with swipe gesture
- Pull-to-refresh to update due counts

#### F2: .apkg Import (Priority: High)
- Import via Files app (Document Picker)
- Support for standard Anki .apkg format
- Extract card content (front/back text, tags, deck name)
- Store cards in local SQLite database
- Show import progress indicator
- Handle import errors gracefully

#### F3: Spaced Repetition Study (Priority: High)
- Show cards due for review based on SM-2 algorithm
- Display front of card, tap to reveal back
- Rate difficulty: Again (0), Hard (1), Good (2), Easy (3)
- Update card schedule based on rating
- Track review history

#### F4: Card Browser (Priority: Medium)
- List all cards in a deck
- Show front text preview
- Search cards by content
- Toggle card suspension

#### F5: Statistics (Priority: Medium)
- Total cards studied today
- Current streak (days)
- Retention rate percentage
- Forecast of upcoming reviews

#### F6: Settings (Priority: Low)
- Daily new card limit (default: 20)
- Maximum reviews per day (default: 200)
- Theme selection (System/Light/Dark)

### User Interactions & Flows

#### Import Flow
1. User taps "+" button on DeckListViewController
2. Document picker presents (filtered to .apkg)
3. User selects file
4. Progress HUD shows "Importing..."
5. On success: New deck appears in list with animation
6. On failure: Alert with error message

#### Study Flow
1. User taps deck with due cards
2. CardStudyViewController presents first due card (front)
3. User taps card to flip and see answer
4. User taps rating button (Again/Hard/Good/Easy)
5. Next card animates in from right
6. When no more cards: Summary shown with stats

### Data Handling

#### Local Storage
- **Database**: SQLite via SQLite.swift
- **Tables**:
  - decks (id, name, created_at, updated_at)
  - cards (id, deck_id, front, back, tags, created_at)
  - reviews (id, card_id, ease_factor, interval, due_date, last_reviewed)
  - study_sessions (id, deck_id, date, cards_studied, correct_count)

#### .apkg Parsing
- .apkg is a ZIP file containing:
  - base.db (SQLite database with card data)
  - media/ (folder with images/audio)
- Parse base.db to extract:
  - decks table → our decks table
  - notes table → card front/back
  - cards table → card scheduling info

### Architecture Pattern: MVVM

```
View (UIKit) ←→ ViewModel ←→ Repository ←→ Database
```

- **View**: UIViewController, handles UI only
- **ViewModel**: Business logic, exposes observable state
- **Repository**: Data access abstraction
- **Database**: SQLite.swift operations

### Edge Cases & Error Handling
- Empty deck: Show "No cards to study" state
- Import invalid file: Alert with "Invalid Anki file format"
- Import duplicate deck: Offer to merge or replace
- No due cards: Show "All caught up!" message with next review time
- Database error: Log error, show generic retry alert

---

## 4. Technical Specification

### Dependencies (Swift Package Manager)

| Package | Version | Purpose |
|---------|---------|---------|
| SnapKit | 5.6.0 | Auto Layout DSL |
| SQLite.swift | 0.14.1 | SQLite wrapper |
| ZIPFoundation | 0.9.18 | .apkg extraction |

### Project Structure

```
AnkiFlow/
├── App/
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   └── Info.plist
├── Core/
│   ├── Extensions/
│   │   ├── UIColor+Theme.swift
│   │   └── Date+Extensions.swift
│   └── Constants/
│       └── AppConstants.swift
├── Data/
│   ├── Database/
│   │   ├── DatabaseManager.swift
│   │   └── Tables/
│   │       ├── DeckTable.swift
│   │       ├── CardTable.swift
│   │       └── ReviewTable.swift
│   ├── Repositories/
│   │   ├── DeckRepository.swift
│   │   └── CardRepository.swift
│   └── AnkiParser/
│       ├── ApkgParser.swift
│       └── AnkiDBReader.swift
├── Domain/
│   ├── Models/
│   │   ├── Deck.swift
│   │   ├── Card.swift
│   │   └── Review.swift
│   └── UseCases/
│       ├── ImportDeckUseCase.swift
│       ├── StudyCardUseCase.swift
│       └── SpacedRepetition.swift
├── Presentation/
│   ├── DeckList/
│   │   ├── DeckListViewController.swift
│   │   ├── DeckListViewModel.swift
│   │   └── DeckCell.swift
│   ├── CardStudy/
│   │   ├── CardStudyViewController.swift
│   │   ├── CardStudyViewModel.swift
│   │   └── FlashcardView.swift
│   ├── CardBrowser/
│   │   ├── CardBrowserViewController.swift
│   │   ├── CardBrowserViewModel.swift
│   │   └── CardBrowserCell.swift
│   ├── Statistics/
│   │   ├── StatisticsViewController.swift
│   │   └── StatisticsViewModel.swift
│   ├── Settings/
│   │   ├── SettingsViewController.swift
│   │   └── SettingsViewModel.swift
│   └── Import/
│       ├── ImportViewController.swift
│       └── ImportViewModel.swift
└── Resources/
    └── Assets.xcassets
```

### Asset Requirements
- App Icon (1024x1024 for App Store, various sizes for device)
- SF Symbols used throughout (system provided):
  - rectangle.stack.fill (decks tab)
  - chart.bar.fill (statistics tab)
  - gearshape.fill (settings tab)
  - plus (import button)
  - arrow.clockwise (sync/refresh)
  - magnifyingglass (search)
  - trash (delete)
  - checkmark.circle.fill (success)
  - xmark.circle.fill (error)

### Info.plist Requirements
```xml
UIFileSharingEnabled: YES
LSSupportsOpeningDocumentsInPlace: YES
UISupportsDocumentBrowser: YES
CFBundleDocumentTypes: [.apkg file type]
```

---

## 5. Implementation Notes

### SM-2 Algorithm Implementation
```
After each review with quality q (0-3):
if q < 2: interval = 1, repetitions = 0
else:
    if repetitions == 0: interval = 1
    elif repetitions == 1: interval = 6
    else: interval = round(interval * easeFactor)

    easeFactor = easeFactor + (0.1 - (3 - q) * (0.08 + (3 - q) * 0.02))
    if easeFactor < 1.3: easeFactor = 1.3

    repetitions += 1

dueDate = today + interval days
```

### Thread Safety
- Database operations on background queue
- UI updates on main queue
- Use Combine/async-await for reactive bindings
