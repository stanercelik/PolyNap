import SwiftUI
import SwiftData
import StoreKit
import UserNotifications

// MARK: - Screen Definitions
enum OnboardingScreen: Int, CaseIterable {
    // Section 1: Story (0-5) — progress bar GÖZÜKMEYECEK
    case splash = 0
    case questionHook = 1
    case nimmyIntro = 2
    case turningPoint = 3
    case beforeAfter = 4
    case transition = 5
    
    // Section 2: Trust (6-7) — progress bar GÖZÜKMEYECEK
    case nameInput = 6
    case personalizedGreeting = 7
    
    // Section 3: Questions (8-25) — progress bar SADECE SORU EKRANLARINDA
    case sleepExperience = 8
    case experienceInfo = 9
    case chronotype = 10
    case ageRange = 11
    case outcomeTimeCalc = 12
    case workSchedule = 13
    case napEnvironment = 14
    case napEnvironmentInfo = 15
    case lifestyle = 16
    case knowledgeLevel = 17
    case comparison = 18
    case healthStatus = 19
    case safetyNote = 20
    case motivationLevel = 21
    case sleepGoal = 22
    case goalSocialProof = 23
    case socialObligations = 24
    case disruptionTolerance = 25
    
    // Section 4: Results (26-32) — progress bar GÖZÜKMEYECEK
    case resultIntro = 26
    case timeline24h = 27
    case firstBadge = 28
    case notificationPrimer = 29
    case alarmPrimer = 30
    case final_ = 31
    case commitment = 32
    
    var section: OnboardingSection {
        switch self.rawValue {
        case 0...5: return .story
        case 6...7: return .trust
        case 8...25: return .questions
        case 26...32: return .results
        default: return .story
        }
    }
    
    var isQuestionScreen: Bool {
        switch self {
        case .sleepExperience, .chronotype, .ageRange, .workSchedule, .napEnvironment,
             .lifestyle, .knowledgeLevel, .healthStatus, .motivationLevel,
             .sleepGoal, .socialObligations, .disruptionTolerance:
            return true
        default:
            return false
        }
    }
    
    static var questionScreens: [OnboardingScreen] {
        allCases.filter { $0.isQuestionScreen }
    }
    
    var questionIndex: Int? {
        guard isQuestionScreen else { return nil }
        return Self.questionScreens.firstIndex(of: self)
    }
    
    var isDarkBackground: Bool {
        switch self {
        case .splash, .nimmyIntro, .turningPoint,
             .goalSocialProof, .resultIntro,
             .firstBadge, .final_, .commitment:
            return true
        default:
            return false
        }
    }
}

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
    
    var progressColor: Color {
        switch self {
        case .story: return OBColors.accentBlue
        case .trust: return OBColors.accentBlue
        case .questions: return OBColors.accentBlue.opacity(0.7)
        case .results: return OBColors.starGold
        }
    }
}

// MARK: - ViewModel
@MainActor
final class NewOnboardingViewModel: ObservableObject {
    // MARK: - Dependencies
    private let recommender: SleepScheduleRecommender
    private let analyticsManager = AnalyticsManager.shared
    private var modelContext: ModelContext?
    private var onboardingStartTime: Date?
    
    // MARK: - DEV
    #if DEBUG
    static let devSkipToQuestions = false
    #endif
    
    // MARK: - Navigation
    #if DEBUG
    @Published var currentScreenIndex: Int = devSkipToQuestions ? OnboardingScreen.sleepExperience.rawValue : 0
    #else
    @Published var currentScreenIndex: Int = 0
    #endif
    @Published var navigationDirection: NavigationDirection = .forward
    @Published var isTransitioning = false
    
    enum NavigationDirection {
        case forward, backward
    }
    
    var currentScreen: OnboardingScreen {
        OnboardingScreen(rawValue: currentScreenIndex) ?? .splash
    }
    
    var totalScreens: Int { OnboardingScreen.allCases.count }
    
    var progress: CGFloat {
        let questionScreens = OnboardingScreen.questionScreens
        guard !questionScreens.isEmpty else { return 0 }
        
        if let qIndex = currentScreen.questionIndex {
            return CGFloat(qIndex) / CGFloat(questionScreens.count)
        }
        
        if currentScreen.section == .questions {
            let questionsRange = questionScreens.map(\.rawValue)
            let minQ = questionsRange.min() ?? 0
            let maxQ = questionsRange.max() ?? 1
            let clamped = min(max(currentScreenIndex, minQ), maxQ)
            return CGFloat(clamped - minQ) / CGFloat(max(maxQ - minQ, 1))
        }
        
        return 0
    }
    
    var shouldShowProgressBar: Bool {
        currentScreen.isQuestionScreen
    }
    
    // MARK: - User Data
    @Published var userName: String = ""
    
    var displayName: String {
        userName.isEmpty ? L("newOnboarding.vm.defaultName", table: "Onboarding") : userName
    }
    
    // MARK: - Question Selections
    @Published var previousSleepExperience: PreviousSleepExperience? = PreviousSleepExperience.none
    @Published var chronotype: Chronotype?
    @Published var ageRange: AgeRange?
    @Published var workSchedule: WorkSchedule?
    @Published var napEnvironment: NapEnvironment?
    @Published var lifestyle: Lifestyle?
    @Published var knowledgeLevel: KnowledgeLevel?
    @Published var healthStatus: HealthStatus?
    @Published var motivationLevel: MotivationLevel?
    @Published var sleepGoal: SleepGoal?
    @Published var socialObligations: SocialObligations?
    @Published var disruptionTolerance: DisruptionTolerance?
    
    // MARK: - Recommendation & Loading
    @Published var recommendationProgress: Double = 0
    @Published var recommendationStatusMessage: String = ""
    @Published var recommendationComplete = false
    @Published var isLoadingRecommendation = false
    @Published var showLoadingView = false
    @Published var navigateToMainScreen = false
    @Published var goToMainScreen = false
    
    // MARK: - UI State
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var isOnboardingComplete = false
    @Published var ratingGiven: Int = 0
    
    // MARK: - Tips Carousel
    @Published var currentTipIndex: Int = 0
    private var tipTimer: Timer?
    
    var tips: [String] {[
        L("newOnboarding.vm.tip1", table: "Onboarding"),
        L("newOnboarding.vm.tip2", table: "Onboarding"),
        L("newOnboarding.vm.tip3", table: "Onboarding"),
        L("newOnboarding.vm.tip4", table: "Onboarding"),
        L("newOnboarding.vm.tip5", table: "Onboarding"),
        L("newOnboarding.vm.tip6", table: "Onboarding"),
        L("newOnboarding.vm.tip7", table: "Onboarding"),
    ]}
    
    func startTipsCarousel() {
        currentTipIndex = 0
        tipTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.5)) {
                    self.currentTipIndex = (self.currentTipIndex + 1) % self.tips.count
                }
            }
        }
    }
    
    func stopTipsCarousel() {
        tipTimer?.invalidate()
        tipTimer = nil
    }
    
    // MARK: - Conditional Screen Logic
    var shouldShowNapEnvironmentInfo: Bool {
        napEnvironment == .limited || napEnvironment == .unsuitable
    }
    
    var experienceInfoText: String {
        guard let experience = previousSleepExperience else {
            return L("newOnboarding.experienceInfo.moderate", table: "Onboarding")
        }
        switch experience {
        case .none:
            return L("newOnboarding.experienceInfo.none", table: "Onboarding")
        case .some:
            return L("newOnboarding.experienceInfo.some", table: "Onboarding")
        case .extensive:
            return L("newOnboarding.experienceInfo.extensive", table: "Onboarding")
        default:
            return L("newOnboarding.experienceInfo.moderate", table: "Onboarding")
        }
    }
    
    var goalSocialProofCards: [(quote: String, author: String, degree: Double)] {
        switch sleepGoal {
        case .moreProductivity:
            return [
                (L("newOnboarding.vm.testimonial.productivity.1.quote", table: "Onboarding"), L("newOnboarding.vm.testimonial.productivity.1.author", table: "Onboarding"), -1.0),
                (L("newOnboarding.vm.testimonial.productivity.2.quote", table: "Onboarding"), L("newOnboarding.vm.testimonial.productivity.2.author", table: "Onboarding"), 1.0),
                (L("newOnboarding.vm.testimonial.productivity.3.quote", table: "Onboarding"), L("newOnboarding.vm.testimonial.productivity.3.author", table: "Onboarding"), -1.0)
            ]
        case .balancedLifestyle:
            return [
                (L("newOnboarding.vm.testimonial.balance.1.quote", table: "Onboarding"), L("newOnboarding.vm.testimonial.balance.1.author", table: "Onboarding"), -1.0),
                (L("newOnboarding.vm.testimonial.balance.2.quote", table: "Onboarding"), L("newOnboarding.vm.testimonial.balance.2.author", table: "Onboarding"), 1.0),
                (L("newOnboarding.vm.testimonial.balance.3.quote", table: "Onboarding"), L("newOnboarding.vm.testimonial.balance.3.author", table: "Onboarding"), -1.0)
            ]
        case .curiosity:
            return [
                (L("newOnboarding.vm.testimonial.curiosity.1.quote", table: "Onboarding"), L("newOnboarding.vm.testimonial.curiosity.1.author", table: "Onboarding"), -1.0),
                (L("newOnboarding.vm.testimonial.curiosity.2.quote", table: "Onboarding"), L("newOnboarding.vm.testimonial.curiosity.2.author", table: "Onboarding"), 1.0),
                (L("newOnboarding.vm.testimonial.curiosity.3.quote", table: "Onboarding"), L("newOnboarding.vm.testimonial.curiosity.3.author", table: "Onboarding"), -1.0)
            ]
        default:
            return [
                (L("newOnboarding.vm.testimonial.default.1.quote", table: "Onboarding"), L("newOnboarding.vm.testimonial.default.1.author", table: "Onboarding"), -1.0),
                (L("newOnboarding.vm.testimonial.default.2.quote", table: "Onboarding"), L("newOnboarding.vm.testimonial.default.2.author", table: "Onboarding"), 1.0),
                (L("newOnboarding.vm.testimonial.default.3.quote", table: "Onboarding"), L("newOnboarding.vm.testimonial.default.3.author", table: "Onboarding"), -1.0)
            ]
        }
    }
    
    // MARK: - Init
    init() {
        self.recommender = SleepScheduleRecommender(repository: Repository.shared)
    }
    
    func setModelContext(_ context: ModelContext) {
        if self.modelContext == nil {
            self.modelContext = context
            if onboardingStartTime == nil {
                onboardingStartTime = Date()
            }
        }
    }
    
    // MARK: - Navigation
    func goToNext() {
        guard !isTransitioning else { return }
        
        let nextIndex = findNextScreen(from: currentScreenIndex)
        guard nextIndex < totalScreens else { return }
        
        isTransitioning = true
        navigationDirection = .forward
        
        withAnimation(.easeInOut(duration: 0.45)) {
            currentScreenIndex = nextIndex
        }

        triggerTransitionHaptic(targetScreenIndex: nextIndex, direction: .forward)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isTransitioning = false
        }
        
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
    }
    
    func goToPrevious() {
        guard !isTransitioning, currentScreenIndex > 0 else { return }
        
        let prevIndex = findPreviousScreen(from: currentScreenIndex)
        let fromScreen = currentScreen.description
        
        isTransitioning = true
        navigationDirection = .backward
        
        withAnimation(.easeInOut(duration: 0.45)) {
            currentScreenIndex = prevIndex
        }

        triggerTransitionHaptic(targetScreenIndex: prevIndex, direction: .backward)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isTransitioning = false
        }
        
        let toScreen = (OnboardingScreen(rawValue: prevIndex) ?? .splash).description
        analyticsManager.logOnboardingStepBack(fromScreen: fromScreen, toScreen: toScreen)
    }
    
    private func findNextScreen(from index: Int) -> Int {
        var next = index + 1
        
        if OnboardingScreen(rawValue: next) == .napEnvironmentInfo && !shouldShowNapEnvironmentInfo {
            next += 1
        }
        
        return next
    }
    
    private func findPreviousScreen(from index: Int) -> Int {
        var prev = index - 1
        
        if OnboardingScreen(rawValue: prev) == .napEnvironmentInfo && !shouldShowNapEnvironmentInfo {
            prev -= 1
        }
        
        return max(prev, 0)
    }

    private func triggerTransitionHaptic(targetScreenIndex: Int, direction: NavigationDirection) {
        guard let targetScreen = OnboardingScreen(rawValue: targetScreenIndex) else {
            HapticFeedbackManager.shared.trigger(.softCommit)
            return
        }

        if direction == .backward {
            HapticFeedbackManager.shared.trigger(.selection)
            return
        }

        switch targetScreen {
        case .resultIntro, .firstBadge, .timeline24h, .commitment:
            HapticFeedbackManager.shared.trigger(.strongCommit)
        case .final_:
            HapticFeedbackManager.shared.trigger(.success)
        default:
            HapticFeedbackManager.shared.trigger(.softCommit)
        }
    }
    
    var canProceed: Bool {
        switch currentScreen {
        case .nameInput:
            return true
        case .sleepExperience: return true
        case .chronotype: return chronotype != nil
        case .ageRange: return ageRange != nil
        case .workSchedule: return workSchedule != nil
        case .napEnvironment: return napEnvironment != nil
        case .lifestyle: return lifestyle != nil
        case .knowledgeLevel: return knowledgeLevel != nil
        case .healthStatus: return healthStatus != nil
        case .motivationLevel: return motivationLevel != nil
        case .sleepGoal: return sleepGoal != nil
        case .socialObligations: return socialObligations != nil
        case .disruptionTolerance: return disruptionTolerance != nil
        default: return true
        }
    }
    
    // MARK: - Analytics Helpers
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
    
    // MARK: - Notification Permission
    func requestNotificationPermission() {
        analyticsManager.logPermissionRequested(permissionType: "notifications")
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                self.analyticsManager.logPermissionResult(permissionType: "notifications", granted: granted)
                
                if granted {
                    print("✅ Notification permission granted")
                } else {
                    print("❌ Notification permission denied")
                }
                self.goToNext()
            }
        }
    }
    
    // MARK: - Rating
    func requestAppRating() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
        }
    }
    
    // MARK: - Alarm Permission
    func requestAlarmPermission() {
        analyticsManager.logPermissionRequested(permissionType: "alarm")
        
        Task { @MainActor in
            await AlarmService.shared.requestPermissions()
            let status = await AlarmService.shared.getAuthorizationStatus()
            analyticsManager.logPermissionResult(permissionType: "alarm", granted: status == .authorized)
            self.goToNext()
        }
    }
    
    // MARK: - Skip Onboarding
    func skipOnboarding() async {
        analyticsManager.logOnboardingSkipped(
            atScreen: currentScreen.description,
            screenIndex: currentScreenIndex
        )
        analyticsManager.setUserProperties(["onboarding_status": "skipped"])
        await markOnboardingAsSkipped()
        await setupDefaultBiphasicSchedule()
    }
    
    private func markOnboardingAsSkipped() async {
        guard let modelContext = self.modelContext else { return }
        
        let fetchDescriptor = FetchDescriptor<UserPreferences>()
        do {
            if let prefs = try modelContext.fetch(fetchDescriptor).first {
                prefs.hasSkippedOnboarding = true
                prefs.hasCompletedOnboarding = true
                prefs.hasCompletedQuestions = false
                try modelContext.save()
            } else {
                let newPrefs = UserPreferences(
                    hasCompletedOnboarding: true,
                    hasCompletedQuestions: false,
                    hasSkippedOnboarding: true
                )
                modelContext.insert(newPrefs)
                try modelContext.save()
            }
        } catch {
            print("❌ Error marking onboarding as skipped: \(error.localizedDescription)")
        }
    }
    
    private func setupDefaultBiphasicSchedule() async {
        let biphasicSchedule = UserScheduleModel(
            id: "biphasic",
            name: "Biphasic Sleep",
            description: LocalizedDescription(
                en: "A sleep pattern with one core sleep period and one short nap during the day, often practiced in some cultures as an afternoon siesta.",
                tr: "Bir ana uyku dönemi ve gün içinde kısa bir şekerlemeden oluşan uyku düzeni. Özellikle bazı kültürlerde öğleden sonra yapılan siesta şeklinde uygulanabilir.",
                ja: "夜にまとめて寝る時間のほかに、日中に短いお昼寝を1回とる睡眠スタイル。スペインのシエスタみたいに、文化として根付いている地域もありますよ。",
                de: "Ein Schlafmuster mit einer Kernschlafphase und einem kurzen Nickerchen während des Tages, das in einigen Kulturen oft als Nachmittagssiesta praktiziert wird.",
                ms: "Corak tidur dengan satu tempoh tidur teras dan satu tidur sebentar pendek pada siang hari, sering diamalkan dalam sesetengah budaya sebagai siesta petang.",
                th: "รูปแบบการนอนที่มีช่วงการนอนหลักหนึ่งครั้งและการหลับสั้นๆ ในช่วงกลางวัน มักพบในบางวัฒนธรรมเป็นการนอนบ่าย"
            ),
            totalSleepHours: 6.5,
            schedule: [
                SleepBlock(startTime: "23:00", duration: 360, type: "core", isCore: true),
                SleepBlock(startTime: "14:00", duration: 30, type: "nap", isCore: false)
            ],
            isPremium: false
        )
        
        do {
            _ = try await Repository.shared.saveSchedule(biphasicSchedule)
            await ScheduleManager.shared.loadActiveScheduleFromRepository()
        } catch {
            let fallbackSchedule = UserScheduleModel.defaultSchedule
            do {
                _ = try await Repository.shared.saveSchedule(fallbackSchedule)
                await ScheduleManager.shared.loadActiveScheduleFromRepository()
            } catch {
                print("❌ Fallback schedule bile kaydedilemedi: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Recommendation Process
    func startRecommendationProcess() async {
        guard previousSleepExperience != nil,
              ageRange != nil,
              workSchedule != nil,
              napEnvironment != nil,
              lifestyle != nil,
              knowledgeLevel != nil,
              healthStatus != nil,
              motivationLevel != nil,
              sleepGoal != nil,
              socialObligations != nil,
              disruptionTolerance != nil,
              chronotype != nil else {
            errorMessage = L("onboarding.error.incompleteAnswers", table: "Onboarding")
            showError = true
            showLoadingView = false
            return
        }
        
        isLoadingRecommendation = true
        showLoadingView = true
        recommendationProgress = 0.0
        recommendationStatusMessage = String(format: L("newOnboarding.vm.buildingPlan", table: "Onboarding"), displayName)
        recommendationComplete = false
        
        await saveUserPreferences()
    }
    
    // MARK: - Save & Complete
    func saveUserPreferences() async {
        guard let modelContext = self.modelContext else {
            await showErrorMessage(L("onboarding.error.noModelContext", table: "Onboarding"))
            return
        }
        
        guard let sleepExperience = previousSleepExperience,
              let ageRange = ageRange,
              let workSchedule = workSchedule,
              let napEnvironment = napEnvironment,
              let lifestyle = lifestyle,
              let knowledgeLevel = knowledgeLevel,
              let healthStatus = healthStatus,
              let motivationLevel = motivationLevel,
              let sleepGoal = sleepGoal,
              let socialObligations = socialObligations,
              let disruptionTolerance = disruptionTolerance,
              let chronotype = chronotype
        else {
            await showErrorMessage(L("onboarding.error.incompleteAnswers", table: "Onboarding"))
            return
        }
        
        updateProgress(0.15, L("newOnboarding.resultIntro.stage1", table: "Onboarding"))
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        let answersTuples: [(String, String)] = [
            ("onboarding.sleepExperience", sleepExperience.rawValue),
            ("onboarding.ageRange", ageRange.rawValue),
            ("onboarding.workSchedule", workSchedule.rawValue),
            ("onboarding.napEnvironment", napEnvironment.rawValue),
            ("onboarding.lifestyle", lifestyle.rawValue),
            ("onboarding.knowledgeLevel", knowledgeLevel.rawValue),
            ("onboarding.healthStatus", healthStatus.rawValue),
            ("onboarding.motivationLevel", motivationLevel.rawValue),
            ("onboarding.sleepGoal", sleepGoal.rawValue),
            ("onboarding.socialObligations", socialObligations.rawValue),
            ("onboarding.disruptionTolerance", disruptionTolerance.rawValue),
            ("onboarding.chronotype", chronotype.rawValue)
        ]
        
        updateProgress(0.30, L("newOnboarding.resultIntro.stage2", table: "Onboarding"))
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        do {
            var currentUserModel: User? = nil
            if let localUserIdString = AuthManager.shared.currentUser?.id,
               let localUserUUID = UUID(uuidString: localUserIdString) {
                let predicate = #Predicate<User> { user in user.id == localUserUUID }
                let descriptor = FetchDescriptor<User>(predicate: predicate)
                currentUserModel = try? modelContext.fetch(descriptor).first
            }
            
            let descriptor = FetchDescriptor<OnboardingAnswerData>()
            let existing = try modelContext.fetch(descriptor)
            for answer in existing { modelContext.delete(answer) }
            
            for (question, answer) in answersTuples {
                let data = OnboardingAnswerData(
                    user: currentUserModel,
                    question: question,
                    answer: answer,
                    date: Date(),
                    createdAt: Date(),
                    updatedAt: Date()
                )
                modelContext.insert(data)
            }
            
            let prefDescriptor = FetchDescriptor<UserPreferences>()
            let preferences: UserPreferences
            if let existingPreferences = try modelContext.fetch(prefDescriptor).first {
                preferences = existingPreferences
            } else {
                let newPreferences = UserPreferences(userName: userName)
                modelContext.insert(newPreferences)
                preferences = newPreferences
            }

            preferences.userName = userName
            applyBehavioralNudgeProfile(to: preferences)
            
            try modelContext.save()
            AuthManager.shared.updateDisplayName(userName)
            
            updateProgress(0.50, L("newOnboarding.resultIntro.stage3", table: "Onboarding"))
            try? await Task.sleep(nanoseconds: 800_000_000)
            
            await getRecommendedSchedule()
        } catch {
            print("❌ Error saving preferences: \(error)")
            await showErrorMessage(String(format: L("onboarding.error.preferencesSaveFailed", table: "Onboarding"), error.localizedDescription))
        }
    }
    
    func getRecommendedSchedule() async {
        updateProgress(0.65, L("newOnboarding.resultIntro.stage4", table: "Onboarding"))
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        updateProgress(0.80, L("newOnboarding.resultIntro.stage5", table: "Onboarding"))
        
        do {
            if let recommendation = try await recommender.recommendSchedule() {
                try? await Task.sleep(nanoseconds: 600_000_000)
                
                updateProgress(0.95, L("newOnboarding.resultIntro.stage6", table: "Onboarding"))
                
                let model = recommendation.schedule.toUserScheduleModel
                _ = try await Repository.shared.saveSchedule(model)
                await ScheduleManager.shared.loadActiveScheduleFromRepository()
                
                try? await Task.sleep(nanoseconds: 400_000_000)
                
                updateProgress(1.0, L("newOnboarding.resultIntro.stage7", table: "Onboarding"))
                isLoadingRecommendation = false
                recommendationComplete = true
            } else {
                let defaultSchedule = UserScheduleModel.defaultSchedule
                _ = try await Repository.shared.saveSchedule(defaultSchedule)
                await ScheduleManager.shared.loadActiveScheduleFromRepository()
                await handleErrorButContinue(L("onboarding.error.noRecommendationFound", table: "Onboarding"))
            }
        } catch let error as EnumConversionError {
            print("❌ Enum conversion error: \(error.localizedDescription)")
            await handleErrorButContinue(L("onboarding.error.dataProcessingFailed", table: "Onboarding"))
        } catch {
            print("❌ Recommendation error: \(error)")
            await handleErrorButContinue(L("onboarding.error.unexpectedError", table: "Onboarding"))
        }
    }
    
    private func handleErrorButContinue(_ message: String) async {
        updateProgress(0.9, message)
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        withAnimation {
            self.recommendationProgress = 1.0
            self.recommendationStatusMessage = L("newOnboarding.resultIntro.stage7", table: "Onboarding")
            self.recommendationComplete = true
            self.isLoadingRecommendation = false
        }
    }
    
    private func updateProgress(_ targetProgress: Double, _ message: String) {
        let startProgress = recommendationProgress
        let totalSteps = 20
        let animationDuration = 0.8
        
        for step in 0...totalSteps {
            let delayForStep = animationDuration * Double(step) / Double(totalSteps)
            let progressForStep = startProgress + (targetProgress - startProgress) * Double(step) / Double(totalSteps)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delayForStep) {
                withAnimation(.easeInOut(duration: animationDuration / Double(totalSteps))) {
                    self.recommendationProgress = progressForStep
                    if step == totalSteps {
                        self.recommendationStatusMessage = message
                    }
                }
            }
        }
    }
    
    private func showErrorMessage(_ message: String) async {
        errorMessage = message
        showError = true
        showLoadingView = false
        isLoadingRecommendation = false
    }

    private func applyBehavioralNudgeProfile(to preferences: UserPreferences) {
        guard let chronotype,
              let lifestyle,
              let healthStatus,
              let motivationLevel,
              let sleepGoal,
              let socialObligations,
              let disruptionTolerance,
              let knowledgeLevel,
              let workSchedule,
              let napEnvironment else {
            return
        }

        let input = OnboardingNudgeProfileInput(
            chronotype: chronotype,
            lifestyle: lifestyle,
            healthStatus: healthStatus,
            motivationLevel: motivationLevel,
            sleepGoal: sleepGoal,
            socialObligations: socialObligations,
            disruptionTolerance: disruptionTolerance,
            knowledgeLevel: knowledgeLevel,
            workSchedule: workSchedule,
            napEnvironment: napEnvironment
        )

        BehavioralNudgeEngine.bootstrap(preferences: preferences, input: input)
    }
    
    func completeOnboarding() async {
        guard let modelContext = self.modelContext else { return }
        
        let fetchDescriptor = FetchDescriptor<UserPreferences>()
        do {
            if let prefs = try modelContext.fetch(fetchDescriptor).first {
                prefs.hasCompletedOnboarding = true
                prefs.hasCompletedQuestions = true
                prefs.hasSkippedOnboarding = false
                prefs.userName = userName
                applyBehavioralNudgeProfile(to: prefs)
                try modelContext.save()
                AuthManager.shared.updateDisplayName(userName)
            } else {
                let newPrefs = UserPreferences(
                    hasCompletedOnboarding: true,
                    hasCompletedQuestions: true,
                    hasSkippedOnboarding: false,
                    userName: userName
                )
                applyBehavioralNudgeProfile(to: newPrefs)
                modelContext.insert(newPrefs)
                try modelContext.save()
                AuthManager.shared.updateDisplayName(userName)
            }
            
            let timeTaken = onboardingStartTime != nil ? Date().timeIntervalSince(onboardingStartTime!) : 0
            analyticsManager.logOnboardingCompleted(
                timeTaken: timeTaken,
                stepsCompleted: totalScreens,
                selectedSchedule: ScheduleManager.shared.activeSchedule?.name ?? "default"
            )
            
            var userProps: [String: Any] = ["onboarding_status": "completed"]
            if let chrono = chronotype { userProps["chronotype"] = chrono.rawValue }
            if let age = ageRange { userProps["age_range"] = age.rawValue }
            if let work = workSchedule { userProps["work_schedule"] = work.rawValue }
            if let goal = sleepGoal { userProps["sleep_goal"] = goal.rawValue }
            if let exp = previousSleepExperience { userProps["sleep_experience"] = exp.rawValue }
            if let motivation = motivationLevel { userProps["motivation_level"] = motivation.rawValue }
            if let health = healthStatus { userProps["health_status"] = health.rawValue }
            if let knowledge = knowledgeLevel { userProps["knowledge_level"] = knowledge.rawValue }
            if let life = lifestyle { userProps["lifestyle"] = life.rawValue }
            if let nap = napEnvironment { userProps["nap_environment"] = nap.rawValue }
            if let social = socialObligations { userProps["social_obligations"] = social.rawValue }
            if let disruption = disruptionTolerance { userProps["disruption_tolerance"] = disruption.rawValue }
            if !userName.isEmpty { userProps["user_name"] = userName }
            userProps["selected_schedule"] = ScheduleManager.shared.activeSchedule?.name ?? "default"
            analyticsManager.setUserProperties(userProps)
            
            isOnboardingComplete = true
            BadgeManager.shared.grantStarterBadge()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.requestPostOnboardingRating()
            }
        } catch {
            print("❌ Error completing onboarding: \(error)")
        }
    }
    
    // MARK: - Post-Onboarding Paywall
    private func requestPostOnboardingRating() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            PaywallManager.shared.presentPaywall(trigger: .onboardingComplete) {
                // Paywall tamamlandı olarak işaretle ve tanıtımı başlat
                UserDefaults.standard.set(true, forKey: "onboardingPaywallCompleted")
                AppTourManager.shared.startTourIfNeeded()
            }
        }
    }
}

// MARK: - Screen Description
extension OnboardingScreen: CustomStringConvertible {
    var description: String {
        switch self {
        case .splash: return "splash"
        case .questionHook: return "question_hook"
        case .nimmyIntro: return "nimmy_intro"
        case .turningPoint: return "turning_point"
        case .beforeAfter: return "before_after"
        case .transition: return "transition"
        case .nameInput: return "name_input"
        case .personalizedGreeting: return "personalized_greeting"
        case .sleepExperience: return "sleep_experience"
        case .experienceInfo: return "experience_info"
        case .chronotype: return "chronotype"
        case .ageRange: return "age_range"
        case .outcomeTimeCalc: return "outcome_time_calc"
        case .workSchedule: return "work_schedule"
        case .napEnvironment: return "nap_environment"
        case .napEnvironmentInfo: return "nap_environment_info"
        case .lifestyle: return "lifestyle"
        case .knowledgeLevel: return "knowledge_level"
        case .comparison: return "comparison"
        case .healthStatus: return "health_status"
        case .safetyNote: return "safety_note"
        case .motivationLevel: return "motivation_level"
        case .sleepGoal: return "sleep_goal"
        case .goalSocialProof: return "goal_social_proof"
        case .socialObligations: return "social_obligations"
        case .disruptionTolerance: return "disruption_tolerance"
        case .resultIntro: return "result_intro"
        case .timeline24h: return "timeline_24h"
        case .firstBadge: return "first_badge"
        case .notificationPrimer: return "notification_primer"
        case .alarmPrimer: return "alarm_primer"
        case .final_: return "final"
        case .commitment: return "commitment"
        }
    }
}
