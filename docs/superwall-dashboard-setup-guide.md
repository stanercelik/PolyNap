# Superwall Dashboard — X Buton Kurulum Kılavuzu

> **Hedef:** Paywall'daki X butonlarına doğru görünürlük koşulu ve tap davranışı eklemek.
>
> **Dashboard:** `superwall.com` → PolySleep → Paywalls → `free-trial-paywall` → Edit

---

## Mantık Özeti

| Durum | Görünen Buton | Tapa Basınca |
|-------|--------------|-------------|
| Günün ilk açılması (her zaman) | Lottie X | **Drawer açılır** |
| Diğer açılmalar + her 3. açılma | Static X | **Drawer açılır** |
| Diğer açılmalar + 3. açılma değil | Static X | **Paywall kapanır** |

**Lottie her zaman drawer açar** — çünkü Lottie'nin göründüğü koşul (`is_first_daily_open = true`) zaten drawer açma koşulunu da kapsar. Lottie için Close varyantı yok.

**Sonuç: 6 buton** (mevcut 4'ten):
```
▼ Right Buttons
    ▶ Lottie X Black Icon      ← Drawer (first_daily=true, dark)
    ▶ Lottie X White Icon      ← Drawer (first_daily=true, light)
      Black X Icon             ← Close  (first_daily=false, discount=false, dark)
      Black X Drawer           ← Drawer (first_daily=false, discount=true, dark)  ← YENİ
      White X Ico              ← Close  (first_daily=false, discount=false, light)
      White X Drawer           ← Drawer (first_daily=false, discount=true, light) ← YENİ
```

---

## `is_first_daily_open` dropdown'da çıkmıyor — ne yapacaksın?

Superwall yalnızca daha önce bir cihazdan gönderilmiş attribute'ları listeler.
`is_first_daily_open` yeni eklendi, henüz gönderilmedi.

→ **Çözüm:** Rule editöründe attribute alanına `is_first_daily_open` **elle yaz**,
"custom attribute" seçeneğiyle ekle. Değer karşılaştırması: `== true` veya `== false`.
Uygulama bir kez çalışınca otomatik listeye eklenir.

---

## Genel Kavramlar

### Is Visible → Dynamic

Bir elementin görünürlüğünü koşula bağlamak için:

1. Elementi seç → sağ sidebar'da `Is Visible` property'sine tıkla
2. **Dynamic** seç → Dynamic Values editörü açılır
3. **Default değeri `false`** yap (hiçbir koşul sağlanmazsa gizli)
4. **Add Value** → yeni blok, değeri `true`
5. Bu bloğa **Add Rule** ile koşulları ekle (aynı bloktaki kurallar AND ile bağlı)
6. **Done** bas

### Tap Behavior

Sağ sidebar → **Tap Behavior** bölümü → **+ Add Action**

Kullanacağın aksiyonlar:
- **Close** → Paywallı kapatır
- **Set/Update Variable** → Drawer'ın `Is Open` değişkenini `true` yapar

Mevcut aksiyonu silmek için: aksiyonun yanındaki **`...`** → **Remove**

---

## BÖLÜM 1 — Lottie X Black Icon

Tap behavior zaten doğru. Sadece **Is Visible** koşulu eklenecek.

### Adım 1 — Butonu seç

Sol sidebar → `Right Buttons → Lottie X Black Icon`

### Adım 2 — Is Visible → Dynamic

1. Sağ sidebar → `Is Visible` → **Dynamic** seç
2. Default = **`false`**
3. **Add Value** → Value 1 = **`true`**, koşullar:

```
user.is_first_daily_open  ==  true
AND  device.colorScheme   ==  dark
```

4. **Done**

### Adım 3 — Tap Behavior doğrula

`Set "Drawer".isOpen → true` olmalı. **Dokunma**, zaten doğru.

---

## BÖLÜM 2 — Lottie X White Icon

Bölüm 1 ile aynı — tek fark `colorScheme == light`.

### Adım 1 — Butonu seç

Sol sidebar → `Right Buttons → Lottie X White Icon`

### Adım 2 — Is Visible → Dynamic

Default = **`false`**

Value 1 = **`true`**, koşullar:
```
user.is_first_daily_open  ==  true
AND  device.colorScheme   ==  light
```

### Adım 3 — Tap Behavior doğrula

`Set "Drawer".isOpen → true` — dokunma.

---

## BÖLÜM 3 — Black X Icon (Close varyantı — MEVCUT BUTON DÜZELTİLİYOR)

Bu butonun mevcut tap behavior'ı **bozuk** (`Custom Placement → discount-drawer`). Düzeltiyoruz.

### Adım 1 — Butonu seç

Sol sidebar → `Right Buttons → Black X Icon`

### Adım 2 — Tap Behavior'ı düzelt

1. Sağ sidebar → **Tap Behavior** bölümü
2. `Custom Placement → discount-drawer` yanındaki **`...`** → **Remove**
3. **+ Add Action** → **Close** seç

### Adım 3 — Is Visible → Dynamic

Default = **`false`**

Value 1 = **`true`**, koşullar:
```
user.is_first_daily_open   ==  false
AND  user.is_discount_eligible  ==  false
AND  device.colorScheme    ==  dark
```

**Done** bas.

---

## BÖLÜM 4 — Black X Drawer (YENİ BUTON)

### Adım 1 — Black X Icon'u duplicate et

Sol sidebar → `Black X Icon` → **sağ tıkla** → **Duplicate**
Kopyanın adını **`Black X Drawer`** yap (çift tıkla veya sağ tıkla → Rename).

### Adım 2 — Is Visible → Dynamic

Kopyada Is Visible editörünü aç.

Default = **`false`**

Value 1 = **`true`**, koşullar:
```
user.is_first_daily_open   ==  false
AND  user.is_discount_eligible  ==  true
AND  device.colorScheme    ==  dark
```

**Done** bas.

### Adım 3 — Tap Behavior

1. Mevcut `Close` aksiyonunu **Remove** et
2. **+ Add Action** → **Set/Update Variable** seç
3. Açılan formda:
   - **Variable:** `Drawer` element variable'ını seç
     _(Bulamazsan: sol sidebar → Variables sekmesi → "Element Variables" altında `Drawer` adlı entry)_
   - **Property:** `Is Open`
   - **Operation:** `Set`
   - **Value:** `true`

---

## BÖLÜM 5 — White X Ico (Close varyantı — MEVCUT BUTON DÜZELTİLİYOR)

Bölüm 3 ile aynı — `light` mode için.

### Adım 1 — Butonu seç

Sol sidebar → `Right Buttons → White X Ico`

### Adım 2 — Tap Behavior

Varsa `Custom Placement → discount-drawer` aksiyonunu sil → **Close** ekle.
(Yoksa direkt **+ Add Action → Close**)

### Adım 3 — Is Visible → Dynamic

Default = **`false`**

Value 1 = **`true`**, koşullar:
```
user.is_first_daily_open   ==  false
AND  user.is_discount_eligible  ==  false
AND  device.colorScheme    ==  light
```

---

## BÖLÜM 6 — White X Drawer (YENİ BUTON)

Bölüm 4 ile aynı — `light` mode için.

### Adım 1 — White X Ico'yu duplicate et → adı: `White X Drawer`

### Adım 2 — Is Visible → Dynamic

Default = **`false`**

Value 1 = **`true`**, koşullar:
```
user.is_first_daily_open   ==  false
AND  user.is_discount_eligible  ==  true
AND  device.colorScheme    ==  light
```

### Adım 3 — Tap Behavior

`Close` aksiyonunu sil → **Set/Update Variable** → `Drawer.Is Open = true`

---

## Son Adım — Publish

Editor'de **Publish** butonuna bas.

---

## Doğrulama Tablosu

Her butonu seçip şunu kontrol et:

| Buton | Is Visible | Tap Behavior |
|-------|-----------|-------------|
| Lottie X Black Icon | `first_daily=true AND dark` | Set Drawer.isOpen = true |
| Lottie X White Icon | `first_daily=true AND light` | Set Drawer.isOpen = true |
| Black X Icon | `first_daily=false AND discount=false AND dark` | Close |
| Black X Drawer | `first_daily=false AND discount=true AND dark` | Set Drawer.isOpen = true |
| White X Ico | `first_daily=false AND discount=false AND light` | Close |
| White X Drawer | `first_daily=false AND discount=true AND light` | Set Drawer.isOpen = true |

---

## Sık Karşılaşılan Sorunlar

**`user.is_first_daily_open` dropdown'da yok**
→ Elle yaz. "custom attribute" olarak ekle, `true`/`false` boolean.

**Drawer variable'ı bulamıyorum**
→ Sol sidebar → Variables sekmesi → Element Variables → `Drawer` adlı entry.
Oradaki tam adı note al, Set/Update Variable aksiyonunda o adı seç.

**Duplicate yapınca tap behavior da kopyalanıyor mu?**
→ Evet, her şey kopyalanır. Bu yüzden her bölümde tap behavior değiştirmeyi unutma.

**Koşullar AND mı OR mu?**
→ Aynı Value bloğu içindeki kurallar **AND**. Farklı Value blokları **OR** gibi çalışır (yukarıdan aşağı, ilk eşleşen kazanır).

---

> Takıldığın adımın ekran görüntüsünü at, devam ederiz.
