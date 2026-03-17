# Behavioral Nudge Engine Inceleme Raporu (PolyNap)

Bu rapor, uygulamayi davranissal psikoloji odakli nudge (itki) sistemi acisindan inceledikten sonra hazirlandi. Hedef: kullanicinin adaptasyon surecini daha az zorlayici, daha motive edici ve daha olcumlenebilir hale getirmek.

## Kisa Sonuc

Evet, yapilacak cok degerli iyilestirmeler var. Uygulamada temel bilesenler mevcut (onboarding, alarm, hatirlatici, analytics, HRV verisi), ancak bunlar henuz tek bir kisisellestirilmis nudge motoru altinda birlesmiyor.

## Mevcut Durum - Guclu Yonler

- Onboarding'te motivasyon, hedef, sosyal yuk ve tolerans gibi psikolojik sinyaller toplaniyor.
- Alarm ve hatirlatici altyapisi hazir, plan bazli yeniden zamanlama yapiliyor.
- Adherence, HRV, kalp hizi, sleep stages gibi metrikler analytics tarafinda hesaplanabiliyor.
- Streak, badge, gunluk tip gibi motivasyon bilesenleri var.

## Tespit Edilen Bosluklar (Oncelikli)

1. **Kisisellestirme verisi toplaniyor ama nudge kararlarina baglanmiyor**
   - Onboarding cevaplari plan onerisinde kullaniliyor, ancak gunluk hatirlatici tonu/zamani/icerigi buna gore degismiyor.
   - Etki: kullaniciya ayni mesaj stili gidiyor, davranis degisikligi etkisi dusuyor.

2. **Bildirimler agirlikla tek tip ve statik**
   - Hatirlatici metni saat + program adi odakli; kullanicinin bugunku durumu (adherence, gecikme, yorgunluk) dahil degil.
   - Etki: eyleme donusen "tek sonraki adim" yonlendirmesi zayif.

3. **Gunluk tip random, davranis baglami yok**
   - Tip secimi kullanici hedefi/adaptasyon fazi/son performans ile iliskilendirilmiyor.
   - Etki: bilgi var ama davranisa ceviren yonlendirme zayif.

4. **Streak gercek davranis yerine takvim gunune dayaniyor**
   - Adaptasyon baslangicindan bugune kadar olan gunler "tamamlandi" gibi gorunuyor.
   - Etki: yanlis pekistirme, guven ve motivasyon kaybi riski.

5. **Sleep quality bildirim akisinda eksik tamamlama noktasi var**
   - Bildirimden gelen kalite puaninin kalici kaydi TODO durumda.
   - Etki: geri besleme dongusu kiriliyor, nudge motoru ogrenemiyor.

6. **HRV var ama aksiyon ureten motor yok**
   - HRV analytics'te gosteriliyor; ancak adherence/adaptasyonla birlestirilip otomatik oneriye donusmuyor.
   - Etki: kullanicinin "ne yapmaliyim" sorusuna cevap eksik kaliyor.

7. **Nudge performans olcumu eksik**
   - Notification opened/acted, nudge accepted/rejected, suggested action completed gibi event zinciri tam degil.
   - Etki: hangi mesajin ise yaradigi ogrenilemiyor.

8. **Lokalizasyon tutarliligi eksikleri**
   - Bazi ekranlarda sabit Turkce metinler var; tum nudge icerigi TR/EN tam kapsanmiyor.
   - Etki: dil degisince deneyim parcali hale geliyor.

## Onerilen Gelistirme Plani

### P0 - Temel Nudge Altyapisi (1-2 hafta)

1. **NudgeProfile modeli ekleyin**
   - Alanlar: `preferredTone`, `notificationCadence`, `quietHours`, `motivationTrigger`, `lastNudgeResponse`, `fatigueScore`.
   - Kaynak: onboarding + davranis gecmisi.

2. **"Next Best Action" kural motoru ekleyin**
   - Her an sadece 1 oneri dondursun (or: "Bugun sadece bir sonraki nap'i zamaninda baslat").
   - Kural girdileri: adherence (son 3 gun), son gecikme, ertelenen kalite puani, HRV recovery.

3. **Nudge turlerini mikro-sprint formatina cevirin**
   - "Tum programa uy" yerine "Onumuzdeki 5 dakikada su tek adimi yap".
   - Her nudge sonunda off-ramp: "5 dk daha mi, bugunluk bu kadar mi?"

### P1 - Adaptif Hatirlatici ve Kopya Motoru (2-4 hafta)

1. **Hatirlatici lead time'i dinamik yapin**
   - Yuksek gecikme varsa +5/+10 dk erken; ust uste basari varsa daha sade/az bildirim.

2. **Mesaj tonunu profile gore degistirin**
   - Yuksek motivasyon: hedef odakli.
   - Dusuk motivasyon/overwhelm: minimum adim + guvence odakli.

3. **Duruma duyarlı bildirim govdesi**
   - Ornek: "Dun 12 dk gec kaldin. Bugun sadece bu nap'i zamaninda baslatman yeterli."

### P2 - HRV + Adherence Birlesik Toparlanma Skoru (3-6 hafta)

1. **Recovery score = HRV trend + adherence + subjective quality**
   - Sadece HRV SDNN normalizasyonu yerine trend ve davranis verisi ekleyin.

2. **Koruyucu guardrail nudgeleri**
   - Dusuk recovery 2-3 gun: daha yumusak plan, nap kisaltma/erteleme onerisi, alarm yogunlugu azaltma.

3. **Watch tarafinda HRV okuma ve senkronizasyon**
   - WatchHealthKit tarafinda HRV read + iOS tarafina context aktarma.

## Hizli Kazanimlar (Low Effort / High Impact)

1. Sleep quality bildirim aksiyonundaki kaydetme TODO'sunu tamamlayin.
2. Streak hesaplamasini gercek tamamlanan bloklara baglayin.
3. Snooze suresini sabit 5 dk yerine kullanici ayarina baglayin.
4. Tum alarm/nudge metinlerini TR/EN localizable anahtarlarina cekin.
5. Notification funnel event'lerini ekleyin: delivered -> opened -> actioned -> completed.

## Onerilen Event Seti (Nudge Analytics)

- `nudge_generated` (type, reason, confidence, recommended_action)
- `nudge_delivered` (channel, local_time, lead_time)
- `nudge_opened`
- `nudge_action_tapped` (accept/edit/dismiss/snooze)
- `nudge_outcome` (completed/partial/skipped, completion_delay_min)
- `recovery_guardrail_triggered` (hrv_delta, adherence_3d, quality_3d)

## Dosya Bazli Teknik Notlar

- `polynap/Models/UserPreferences.swift`
  - Nudge profil alanlari eklenmeli (cadence, tone, quiet hours, trigger type).

- `polynap/Screen/NewOnboarding/ViewModels/NewOnboardingViewModel.swift`
  - Toplanan psikolojik sinyallerin nudge profile bootstrap'ina yazilmasi gerekir.

- `polynap/Services/AlarmService.swift`
  - Statik reminder govdesi yerine context-aware govde uretilmeli.
  - Snooze suresi kullanici ayarindan alinmali.

- `polynap/Screen/MainScreen/Models/DailyTipManager.swift`
  - Random tip yerine "bugunun tek adimi" secimi yapan kural katmani eklenmeli.

- `polynap/Views/SleepQuality/SleepQualityNotificationManager.swift`
  - Bildirimden gelen kalite puani persistence + analytics entegrasyonu tamamlanmali.

- `polynap/Screen/Analytics/AnalyticsViewModel.swift`
  - HRV recovery hesaplamasi adherence + kalite ile birlestirilmeli.

- `PolyNap Watch Extension/Services/WatchHealthKitManager.swift`
  - HRV read type + fetch akisi eklenmeli.

## Basari Kriterleri

- 2 hafta: nudge acilma orani +%15
- 4 hafta: ilk 7 gun adherence +%10
- 6 hafta: ertelenen sleep quality rating oraninda %20 azalis
- 8 hafta: D7 retention +%5 ve "overwhelm" geri bildirimi azalisi

## Son Not

PolyNap'in elinde davranissal nudge icin guclu bir temel var. Asil carpani, bu metrikleri tek bir "dogru zamanda tek dogru adim" motorunda birlestirmek olacak. Once P0 + hizli kazanimlari tamamlamak, sonra HRV/adherence tabanli adaptif nudge katmanina gecmek en dogru yol.
