# Paywall Close Button & Discount Drawer Logic — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Paywall X butonlarının görsel (Lottie/Static) ve davranış (Drawer/Close) koşullarını bağımsız iki Superwall attribute üzerinden yönetmek.

**Architecture:** `PaywallManager.swift` içinde tek attribute (`is_discount_eligible`) ikiye ayrılır: `is_first_daily_open` (Lottie görünürlüğü) ve `is_discount_eligible` (sadece her 3. açılma, drawer davranışı). Superwall dashboard'da 4 olan X butonu 8'e çıkar; her biri tek bir koşul kombinasyonunda görünür.

**Tech Stack:** Swift, SuperwallKit, Superwall Dashboard (paywall editor)

---

## Task 1: PaywallManager — İki attribute'a geçiş

**Files:**
- Modify: `polynap/Managers/PaywallManager.swift`

Mevcut `setDiscountEligibility(_ eligible: Bool)` metodu tek bir boolean gönderiyordu. Bunu iki ayrı değer gönderecek şekilde değiştiriyoruz. Attributes `incrementPaywallOpenCount()` çağrısından **önce** gönderilmeli çünkü increment sonrasında `isFirstPaywallOpenToday()` false döner.

- [ ] **Step 1: `setDiscountEligibility` metodunu `setPaywallAttributes` olarak değiştir**

`polynap/Managers/PaywallManager.swift` içinde `setDiscountEligibility` metodunu tamamen kaldır, yerine şunu ekle:

```swift
/// Sends two independent user attributes to Superwall before each paywall open:
/// - `is_first_daily_open`: true if this is the first paywall open of the calendar day
/// - `is_discount_eligible`: true on every 3rd total open (3rd, 6th, 9th…)
private func setPaywallAttributes(isFirstDaily: Bool, isEveryThird: Bool) {
    #if canImport(SuperwallKit)
    Superwall.shared.setUserAttributes([
        "is_first_daily_open": isFirstDaily,
        "is_discount_eligible": isEveryThird
    ])
    #endif
}
```

- [ ] **Step 2: `presentPaywall` içindeki çağrıları güncelle**

Mevcut:
```swift
let eligible = shouldShowDrawerOnNextOpen()
setDiscountEligibility(eligible)
incrementPaywallOpenCount()
```

Yeni:
```swift
let isFirstDaily = isFirstPaywallOpenToday()
let openCount = getPaywallOpenCount()
let isEveryThird = openCount > 0 && (openCount + 1) % 3 == 0
setPaywallAttributes(isFirstDaily: isFirstDaily, isEveryThird: isEveryThird)
incrementPaywallOpenCount()
```

- [ ] **Step 3: `shouldShowDrawerOnNextOpen` metodunu kaldır**

Bu metod artık kullanılmıyor. `PaywallManager.swift`'ten şu satırları sil:

```swift
private func shouldShowDrawerOnNextOpen() -> Bool {
    let isFirstToday = isFirstPaywallOpenToday()
    let openCount = getPaywallOpenCount()
    let isEveryThird = openCount > 0 && (openCount + 1) % 3 == 0
    return isFirstToday || isEveryThird
}
```

- [ ] **Step 4: Debug print'i güncelle**

`presentPaywall` içindeki print bloğunu güncelle:

```swift
print("\n📱 ========== SUPERWALL PAYWALL ==========")
print("📱 Trigger: \(trigger) | Placement: \(placement)")
print("📱 is_first_daily_open: \(isFirstDaily)")
print("📱 is_discount_eligible (every 3rd): \(isEveryThird)")
print("📱 Open count: \(getPaywallOpenCount())")
print("📱 =========================================\n")
```

- [ ] **Step 5: Derlemeyi doğrula**

```bash
xcodebuild -project /Users/tanercelik/Projects/polynap-xcode-fix/polynap.xcodeproj \
  -scheme polynap -destination 'platform=iOS Simulator,name=iPhone 16' \
  build 2>&1 | grep -E "error:|warning:|BUILD"
```

Beklenen: `BUILD SUCCEEDED`, `setDiscountEligibility` ile ilgili hata yok.

- [ ] **Step 6: Commit**

```bash
git add polynap/Managers/PaywallManager.swift
git commit -m "refactor: split paywall attributes into is_first_daily_open and is_discount_eligible

- is_first_daily_open: true on first paywall open of the calendar day (controls Lottie visibility)
- is_discount_eligible: true on every 3rd total open — 3rd, 6th, 9th... (controls drawer behavior)
- removed shouldShowDrawerOnNextOpen() as logic is now inline in presentPaywall()"
```

---

## Task 2: Superwall Dashboard — Lottie X butonlarını güncelle

> Bu task tamamen Superwall web dashboard'unda yapılır (kod değişikliği yok).
> Dashboard URL: https://superwall.com/applications/15316/paywalls
> Paywall adı: `free-trial-paywall` (ID: 189992)

**Açıklama:** Mevcut `Lottie X Black Icon` ve `Lottie X White Icon` butonlarına visibility condition ekle. Tap behavior zaten doğru (`Set "Drawer".isOpen = true`) — sadece görünürlük koşullarını güncellemek gerekiyor. Ardından her biri için bir "Close" varyantı oluştur.

### Lottie X Black Icon — iki varyanta ayır

- [ ] **Step 1: Mevcut Lottie X Black Icon'u "Drawer" varyantı olarak yapılandır**

  1. Paywall editor'de `Right Buttons → Lottie X Black Icon`'a tıkla
  2. Sol sidebar'da elementin **Is Visible** property'sine tıkla → **Dynamic** seç
  3. **Add Value** → Value 1 olarak `false` ayarla (default hidden)
  4. **Add Rule** ekle → şu group koşulunu kur:
     - Rule 1: `user.is_first_daily_open == true`
     - Rule 2 (AND): `user.is_discount_eligible == true`
     - Rule 3 (AND): `device.colorScheme == dark`
  5. Bu koşullar sağlandığında `true` dönsün → buton görünür olsun
  6. Tap behavior: `Set "Drawer".isOpen = true` — **değiştirme**, zaten doğru
  7. **Done**

- [ ] **Step 2: "Lottie X Black — Close" adlı yeni buton ekle**

  1. `Right Buttons` grubuna sağ tıkla → **Duplicate** ile `Lottie X Black Icon`'u kopyala
  2. Kopyanın adını **"Lottie X Black Close"** yap
  3. Bu kopyanın **Is Visible** Dynamic Value'sunu aç, Rule 2'yi şu şekilde değiştir:
     - Rule 2 (AND): `user.is_discount_eligible == false`
     - (Rule 1 ve 3 aynı kalır: `is_first_daily_open == true`, `colorScheme == dark`)
  4. Bu kopyanın **Tap Behavior**'ını değiştir:
     - Mevcut `Set "Drawer".isOpen = true` aksiyonunu sil
     - **+ Add Action** → **Close** seç
  5. **Done**

### Lottie X White Icon — aynı pattern, light mode

- [ ] **Step 3: Lottie X White Icon visibility'sini güncelle**

  1. `Right Buttons → Lottie X White Icon`'a tıkla
  2. **Is Visible** → Dynamic:
     - Rule 1: `user.is_first_daily_open == true`
     - Rule 2: `user.is_discount_eligible == true`
     - Rule 3: `device.colorScheme == light`
     - Default: `false`
  3. Tap behavior: `Set "Drawer".isOpen = true` — değiştirme

- [ ] **Step 4: "Lottie X White Close" adlı yeni buton ekle**

  1. `Lottie X White Icon`'u duplicate et → adını **"Lottie X White Close"** yap
  2. Visibility:
     - Rule 1: `user.is_first_daily_open == true`
     - Rule 2: `user.is_discount_eligible == false`
     - Rule 3: `device.colorScheme == light`
  3. Tap Behavior: mevcut aksiyonu sil → **Close** ekle

- [ ] **Step 5: Kaydet (Publish değil, sadece taslak)**

  Editor'de **Save** (Draft olarak) yap. Henüz Publish etme.

---

## Task 3: Superwall Dashboard — Static X butonlarını güncelle

> Aynı paywall, `Right Buttons` bölümü devam ediyor.

### Black X Icon — iki varyanta ayır

- [ ] **Step 1: Mevcut Black X Icon'u "Close" varyantı olarak yapılandır**

  1. `Right Buttons → Black X Icon`'a tıkla
  2. **Tap Behavior** bölümünü aç
  3. Mevcut aksiyon `Custom Placement → discount-drawer`'ı **sil** (… → Remove)
  4. **+ Add Action** → **Close** seç
  5. **Is Visible** → Dynamic:
     - Rule 1: `user.is_first_daily_open == false`
     - Rule 2: `user.is_discount_eligible == false`
     - Rule 3: `device.colorScheme == dark`
     - Default: `false`
  6. **Done**

- [ ] **Step 2: "Static X Black Drawer" adlı yeni buton ekle**

  1. `Black X Icon`'u duplicate et → adını **"Black X Drawer"** yap
  2. Visibility:
     - Rule 1: `user.is_first_daily_open == false`
     - Rule 2: `user.is_discount_eligible == true`
     - Rule 3: `device.colorScheme == dark`
  3. Tap Behavior: `Close` aksiyonunu sil → **Set/Update Variable** → Drawer'ın `Is Open` variable'ını `true` olarak set et
  4. **Done**

### White X Ico — aynı pattern, light mode

- [ ] **Step 3: Mevcut White X Ico'yu "Close" varyantı olarak yapılandır**

  1. `Right Buttons → White X Ico`'ya tıkla
  2. Mevcut tap behavior'ı kontrol et; Custom Placement varsa sil
  3. Tap Behavior: **Close**
  4. **Is Visible** → Dynamic:
     - Rule 1: `user.is_first_daily_open == false`
     - Rule 2: `user.is_discount_eligible == false`
     - Rule 3: `device.colorScheme == light`
     - Default: `false`

- [ ] **Step 4: "White X Drawer" adlı yeni buton ekle**

  1. `White X Ico`'yu duplicate et → adını **"White X Drawer"** yap
  2. Visibility:
     - Rule 1: `user.is_first_daily_open == false`
     - Rule 2: `user.is_discount_eligible == true`
     - Rule 3: `device.colorScheme == light`
  3. Tap Behavior: **Set/Update Variable** → Drawer `Is Open = true`

- [ ] **Step 5: Publish**

  Editor'de **Publish** butonuna bas. Değişiklikler canlıya alınır.

---

## Task 4: Manuel Test

Superwall'un Test Mode özelliği ile simulator'da doğrula.

- [ ] **Step 1: `resetPaywallHistory()` çağır**

  App'i simulator'da aç, debug menüsünden `PaywallManager.shared.resetPaywallHistory()` çalıştır (veya UserDefaults'u sıfırla). Bu sayede `openCount = 0` sıfırlanır.

- [ ] **Step 2: Senaryo 1 — İlk günlük açılma, drawer yok (openCount=0)**

  - App'i aç, paywallı tetikle
  - Beklenen: **Lottie X Black/White** görünür (dark/light mode'a göre), 2sn sonra
  - `is_first_daily_open = true`, `is_discount_eligible = false` (0+1=1, 1%3≠0)
  - X'e bas → **Paywall kapanmalı** (drawer açılmamalı)

- [ ] **Step 3: Senaryo 2 — 2. açılma, drawer yok (openCount=1)**

  - Paywallı tekrar aç
  - Beklenen: **Static X Black/White** görünür (hemen)
  - `is_first_daily_open = false`, `is_discount_eligible = false` (1+1=2, 2%3≠0)
  - X'e bas → **Paywall kapanmalı**

- [ ] **Step 4: Senaryo 3 — 3. açılma, drawer açılmalı (openCount=2)**

  - Paywallı tekrar aç
  - Beklenen: **Static X Black/White** görünür
  - `is_first_daily_open = false`, `is_discount_eligible = true` (2+1=3, 3%3=0)
  - X'e bas → **Exit-offer drawer açılmalı**

- [ ] **Step 5: Senaryo 4 — 4. ve 5. açılma, drawer yok (openCount=3,4)**

  - 4. ve 5. açılmalar
  - Static X → tap → kapanmalı (4+1=5, 5%3≠0; 5+1=6, 6%3=0 → 6. açılma eligible)

- [ ] **Step 6: Senaryo 5 — 6. açılma, drawer açılmalı (openCount=5)**

  - `is_discount_eligible = true` (5+1=6, 6%3=0)
  - X'e bas → drawer açılmalı ✓

- [ ] **Step 7: Ertesi gün simülasyonu**

  `lastDailyPaywallOpenKey` UserDefaults değerini dünün tarihi olarak set et:
  ```swift
  UserDefaults.standard.set(
      Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
      forKey: "last_daily_paywall_open_date"
  )
  ```
  Paywallı aç → **Lottie X** görünmeli, `is_first_daily_open = true`

- [ ] **Step 8: Final commit**

  ```bash
  git add docs/
  git commit -m "docs: add paywall close button drawer logic spec and plan"
  ```

---

## Hızlı Referans — Attribute Tablosu

| `openCount` | 1. günlük mü? | `is_first_daily_open` | `is_discount_eligible` | Görsel | Tap |
|-------------|--------------|----------------------|------------------------|--------|-----|
| 0 | Evet | true | false (1%3≠0) | Lottie | Close |
| 1 | Hayır | false | false (2%3≠0) | Static | Close |
| 2 | Hayır | false | **true** (3%3=0) | Static | **Drawer** |
| 3 | Hayır | false | false (4%3≠0) | Static | Close |
| 4 | Hayır | false | false (5%3≠0) | Static | Close |
| 5 | Hayır | false | **true** (6%3=0) | Static | **Drawer** |
| 6 | Ertesi gün | true | false (7%3≠0) | Lottie | Close |
| 7 | Hayır | false | false (8%3≠0) | Static | Close |
| 8 | Hayır | false | **true** (9%3=0) | Static | **Drawer** |
