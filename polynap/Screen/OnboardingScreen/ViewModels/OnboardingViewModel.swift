import SwiftUI
import SwiftData

// Enum dönüşüm hatası için özel hata tipi
struct EnumConversionError: Error, LocalizedError {
    let enumType: String
    let value: String
    
    var errorDescription: String? {
        return "'\(value)' değeri '\(enumType)' enum tipine dönüştürülemedi."
    }
}

@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Dependencies
    private let recommender: SleepScheduleRecommender
    private let analyticsManager = AnalyticsManager.shared
    private var modelContext: ModelContext?
    
    // 📊 Analytics: Onboarding timing tracking
    private var onboardingStartTime: Date?
    
    // MARK: - Published Properties
    @Published var currentPage = 0
    let totalPages = 12
    @Published var shouldNavigateToSleepSchedule = false
    @Published var showStartButton = false
    @Published var isLoadingRecommendation = false
    @Published var showError = false
    @Published var errorMessage = ""
    
    // Yükleme ekranı için yeni değişkenler
    @Published var recommendationProgress: Double = 0.0
    @Published var recommendationStatusMessage: String = ""
    @Published var recommendationComplete: Bool = false
    @Published var showLoadingView: Bool = false
    @Published var navigateToMainScreen: Bool = false
    
    // Ana ekrana geçiş için NavigationLink değişkeni
    @Published var goToMainScreen: Bool = false
    
    // User selections
    @Published var previousSleepExperience: PreviousSleepExperience?
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
    @Published var chronotype: Chronotype?
    
    // MARK: - Initialization
    init(modelContext: ModelContext? = nil) {
        self.recommender = SleepScheduleRecommender(repository: Repository.shared)
        self.modelContext = modelContext
        if modelContext == nil {
            print("⚠️ OnboardingViewModel: ModelContext nil olarak başlatıldı. View'dan inject edildiğinden emin olun.")
        } else {
            print("✅ OnboardingViewModel: ModelContext başarıyla başlatıldı/inject edildi.")
        }
    }
    
    func setModelContext(_ context: ModelContext) {
        if self.modelContext == nil { // Sadece nil ise ata, birden fazla kez atanmasını engelle
            self.modelContext = context
            
            // 📊 Analytics: Onboarding başlangıç zamanını kaydet
            if onboardingStartTime == nil {
                onboardingStartTime = Date()
            }
            
            print("✅ OnboardingViewModel: setModelContext çağrıldı.")
        }
    }
    
    // MARK: - Computed Properties
    var canMoveNext: Bool {
        switch currentPage {
        case 0: return previousSleepExperience != nil
        case 1: return ageRange != nil
        case 2: return workSchedule != nil
        case 3: return napEnvironment != nil
        case 4: return lifestyle != nil
        case 5: return knowledgeLevel != nil
        case 6: return healthStatus != nil
        case 7: return motivationLevel != nil
        case 8: return sleepGoal != nil
        case 9: return socialObligations != nil
        case 10: return disruptionTolerance != nil
        case 11: return chronotype != nil
        default: return false
        }
    }
    
    // MARK: - Methods
    func moveNext() {
        guard !isLoadingRecommendation else { return }
        
        if currentPage < totalPages - 1 {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentPage += 1
            }
        } else {
            // Son sayfada ise, loading'i göster ve recommendation'ı başlat
            isLoadingRecommendation = true
            Task {
                await startRecommendationProcess()
            }
        }
    }
    
    func movePrevious() {
        guard !isLoadingRecommendation else { return }
        
        if currentPage > 0 {
            withAnimation(.easeInOut(duration: 0.25)) {
                currentPage -= 1
            }
        }
    }
    
    func skipOnboarding() async {
        print("⏭️ OnboardingViewModel: Onboarding atlandı")
        
        // Skip analytics event
        analyticsManager.logOnboardingSkipped()
        
        // Mark onboarding as skipped in UserPreferences
        await markOnboardingAsSkippedInSwiftData()
        
        // Set up default biphasic sleep schedule
        await setupDefaultBiphasicSchedule()
        
        // ContentView will automatically navigate to MainTabBarView since hasCompletedOnboarding = true
        print("✅ OnboardingViewModel: Skip tamamlandı, ContentView otomatik olarak MainTabBarView'a geçecek")
    }
    
    /// Skip onboarding without immediately completing - for circular transition
    func skipOnboardingForTransition() async {
        print("⏭️ OnboardingViewModel: Skip başlatıldı (transition için)")
        
        // Skip analytics event
        analyticsManager.logOnboardingSkipped()
        
        // Set up default biphasic sleep schedule
        await setupDefaultBiphasicSchedule()
        
        print("✅ OnboardingViewModel: Skip hazırlandı, transition sonrası complete edilecek")
    }
    
    /// Complete the skip process after transition
    func completeSkipAfterTransition() async {
        print("⏭️ OnboardingViewModel: Skip transition sonrası tamamlanıyor")
        
        // Mark onboarding as skipped and completed
        await markOnboardingAsSkippedInSwiftData()
        
        print("✅ OnboardingViewModel: Skip tamamen tamamlandı")
    }
    
    private func markOnboardingAsSkippedInSwiftData() async {
        guard let modelContext = self.modelContext else {
            print("❌ OnboardingViewModel: Onboarding atlandı olarak işaretlenemedi, ModelContext yok.")
            return
        }
        
        let fetchDescriptor = FetchDescriptor<UserPreferences>()
        do {
            if let userPreferences = try modelContext.fetch(fetchDescriptor).first {
                userPreferences.hasSkippedOnboarding = true
                userPreferences.hasCompletedOnboarding = true // Skip edilse de onboarding tamamlandı sayılır
                userPreferences.hasCompletedQuestions = false // Sorular tamamlanmadı
                try modelContext.save()
                print("✅ OnboardingViewModel: UserPreferences'da onboarding atlandı olarak işaretlendi.")
            } else {
                let newPreferences = UserPreferences(
                    hasCompletedOnboarding: true, // Skip edilse de onboarding tamamlandı sayılır
                    hasCompletedQuestions: false,
                    hasSkippedOnboarding: true
                )
                modelContext.insert(newPreferences)
                try modelContext.save()
                print("✅ OnboardingViewModel: UserPreferences oluşturuldu ve onboarding atlandı olarak işaretlendi.")
            }
        } catch {
            print("❌ OnboardingViewModel: UserPreferences güncellenirken hata: \(error.localizedDescription)")
        }
    }
    
    private func setupDefaultBiphasicSchedule() async {
        print("🔧 OnboardingViewModel: Varsayılan biphasic schedule ayarlanıyor...")
        
        // Create a biphasic schedule based on the JSON data
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
                SleepBlock(
                    startTime: "23:00",
                    duration: 360, // 6 hours core sleep
                    type: "core",
                    isCore: true
                ),
                SleepBlock(
                    startTime: "14:00",
                    duration: 30, // 30 minutes nap
                    type: "nap",
                    isCore: false
                )
            ],
            isPremium: false
        )
        
        do {
            // Save the schedule using the Repository
            _ = try await Repository.shared.saveSchedule(biphasicSchedule)
            print("✅ OnboardingViewModel: Varsayılan biphasic schedule kaydedildi ve aktif edildi.")
            
            // Update ScheduleManager with the new active schedule
            await ScheduleManager.shared.loadActiveScheduleFromRepository()
            print("✅ OnboardingViewModel: ScheduleManager güncellendi.")
            
        } catch {
            print("❌ OnboardingViewModel: Varsayılan biphasic schedule kaydedilirken hata: \(error.localizedDescription)")
            
            // Fallback to current default schedule if biphasic setup fails
            let fallbackSchedule = UserScheduleModel.defaultSchedule
            do {
                _ = try await Repository.shared.saveSchedule(fallbackSchedule)
                await ScheduleManager.shared.loadActiveScheduleFromRepository()
                print("⚠️ OnboardingViewModel: Fallback schedule kullanıldı.")
            } catch {
                print("❌ OnboardingViewModel: Fallback schedule bile kaydedilemedi: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Recommendation Process
    func startRecommendationProcess() async {
        // Kullanıcı seçimlerinin tam olup olmadığını kontrol et
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
            await MainActor.run {
                errorMessage = L("onboarding.error.incompleteAnswers", table: "Onboarding")
                showError = true
                showLoadingView = false
            }
            return
        }
        
        await MainActor.run {
            showLoadingView = true
            recommendationProgress = 0.0
            recommendationStatusMessage = L("onboarding.loading.preparingProgram", table: "Onboarding")
            recommendationComplete = false
        }
        
        // Bilgileri kaydet
        await saveUserPreferences()
    }
    
    // MARK: - UserPreferences kaydı
    func markOnboardingAsCompletedInSwiftData() async {
        guard let modelContext = self.modelContext else {
            print("❌ OnboardingViewModel: Onboarding tamamlandı olarak işaretlenemedi, ModelContext yok.")
            return
        }
        let fetchDescriptor = FetchDescriptor<UserPreferences>()
        do {
            if let userPreferences = try modelContext.fetch(fetchDescriptor).first {
                userPreferences.hasCompletedOnboarding = true
                userPreferences.hasCompletedQuestions = true // FIXED: Set this when user completes full flow
                userPreferences.hasSkippedOnboarding = false // Ensure this is false for completed flow
                try modelContext.save()
                print("✅ OnboardingViewModel: UserPreferences'da onboarding tamamlandı olarak işaretlendi.")
            } else {
                // WelcomeView'da oluşturulmuş olmalı. Eğer yoksa burada oluşturmak bir yedek plan.
                let newPreferences = UserPreferences(
                    hasCompletedOnboarding: true, 
                    hasCompletedQuestions: true, // FIXED: Set this when user completes full flow
                    hasSkippedOnboarding: false
                )
                modelContext.insert(newPreferences)
                try modelContext.save()
                print("✅ OnboardingViewModel: UserPreferences oluşturuldu ve onboarding tamamlandı olarak işaretlendi.")
            }
        } catch {
            print("❌ OnboardingViewModel: UserPreferences güncellenirken hata: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Saving
    func saveUserPreferences() async {
        print("\n=== Saving User Preferences ===")
        
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
            print("❌ Error: Some user preferences are not set")
            await showErrorMessage(L("onboarding.error.incompleteAnswers", table: "Onboarding"))
            return
        }
        
        updateProgress(0.15, L("onboarding.loading.savingPreferences", table: "Onboarding"))
        
        print("\nSaving values:")
        print("- Sleep Experience: \(sleepExperience.rawValue)")
        print("- Age Range: \(ageRange.rawValue)")
        print("- Work Schedule: \(workSchedule.rawValue)")
        print("- Nap Environment: \(napEnvironment.rawValue)")
        print("- Lifestyle: \(lifestyle.rawValue)")
        print("- Knowledge Level: \(knowledgeLevel.rawValue)")
        print("- Health Status: \(healthStatus.rawValue)")
        print("- Motivation Level: \(motivationLevel.rawValue)")
        print("- Sleep Goal: \(sleepGoal.rawValue)")
        print("- Social Obligations: \(socialObligations.rawValue)")
        print("- Disruption Tolerance: \(disruptionTolerance.rawValue)")
        print("- Chronotype: \(chronotype.rawValue)")
        
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
        
        updateProgress(0.30, L("onboarding.loading.savingDataLocally", table: "Onboarding"))
        
        do {
            guard let modelContext = self.modelContext else {
                print("❌ ModelContext bulunamadı, onboarding yanıtları kaydedilemedi")
                await showErrorMessage(L("onboarding.error.noModelContext", table: "Onboarding"))
                return
            }
            
            var currentUserModel: User? = nil
            if let localUserIdString = AuthManager.shared.currentUser?.id,
               let localUserUUID = UUID(uuidString: localUserIdString) {
                
                let predicate = #Predicate<User> { user in user.id == localUserUUID }
                let descriptor = FetchDescriptor<User>(predicate: predicate)
                do {
                    currentUserModel = try modelContext.fetch(descriptor).first
                    if currentUserModel == nil {
                        print("⚠️ OnboardingViewModel: ID'si \(localUserUUID) olan User @Model bulunamadı. OnboardingAnswer kullanıcısız kaydedilecek.")
                        // Tamamen offline bir uygulamada, User @Model'i, yerel kullanıcı ilk oluşturulduğunda
                        // veya burada AuthManager.shared.currentUser bilgilerine dayanarak oluşturabilirsiniz.
                    }
                } catch {
                    print("❌ OnboardingViewModel: User @Model alınırken hata: \(error.localizedDescription)")
                }
            } else {
                print("ℹ️ OnboardingViewModel: AuthManager'dan geçerli kullanıcı ID'si alınamadı.")
            }
            
            try cleanupExistingAnswers(in: modelContext)
            
            for (questionKey, answerValue) in answersTuples {
                let newAnswerData = OnboardingAnswerData(
                    user: currentUserModel,
                    question: questionKey,
                    answer: answerValue,
                    date: Date(),
                    createdAt: Date(),
                    updatedAt: Date()
                )
                modelContext.insert(newAnswerData)
            }
            
            try modelContext.save()
            print("✅ Onboarding yanıtları yerel olarak SwiftData'ya kaydedildi.")
            
            updateProgress(0.45, L("onboarding.loading.calculatingSchedule", table: "Onboarding"))
            await getRecommendedSchedule()
            
        } catch {
            print("❌ Onboarding yanıtları SwiftData'ya kaydedilirken hata: \(error.localizedDescription)")
            await showErrorMessage(String(format: L("onboarding.error.preferencesSaveFailed", table: "Onboarding"), error.localizedDescription))
        }
    }
    
    // Mevcut yanıtları temizleme yardımcı fonksiyonu
    private func cleanupExistingAnswers(in context: ModelContext) throws {
        let descriptor = FetchDescriptor<OnboardingAnswerData>()
        let existingAnswers = try context.fetch(descriptor)
        
        if !existingAnswers.isEmpty {
            print("🧹 \(existingAnswers.count) mevcut yanıt temizleniyor...")
            for answer in existingAnswers {
                context.delete(answer)
            }
        }
    }
    
    private func showErrorMessage(_ message: String) async {
        await MainActor.run {
            errorMessage = message
            showError = true
            showLoadingView = false
        }
    }
    
    private func updateProgress(_ targetProgress: Double, _ message: String) {
        // Animasyon için başlangıç değeri
        let startProgress = recommendationProgress
        let totalSteps = 20
        let animationDuration = 1.0 // Toplam animasyon süresi (saniye)
        
        for step in 0...totalSteps {
            let delayForStep = animationDuration * Double(step) / Double(totalSteps)
            let progressForStep = startProgress + (targetProgress - startProgress) * Double(step) / Double(totalSteps)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + delayForStep) {
                withAnimation(.easeInOut(duration: animationDuration / Double(totalSteps))) {
                    self.recommendationProgress = progressForStep
                    
                    // Sadece son adımda mesajı güncelle
                    if step == totalSteps {
                        self.recommendationStatusMessage = message
                    }
                }
            }
        }
    }
    
    func getRecommendedSchedule() async {
        updateProgress(0.6, L("onboarding.loading.analyzingProgram", table: "Onboarding"))
        
        // Yapay bir gecikme ekleyelim ki kullanıcı hesaplamanın yapıldığını görsün
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 saniye
        
        updateProgress(0.75, L("onboarding.loading.almostReady", table: "Onboarding"))
        
        do {
            if let recommendation = try await recommender.recommendSchedule() {
                print("\n=== Recommended Schedule ===")
                print("Name: \(recommendation.schedule.name)")
                print("Confidence Score: \(recommendation.confidenceScore)")
                
                // Yapay bir gecikme ekleyelim ki kullanıcı hesaplamanın yapıldığını görsün
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 saniye
                
                updateProgress(0.9, L("onboarding.loading.savingProgram", table: "Onboarding"))
                
                let recommendedUserScheduleModel = recommendation.schedule.toUserScheduleModel
                do {
                    // Repository.saveSchedule, ScheduleEntity'yi kaydeder ve aktif eder.
                    _ = try await Repository.shared.saveSchedule(recommendedUserScheduleModel)
                    print("✅ Önerilen program (ScheduleEntity) yerel olarak kaydedildi ve aktif edildi.")
                    
                    // ScheduleManager'ın aktif programını güncellemesini sağla
                    await ScheduleManager.shared.loadActiveScheduleFromRepository()
                    
                    await MainActor.run {
                        updateProgress(1.0, L("onboarding.loading.ready", table: "Onboarding"))
                        recommendationComplete = true
                    }
                } catch {
                    print("❌ Önerilen program kaydedilirken/aktifleştirilirken hata: \(error.localizedDescription)")
                    await handleErrorButContinue(L("onboarding.error.programSetupFailed", table: "Onboarding"))
                }
            } else {
                print("❌ Failed to get recommendation")
                
                // Öneri bulunamazsa varsayılan bir programı kaydet
                print("⚠️ Tavsiye bulunamadı. Varsayılan program ayarlanıyor.")
                let defaultScheduleModel = UserScheduleModel.defaultSchedule
                do {
                    _ = try await Repository.shared.saveSchedule(defaultScheduleModel)
                    print("✅ Varsayılan program yerel olarak kaydedildi ve aktif edildi.")
                    await ScheduleManager.shared.loadActiveScheduleFromRepository()
                    await handleErrorButContinue(L("onboarding.error.noRecommendationFound", table: "Onboarding"))
                } catch {
                    print("❌ Varsayılan program kaydedilirken/aktifleştirilirken hata: \(error.localizedDescription)")
                    await handleErrorButContinue(L("onboarding.error.defaultProgramSetupFailed", table: "Onboarding"))
                }
            }
        } catch let error as EnumConversionError {
            print("❌ Enum conversion error: \(error.localizedDescription)")
            await handleErrorButContinue(L("onboarding.error.dataProcessingFailed", table: "Onboarding"))
        } catch {
            print("❌ Error getting recommendation: \(error.localizedDescription)")
            await handleErrorButContinue(L("onboarding.error.unexpectedError", table: "Onboarding"))
        }
    }
    
    // Hata durumlarında yükleme ekranını tamamlamak için yardımcı fonksiyon
    private func handleErrorButContinue(_ message: String) async {
        await MainActor.run {
            updateProgress(0.9, message)
        }
        try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 saniye
        await MainActor.run {
            withAnimation {
                self.recommendationProgress = 1.0
                self.recommendationStatusMessage = L("onboarding.loading.ready", table: "Onboarding")
                self.recommendationComplete = true
            }
        }
    }
    
    func startUsingApp() {
        navigateToMainScreen = true
    }
    
    // 📊 Analytics: Seçilen schedule'ı analytics için string olarak döndür
    private func getSelectedScheduleForAnalytics() -> String {
        // Schedule Manager'dan aktif schedule'ı al
        if let activeSchedule = ScheduleManager.shared.activeSchedule {
            return activeSchedule.name
        }
        
        // Eğer schedule henüz aktif değilse, varsayılan schedule'ı döndür
        return UserScheduleModel.defaultSchedule.name
    }
    
    // Ana ekrana geçiş işlemini yönetir
    func handleNavigationToMainScreen() {
        print("🎯 OnboardingViewModel: handleNavigationToMainScreen() ÇAĞRILDI!")
        
        // 📊 Analytics: Onboarding tamamlanma event'ı (enhanced parameters ile)
        let timeTaken = onboardingStartTime != nil ? Date().timeIntervalSince(onboardingStartTime!) : 0
        let stepsCompleted = totalPages // Tüm adımları tamamladığı için totalPages
        let selectedSchedule = getSelectedScheduleForAnalytics()
        
        print("🎯 Analytics Debug:")
        print("   - timeTaken: \(timeTaken) seconds")
        print("   - stepsCompleted: \(stepsCompleted)")
        print("   - selectedSchedule: \(selectedSchedule)")
        print("   - onboardingStartTime: \(onboardingStartTime?.description ?? "nil")")
        
        print("📊 Analytics: logOnboardingCompleted ÇAĞRILIYOR...")
        analyticsManager.logOnboardingCompleted(
            timeTaken: timeTaken,
            stepsCompleted: stepsCompleted,
            selectedSchedule: selectedSchedule
        )
        print("📊 Analytics: logOnboardingCompleted ÇAĞRILDI ✅")
        
        // Onboarding tamamlandı, doğrudan ana ekrana geçiş yap
        BadgeManager.shared.grantStarterBadge()
        withAnimation {
            goToMainScreen = true
        }
        
        // Ana ekrana geçtikten 1 saniye sonra rating request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.requestRatingIfNeeded()
        }
    }
    
    // Rating request'ini yönetir
    private func requestRatingIfNeeded() {
        print("📝 OnboardingViewModel: Rating request başlatılıyor...")
        
        RatingManager.shared.requestRating {
            print("📝 OnboardingViewModel: Rating completed, paywall tetikleniyor...")
            
            // Rating tamamlandıktan 0.5 saniye sonra paywall tetikle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.triggerOnboardingPaywall()
            }
        }
    }
    
    // Onboarding sonrası paywall'ı tetikler
    private func triggerOnboardingPaywall() {
        print("📱 OnboardingViewModel: Onboarding paywall tetikleniyor...")
        PaywallManager.shared.presentPaywall(trigger: .onboardingComplete)
    }
}
