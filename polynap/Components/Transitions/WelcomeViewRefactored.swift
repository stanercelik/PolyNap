// WelcomeViewRefactored.swift
// polynap
//
// Example of how to refactor WelcomeView to use CircularTransition component

import SwiftUI
import SwiftData

struct WelcomeViewRefactored: View {
    @StateObject private var viewModel = WelcomeViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    
    // Analytics
    private let analyticsManager = AnalyticsManager.shared
    
    @State private var buttonCenter: CGPoint = .zero
    @State private var showOnboarding: Bool = false
    
    var body: some View {
        mainContent
            .circularTransition(
                to: onboardingDestination,
                startPosition: buttonCenter,
                isActive: $showOnboarding
            )
            .toolbar(.hidden, for: .navigationBar)
            .ignoresSafeArea()
            .onAppear {
                // ModelContext'i ViewModel'e ilet
                viewModel.setModelContext(modelContext)
                
                // Analytics: Welcome screen görüntüleme
                analyticsManager.logScreenView(
                    screenName: "welcome_screen",
                    screenClass: "WelcomeViewRefactored"
                )
            }
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
            // Analytics: Get Started button tap
            analyticsManager.logFeatureUsed(
                featureName: "welcome_get_started",
                action: "button_tap"
            )
            
            // Timer'ı durdur
            viewModel.stopTimer()
            
            // Fade out existing content
            viewModel.fadeOutAnimations()
            
            // Start transition after short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showOnboarding = true
            }
        }
        .padding(.bottom, PSSpacing.lg)
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
                    .onChange(of: proxy.frame(in: .global)) { _, frame in
                        buttonCenter = CGPoint(
                            x: frame.midX,
                            y: frame.midY
                        )
                    }
            }
        )
    }
    
    private var onboardingDestination: some View {
        OnboardingView()
            .onDisappear {
                // Handle onboarding completion
                NotificationCenter.default.post(
                    name: NSNotification.Name("OnboardingCompleted"),
                    object: nil
                )
                
                // Update UserPreferences
                updateUserPreferences()
            }
    }
    
    private func updateUserPreferences() {
        let fetchDescriptor = FetchDescriptor<UserPreferences>()
        do {
            let preferences = try modelContext.fetch(fetchDescriptor)
            if let userPreferences = preferences.first {
                userPreferences.hasCompletedOnboarding = true
                try modelContext.save()
                print("✅ Onboarding marked as completed")
            } else {
                print("❌ No UserPreferences found")
            }
        } catch {
            print("❌ Error updating UserPreferences: \(error.localizedDescription)")
        }
    }
}

// MARK: - Alternative Implementation using CircularTransitionButton
struct WelcomeViewWithTransitionButton: View {
    @StateObject private var viewModel = WelcomeViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    
    private let analyticsManager = AnalyticsManager.shared
    
    var body: some View {
        VStack(alignment: .leading) {
            progressBar
            welcomeText
            Spacer()
            infoPages
            Spacer()
            
            // Using IntegratedCircularTransitionButton instead of regular button
            IntegratedCircularTransitionButton(
                buttonTitle: NSLocalizedString("continue", tableName: "Welcome", comment: ""),
                primaryColor: .appPrimary,
                backgroundColor: .appBackground,
                action: {
                    // Analytics tracking
                    analyticsManager.logFeatureUsed(
                        featureName: "welcome_get_started",
                        action: "button_tap"
                    )
                    
                    // Stop timer
                    viewModel.stopTimer()
                    
                    // Fade out animations
                    viewModel.fadeOutAnimations()
                },
                destination: {
                    OnboardingView()
                        .onDisappear {
                            // Handle completion
                            NotificationCenter.default.post(
                                name: NSNotification.Name("OnboardingCompleted"),
                                object: nil
                            )
                        }
                }
            )
            .padding(.bottom, PSSpacing.lg)
        }
        .padding(.top, 72)
        .padding(.bottom, 64)
        .padding(.horizontal, PSSpacing.lg)
        .toolbar(.hidden, for: .navigationBar)
        .ignoresSafeArea()
        .onAppear {
            viewModel.setModelContext(modelContext)
            analyticsManager.logScreenView(
                screenName: "welcome_screen",
                screenClass: "WelcomeViewWithTransitionButton"
            )
        }
    }
    
    // ... same helper views as above
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
            }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .onChange(of: viewModel.currentPageIndex) {
            viewModel.fadeOutAnimations()
        }
        .padding(.horizontal, PSSpacing.sm)
        .padding(.top, PSSpacing.xxl + PSSpacing.xs)
    }
}

// MARK: - Usage Examples for other screens
struct AnyScreenExample: View {
    @State private var showNextScreen = false
    @State private var buttonPosition: CGPoint = .zero
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Any Screen")
                .font(.largeTitle)
            
            Text("You can use circular transition from any screen to any other screen")
                .multilineTextAlignment(.center)
                .padding()
            
            Spacer()
            
            PSPrimaryButton("Go to Profile") {
                showNextScreen = true
            }
            .overlay(
                GeometryReader { proxy in
                    Color.clear.onAppear {
                        buttonPosition = CGPoint(
                            x: proxy.frame(in: .global).midX,
                            y: proxy.frame(in: .global).midY
                        )
                    }
                }
            )
            
            Spacer()
        }
        .padding()
        .circularTransition(
            to: Text("Profile Screen"), // Any destination view
            startPosition: buttonPosition,
            isActive: $showNextScreen,
            primaryColor: .blue,
            backgroundColor: .purple
        )
    }
}

#Preview("Refactored Welcome") {
    WelcomeViewRefactored()
}

#Preview("Transition Button") {
    WelcomeViewWithTransitionButton()
}

#Preview("Any Screen Example") {
    AnyScreenExample()
}