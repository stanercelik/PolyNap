# PolyNap – Copilot Instructions

## Overview

PolyNap is an iOS 17+ SwiftUI app for managing polyphasic sleep schedules. It targets iPhone/iPad with an Apple Watch companion. The codebase is in Swift

## Build & Run

- Open `polynap.xcodeproj` in Xcode 15+
- Requires iOS 17.0+ deployment target
- Add `GoogleService-Info.plist` (Firebase) and set `RevenueCatAPIKey` in `Keys.xcconfig` / `AppConfiguration.swift` before building
- No separate build script — use Xcode or `xcodebuild`

## Architecture

### Entry Point & Navigation

`polynapApp.swift` bootstraps SwiftData, configures Firebase and RevenueCat, then injects every manager as an `.environmentObject()` into the root `ContentView`. Navigation routes to either `NewOnboardingContainerView` or `MainTabBarView` based on `UserPreferences.hasCompletedOnboarding`.

`MainTabBarView` is a 4-tab TabView:

- **Schedule** (main sleep timeline)
- **History**
- **Analytics**
- **Profile**

Each tab is wrapped in its own `NavigationStack`.

### MVVM Pattern

ViewModels follow this exact signature:

```swift
@MainActor
class SomeScreenViewModel: ObservableObject {
    @Published var someState: Type = defaultValue

    func setModelContext(_ context: ModelContext) { ... }
}
```

ViewModels live in `Screen/{Feature}/ViewModels/`. Every ViewModel that needs persistence has a `setModelContext(_:)` method called from the owning view's `.onAppear`.

### Data Layer (SwiftData + Repository Pattern)

Key SwiftData models (`polynap/Models/SwiftDataModels.swift`):

- `User` → `UserSchedule` → `UserSleepBlock` (cascade delete)
- `SleepEntry` (linked to User)
- `UserPreferences`, `OnboardingAnswerData`, `AlarmSettings`

All data access goes through singletons in `Services/Repository/`:

- `Repository.shared` — hub that coordinates sub-repositories
- `UserRepository.shared`, `ScheduleRepository.shared`, `SleepEntryRepository.shared`
- `SharedRepository.shared` — shared with Watch via `PolyNapShared` package

`Repository.shared.setModelContext(context)` must be called at app startup (done in `polynapApp.init()`). Sub-repositories receive the context from the hub.

### Managers (all singletons in `Managers/`)

| Manager             | Role                                                                                 |
| ------------------- | ------------------------------------------------------------------------------------ |
| `AnalyticsManager`  | Firebase Analytics wrapper — all events go through here                              |
| `LanguageManager`   | Dynamic language switching, stores in UserDefaults                                   |
| `RevenueCatManager` | RevenueCat SDK, user state `.free` / `.premium`                                      |
| `PaywallManager`    | 4-scenario paywall display logic                                                     |
| `AlarmManager`      | `@MainActor` singleton, audio playback, `isAlarmFiring` state                        |
| `BadgeManager`      | Badge evaluation, posts `.badgeEarned` Notification or schedules UNLocalNotification |
| `RatingManager`     | App Store review prompts                                                             |

### Services (in `Services/`)

- `AlarmService` — `UNUserNotificationCenter` scheduling (max 64 pending notifications)
- `HealthKitManager` — HKHealthStore integration (iOS)
- `WatchSyncBridge` — iPhone ↔ Watch via `WCSession`
- `ScheduleManager` — schedule creation/update coordination
- `AuthManager` — local user session management
- `MigrationService` — SwiftData schema migration

### Watch App

Two watch targets:

- **`watchkitapp Watch App/`** — main Watch UI (`MainWatchView`, `WatchCircularSleepChart`, `QuickSleepEntryView`)
- **`PolyNap Watch Extension/`** — complications (`ComplicationController`) and `WatchHealthKitManager`

Shared code lives in the local **`PolyNapShared`** Swift package (`Package.swift`), which contains `SharedRepository`, `WatchConnectivityManager`, and shared models.

## Key Conventions

### Design System

All UI components use the `PS`-prefixed design system defined in `DesignPrinciples.swift`:

- **Components**: `PSCard`, `PSPrimaryButton`, `PSSecondaryButton`, `PSTertiaryButton`, `PSIconButton`, `PSStatusBadge`, `PSInfoBox`, `PSEmptyState`, `PSErrorState`, `PSLoadingState`
- **Spacing**: `PSSpacing.xs/sm/md/lg/xl/xxl/xxxl` (8pt grid)
- **Typography**: `PSTypography.largeTitle/headline/body/caption/button`
- **Corner radius**: `PSCornerRadius.small/medium/large/extraLarge/button`
- **Semantic colors**: `.appPrimary`, `.appBackground`, `.appCardBackground`, `.appText`, `.appTextSecondary`, `.appTextOnPrimary`, `.appAccent`, `.appError`

Always use these design tokens — never hardcode colors, spacing, or fonts.

### Localization

Strings use `.xcstrings` files in `polynap/Resources/Localizations/` (TR, EN, JA, DE, MS, TH). The helper function:

```swift
L("key", table: "TableName")  // e.g., L("schedule.title", table: "Common")
```

`LanguageManager.shared` drives dynamic switching via `.environment(\.locale, ...)`.

**Badge localization keys**: `BadgeDefinition.locKey` strips `"badge-"` prefix and camelCases the remainder (e.g., `"badge-one-week"` → `"oneWeek"`). Keys in `Profile.xcstrings` are `badge.{locKey}.name`, `badge.{locKey}.desc`, `badge.{locKey}.how`.

Always add both Turkish and English strings when adding new UI text.

### Analytics

Log every meaningful user action through `AnalyticsManager.shared`:

```swift
analyticsManager.logEvent("event_name", parameters: ["key": "value"])
analyticsManager.logFeatureUsed(featureName: "hrv", action: "viewed")
analyticsManager.logScreenView(screenName: "HRVDashboard", screenClass: "HRVDashboardView")
```

### Paywall / Premium

Check `RevenueCatManager.shared.userState == .premium` before showing premium content. Use the `.managePaywalls()` View modifier for automatic paywall display. Never gate content without going through `PaywallManager`.

### Alarm System

Alarm flow: `AlarmService` schedules `UNUserNotificationCenter` notifications → `AppDelegate` intercepts → posts `Notification.Name.startAlarm` → `AlarmManager.shared.isAlarmFiring = true` → `ContentView` presents `AlarmFiringView` as `.fullScreenCover`.

Critical alerts bypass Focus/Silent mode. Maximum 64 pending notifications are scheduled at a time.

### SwiftData ModelContainer

`polynapApp.init()` has a 3-tier fallback for `ModelContainer` initialization (full → minimal → in-memory). When adding new `@Model` types, register them in all three tiers of the initializer in `polynapApp.swift`.
