import SwiftUI
import SwiftData

struct NewOnboardingContainerView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var analyticsManager: AnalyticsManager
    @StateObject private var viewModel = NewOnboardingViewModel()
    
    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.5), value: viewModel.currentScreen.isDarkBackground)
            
            VStack(spacing: 0) {
                if viewModel.shouldShowProgressBar {
                    progressBar
                        .padding(.horizontal, OBSpacing.md)
                        .padding(.top, 8)
                }
                
                screenContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            viewModel.setModelContext(modelContext)
            analyticsManager.logOnboardingStarted()
            analyticsManager.logScreenView(screenName: "new_onboarding", screenClass: "NewOnboardingContainerView")
            // Track initial screen view (first screen has no preceding goToNext call)
            let firstScreen = viewModel.currentScreen
            analyticsManager.logOnboardingScreenViewed(
                screenName: firstScreen.description,
                screenIndex: firstScreen.rawValue,
                section: firstScreen.section.analyticsName,
                progressPct: 0
            )
        }
        .statusBarHidden(viewModel.currentScreen == .splash)
    }
    
    // MARK: - Background Color
    private var backgroundColor: Color {
        viewModel.currentScreen.isDarkBackground ? OBColors.darkNavy : .white
    }
    
    // MARK: - Progress Bar
    private var progressBar: some View {
        OBProgressBar(
            progress: viewModel.progress,
            sectionColor: viewModel.currentScreen.section.progressColor
        )
        .transition(.opacity)
    }
    
    // MARK: - Screen Router
    @ViewBuilder
    private var screenContent: some View {
        let screen = viewModel.currentScreen
        let transition: AnyTransition = viewModel.navigationDirection == .forward
            ? OBTransition.slideForward
            : OBTransition.slideBackward
        
        Group {
            switch screen {
            // SECTION 1: Story
            case .splash:
                SplashScreen(viewModel: viewModel)
            case .questionHook:
                QuestionHookScreen(viewModel: viewModel)
            case .nimmyIntro:
                NimmyIntroScreen(viewModel: viewModel)
            case .turningPoint:
                TurningPointScreen(viewModel: viewModel)
            case .beforeAfter:
                BeforeAfterScreen_(viewModel: viewModel)
            case .transition:
                TransitionScreen(viewModel: viewModel)
                
            // SECTION 2: Trust
            case .nameInput:
                NameInputScreen(viewModel: viewModel)
            case .personalizedGreeting:
                PersonalizedGreetingScreen(viewModel: viewModel)
                
            // SECTION 3: Questions
            case .sleepExperience:
                SleepExperienceScreen(viewModel: viewModel)
            case .experienceInfo:
                ExperienceInfoScreen(viewModel: viewModel)
            case .chronotype:
                ChronotypeScreen(viewModel: viewModel)
            case .ageRange:
                AgeRangeScreen(viewModel: viewModel)
            case .outcomeTimeCalc:
                OutcomeTimeCalcScreen(viewModel: viewModel)
            case .workSchedule:
                WorkScheduleScreen(viewModel: viewModel)
            case .napEnvironment:
                NapEnvironmentScreen(viewModel: viewModel)
            case .napEnvironmentInfo:
                NapEnvironmentInfoScreen(viewModel: viewModel)
            case .lifestyle:
                LifestyleScreen(viewModel: viewModel)
            case .knowledgeLevel:
                KnowledgeLevelScreen(viewModel: viewModel)
            case .comparison:
                ComparisonScreen(viewModel: viewModel)
            case .healthStatus:
                HealthStatusScreen(viewModel: viewModel)
            case .safetyNote:
                SafetyNoteScreen(viewModel: viewModel)
            case .motivationLevel:
                MotivationLevelScreen(viewModel: viewModel)
            case .sleepGoal:
                SleepGoalScreen(viewModel: viewModel)
            case .goalSocialProof:
                GoalSocialProofScreen(viewModel: viewModel)
            case .socialObligations:
                SocialObligationsScreen(viewModel: viewModel)
            case .disruptionTolerance:
                DisruptionToleranceScreen(viewModel: viewModel)
                
            // SECTION 4: Results
            case .resultIntro:
                ResultIntroScreen(viewModel: viewModel)
            case .timeline24h:
                Timeline24hScreen(viewModel: viewModel)
            case .firstBadge:
                FirstBadgeScreen(viewModel: viewModel)
            case .notificationPrimer:
                NotificationPrimerScreen(viewModel: viewModel)
            case .alarmPrimer:
                AlarmPrimerScreen(viewModel: viewModel)
            case .final_:
                FinalScreen(viewModel: viewModel)
            case .commitment:
                CommitmentScreen(viewModel: viewModel)
            }
        }
        .id(screen)
        .transition(transition)
    }
}

#Preview {
    NewOnboardingContainerView()
        .environmentObject(AnalyticsManager.shared)
}
