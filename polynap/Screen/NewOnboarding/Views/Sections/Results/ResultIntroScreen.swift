import SwiftUI

struct ResultIntroScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    @State private var ringProgress: CGFloat = 0
    @State private var displayedText: String = ""
    @State private var showTips = true
    @State private var ringComplete = false
    @State private var showButton = false
    @State private var heartbeatScale: CGFloat = 1.0
    @State private var heartbeatTimer: Timer?
    @State private var animationTask: Task<Void, Never>?
    
    private var stages: [(text: String, target: CGFloat, wait: Double)] {[
        (L("newOnboarding.resultIntro.stage1", table: "Onboarding"), 0.12, 0.6),
        (L("newOnboarding.resultIntro.stage2", table: "Onboarding"), 0.26, 0.5),
        (L("newOnboarding.resultIntro.stage3", table: "Onboarding"), 0.50, 0.8),
        (L("newOnboarding.resultIntro.stage4", table: "Onboarding"), 0.70, 0.5),
        (L("newOnboarding.resultIntro.stage5", table: "Onboarding"), 0.87, 0.5),
        (L("newOnboarding.resultIntro.stage6", table: "Onboarding"), 0.97, 0.4),
        (L("newOnboarding.resultIntro.stage7", table: "Onboarding"), 1.0, 0.3)
    ]}
    
    var body: some View {
        ZStack {
            StarsBackground(count: 8, color: .white.opacity(0.4))
            
            VStack(spacing: OBSpacing.lg) {
                Spacer()
                    .frame(height: OBSpacing.xxxl)
                
                FadeInText(
                    String(format: L("newOnboarding.resultIntro.buildingPlan", table: "Onboarding"), viewModel.displayName),
                    font: OBFont.largeTitle,
                    color: .white,
                    delay: 0.5
                )
                .padding(.horizontal, OBSpacing.lg)
                
                ZStack {
                    RingProgress(
                        progress: ringProgress,
                        lineWidth: 10,
                        size: 160
                    )
                    
                    NimmyImage(.meditation, size: 120)
                        .scaleEffect(heartbeatScale)
                        .glowEffect(color: .accentColor.opacity(0.4), radius: 25)
                }
                
                Text(displayedText + (ringComplete ? "" : "▌"))
                    .font(OBFont.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .frame(minHeight: 20)
                    .animation(.none, value: displayedText)
                    .padding(.horizontal, OBSpacing.lg)
                
                if showTips && !ringComplete {
                    TipsCarousel(
                        tips: viewModel.tips,
                        currentIndex: $viewModel.currentTipIndex
                    )
                    .frame(minHeight: 80)
                }
                
                if ringComplete {
                    FadeInText(
                        L("newOnboarding.resultIntro.completed", table: "Onboarding"),
                        font: OBFont.title,
                        color: .white,
                        delay: 0.2
                    )
                    .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
                
                if showButton {
                    FadeIn(delay: 0.2) {
                        OBButton(L("newOnboarding.resultIntro.cta", table: "Onboarding"), style: .primaryWhite) {
                            viewModel.goToNext()
                        }
                    }
                    .padding(.horizontal, OBSpacing.lg)
                    .padding(.bottom, OBSpacing.xl)
                }
            }
        }
        .onAppear {
            startHeartbeat()
            animationTask = Task { await runLoadingAnimation() }
            Task { await viewModel.startRecommendationProcess() }
            viewModel.startTipsCarousel()
        }
        .onDisappear {
            heartbeatTimer?.invalidate()
            heartbeatTimer = nil
            animationTask?.cancel()
            viewModel.stopTipsCarousel()
        }
    }
    
    // MARK: - Loading Animation
    
    private func runLoadingAnimation() async {
        try? await Task.sleep(for: .milliseconds(800))
        
        for stage in stages {
            guard !Task.isCancelled else { return }
            
            if !displayedText.isEmpty {
                await eraseText()
            }
            
            await typeText(stage.text)
            
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.8)) {
                    ringProgress = stage.target
                }
            }
            
            let pause = stage.wait + Double.random(in: 0...0.2)
            try? await Task.sleep(for: .seconds(pause))
        }
        
        await MainActor.run {
            withAnimation(.easeInOut(duration: 0.5)) {
                showTips = false
                ringComplete = true
            }
        }
        
        try? await Task.sleep(for: .seconds(0.8))
        
        await MainActor.run {
            withAnimation { showButton = true }
            heartbeatTimer?.invalidate()
            heartbeatTimer = nil
        }
    }
    
    @MainActor
    private func typeText(_ text: String) async {
        displayedText = ""
        for char in text {
            guard !Task.isCancelled else { return }
            displayedText += String(char)
            let delay = char == " " ? 20 : Int.random(in: 25...45)
            try? await Task.sleep(for: .milliseconds(delay))
        }
    }
    
    @MainActor
    private func eraseText() async {
        while !displayedText.isEmpty {
            guard !Task.isCancelled else { return }
            displayedText.removeLast()
            try? await Task.sleep(for: .milliseconds(12))
        }
    }
    
    // MARK: - Heartbeat
    
    private func startHeartbeat() {
        heartbeatTimer = Timer.scheduledTimer(withTimeInterval: 1.1, repeats: true) { _ in
            Task { @MainActor in
                withAnimation(.easeIn(duration: 0.1)) { heartbeatScale = 1.08 }
                try? await Task.sleep(for: .milliseconds(100))
                withAnimation(.easeOut(duration: 0.1)) { heartbeatScale = 1.0 }
                try? await Task.sleep(for: .milliseconds(150))
                withAnimation(.easeIn(duration: 0.08)) { heartbeatScale = 1.05 }
                try? await Task.sleep(for: .milliseconds(80))
                withAnimation(.easeOut(duration: 0.2)) { heartbeatScale = 1.0 }
            }
        }
    }
}

#Preview {
    ResultIntroScreen(viewModel: NewOnboardingViewModel())
        .background(OBColors.darkNavy.ignoresSafeArea())
}
