# PolyNap Onboarding Analytics Planı

## 1. Mevcut Durum Analizi

### 1.1 Onboarding Akışı (Aktif: NewOnboarding)

Aktif onboarding akışı `NewOnboardingContainerView` + `NewOnboardingViewModel` tarafından yönetiliyor.
36 ekran, 4 bölüm, ~12 soru ekranı var.

| # | Ekran (enum) | Bölüm | Tür | Atlanan? |
|---|---|---|---|---|
| 0 | `splash` | Story | Animasyon | - |
| 1 | `questionHook` | Story | Merak | - |
| 2 | `nimmyIntro` | Story | Tanıtım | - |
| 3 | `turningPoint` | Story | Hikaye | - |
| 4 | `beforeAfter` | Story | Karşılaştırma | - |
| 5 | `transition` | Story | Geçiş | - |
| 6 | `trustScreen` | Trust | Güven | ATLANIYOR |
| 7 | `nameInput` | Trust | Giriş | - |
| 8 | `personalizedGreeting` | Trust | Selamlama | - |
| 9 | `sleepExperience` | Questions | SORU | - |
| 10 | `experienceInfo` | Questions | Bilgi | - |
| 11 | `chronotype` | Questions | SORU | - |
| 12 | `ageRange` | Questions | SORU | - |
| 13 | `outcomeTimeCalc` | Questions | Hesaplama | - |
| 14 | `workSchedule` | Questions | SORU | - |
| 15 | `napEnvironment` | Questions | SORU | - |
| 16 | `napEnvironmentInfo` | Questions | Bilgi | Koşullu (sadece limited/unsuitable) |
| 17 | `lifestyle` | Questions | SORU | - |
| 18 | `knowledgeLevel` | Questions | SORU | - |
| 19 | `comparison` | Questions | Karşılaştırma | - |
| 20 | `healthStatus` | Questions | SORU | - |
| 21 | `safetyNote` | Questions | Bilgi | - |
| 22 | `motivationLevel` | Questions | SORU | - |
| 23 | `chartReview` | Questions | Grafik | ATLANIYOR |
| 24 | `sleepGoal` | Questions | SORU | - |
| 25 | `goalSocialProof` | Questions | Sosyal kanıt | - |
| 26 | `socialObligations` | Questions | SORU | - |
| 27 | `disruptionTolerance` | Questions | SORU | - |
| 28 | `resultIntro` | Results | Loading | - |
| 29 | `recommendedProgram` | Results | Öneri | ATLANIYOR |
| 30 | `timeline24h` | Results | Program | - |
| 31 | `firstBadge` | Results | Rozet | - |
| 32 | `notificationPrimer` | Results | İZİN | - |
| 33 | `alarmPrimer` | Results | İZİN | - |
| 34 | `final_` | Results | Kutlama | - |
| 35 | `commitment` | Results | Tamamla | - |

### 1.2 Şu An PostHog'a Giden Eventler

| Event | Dosya | Satır | Durum |
|---|---|---|---|
| `screen_view` (screen_name: "new_onboarding") | `NewOnboardingContainerView.swift` | 28 | Sadece container onAppear'da 1 kez |
| `onboarding_step_completed` (step_number, step_name) | `NewOnboardingViewModel.swift` | 314 | Her goToNext() çağrısında |
| `onboarding_skipped` (default_schedule_set) | `NewOnboardingViewModel.swift` | 458 | Skip butonuna basınca |
| `onboarding_completed` (total_time_spent, steps_completed, selected_schedule) | `NewOnboardingViewModel.swift` | 777 | completeOnboarding() içinde |

### 1.3 Tanımlı Ama Çağrılmayan Methodlar

| Method | Dosya | Satır | Durum |
|---|---|---|---|
| `logOnboardingStarted()` | `AnalyticsManager.swift` | 58 | TANIMLI ama NewOnboarding'de HİÇ ÇAĞRILMIYOR |
| `logOnboardingScreenViewed(...)` | `AnalyticsManager.swift` | 79 | TANIMLI ama HİÇBİR YERDE ÇAĞRILMIYOR |
| `logOnboardingStepBack(...)` | `AnalyticsManager.swift` | 99 | TANIMLI ama HİÇBİR YERDE ÇAĞRILMIYOR |

---

## 2. Sorunlar ve Eksikler

### 2.1 `onboarding_started` gönderilmiyor

**Dosya:** `NewOnboardingContainerView.swift` satir 26-29

```swift
.onAppear {
    viewModel.setModelContext(modelContext)
    analyticsManager.logScreenView(screenName: "new_onboarding", screenClass: "NewOnboardingContainerView")
}
```

`logOnboardingStarted()` çağrısı eksik. Eski `OnboardingView.swift` satır 204'te mevcut ama yeni akışa taşınmamış.

**Düzeltme:** `.onAppear` bloğuna `analyticsManager.logOnboardingStarted()` ekle.

### 2.2 Ekran geçişleri takip edilmiyor

`logOnboardingScreenViewed(screenName:screenIndex:section:progressPct:)` methodu `AnalyticsManager.swift` satır 79'da tanımlı ama hiçbir yerde çağrılmıyor. Dolayısıyla hangi ekrana kadar gelindiği, hangi ekranda kullanıcının bıraktığı bilinmiyor.

**Düzeltme:** `NewOnboardingViewModel.goToNext()` içinde, `logOnboardingStepCompleted` çağrısından hemen sonra `logOnboardingScreenViewed` çağrısı ekle.

### 2.3 Soru cevapları PostHog'a gitmiyor

`onboarding_step_completed` event'i sadece `step_number` ve `step_name` gönderiyor:

```swift
// NewOnboardingViewModel.swift satır 314
analyticsManager.logOnboardingStepCompleted(step: nextIndex, stepName: currentScreen.description)
```

Kullanıcının seçtiği cevaplar (chronotype, workSchedule, sleepGoal vb.) hiç gönderilmiyor. Hangi kullanıcı profilinin hangi sonucu verdiği analiz edilemiyor.

**Düzeltme:** Soru ekranlarından çıkılırken ilgili cevabı `answer_value` parametresi olarak ekle.

### 2.4 Geri gitme takip edilmiyor

`goToPrevious()` içinde hiçbir analytics çağrısı yok:

```swift
// NewOnboardingViewModel.swift satır 317-334
func goToPrevious() {
    guard !isTransitioning, currentScreenIndex > 0 else { return }
    // ... navigasyon kodu ...
    // Analytics çağrısı YOK
}
```

**Düzeltme:** `logOnboardingStepBack(fromScreen:toScreen:)` çağrısı ekle.

### 2.5 İzin sonuçları izlenmiyor

**Bildirim izni** (`NewOnboardingViewModel.swift` satır 428-439):

```swift
func requestNotificationPermission() {
    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        DispatchQueue.main.async {
            if granted {
                print("✅ Notification permission granted")
            } else {
                print("❌ Notification permission denied")
            }
            self.goToNext()  // İzin sonucundan bağımsız devam ediyor
        }
    }
}
```

`granted` true/false bilgisi alınıyor ama PostHog'a gönderilmiyor.

**Alarm izni** (`NewOnboardingViewModel.swift` satır 449-454):

```swift
func requestAlarmPermission() {
    Task { @MainActor in
        await AlarmService.shared.requestPermissions()
        self.goToNext()  // Sonuç kontrol edilmiyor
    }
}
```

Alarm izin sonucu hiç kontrol bile edilmiyor, doğrudan devam ediyor.

**Düzeltme:** Her iki izin fonksiyonuna `permission_result` event'i ekle.

### 2.6 User Properties set edilmiyor

Onboarding'de toplanan veriler (chronotype, ageRange, sleepGoal vb.) PostHog user property olarak set edilmiyor. Bu veriler olmadan cohort analizi ve kişiselleştirilmiş segmentasyon yapılamaz.

**Düzeltme:** `completeOnboarding()` içinde `analyticsManager.setUserProperty(...)` çağrıları ekle.

---

## 3. Nudge Spam Sorunu

### 3.1 Sorunun Açıklaması

PostHog'da tek bir oturumda 100+ `nudge_generated` ve `nudge_delivered` event'i görülüyor. Bu eventler gerçek nudge iletimlerini temsil etmiyor, bildirim kuyruğuna ekleme anında tetikleniyor.

### 3.2 Kök Neden

**`AlarmService.swift` satır 336-380:** `scheduleReminder()` fonksiyonu her iOS bildirim kuyruğuna ekleme işleminde `nudge_generated` + `nudge_delivered` eventlerini ateşliyor.

**`AlarmService.swift` satır 185-243:** `rescheduleWithNotifications()` fonksiyonu 7 günlük tüm blokları hesaplayıp her biri için `scheduleReminder()` çağırıyor.

**Hesap:**
- Biphasic program (2 blok/gün): 7 gün x 2 blok = 14 reminder
- Her reminder = 1 `nudge_generated` + 1 `nudge_delivered` = 2 event
- 14 x 2 = 28 event / reschedule çağrısı
- Oturumda ~6 reschedule çağrısı olabiliyor = **168 event/oturum**

**Neden 6 reschedule çağrısı?**

1. `ScheduleManager.init()` -> uygulama açılışında
2. `MainScreenViewModel.setModelContext` -> `loadScheduleFromRepository` -> `updateAlarms()`
3. `MainScreenViewModel` auth state listener -> `loadScheduleFromRepository` -> `updateAlarms()`
4. `isEditing` her false olduğunda -> `updateAlarms()`

Kritik olarak, `MainScreenViewModel.updateAlarms()` doğrudan `AlarmService.shared.rescheduleNotificationsForActiveSchedule()` çağırıyor ve `ScheduleManager`'ın 10 saniyelik throttle mekanizmasını bypass ediyor.

### 3.3 Semantik Hata

- `nudge_generated`: Bir nudge'ın "üretildiği" anı temsil etmeli. Ancak iOS bildirim kuyruğuna plan olarak eklenmesiyle gerçek üretim farklı şeyler.
- `nudge_delivered`: Bir nudge'ın kullanıcıya "iletildiği" anı temsil etmeli. Ancak planlama anında tetikleniyor, gerçek iletim anında değil.

### 3.4 Düzeltme Planı (Sonraki Aşama - Bu Dokümandaki Scope Dışı)

1. `nudge_generated` -> Sadece `rescheduleWithNotifications()` başarıyla tamamlandığında 1 kez, toplam planlanan bildirim sayısıyla birlikte tetiklenmeli
2. `nudge_delivered` -> `UNUserNotificationCenterDelegate.willPresent` veya `didReceive` callback'lerinde tetiklenmeli (gerçek iletim anı)
3. `MainScreenViewModel.updateAlarms()` -> `ScheduleManager` üzerinden çağırılmalı, throttle koruması sağlanmalı

---

## 4. Yapılacak Kod Değişiklikleri

### 4.1 `NewOnboardingContainerView.swift` - onboarding_started ekle

```swift
// ONCE (satir 26-29):
.onAppear {
    viewModel.setModelContext(modelContext)
    analyticsManager.logScreenView(screenName: "new_onboarding", screenClass: "NewOnboardingContainerView")
}

// SONRA:
.onAppear {
    viewModel.setModelContext(modelContext)
    analyticsManager.logOnboardingStarted()
    analyticsManager.logScreenView(screenName: "new_onboarding", screenClass: "NewOnboardingContainerView")
}
```

### 4.2 `NewOnboardingViewModel.swift` - goToNext() guncelle

Mevcut `goToNext()` fonksiyonuna ekran goruntulenme ve cevap takibi ekle.

```swift
// ONCE (satir 314):
analyticsManager.logOnboardingStepCompleted(step: nextIndex, stepName: currentScreen.description)

// SONRA:
let answerValue = getCurrentAnswerValue()
analyticsManager.logOnboardingStepCompleted(
    step: nextIndex,
    stepName: currentScreen.description,
    answerValue: answerValue
)

let nextScreen = OnboardingScreen(rawValue: nextIndex) ?? .splash
analyticsManager.logOnboardingScreenViewed(
    screenName: nextScreen.description,
    screenIndex: nextIndex,
    section: nextScreen.section.analyticsName,
    progressPct: Int(progress * 100)
)
```

### 4.3 `NewOnboardingViewModel.swift` - Cevap degerini al

ViewModel'e yeni helper fonksiyon ekle:

```swift
private func getCurrentAnswerValue() -> String? {
    switch currentScreen {
    case .sleepExperience:
        return previousSleepExperience?.rawValue
    case .chronotype:
        return chronotype?.rawValue
    case .ageRange:
        return ageRange?.rawValue
    case .workSchedule:
        return workSchedule?.rawValue
    case .napEnvironment:
        return napEnvironment?.rawValue
    case .lifestyle:
        return lifestyle?.rawValue
    case .knowledgeLevel:
        return knowledgeLevel?.rawValue
    case .healthStatus:
        return healthStatus?.rawValue
    case .motivationLevel:
        return motivationLevel?.rawValue
    case .sleepGoal:
        return sleepGoal?.rawValue
    case .socialObligations:
        return socialObligations?.rawValue
    case .disruptionTolerance:
        return disruptionTolerance?.rawValue
    case .nameInput:
        return userName.isEmpty ? nil : "provided"
    default:
        return nil
    }
}
```

### 4.4 `NewOnboardingViewModel.swift` - goToPrevious() analytics ekle

```swift
// ONCE (satir 317-334):
func goToPrevious() {
    guard !isTransitioning, currentScreenIndex > 0 else { return }
    let prevIndex = findPreviousScreen(from: currentScreenIndex)
    // ... navigasyon kodu ...
}

// SONRA:
func goToPrevious() {
    guard !isTransitioning, currentScreenIndex > 0 else { return }
    let prevIndex = findPreviousScreen(from: currentScreenIndex)
    let fromScreen = currentScreen.description
    // ... navigasyon kodu ...
    let toScreen = (OnboardingScreen(rawValue: prevIndex) ?? .splash).description
    analyticsManager.logOnboardingStepBack(fromScreen: fromScreen, toScreen: toScreen)
}
```

### 4.5 `NewOnboardingViewModel.swift` - Izin sonuclarini izle

**Bildirim izni:**

```swift
func requestNotificationPermission() {
    analyticsManager.logEvent("permission_requested", parameters: ["permission_type": "notifications"])

    UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
        DispatchQueue.main.async {
            if granted {
                self.analyticsManager.logEvent("permission_result", parameters: [
                    "permission_type": "notifications",
                    "granted": true
                ])
            } else {
                self.analyticsManager.logEvent("permission_result", parameters: [
                    "permission_type": "notifications",
                    "granted": false
                ])
            }
            self.goToNext()
        }
    }
}
```

**Alarm izni:**

```swift
func requestAlarmPermission() {
    analyticsManager.logEvent("permission_requested", parameters: ["permission_type": "alarm"])

    Task { @MainActor in
        await AlarmService.shared.requestPermissions()
        // AlarmKit izin sonucunu kontrol et
        let status = await AlarmService.shared.currentAuthorizationStatus()
        analyticsManager.logEvent("permission_result", parameters: [
            "permission_type": "alarm",
            "granted": status == .authorized
        ])
        self.goToNext()
    }
}
```

### 4.6 `NewOnboardingViewModel.swift` - completeOnboarding() user properties ekle

`completeOnboarding()` fonksiyonunda, `logOnboardingCompleted` çağrısından sonra:

```swift
// User properties set et
if let chrono = chronotype { analyticsManager.setUserProperty("chronotype", value: chrono.rawValue) }
if let age = ageRange { analyticsManager.setUserProperty("age_range", value: age.rawValue) }
if let work = workSchedule { analyticsManager.setUserProperty("work_schedule", value: work.rawValue) }
if let goal = sleepGoal { analyticsManager.setUserProperty("sleep_goal", value: goal.rawValue) }
if let exp = previousSleepExperience { analyticsManager.setUserProperty("sleep_experience", value: exp.rawValue) }
if let motivation = motivationLevel { analyticsManager.setUserProperty("motivation_level", value: motivation.rawValue) }
if let health = healthStatus { analyticsManager.setUserProperty("health_status", value: health.rawValue) }
analyticsManager.setUserProperty("onboarding_status", value: "completed")
```

### 4.7 `AnalyticsManager.swift` - logOnboardingStepCompleted guncelle

```swift
// ONCE (satir 88-97):
func logOnboardingStepCompleted(step: Int, stepName: String, timeSpentSeconds: Int? = nil) {
    var params: [String: Any] = [
        "step_number": step,
        "step_name": stepName
    ]
    if let time = timeSpentSeconds {
        params["time_spent_seconds"] = time
    }
    logEvent("onboarding_step_completed", parameters: params)
}

// SONRA:
func logOnboardingStepCompleted(step: Int, stepName: String, timeSpentSeconds: Int? = nil, answerValue: String? = nil) {
    var params: [String: Any] = [
        "step_number": step,
        "step_name": stepName
    ]
    if let time = timeSpentSeconds {
        params["time_spent_seconds"] = time
    }
    if let answer = answerValue {
        params["answer_value"] = answer
    }
    logEvent("onboarding_step_completed", parameters: params)
}
```

### 4.8 `OnboardingSection` - analyticsName ekle

```swift
enum OnboardingSection {
    case story, trust, questions, results

    var analyticsName: String {
        switch self {
        case .story: return "story"
        case .trust: return "trust"
        case .questions: return "questions"
        case .results: return "results"
        }
    }
    // ... mevcut progressColor ...
}
```

---

## 5. Nihai Event Tablosu

Degisikliklerden sonra PostHog'a gidecek onboarding eventleri:

| Event | Tetiklenme Anı | Parametreler |
|---|---|---|
| `onboarding_started` | Container onAppear | - |
| `onboarding_screen_viewed` | Her ekran gecisinde (goToNext) | `screen_name`, `screen_index`, `section`, `progress_pct` |
| `onboarding_step_completed` | Her ileri adimda (goToNext) | `step_number`, `step_name`, `answer_value` (nullable) |
| `onboarding_step_back` | Her geri adimda (goToPrevious) | `from_screen`, `to_screen` |
| `permission_requested` | Izin istenmeden hemen once | `permission_type` ("notifications" / "alarm") |
| `permission_result` | Izin sonucu alindiktan sonra | `permission_type`, `granted` (bool) |
| `onboarding_skipped` | Skip butonuna basildiginda | `default_schedule_set` |
| `onboarding_completed` | Commitment ekraninda basari | `total_time_spent`, `steps_completed`, `selected_schedule` |

### Gonderilmeyecek / Gereksiz Eventler

| Event | Neden Gonderilmiyor |
|---|---|
| Her ekran icin ayri `screen_view` | `onboarding_screen_viewed` zaten takip ediyor, duplicate olur |
| `onboarding_step_completed` bilgi ekranlarinda cevap olmadan | Soru olmayan ekranlarda `answer_value` null olarak gider, extra event yok |
| `feature_used` onboarding icinde | Onboarding'e ozel eventler yeterli |

---

## 6. PostHog Dashboard Ayarlari

### 6.1 Onboarding Funnel Olustur

1. PostHog > Insights > + New Insight > Funnel
2. Steps:
   - Step 1: `onboarding_started`
   - Step 2: `onboarding_screen_viewed` where `section = "questions"`
   - Step 3: `onboarding_screen_viewed` where `screen_name = "notification_primer"`
   - Step 4: `permission_result` where `permission_type = "notifications"`
   - Step 5: `onboarding_completed`
3. Conversion window: 1 hour (onboarding tek oturumda tamamlanmali)
4. Kaydet: **"Onboarding Completion Funnel"**

### 6.2 Drop-off Analizi

1. PostHog > Insights > + New Insight > Trends
2. Event: `onboarding_step_completed`
3. Breakdown by: `step_name`
4. Display: Table (Total)
5. Bu tablo hangi adimda kac kisi oldugunu gosterecek -> En buyuk dusus = drop-off noktasi
6. Kaydet: **"Onboarding Step Drop-off"**

### 6.3 Soru Cevaplari Dagilimi

1. PostHog > Insights > + New Insight > Trends
2. Event: `onboarding_step_completed`
3. Filter: `step_name = "chronotype"` (veya diger sorular)
4. Breakdown by: `answer_value`
5. Tekrarla: `sleep_goal`, `work_schedule`, `motivation_level`, `age_range`
6. Kaydet: **"Onboarding Answer Distribution"**

### 6.4 Izin Oranlari

1. PostHog > Insights > + New Insight > Trends
2. Events:
   - A: `permission_result` where `permission_type = "notifications"` AND `granted = true`
   - B: `permission_result` where `permission_type = "notifications"` AND `granted = false`
3. Display: Pie chart
4. Tekrarla alarm icin
5. Kaydet: **"Permission Grant Rates"**

### 6.5 Nudge Eventlerini Gizle

1. PostHog > Data Management > Events
2. `nudge_generated` -> "..." menusunden "Hide from queries"
3. `nudge_delivered` -> "..." menusunden "Hide from queries"
4. Kod duzeltmesi yapildiktan sonra geri acilaabilir
5. **SILME** - tarihi veri kaybolur

### 6.6 User Properties Kullanimi

`completeOnboarding()` icinde set edilen user property'ler sayesinde:

1. PostHog > People > Cohorts
2. Ornek cohortlar:
   - "Morning Chronotypes": `chronotype = morning` olan kullanicilar
   - "High Motivation": `motivation_level = high` olan kullanicilar
   - "Completed Onboarding": `onboarding_status = completed`
3. Bu cohortlari retention, funnel ve trend analizlerinde filtre olarak kullan

### 6.7 Dashboard Olustur

1. PostHog > Dashboards > + New Dashboard
2. Isim: **"Onboarding Analytics"**
3. Ekle:
   - Onboarding Completion Funnel
   - Onboarding Step Drop-off
   - Onboarding Answer Distribution (chronotype)
   - Permission Grant Rates
4. Refresh: Daily

---

## 7. Dokunulacak Dosyalar Ozeti

| Dosya | Degisiklik |
|---|---|
| `polynap/Screen/NewOnboarding/Views/NewOnboardingContainerView.swift` | `logOnboardingStarted()` ekle |
| `polynap/Screen/NewOnboarding/ViewModels/NewOnboardingViewModel.swift` | `goToNext()` guncelle, `goToPrevious()` analytics ekle, `getCurrentAnswerValue()` ekle, `requestNotificationPermission()` guncelle, `requestAlarmPermission()` guncelle, `completeOnboarding()` user properties ekle |
| `polynap/Managers/AnalyticsManager.swift` | `logOnboardingStepCompleted()` imza guncelle (`answerValue` parametresi) |

---

## 8. Onemli Notlar

- `onboarding_screen_viewed` ve `onboarding_step_completed` ayni anda tetikleniyor ama farkli amaclar icin: `screen_viewed` navigasyon takibi (funnel), `step_completed` ise adim tamamlama + cevap takibi icin.
- `permission_requested` ve `permission_result` iki ayri event olarak gonderiliyor cunku kullanici izin diyalogunu gorup kapatabilir (iOS seviyesinde). requested -> result arasindaki sure de olculebilir.
- `answer_value` soru olmayan ekranlarda `nil` olarak gider, PostHog'da bu property'nin olmamasi o event'in soru icermedigini gosterir.
- Onboarding skip durumunda `onboarding_skipped` event'i zaten atScreen ve screenIndex parametreleri ile gonderilebilir ama su an bu parametreler `skipOnboarding()` cagirisinda verilmiyor. Opsiyonel olarak eklenebilir.
