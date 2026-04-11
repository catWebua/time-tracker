# ⏱ Time Tracker — FreelanceKit

Нативний iOS-застосунок для трекінгу часу на фрілансі.  
**Swift + SwiftUI + SwiftData | iOS 17+**

---

## 🚀 Налаштування в Xcode

### 1. Створи новий проект

1. Відкрий **Xcode** → `File → New → Project`
2. Обери **iOS → App**
3. Налаштування:
   - **Product Name**: `TimeTracker`
   - **Interface**: `SwiftUI`
   - **Language**: `Swift`
   - **Storage**: `SwiftData`
4. Натисни **Next**, обери папку `Desktop/time-tracker/` як місце збереження

### 2. Замінити автогенеровані файли

Xcode створить базову структуру. Тобі треба:

1. **Видалити** автогенеровані файли: `ContentView.swift`, `Item.swift`
2. **Замінити** `TimeTrackerApp.swift` файлом з цього проекту

### 3. Додати файли з цього репозиторію

Перетягни всі папки в проект у Xcode:
```
Models/
ViewModels/
Views/
Helpers/
```

При додаванні обери **"Create groups"** (не folder references).

### 4. Налаштування проекту

У налаштуваннях таргету переконайся:
- **Deployment Target**: iOS 17.0
- **Frameworks**: автоматично (SwiftData та Charts вже вбудовані)

### 5. Запуск

Натисни ▶ або `Cmd + R`. Додаток запустився!

---

## 📁 Структура проекту

```
TimeTracker/
├── TimeTrackerApp.swift          # Entry point
├── Models/
│   ├── Project.swift             # SwiftData модель проекту
│   └── TimeEntry.swift           # SwiftData модель запису
├── ViewModels/
│   └── TimerViewModel.swift      # Логіка таймера (@Observable)
├── Views/
│   ├── ContentView.swift         # TabView навігація
│   ├── Timer/
│   │   ├── TimerView.swift       # Головний екран з таймером
│   │   └── ProjectPickerSheet.swift
│   ├── Projects/
│   │   ├── ProjectListView.swift
│   │   ├── ProjectFormView.swift
│   │   └── ProjectDetailView.swift
│   ├── Entries/
│   │   ├── EntryListView.swift
│   │   └── EntryFormView.swift
│   └── Reports/
│       └── ReportsView.swift
└── Helpers/
    ├── DurationFormatter.swift
    └── Extensions.swift
```

---

## ✨ Функціонал

| Екран | Що вміє |
|-------|---------|
| ⏱ Таймер | Start/Stop, вибір проекту, live час |
| 🗂 Проекти | CRUD, кольори, погодинна ставка |
| 📋 Записи | Журнал по днях, swipe to delete, ручне додавання |
| 📊 Звіти | Тиждень/місяць, графіки, дохід |
