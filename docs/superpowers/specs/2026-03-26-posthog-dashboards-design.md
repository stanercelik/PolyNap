# PostHog Analytics Dashboards & Funnels — Design Spec

## Goal

Mevcut PostHog event'lerini kullanarak 3 dashboard + 4 ana funnel oluşturmak. Kod değişikliği gerekmez — tüm event'ler zaten `AnalyticsManager` tarafından gönderiliyor.

## Mevcut Event Envanteri

| Kategori | Event'ler |
|----------|-----------|
| App Lifecycle | `app_open`, `app_background`, `app_foreground` |
| Onboarding | `onboarding_started`, `onboarding_screen_viewed`, `onboarding_step_completed`, `onboarding_step_back`, `onboarding_skipped`, `onboarding_completed` |
| Permissions | `permission_requested`, `permission_result` |
| Schedule | `schedule_selected`, `schedule_changed`, `schedule_successfully_applied` |
| Sleep | `sleep_entry_added`, `sleep_quality_rated` |
| Alarm | `alarm_set`, `alarm_triggered`, `alarm_stopped` |
| Revenue | `paywall_viewed`, `purchase_attempt`, `purchase_completed` |
| Nudge | `nudge_generated`, `nudge_delivered`, `nudge_opened`, `nudge_action_tapped`, `nudge_outcome` |
| Engagement | `notification_opened`, `setting_changed`, `feature_used`, `user_retention` |

## Dashboard 1: Onboarding

### Ana Funnel
```
onboarding_started
  → onboarding_screen_viewed (section = "story")
  → onboarding_screen_viewed (section = "questions")
  → onboarding_completed
  → paywall_viewed
```

### Ek Insight'lar
- **Ekran bazlı drop-off**: `onboarding_screen_viewed` event'lerini `screen_index` bazında breakdown → hangi ekranda kullanıcı kaybediliyor
- **Skip oranı**: `onboarding_skipped` / `onboarding_started` trend
- **Kullanıcı profili dağılımı**: `onboarding_step_completed` events, `answer_value` property breakdown (chronotype, sleep_goal, age_range)
- **Ortalama tamamlama süresi**: `onboarding_started` → `onboarding_completed` arasındaki süre
- **Geri dönme analizi**: `onboarding_step_back` count — hangi ekranlardan geri dönülüyor

## Dashboard 2: Revenue

### Ana Funnel
```
paywall_viewed
  → purchase_attempt
  → purchase_completed
```

### Ek Insight'lar
- **Paywall kaynak dağılımı**: `paywall_viewed` events, `source` property breakdown
- **Ürün bazlı conversion**: `purchase_completed`, `product_id` breakdown
- **Revenue trend**: `purchase_completed`, günlük/haftalık trend
- **Drop-off noktası**: `paywall_viewed` → `purchase_attempt` arası kayıp

## Dashboard 3: Retention & Engagement

### Ana Funnel (Activation)
```
app_open (first_time_user = true)
  → onboarding_completed
  → sleep_entry_added (is_first_entry = true)
  → app_open [D7 retention]
```

### Nudge Effectiveness Funnel
```
nudge_delivered
  → nudge_opened
  → nudge_action_tapped
  → nudge_outcome (outcome = "completed")
```

### Ek Insight'lar
- **D1/D7/D30 retention**: Lifecycle analizi — `app_open` events cohort analizi
- **Sleep entry frequency**: `sleep_entry_added` / aktif kullanıcı başına
- **Alarm kullanımı**: `alarm_set` → `alarm_triggered` → `alarm_stopped` oranı
- **Schedule bağlılığı**: `schedule_successfully_applied`, `days_used` dağılımı
- **Nudge open rate**: `nudge_delivered` → `nudge_opened` conversion

## Önceliklendirme

1. Onboarding Dashboard (en yüksek etki — dönüşüm funnel'ının başlangıcı)
2. Revenue Dashboard (direkt gelir ölçümü)
3. Retention & Engagement Dashboard (uzun vadeli sağlık)
