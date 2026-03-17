# PolyNap Haptic Feedback & Micro-Interaction Plan

Date: 2026-03-17

## 1) Why this plan

PolyNap already has strong core interactions, especially in schedule editing. The next step is to make feedback feel consistent, intentional, and emotionally rewarding across the entire app.

This plan covers:

- Current-state haptic audit (what exists vs. what is missing)
- Micro-interaction opportunities beyond haptics (motion, visual responses, subtle sound cues)
- A practical implementation architecture
- Rollout order with low-risk phases
- QA and accessibility guardrails

---

## 2) Experience principles

1. **Semantic over random**: Every haptic maps to meaning (select, commit, warning, success, celebrate).
2. **Consistency over novelty**: Shared UI components should feel the same everywhere.
3. **Delight without noise**: Reward milestones and confirmations; avoid constant vibration fatigue.
4. **Multi-sensory pairing**: Best interactions pair haptic + motion + visual state change.
5. **Respect settings**: Follow system accessibility and in-app haptic preferences.

---

## 3) Current-state audit summary

## 3.1 Strong today

- **Main schedule editing flow** (`polynap/Screen/MainScreen/ViewModels/MainScreenViewModel.swift`)
  - Pre-allocated generators
  - Snap-based haptic cadence for timeline edits
  - Heavier feedback for destructive zones and stronger transitions
- **History add-entry flow** (`polynap/Screen/History/Views/AddSleepEntrySheet.swift`)
  - Good slider and save confirmation feedback
- **Onboarding shared controls** (`polynap/Screen/NewOnboarding/Components/OnboardingSharedComponents.swift`)
  - Selection and button tap cues
- **Commitment moment** (`polynap/Screen/NewOnboarding/Views/Sections/Results/CommitmentScreen.swift`)
  - Escalating pattern is emotionally effective

## 3.2 High-impact gaps

- **Design system buttons have no built-in haptics** (`polynap/DesignPrinciples.swift`)
  - Biggest systemic gap, because these components are reused app-wide
- **Celebration modal has no tactile celebration** (`polynap/Screen/Profile/Views/Components/Badges/BadgeCelebrationModal.swift`)
  - Emotional payoff moment currently relies only on visual animation
- **Settings interactions mostly silent** (`polynap/Screen/Settings/Views/SettingsView.swift`)
- **Tab switching has no tactile navigation cue** (`polynap/Navigation/MainTabBarView.swift`)
- **App tour transitions have no tactile progression** (`polynap/Screen/AppTour/AppTourManager.swift`)
- **Onboarding animations are visually rich but tactility-light** (`polynap/Screen/NewOnboarding/Components/OnboardingAnimations.swift`)
- **Analytics exploration feedback is thin** (`polynap/Screen/Analytics/AnalyticsView.swift` + charts)

---

## 4) Recommended interaction language

Define one shared semantic map for the entire app:

- **Selection tick**: tiny state change, picker step, segment switch
  - `UISelectionFeedbackGenerator.selectionChanged()`
- **Soft commit**: non-destructive button tap, card select, tab tap
  - `UIImpactFeedbackGenerator(style: .light)`
- **Strong commit**: save, confirm, apply schedule
  - `UIImpactFeedbackGenerator(style: .medium)`
- **Boundary / warning**: invalid action, limit reached, risky delete zone
  - `UIImpactFeedbackGenerator(style: .rigid)` or `.heavy`
- **Success / error / warning outcome**: async completion states
  - `UINotificationFeedbackGenerator.notificationOccurred(.success/.error/.warning)`
- **Celebration pulse pattern**: badge/achievement/long streak moments
  - Short sequence (e.g. light -> medium -> success), rate-limited

---

## 5) Feature-area recommendations

## 5.1 Design system foundation (highest priority)

**Files**: `polynap/DesignPrinciples.swift`

### Add

- Optional haptic intent parameter to reusable button components:
  - `haptic: HapticIntent = .softCommit`
- Fire haptic on tap inside the shared component, not per screen.
- Add shared press animation language:
  - Scale to `0.97` on press down
  - Spring back on release
  - 120-180ms, smooth spring

### Outcome

- Immediate consistency across all screens using design system controls.

## 5.2 Main tab navigation

**Files**: `polynap/Navigation/MainTabBarView.swift`

### Add

- One soft commit haptic on tab change
- Subtle icon bounce + label opacity transition (120-160ms)
- Avoid firing if user taps currently active tab repeatedly (debounce)

### Outcome

- Navigation feels tactile and responsive without becoming noisy.

## 5.3 Main schedule editor and circular chart

**Files**:

- `polynap/Screen/MainScreen/ViewModels/MainScreenViewModel.swift`
- `polynap/Screen/SleepScheduleScreen/Views/EditableCircularSleepChart.swift`

### Keep

- Existing snap and drag zone strategy

### Improve

- Add haptic intensity progression for resize handles:
  - Snap ticks = selection
  - Crossing hour boundary = medium impact
- Add success confirmation when block edit is committed
- Add invalid overlap warning haptic if constraints reject changes
- Pair floating/add animation with one soft commit when block is created

### Outcome

- Core interaction becomes clearer at boundaries and confirmations.

## 5.4 Add/Edit sleep entry sheets

**Files**:

- `polynap/Screen/History/Views/AddSleepEntrySheet.swift`
- `polynap/Views/SleepQuality/SleepQualityRatingView.swift`

### Add

- Save CTA: success notification haptic
- Dismiss/cancel: no haptic (or very light only if action is deliberate)
- Stepper/slider snaps: selection haptic, rate-limited
- Quality submission success: medium + success pair only once

### Outcome

- Form interactions feel confident and complete at submit time.

## 5.5 Onboarding flow + motion pairing

**Files**:

- `polynap/Screen/NewOnboarding/Components/OnboardingAnimations.swift`
- `polynap/Screen/NewOnboarding/Components/OnboardingSharedComponents.swift`
- `polynap/Screen/NewOnboarding/Views/Sections/Results/CommitmentScreen.swift`

### Add

- Step transition (Next): soft commit
- Milestone pages (result reveal, commitment confirm): medium/success
- Animation sync points:
  - Confetti burst -> success haptic
  - Card reveal -> light impact
  - Progress ring completion -> medium impact
- Keep escalating pattern in commitment flow as signature moment

### Outcome

- Onboarding feels guided, alive, and emotionally coherent.

## 5.6 Badge and achievement celebrations

**Files**:

- `polynap/Screen/Profile/Views/Components/Badges/BadgeCelebrationModal.swift`
- `polynap/Managers/BadgeManager.swift`

### Add

- Celebration tactile sequence:
  - Modal appears: medium impact
  - Trophy peak frame: success notification
  - CTA tap: soft commit
- Add anti-spam guard:
  - Do not replay full celebration haptic within a cooldown window

### Outcome

- Badge unlocks become memorable reward moments.

## 5.7 Settings, preferences, and toggles

**Files**:

- `polynap/Screen/Settings/Views/SettingsView.swift`
- `polynap/Screen/Settings/Views/AlarmSettingsView.swift`
- `polynap/Screen/Settings/Views/NotificationSettingsView.swift`

### Add

- [x] Toggle ON/OFF: selection haptic
- [x] Picker value change (theme/language): selection haptic
- [x] Dangerous/reset actions: warning haptic + confirmation haptic on success
- [x] Inline save/apply states: success notification when changes persist

### Outcome

- Utility flows feel responsive and trustworthy.

## 5.8 App tour guidance

**File**: `polynap/Screen/AppTour/AppTourManager.swift`

### Add

- [x] Tour start: medium impact
- [x] Step next/back: selection haptic
- [x] Final completion: success notification
- [x] Highlight pulse animation synchronized with each step transition

### Outcome

- Tour becomes guided and tactile, improving orientation and completion.

## 5.9 Analytics data exploration

**Files**: `polynap/Screen/Analytics/AnalyticsView.swift`, `polynap/Screen/Analytics/Charts/`

### Add

- Segment/time-range changes: selection haptic
- Tooltip lock on data point: light impact
- Trend crossing key threshold (if visually highlighted): medium impact once

### Outcome

- Data exploration feels interactive instead of static.

---

## 6) Micro-interactions beyond haptics

## 6.1 Motion design patterns

- **Press states** for all primary controls (scale + shadow compression)
- **Staggered reveal** for list/card sections entering viewport
- **Magnetic snap** feel for circular schedule handles near exact intervals
- **Completion states** with short checkmark morph + fade

## 6.2 Visual delight moments

- Badge rarity color glow tiers (bronze/silver/gold/platinum)
- Tiny orbiting particles around newly earned badge for 1.2-1.8s
- Subtle sunrise/sunset gradient shift for sleep schedule summary cards

## 6.3 Optional sound layer (future)

- Keep default OFF initially
- Add small SFX pack for:
  - success chime
  - gentle click
  - warning tone
- Gate with explicit in-app toggle and system audio respect

---

## 7) Implementation architecture

## 7.1 Create a shared feedback service

Suggested new file: `polynap/Managers/HapticFeedbackManager.swift`

### Responsibilities

- Centralize all generator setup and reuse
- Provide semantic API:
  - `trigger(_ intent: HapticIntent)`
- Support rate-limiting/debouncing for continuous gestures
- Respect app setting + system capability checks
- Offer no-op behavior in previews/simulator contexts as needed

### Suggested intent enum

```swift
enum HapticIntent {
    case selection
    case softCommit
    case strongCommit
    case warning
    case success
    case error
    case celebrationPulse
}
```

## 7.2 Keep business logic clean

- Trigger haptics at interaction boundaries (view/view-model edges), not deep in data layer.
- Avoid duplicated direct UIKit generator calls across files.
- Move ad-hoc patterns gradually into manager-based semantic calls.

---

## 8) Accessibility and localization

- Respect iOS settings that reduce/disable haptics.
- Add in-app setting: **Haptic Feedback** (On by default).
- Avoid strong haptics in high-frequency loops.
- Ensure text for micro-interaction-related settings is localized in both English and Turkish.
  - Example keys:
    - `settings.haptics.title`
    - `settings.haptics.description`
    - `settings.sounds.title`
    - `settings.sounds.description`

---

## 9) Rollout plan (phased)

## Phase 1 - Foundation (1 sprint)

1. [x] Introduce `HapticFeedbackManager`
2. [x] Integrate with design-system buttons in `DesignPrinciples.swift`
3. [x] Add tab-switch and settings toggle haptics
4. [x] Add app-level haptic preference toggle

**Impact**: biggest consistency gain with low risk

## Phase 2 - Core journey polish (1 sprint)

1. [x] Extend schedule editor edge cases (commit/warning/success)
2. [x] Improve onboarding step transitions and key animation sync points
3. [x] Add sleep quality + history submission confirmations

**Impact**: improves first-week retention experience

## Phase 3 - Delight and reward (1 sprint)

1. [x] Implement badge celebration tactile sequence
2. [x] Add analytics exploration cues
3. [x] Optional: prototype lightweight SFX layer (behind toggle)

**Impact**: stronger emotional payoff and perceived product quality

---

## 10) QA checklist

- Verify each intent maps to expected generator style.
- Verify no repeated vibration spam during drags/sliders.
- Verify no haptic on disabled controls.
- Verify success/error states fire exactly once per outcome.
- Verify behavior on physical device (not simulator-only validation).
- Verify in-app haptic toggle fully suppresses app-triggered haptics.
- Verify Turkish/English strings for new settings and labels.

---

## 11) Success metrics

Track before vs. after rollout:

- Onboarding completion rate
- Day 1 / Day 7 retention
- Schedule edit completion rate
- Badge modal completion/CTA tap-through
- Settings change confirmation errors or reversals

Optional qualitative:

- In-app survey item: "The app feels responsive and satisfying to use" (Likert 1-5)

---

## 12) Immediate next coding tasks

1. [x] Add `HapticFeedbackManager` with semantic intents.
2. [x] Integrate shared buttons in `DesignPrinciples.swift`.
3. [x] Add haptics to `MainTabBarView.swift` and `SettingsView.swift`.
4. [x] Implement celebration sequence in `BadgeCelebrationModal.swift`.
5. [x] Add onboarding animation sync points.

This order gives maximum user-perceived improvement early while minimizing refactor risk.
