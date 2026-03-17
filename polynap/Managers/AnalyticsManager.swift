import Foundation
import PostHog

class AnalyticsManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = AnalyticsManager()
    
    private init() {}
    
    // MARK: - Core Analytics Methods
    
    func logEvent(_ name: String, parameters: [String: Any]? = nil) {
        PostHogSDK.shared.capture(name, properties: parameters)
        #if DEBUG
        print("📊 Analytics: \(name)\(parameters != nil ? " - \(parameters!)" : "")")
        #endif
    }
    
    func logScreenView(screenName: String, screenClass: String) {
        PostHogSDK.shared.capture("screen_view", properties: [
            "screen_name": screenName,
            "screen_class": screenClass
        ])
    }
    
    func setUserProperty(_ name: String, value: String?) {
        PostHogSDK.shared.identify(
            PostHogSDK.shared.getDistinctId(),
            userProperties: [name: value ?? NSNull()]
        )
    }
    
    func setUserId(_ userId: String?) {
        if let userId = userId {
            PostHogSDK.shared.identify(userId)
        } else {
            PostHogSDK.shared.reset()
        }
    }
    
    // MARK: - App Lifecycle Events
    
    func logAppOpen() {
        logEvent("app_open")
    }
    
    func logAppBackground() {
        logEvent("app_background")
    }
    
    func logAppForeground() {
        logEvent("app_foreground")
    }
    
    // MARK: - Onboarding Events
    
    func logOnboardingStarted() {
        logEvent("onboarding_started")
    }
    
    func logOnboardingSkipped(atScreen: String? = nil, screenIndex: Int? = nil) {
        var params: [String: Any] = [
            "default_schedule_set": true
        ]
        if let screen = atScreen { params["at_screen"] = screen }
        if let index = screenIndex { params["screen_index"] = index }
        logEvent("onboarding_skipped", parameters: params)
    }
    
    func logOnboardingCompleted(timeTaken: TimeInterval? = nil, stepsCompleted: Int? = nil, selectedSchedule: String? = nil) {
        var parameters: [String: Any] = [:]
        if let time = timeTaken { parameters["total_time_spent"] = Int(time) }
        if let steps = stepsCompleted { parameters["steps_completed"] = steps }
        if let schedule = selectedSchedule { parameters["selected_schedule"] = schedule }
        logEvent("onboarding_completed", parameters: parameters.isEmpty ? nil : parameters)
    }
    
    func logOnboardingScreenViewed(screenName: String, screenIndex: Int, section: String, progressPct: Int) {
        logEvent("onboarding_screen_viewed", parameters: [
            "screen_name": screenName,
            "screen_index": screenIndex,
            "section": section,
            "progress_pct": progressPct
        ])
    }
    
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
    
    func logOnboardingStepBack(fromScreen: String, toScreen: String) {
        logEvent("onboarding_step_back", parameters: [
            "from_screen": fromScreen,
            "to_screen": toScreen
        ])
    }
    
    // MARK: - Sleep Schedule Events
    
    func logScheduleSelected(scheduleName: String, difficulty: String) {
        logEvent("schedule_selected", parameters: [
            "schedule_name": scheduleName,
            "difficulty_level": difficulty
        ])
    }
    
    func logScheduleChanged(fromSchedule: String, toSchedule: String, reason: String? = nil) {
        var parameters: [String: Any] = [
            "from_schedule": fromSchedule,
            "to_schedule": toSchedule
        ]
        if let reason = reason {
            parameters["change_reason"] = reason
        }
        logEvent("schedule_changed", parameters: parameters)
    }
    
    // MARK: - Sleep Entry Events
    
    func logSleepEntryAdded(sleepType: String, duration: Int, quality: Int? = nil) {
        var parameters: [String: Any] = [
            "sleep_type": sleepType,
            "duration_minutes": duration
        ]
        if let quality = quality {
            parameters["quality_rating"] = quality
        }
        logEvent("sleep_entry_added", parameters: parameters)
    }
    
    func logSleepEntryAdded(sleepType: String, duration: Int, quality: Double? = nil, isFirstEntry: Bool = false) {
        var parameters: [String: Any] = [
            "sleep_type": sleepType,
            "duration_minutes": duration,
            "is_first_entry": isFirstEntry
        ]
        if let quality = quality {
            parameters["quality_rating"] = quality
        }
        logEvent("sleep_entry_added", parameters: parameters)
    }
    
    func logSleepQualityRated(rating: Double, sleepType: String) {
        logEvent("sleep_quality_rated", parameters: [
            "rating": rating,
            "sleep_type": sleepType
        ])
    }
    
    // MARK: - Alarm Events
    
    func logAlarmSet(alarmType: String, soundName: String) {
        logEvent("alarm_set", parameters: [
            "alarm_type": alarmType,
            "sound_name": soundName
        ])
    }
    
    func logAlarmTriggered() {
        logEvent("alarm_triggered")
    }
    
    func logAlarmStopped(snoozeUsed: Bool = false) {
        logEvent("alarm_stopped", parameters: [
            "snooze_used": snoozeUsed
        ])
    }
    
    // MARK: - Premium/Revenue Events
    
    func logPaywallViewed(source: String, placement: String? = nil) {
        var parameters: [String: Any] = ["source": source]
        if let placement = placement {
            parameters["placement"] = placement
        }
        logEvent("paywall_viewed", parameters: parameters)
    }
    
    func logPurchaseAttempt(productId: String, source: String) {
        logEvent("purchase_attempt", parameters: [
            "product_id": productId,
            "source": source
        ])
    }
    
    func logPurchaseSuccess(productId: String, revenue: Double, currency: String) {
        logEvent("purchase_completed", parameters: [
            "product_id": productId,
            "revenue": revenue,
            "currency": currency
        ])
    }
    
    // MARK: - User Engagement Events
    
    func logNotificationOpened(notificationType: String) {
        logEvent("notification_opened", parameters: [
            "notification_type": notificationType
        ])
    }
    
    func logNudgeGenerated(type: String, reason: String, confidence: Double, recommendedAction: String) {
        logEvent("nudge_generated", parameters: [
            "type": type,
            "reason": reason,
            "confidence": confidence,
            "recommended_action": recommendedAction
        ])
    }
    
    func logNudgeDelivered(channel: String, localTime: String, leadTime: Int, type: String) {
        logEvent("nudge_delivered", parameters: [
            "channel": channel,
            "local_time": localTime,
            "lead_time": leadTime,
            "type": type
        ])
    }
    
    func logNudgeOpened(type: String) {
        logEvent("nudge_opened", parameters: [
            "type": type
        ])
    }
    
    func logNudgeActionTapped(type: String, action: String) {
        logEvent("nudge_action_tapped", parameters: [
            "type": type,
            "action": action
        ])
    }
    
    func logNudgeOutcome(type: String, outcome: String, completionDelayMinutes: Int?) {
        var parameters: [String: Any] = [
            "type": type,
            "outcome": outcome
        ]
        if let completionDelayMinutes {
            parameters["completion_delay_min"] = completionDelayMinutes
        }
        logEvent("nudge_outcome", parameters: parameters)
    }
    
    func logRecoveryGuardrailTriggered(hrvDelta: Double?, adherence3d: Double, quality3d: Double) {
        var parameters: [String: Any] = [
            "adherence_3d": adherence3d,
            "quality_3d": quality3d
        ]
        if let hrvDelta {
            parameters["hrv_delta"] = hrvDelta
        }
        logEvent("recovery_guardrail_triggered", parameters: parameters)
    }
    
    func logSettingChanged(settingName: String, oldValue: String, newValue: String) {
        logEvent("setting_changed", parameters: [
            "setting_name": settingName,
            "old_value": oldValue,
            "new_value": newValue
        ])
    }
    
    func logFeatureUsed(featureName: String, action: String) {
        logEvent("feature_used", parameters: [
            "feature_name": featureName,
            "action": action
        ])
    }
    
    // MARK: - Key Business Events
    
    func logFirstAppOpen() {
        logEvent("app_open", parameters: ["first_time_user": true])
    }
    
    func logScheduleSuccessfullyApplied(scheduleName: String, daysUsed: Int) {
        logEvent("schedule_successfully_applied", parameters: [
            "schedule_name": scheduleName,
            "days_used": daysUsed
        ])
    }
    
    func logUserRetention(daysSinceInstall: Int) {
        logEvent("user_retention", parameters: [
            "days_since_install": daysSinceInstall
        ])
    }
    
    // MARK: - Analytics State Management
    
    func setAnalyticsEnabled(_ enabled: Bool) {
        if enabled {
            PostHogSDK.shared.optIn()
        } else {
            PostHogSDK.shared.optOut()
        }
    }
    
    func enableDebugMode() {
        #if DEBUG
        print("🐛 Analytics: PostHog debug mode active")
        #endif
    }
}
