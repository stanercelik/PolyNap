# Paywall Close Button & Discount Drawer Logic

## Goal

Paywall'daki X (close) butonları iki bağımsız koşula göre davranacak:
1. **Görsel:** Günün ilk açılmasında Lottie X (2sn delay), diğerlerinde Static X
2. **Davranış:** Her 3. toplam açılmada (3, 6, 9...) drawer açılır; diğerlerinde paywall kapanır

## Mevcut Durum (Sorunlar)

- `is_discount_eligible` tek attribute olarak `isFirstToday || isEveryThird` hesaplanıyor
- Lottie/Static görsel ayrımı ile Drawer/Close davranış ayrımı aynı attribute'a bağlı → bağımsız kontrol edilemiyor
- Static X butonları `Custom Placement → discount-drawer` tetikliyor ama bu campaign'in placement'ı yok → hiçbir şey olmuyor

## Çözüm

### Kod — İki ayrı attribute

| Attribute | Değer | Kullanım |
|-----------|-------|----------|
| `is_first_daily_open` | `isFirstPaywallOpenToday()` | Lottie vs Static görünürlüğü |
| `is_discount_eligible` | `(openCount + 1) % 3 == 0` | Drawer vs Close tap davranışı |

Her ikisi de `presentPaywall()` içinde, `incrementPaywallOpenCount()` çağrısından **önce** set edilir.

### Dashboard — 8 buton

Mevcut 4 buton, her biri "Drawer" ve "Close" olmak üzere ikiye ayrılır:

| Buton | Görünürlük | Tap |
|-------|-----------|-----|
| Lottie X Black — Drawer | `is_first_daily_open == true AND is_discount_eligible == true AND dark` | Set Drawer.isOpen = true |
| Lottie X Black — Close | `is_first_daily_open == true AND is_discount_eligible == false AND dark` | Close |
| Lottie X White — Drawer | `is_first_daily_open == true AND is_discount_eligible == true AND light` | Set Drawer.isOpen = true |
| Lottie X White — Close | `is_first_daily_open == true AND is_discount_eligible == false AND light` | Close |
| Static X Black — Drawer | `is_first_daily_open == false AND is_discount_eligible == true AND dark` | Set Drawer.isOpen = true |
| Static X Black — Close | `is_first_daily_open == false AND is_discount_eligible == false AND dark` | Close |
| Static X White — Drawer | `is_first_daily_open == false AND is_discount_eligible == true AND light` | Set Drawer.isOpen = true |
| Static X White — Close | `is_first_daily_open == false AND is_discount_eligible == false AND light` | Close |

Her an sadece 1 buton görünür durumdadır.

## Kapsam Dışı

- Drawer içeriği değiştirilmeyecek
- Campaign yapısı değiştirilmeyecek
- Diğer paywall davranışları değiştirilmeyecek
