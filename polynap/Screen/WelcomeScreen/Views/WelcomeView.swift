// WelcomeView.swift
// polynap
//
// Created by Taner Çelik on 27.12.2024.

import SwiftUI
import SwiftData

struct WelcomeView: View {
    @StateObject private var viewModel = WelcomeViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    
    // Analytics
    private let analyticsManager = AnalyticsManager.shared
    
    @State private var buttonCenter: CGPoint = .zero
    @State private var circleDiameter: CGFloat = 0
    
    var body: some View {
        GeometryReader { geo in
                    ZStack {
                        // 1) Main Content
                        mainContent
                            .opacity(viewModel.isOnboardingPresented ? 0 : 1)
                        
                        // 2) First Circle
                        Circle()
                            .fill(Color.appPrimary)
                            .frame(width: circleDiameter, height: circleDiameter)
                            .scaleEffect(viewModel.isPrimaryCircleExpanded ? 1.5 : 0, anchor: .center)
                            .position(buttonCenter)
                            .opacity(viewModel.isPrimaryCircleExpanded ? 1 : 0)
                        
                        // 3) Second Circle
                        Circle()
                            .fill(Color.appBackground)
                            .frame(width: circleDiameter, height: circleDiameter)
                            .scaleEffect(viewModel.isBackgroundCircleExpanded ? 1.5 : 0, anchor: .center)
                            .position(x: geo.size.width / 2, y: geo.size.height / 2)
                            .opacity(viewModel.isBackgroundCircleExpanded ? 1 : 0)
                        
                        // 4) Onboarding View
                        if viewModel.isOnboardingPresented {
                            OnboardingView()
                                .transition(.opacity)
                                .zIndex(1)
                                .onAppear {
                                    print("🎯 WelcomeView: OnboardingView APPEARED!")
                                }
                                .onDisappear {
                                    print("🎯 WelcomeView: OnboardingView DISAPPEARED!")
                                }
                        }
                    }
                    .onAppear {
                        let screenWidth = geo.size.width
                        let screenHeight = geo.size.height
                        circleDiameter = max(screenWidth, screenHeight) * 2
                        
                        // ModelContext'i ViewModel'e ilet
                        viewModel.setModelContext(modelContext)
                        
                        #if DEBUG
                        // DEVELOPMENT ONLY: Reset onboarding state for testing and debug current state
                        do {
                            let fetchDescriptor = FetchDescriptor<UserPreferences>()
                            if let userPreferences = try modelContext.fetch(fetchDescriptor).first {
                                print("🔍 WelcomeView: DEBUG - Current UserPreferences state:")
                                print("    - hasCompletedOnboarding: \(userPreferences.hasCompletedOnboarding)")
                                print("    - hasCompletedQuestions: \(userPreferences.hasCompletedQuestions)")  
                                print("    - hasSkippedOnboarding: \(userPreferences.hasSkippedOnboarding)")
                                let shouldShowMainApp = userPreferences.hasCompletedOnboarding && (userPreferences.hasCompletedQuestions || userPreferences.hasSkippedOnboarding)
                                print("    - shouldShowMainApp calculation: \(shouldShowMainApp)")
                                
                                // Reset for testing
                                userPreferences.hasCompletedOnboarding = false
                                userPreferences.hasCompletedQuestions = false
                                userPreferences.hasSkippedOnboarding = false
                                try modelContext.save()
                                print("🔧 DEBUG: Force reset onboarding state to false")
                            }
                        } catch {
                            print("❌ DEBUG: Error resetting onboarding state: \(error)")
                        }
                        #endif
                        
                        // Analytics: Welcome screen görüntüleme
                        analyticsManager.logScreenView(
                            screenName: "welcome_screen",
                            screenClass: "WelcomeView"
                        )
                    }
                }
                .toolbar(.hidden, for: .navigationBar)
                .ignoresSafeArea()
    }
    
    private var mainContent: some View {
        VStack(alignment: .leading) {
            progressBar
            welcomeText
            Spacer()
            infoPages
            Spacer()
            continueButton
        }
        .padding(.top, 72)
        .padding(.bottom, 64)
        .padding(.horizontal, PSSpacing.lg)
    }
    
    private var progressBar: some View {
        HStack(spacing: 3) {
            ForEach(0..<viewModel.totalPages, id: \.self) { index in
                PSProgressBar(progress: viewModel.progressValues[index])
            }
        }
    }
    
    private var welcomeText: some View {
        HStack(spacing: PSSpacing.md) {
            Image("OnboardingAppLogo")
                .resizable()
                .renderingMode(.template)
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .frame(width: PSIconSize.large, height: PSIconSize.large)
            
            Text("welcomeTitle", tableName: "Welcome")
                .font(PSTypography.headline)
                .foregroundColor(.appTextSecondary)
        }
        .padding(.top, PSSpacing.sm)
    }
    
    private var infoPages: some View {
        TabView(selection: $viewModel.currentPageIndex) {
            ForEach(0..<viewModel.totalPages, id: \.self) { index in
                WelcomePageView(
                    pageIndex: index,
                    showTitle: $viewModel.showTitle,
                    showDescription: $viewModel.showDescription,
                    showImage: $viewModel.showImage
                )
                .tag(index)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .contentShape(Rectangle())
                .onTapGesture { location in
                    let screenWidth = UIScreen.main.bounds.width
                    if location.x < screenWidth * 0.3 {
                        viewModel.previousPage()
                    } else if location.x > screenWidth * 0.7 {
                        viewModel.nextPage()
                    }
                }
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onChange(of: viewModel.currentPageIndex) {
            viewModel.fadeOutAnimations()
        }
        .padding(.horizontal, PSSpacing.sm)
        .padding(.top, PSSpacing.xxl + PSSpacing.xs)
    }
    
    private var continueButton: some View {
        PSPrimaryButton(NSLocalizedString("continue", tableName: "Welcome", comment: "")) {
            print("🔥 WelcomeView: Continue button CLICKED!")
            
            // Analytics: Get Started button tap
            analyticsManager.logFeatureUsed(
                featureName: "welcome_get_started",
                action: "button_tap"
            )
            
            print("🔥 WelcomeView: Calling viewModel.animateAndPresentOnboarding()")
            viewModel.animateAndPresentOnboarding()
            print("🔥 WelcomeView: viewModel.animateAndPresentOnboarding() COMPLETED")
        }
        .padding(.bottom, PSSpacing.lg)
        .opacity(viewModel.isContinueButtonVisible ? 1 : 0)
        .overlay(
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        let frame = proxy.frame(in: .global)
                        buttonCenter = CGPoint(
                            x: frame.midX,
                            y: frame.midY
                        )
                    }
            }
        )
    }
}

#Preview {
    WelcomeView()
}
