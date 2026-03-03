import SwiftUI
import SwiftData

struct PersonalInfoView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.colorScheme) private var colorScheme
    
    // State için async veri yükleme
    @State private var onboardingAnswers: [OnboardingAnswerData] = []
    @State private var scheduleStore: [SleepScheduleStore] = []
    @State private var isLoading = true
    
    var answersForDisplay: [String: String] {
        var dict: [String: String] = [:]
        for answerData in onboardingAnswers {
            dict[answerData.question] = answerData.answer
        }
        return dict
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: PSSpacing.xl) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                        .padding(.top, PSSpacing.xxl)
                } else if answersForDisplay.isEmpty {
                    VStack(spacing: 12) {
                        Text(L("personalInfo.empty.title", table: "Profile"))
                            .font(.system(.headline, design: .rounded, weight: .semibold))
                            .foregroundColor(.appText)
                        Text(L("personalInfo.empty.message", table: "Profile"))
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundColor(.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, PSSpacing.xxl)
                    .padding(.horizontal, PSSpacing.xl)
                } else {
                    // Active Schedule Card
                    if let schedule = scheduleStore.first {
                        SettingsGroup(title: L("personalInfo.schedule.title", table: "Profile")) {
                            HStack(spacing: 12) {
                                Image(systemName: "bed.double")
                                    .font(.system(size: 18, weight: .regular))
                                    .foregroundColor(.appAccent)
                                    .frame(width: 24, height: 24)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(schedule.name)
                                        .font(.system(.body, design: .rounded, weight: .medium))
                                        .foregroundColor(.appText)
                                    Text("\(String(format: "%.1f", schedule.totalSleepHours)) " + L("personalInfo.schedule.hours", table: "Profile"))
                                        .font(.system(size: 13, design: .rounded))
                                        .foregroundColor(.appTextSecondary)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 13)
                        }
                    }

                    // Onboarding Answers
                    SettingsGroup(title: L("personalInfo.answers.title", table: "Profile")) {
                        let questions = getOrderedQuestions()
                        ForEach(Array(questions.enumerated()), id: \.element) { index, question in
                            if let answer = answersForDisplay[question] {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(getLocalizedQuestion(for: question).uppercased())
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .foregroundColor(.appTextSecondary)
                                    Text(getLocalizedAnswer(for: question, value: answer))
                                        .font(.system(.body, design: .rounded, weight: .medium))
                                        .foregroundColor(.appText)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 13)

                                if index < questions.count - 1 {
                                    Divider().padding(.leading, 16)
                                }
                            }
                        }
                    }
                }

                Spacer(minLength: PSSpacing.xl)
            }
            .padding(.horizontal, PSSpacing.lg)
            .padding(.top, PSSpacing.sm)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .navigationTitle(L("personalInfo.title", table: "Profile"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadDataAsync()
        }
    }
    
    // MARK: - Data Loading
    private func loadDataAsync() {
        // Zaten yüklü ise tekrar yükleme
        guard isLoading else { return }
        
        Task { @MainActor in
            do {
                // SwiftData'dan async olarak veri çek
                let fetchDescriptor1 = FetchDescriptor<OnboardingAnswerData>()
                let answers = try modelContext.fetch(fetchDescriptor1)
                
                let fetchDescriptor2 = FetchDescriptor<SleepScheduleStore>()
                let schedules = try modelContext.fetch(fetchDescriptor2)
                
                onboardingAnswers = answers
                scheduleStore = schedules
                isLoading = false
            } catch {
                print("PersonalInfoView: Veri yükleme hatası - \(error)")
                isLoading = false
            }
        }
    }
    
    private func getOrderedQuestions() -> [String] {
        let orderedQuestions = [
            "onboarding.sleepExperience", 
            "onboarding.ageRange", 
            "onboarding.workSchedule", 
            "onboarding.napEnvironment",
            "onboarding.lifestyle", 
            "onboarding.knowledgeLevel", 
            "onboarding.healthStatus", 
            "onboarding.motivationLevel",
            "onboarding.sleepGoal", 
            "onboarding.socialObligations", 
            "onboarding.disruptionTolerance", 
            "onboarding.chronotype"
        ]
        
        return orderedQuestions.filter { answersForDisplay.keys.contains($0) }
    }
    
    private func getLocalizedQuestion(for question: String) -> String {
        let key = question
        return NSLocalizedString(key, tableName: "Onboarding", comment: "")
    }
    
    private func getLocalizedAnswer(for question: String, value: String) -> String {
        let key = "\(question).\(value)"
        return NSLocalizedString(key, tableName: "Onboarding", comment: "")
    }
}

// MARK: - Modern Components

// Modern card component with enhanced styling
struct PersonalInfoModernCard<Content: View>: View {
    @ViewBuilder let content: Content
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        content
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.appCardBackground)
                    .overlay(
                        // Subtle border for light mode
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        Color.gray.opacity(colorScheme == .light ? 0.15 : 0),
                                        Color.gray.opacity(colorScheme == .light ? 0.05 : 0)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: colorScheme == .light ? 
                        Color.black.opacity(0.08) : 
                        Color.black.opacity(0.3),
                        radius: colorScheme == .light ? 12 : 16,
                        x: 0,
                        y: colorScheme == .light ? 6 : 8
                    )
            )
    }
}

// Enhanced answer card with modern design
struct PersonalInfoAnswerCard: View {
    let question: String
    let answer: String
    let index: Int
    @Environment(\.colorScheme) private var colorScheme
    
    // Define accent colors for variety
    private var accentColor: Color {
        let colors: [Color] = [.appPrimary, .appAccent, .appSecondary, .blue, .purple, .orange]
        return colors[index % colors.count]
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Question with colored accent
            HStack(spacing: 8) {
                Circle()
                    .fill(accentColor.opacity(0.2))
                    .frame(width: 6, height: 6)
                
                Text(question)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            // Answer text
            Text(answer)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.appText)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            accentColor.opacity(0.03),
                            accentColor.opacity(0.01)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(accentColor.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

struct PersonalInfoView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            PersonalInfoView()
        }
        .environmentObject(LanguageManager.shared)
    }
}
