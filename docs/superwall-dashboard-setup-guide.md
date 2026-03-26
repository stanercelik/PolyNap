# Superwall Dashboard — X Buton Kurulum Kılavuzu

> **Hedef:** Paywall'daki 4 X butonunu 8'e çıkarıp her birine doğru görünürlük koşulu ve tap davranışı eklemek.
>
> **Dashboard:** `superwall.com` → PolySleep → Paywalls → `free-trial-paywall` → Edit

---

## Önce: `is_first_daily_open` attribute'u neden görünmüyor?

Superwall, dropdown'da sadece daha önce en az bir cihazdan gönderilmiş attribute'ları listeler.
`is_first_daily_open` yeni eklendi, henüz gönderilmedi. **Çözüm:** Rule editörüne attribute adını
**elle yazacaksın** — dropdown seçmek zorunda değilsin, manuel yazınca Superwall kabul eder.

---

## Genel Kurallar (Okumadan Geçme)

### Dynamic Value nedir?

Bir elementin herhangi bir property'si (görünürlük, renk, metin, vs.) koşula bağlanabilir.
Bunu yapmak için property'ye tıklayıp **Dynamic** seçiyorsun. Açılan editörde şu yapıyı kuruyorsun:

```
if (koşul)
  → bu değeri kullan   ← "Value 1"
else
  → şu değeri kullan   ← default / "Add Value" ile eklenir
```

**Is Visible** property'si `true` veya `false` alır:
- `true` → element görünür
- `false` → element gizli

### Tap Behavior nedir?

Bir butona/elementa tıklandığında ne olacağını tanımlar.
Seçili elementin sağ sidebar'ında **Tap Behavior** bölümü bulunur.
**+ Add Action** ile aksiyon eklenir, birden fazla aksiyon zincirlenir.

Kullanacağımız aksiyonlar:
- **Close** → Paywallı kapatır
- **Set/Update Variable** → Drawer'ın `Is Open` değişkenini `true` yapar (drawer açılır)

### `user.is_first_daily_open` nasıl yazılır?

Rule editöründe attribute seçerken arama kutusuna `is_first_daily_open` yaz.
Dropdown'da çıkmazsa **"Custom"** veya **"Enter to add"** seçeneğini kullan.
Değer karşılaştırması: `== true` veya `== false`

---

## Başlamadan Önce — Layout Kontrolü

Sol sidebar'da `Right Buttons` grubunu aç. Şu an 4 buton olmalı:

```
▼ Right Buttons
    ▶ Lottie X Black Icon   (eye-slash = hidden)
      Black X Icon
    ▶ Lottie X White Icon   (eye-slash = hidden)
      White X Ico            (eye-slash = hidden)
```

Bu kılavuzun sonunda 8 buton olacak:

```
▼ Right Buttons
    ▶ Lottie X Black Icon        ← Drawer (first_daily=true, discount=true, dark)
    ▶ Lottie X Black Close       ← Close  (first_daily=true, discount=false, dark)
      Black X Icon               ← Close  (first_daily=false, discount=false, dark)
      Black X Drawer             ← Drawer (first_daily=false, discount=true, dark)
    ▶ Lottie X White Icon        ← Drawer (first_daily=true, discount=true, light)
    ▶ Lottie X White Close       ← Close  (first_daily=true, discount=false, light)
      White X Ico                ← Close  (first_daily=false, discount=false, light)
      White X Drawer             ← Drawer (first_daily=false, discount=true, light)
```

---

## BÖLÜM 1 — Lottie X Black Icon (Drawer varyantı)

Bu butonun tap behavior'ı zaten doğru (`Set "Drawer".isOpen = true`). Sadece **Is Visible** koşulunu ekleyeceğiz.

### Adım 1 — Butonu seç

Sol sidebar'da `Right Buttons → Lottie X Black Icon`'a **tıkla**.
Sağ sidebar'da bu elementin property'leri görünür.

### Adım 2 — Is Visible'ı Dynamic yap

Sağ sidebar'da `Is Visible` property'sini bul.
Şu an muhtemelen sabit `false` (gizli, eye-slash var).

1. `Is Visible` property'sine tıkla
2. Açılan dropdown'dan **Dynamic** seç
3. Dynamic Values editörü açılır

### Adım 3 — Default değeri false yap

Editörde ilk gördüğün "Value 1" kutucuğu — bu **default** (koşul yokken ne dönsün).
Bu değeri **`false`** olarak ayarla. (Hiçbir koşul sağlanmazsa gizli kalacak.)

### Adım 4 — Koşullu `true` değeri ekle

**Add Value** butonuna bas → yeni bir değer bloğu eklenir.
Bu yeni bloğun değerini **`true`** olarak ayarla.

Şimdi bu bloğa **3 koşul** ekleyeceğiz (hepsi AND ile bağlı):

**Koşul 1:**
1. **Add Rule** bas
2. Sol taraf (attribute): `user.is_first_daily_open` — elle yaz, dropdown'da yoksa "custom" seç
3. Operator: `==`
4. Sağ taraf (değer): `true`

**Koşul 2:**
1. Tekrar **Add Rule** bas (aynı bloğa, bir alt satıra eklenir — AND ile bağlı)
2. Sol taraf: `user.is_discount_eligible`
3. Operator: `==`
4. Sağ taraf: `true`

**Koşul 3:**
1. Tekrar **Add Rule** bas
2. Sol taraf: `device.colorScheme`
3. Operator: `==`
4. Sağ taraf: `dark`

Sonuç şu şekilde görünmeli:
```
Value 1 = true
  WHEN:
    user.is_first_daily_open == true
    AND user.is_discount_eligible == true
    AND device.colorScheme == dark

Default = false
```

### Adım 5 — Kaydet

**Done** butonuna bas. Is Visible üzerinde artık ⚙ (gear) ikonu görünür — dynamic value set edildi demek.

### Adım 6 — Tap Behavior'ı doğrula

Sağ sidebar'da **Tap Behavior** bölümüne bak.
`Set "Drawer".isOpen → true` olmalı. **Dokunma**, zaten doğru.

---

## BÖLÜM 2 — Lottie X Black Close (yeni buton)

### Adım 1 — Lottie X Black Icon'u duplicate et

Sol sidebar'da `Lottie X Black Icon`'a **sağ tıkla** → **Duplicate** seç.
Bir kopya oluşur, muhtemelen "Lottie X Black Icon copy" adıyla.

### Adım 2 — Adını değiştir

Kopyaya **çift tıkla** (veya sağ tıkla → Rename) → adını **`Lottie X Black Close`** yap.

### Adım 3 — Is Visible koşulunu güncelle

Kopyayı seç → `Is Visible` → Dynamic editörü aç.

**Sadece Koşul 2'yi değiştir:**
- `user.is_discount_eligible == true` → `user.is_discount_eligible == false`

Koşul 1 ve 3 aynı kalır:
- `user.is_first_daily_open == true`
- `device.colorScheme == dark`

Sonuç:
```
Value 1 = true
  WHEN:
    user.is_first_daily_open == true
    AND user.is_discount_eligible == false
    AND device.colorScheme == dark

Default = false
```

**Done** bas.

### Adım 4 — Tap Behavior'ı değiştir

Sağ sidebar'da **Tap Behavior** bölümünü aç.

1. Mevcut aksiyon `Set "Drawer".isOpen = true` yanındaki **`...`** (üç nokta) → **Remove** (veya çöp kutusu ikonu)
2. **+ Add Action** bas
3. Listeden **Close** seç

Sonuç: Tap Behavior = `Close`

---

## BÖLÜM 3 — Lottie X White Icon (Drawer varyantı)

Bölüm 1 ile aynı, tek fark `device.colorScheme == light`.

### Adım 1 — Lottie X White Icon'u seç

### Adım 2 — Is Visible → Dynamic

Default = `false`

Value 1 = `true`, koşullar:
```
user.is_first_daily_open == true
AND user.is_discount_eligible == true
AND device.colorScheme == light
```

### Adım 3 — Tap Behavior doğrula

`Set "Drawer".isOpen = true` — dokunma.

---

## BÖLÜM 4 — Lottie X White Close (yeni buton)

Bölüm 2 ile aynı, `light` mode için.

### Adım 1 — Lottie X White Icon'u duplicate et → adı: `Lottie X White Close`

### Adım 2 — Is Visible koşulu

```
user.is_first_daily_open == true
AND user.is_discount_eligible == false
AND device.colorScheme == light
```

### Adım 3 — Tap Behavior

Mevcut aksiyonu sil → **Close** ekle.

---

## BÖLÜM 5 — Black X Icon (Close varyantı — MEVCUT BUTON)

Bu butonun şu anki tap behavior'ı **bozuk** (`Custom Placement → discount-drawer`). Hem bunu düzelteceğiz hem de visibility koşulu ekleyeceğiz.

### Adım 1 — Black X Icon'u seç

### Adım 2 — Tap Behavior'ı düzelt

Sağ sidebar → **Tap Behavior** bölümü.

Mevcut aksiyon `Custom Placement → discount-drawer` yanındaki **`...`** → **Remove**.

**+ Add Action** → **Close** seç.

### Adım 3 — Is Visible → Dynamic

Default = `false`

Value 1 = `true`, koşullar:
```
user.is_first_daily_open == false
AND user.is_discount_eligible == false
AND device.colorScheme == dark
```

**Done** bas.

---

## BÖLÜM 6 — Black X Drawer (yeni buton)

### Adım 1 — Black X Icon'u duplicate et → adı: `Black X Drawer`

### Adım 2 — Is Visible koşulu

```
user.is_first_daily_open == false
AND user.is_discount_eligible == true
AND device.colorScheme == dark
```

### Adım 3 — Tap Behavior

Mevcut `Close` aksiyonunu sil.

**+ Add Action** → **Set/Update Variable** seç.

Açılan ekranda:
1. **Variable** alanına tıkla → `Drawer` isimli element variable'ı seç (Variables tabında görünür, adı `Drawer` veya paywall'daki drawer elementinin adı neyse)
2. **Property:** `Is Open`
3. **Operation:** `Set`
4. **Value:** `true`

> **Not:** Drawer variable'ını bulamazsan: sol sidebar'ın üstündeki **Variables** sekmesine geç → orada `Drawer` adlı bir element variable olmalı. Adını not al, Tap Behavior'da o adla ara.

---

## BÖLÜM 7 — White X Ico (Close varyantı — MEVCUT BUTON)

Bölüm 5 ile aynı, `light` mode için.

### Adım 1 — White X Ico'yu seç

### Adım 2 — Tap Behavior

Varsa `Custom Placement → discount-drawer` aksiyonunu sil → **Close** ekle.

### Adım 3 — Is Visible → Dynamic

```
user.is_first_daily_open == false
AND user.is_discount_eligible == false
AND device.colorScheme == light
```

---

## BÖLÜM 8 — White X Drawer (yeni buton)

### Adım 1 — White X Ico'yu duplicate et → adı: `White X Drawer`

### Adım 2 — Is Visible koşulu

```
user.is_first_daily_open == false
AND user.is_discount_eligible == true
AND device.colorScheme == light
```

### Adım 3 — Tap Behavior

Close sil → **Set/Update Variable** → `Drawer.Is Open = true`

---

## Son Adım — Publish

Sol üstte **Publish** butonuna bas. Değişiklikler canlıya alınır.

---

## Doğrulama — Her buton için kontrol listesi

Bitmeden önce her butonu seç ve şunu kontrol et:

| Buton | Is Visible Koşulu | Tap Behavior |
|-------|-------------------|-------------|
| Lottie X Black Icon | `first_daily=true, discount=true, dark` | Set Drawer.isOpen = true |
| Lottie X Black Close | `first_daily=true, discount=false, dark` | Close |
| Lottie X White Icon | `first_daily=true, discount=true, light` | Set Drawer.isOpen = true |
| Lottie X White Close | `first_daily=true, discount=false, light` | Close |
| Black X Icon | `first_daily=false, discount=false, dark` | Close |
| Black X Drawer | `first_daily=false, discount=true, dark` | Set Drawer.isOpen = true |
| White X Ico | `first_daily=false, discount=false, light` | Close |
| White X Drawer | `first_daily=false, discount=true, light` | Set Drawer.isOpen = true |

---

## Sık Karşılaşılan Sorunlar

### `user.is_first_daily_open` dropdown'da yok

→ Elle yaz. Rule editöründe attribute alanına `is_first_daily_open` yaz, "custom attribute" olarak ekle. Değer `true` / `false` (boolean). Uygulama çalıştırılınca otomatik listeye eklenir.

### Drawer variable'ı bulamıyorum

→ Sol sidebar → **Variables** sekmesi → "Element Variables" altında `Drawer` adlı bir entry olmalı. Oradaki tam adı not alıp Set/Update Variable aksiyonunda o adı seç.

### Duplicate yapınca tap behavior da kopyalanıyor mu?

→ Evet. Duplicate her şeyi kopyalar (visibility + tap behavior + style). Bu yüzden her bölümde tap behavior'ı değiştirmeyi unutma.

### Koşullar AND mı OR mu bağlanıyor?

→ Aynı "Value" bloğu içindeki kurallar **AND** ile bağlanır. Farklı "Value" blokları **OR** gibi çalışır (ilk eşleşen kazanır, yukarıdan aşağı).

---

> Takıldığın adımın ekran görüntüsünü at, devam ederiz.
