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
    
    // Section 2: Trust (6-8) — progress bar GÖZÜKMEYECEK
    case trustScreen = 6
    case nameInput = 7
    case personalizedGreeting = 8
    
    // Section 3: Questions (9-27) — progress bar SADECE SORU EKRANLARINDA
    case sleepExperience = 9
    case experienceInfo = 10
    case chronotype = 11
    case ageRange = 12
    case outcomeTimeCalc = 13
    case workSchedule = 14
    case napEnvironment = 15
    case napEnvironmentInfo = 16
    case lifestyle = 17
    case knowledgeLevel = 18
    case comparison = 19
    case healthStatus = 20
    case safetyNote = 21
    case motivationLevel = 22
    case chartReview = 23
    case sleepGoal = 24
    case goalSocialProof = 25
    case socialObligations = 26
    case disruptionTolerance = 27
    
    // Section 4: Results (28-35) — progress bar GÖZÜKMEYECEK
    case resultIntro = 28
    case recommendedProgram = 29
    case timeline24h = 30
    case firstBadge = 31
    case notificationPrimer = 32
    case notificationPrompt = 33
    case final_ = 34
    case commitment = 35
    
    var section: OnboardingSection {
        switch self.rawValue {
        case 0...5: return .story
        case 6...8: return .trust
        case 9...27: return .questions
        case 28...35: return .results
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
        case .splash, .nimmyIntro, .turningPoint, .trustScreen,
             .chartReview, .goalSocialProof, .resultIntro, .recommendedProgram,
             .firstBadge, .final_, .commitment:
            return true
        default:
            return false
        }
    }
}

enum OnboardingSection {
    case story, trust, questions, results
    
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
    static let devSkipToQuestions = true
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
        userName.isEmpty ? "arkadaş" : userName
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
    
    let tips: [String] = [
        "NASA araştırmalarına göre 26 dakikalık bir şekerleme, pilotların performansını %34 artırıyor.",
        "Leonardo da Vinci günde sadece 1.5-2 saat uyuyordu — polifazik uyku kullanarak.",
        "Birçok kültürde öğleden sonra şekerlemesi (siesta) yüzyıllardır bir gelenek.",
        "İnsan vücudu doğal olarak günde iki kez uyku hisseder: gece ve öğleden sonra.",
        "20 dakikalık bir nap, 200mg kafeinden daha etkili olabilir.",
        "Düzenli şekerlemeler kalp sağlığını iyileştirebilir.",
        "Japon kültüründe 'inemuri' — toplum içinde kısa uyku — saygın bir pratik."
    ]
    
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
        switch previousSleepExperience {
        case .none:
            return "başlamak için iyi bir an.\n\nnimmy da sıfırdan başladı.\n\nve şunu söyleyelim: planı tamamlayıp kullananların büyük çoğunluğu en zorlu günleri ilk 2–3 gün olarak tarif ediyor.\n\nbu geçiyor."
        case .some:
            return "bu çok yaygın.\n\nçoğu zaman kişi beceremediği için değil, plan hayatına uymadığı için bırakıyor.\n\nbu sefer planı hayatına göre kuruyoruz."
        case .extensive:
            return "harika. zaten ne beklediğini biliyorsun.\n\nbu sefer sadece tutarlılığı oturtmaya odaklanacağız."
        default:
            return "güzel. bir deneyimin var.\n\nşimdi sana özel bir plan oluşturacağız."
        }
    }
    
    var goalSocialProofCards: [(quote: String, author: String, degree: Double)] {
        switch sleepGoal {
        case .moreProductivity:
            return [
                ("öğlen nap'inden sonra sanki gün yeniden başlıyor. o 20 dakika, bana bütün öğleden sonrayı geri veriyor.", "yazılım geliştirici",-1.0),
                ("toplantılardan sonra 15 dk nap alıyorum. odaklanma farkı inanılmaz.", "ürün müdürü",1.0),
                ("gece 5 saat uyuyorum ama gündüz nap ile toplam 6.5 saat. hiç bu kadar verimli olmamıştım.", "girişimci",-1.0)
            ]
        case .balancedLifestyle:
            return [
                ("plan mükemmel değil. ama esnek. bir gün kaçırdığımda 'her şey bitti' demiyorum artık.", "3 çocuk annesi",-1.0),
                ("iş-yaşam dengesini uyku ile kurdum. artık akşamları kendime vakit kalıyor.", "öğretmen",1.0),
                ("hafta sonları farklı plan kullanabiliyorum. bu esneklik beni tuttu.", "serbest çalışan",-1.0)
            ]
        case .curiosity:
            return [
                ("deneyeyim dedim, iki haftada gerçekten alıştım. merak başladı, alışkanlık bitti.", "23 yaş",-1.0),
                ("reddit'te okudum, denedim, tuttu. artık 7 aydır yapıyorum.", "üniversite öğrencisi",1.0),
                ("da vinci de yapıyormuş dediler, merak ettim. şimdi günde 2 saat fazla vaktim var.", "tasarımcı",-1.0)
            ]
        default:
            return [
                ("ilk 3 gün çok zorlandım. 4. günden sonra bir şeyler değişmeye başladı.", "28 yaş",-1.0),
                ("öğleden sonra artık kahve içmiyorum. nap yeterli.", "mühendis",1.0),
                ("alışması 1 hafta sürdü ama sonra harika hissettim.", "25 yaş",-1.0)
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
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isTransitioning = false
        }
        
        analyticsManager.logOnboardingStepCompleted(step: nextIndex, stepName: currentScreen.description)
    }
    
    func goToPrevious() {
        guard !isTransitioning, currentScreenIndex > 0 else { return }
        
        let prevIndex = findPreviousScreen(from: currentScreenIndex)
        
        isTransitioning = true
        navigationDirection = .backward
        
        withAnimation(.easeInOut(duration: 0.45)) {
            currentScreenIndex = prevIndex
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isTransitioning = false
        }
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
    
    // MARK: - Notification Permission
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
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
    
    // MARK: - Skip Onboarding
    func skipOnboarding() async {
        analyticsManager.logOnboardingSkipped()
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
        recommendationStatusMessage = "\(displayName), planını oluşturuyorum..."
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
        
        updateProgress(0.15, "uyku profilini analiz ediyorum...")
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
        
        updateProgress(0.30, "tercihlerini kaydediyorum...")
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
            if let prefs = try modelContext.fetch(prefDescriptor).first {
                prefs.userName = userName
            }
            
            try modelContext.save()
            
            updateProgress(0.50, "sana uygun ritmi hesaplıyorum...")
            try? await Task.sleep(nanoseconds: 800_000_000)
            
            await getRecommendedSchedule()
        } catch {
            print("❌ Error saving preferences: \(error)")
            await showErrorMessage(String(format: L("onboarding.error.preferencesSaveFailed", table: "Onboarding"), error.localizedDescription))
        }
    }
    
    func getRecommendedSchedule() async {
        updateProgress(0.65, "planını kişiselleştiriyorum...")
        try? await Task.sleep(nanoseconds: 800_000_000)
        
        updateProgress(0.80, "bilimsel verileri inceliyorum...")
        
        do {
            if let recommendation = try await recommender.recommendSchedule() {
                try? await Task.sleep(nanoseconds: 600_000_000)
                
                updateProgress(0.95, "programını kaydediyorum...")
                
                let model = recommendation.schedule.toUserScheduleModel
                _ = try await Repository.shared.saveSchedule(model)
                await ScheduleManager.shared.loadActiveScheduleFromRepository()
                
                try? await Task.sleep(nanoseconds: 400_000_000)
                
                updateProgress(1.0, "hazır!")
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
            self.recommendationStatusMessage = "hazır!"
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
    
    func completeOnboarding() async {
        guard let modelContext = self.modelContext else { return }
        
        let fetchDescriptor = FetchDescriptor<UserPreferences>()
        do {
            if let prefs = try modelContext.fetch(fetchDescriptor).first {
                prefs.hasCompletedOnboarding = true
                prefs.hasCompletedQuestions = true
                prefs.hasSkippedOnboarding = false
                prefs.userName = userName
                try modelContext.save()
            } else {
                let newPrefs = UserPreferences(
                    hasCompletedOnboarding: true,
                    hasCompletedQuestions: true,
                    hasSkippedOnboarding: false,
                    userName: userName
                )
                modelContext.insert(newPrefs)
                try modelContext.save()
            }
            
            let timeTaken = onboardingStartTime != nil ? Date().timeIntervalSince(onboardingStartTime!) : 0
            analyticsManager.logOnboardingCompleted(
                timeTaken: timeTaken,
                stepsCompleted: totalScreens,
                selectedSchedule: ScheduleManager.shared.activeSchedule?.name ?? "default"
            )
            
            isOnboardingComplete = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.requestPostOnboardingRating()
            }
        } catch {
            print("❌ Error completing onboarding: \(error)")
        }
    }
    
    // MARK: - Post-Onboarding Rating & Paywall
    private func requestPostOnboardingRating() {
        RatingManager.shared.requestRating {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                PaywallManager.shared.presentPaywall(trigger: .onboardingComplete)
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
        case .trustScreen: return "trust_screen"
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
        case .chartReview: return "chart_review"
        case .sleepGoal: return "sleep_goal"
        case .goalSocialProof: return "goal_social_proof"
        case .socialObligations: return "social_obligations"
        case .disruptionTolerance: return "disruption_tolerance"
        case .resultIntro: return "result_intro"
        case .recommendedProgram: return "recommended_program"
        case .timeline24h: return "timeline_24h"
        case .firstBadge: return "first_badge"
        case .notificationPrimer: return "notification_primer"
        case .notificationPrompt: return "notification_prompt"
        case .final_: return "final"
        case .commitment: return "commitment"
        }
    }
}
