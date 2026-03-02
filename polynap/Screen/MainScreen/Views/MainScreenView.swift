import SwiftUI
import SwiftData

// MARK: - Redacted Shimmer Effect Modifier
struct RedactedShimmerModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .modifier(
                AnimatedMaskModifier(
                    direction: .topLeading,
                    duration: 1.5
                )
            )
    }
}

struct AnimatedMaskModifier: ViewModifier {
    enum Direction {
        case topLeading
        case bottomTrailing
        
        var start: UnitPoint {
            switch self {
            case .topLeading: return .topLeading
            case .bottomTrailing: return .bottomTrailing
            }
        }
        
        var end: UnitPoint {
            switch self {
            case .topLeading: return .bottomTrailing
            case .bottomTrailing: return .topLeading
            }
        }
    }
    
    let direction: Direction
    let duration: Double
    @State private var isAnimated = false
    
    func body(content: Content) -> some View {
        content
            .mask(
                LinearGradient(
                    gradient: Gradient(
                        stops: [
                            .init(color: .black.opacity(0.5), location: 0),
                            .init(color: .black, location: 0.3),
                            .init(color: .black, location: 0.7),
                            .init(color: .black.opacity(0.5), location: 1)
                        ]
                    ),
                    startPoint: isAnimated ? direction.end : direction.start,
                    endPoint: isAnimated ? direction.start : direction.end
                )
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: duration)
                        .repeatForever(autoreverses: false)
                ) {
                    isAnimated = true
                }
            }
    }
}

struct MainScreenView: View {
    @StateObject private var viewModel: MainScreenViewModel
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var alarmManager: AlarmManager
    @State private var hasLoggedScreenView = false
    
    // Analytics
    private let analyticsManager = AnalyticsManager.shared
    
    init(viewModel: MainScreenViewModel? = nil) {
        let initialViewModel = viewModel ?? MainScreenViewModel(languageManager: LanguageManager.shared)
        _viewModel = StateObject(wrappedValue: initialViewModel)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero Section (gradient header)
                        MainHeroSection(viewModel: viewModel)
                        
                        // Content Area
                        VStack(spacing: PSSpacing.xl) {
                            // Skipped Onboarding Card
                            if viewModel.shouldShowSkippedOnboardingCard {
                                SkippedOnboardingCardView(
                                    isPresented: $viewModel.showSkippedOnboardingCard,
                                    onChooseSchedule: {
                                        viewModel.showScheduleSelectionSheet()
                                    }
                                )
                                .onDisappear {
                                    viewModel.dismissSkippedOnboardingCard()
                                }
                            }
                            
                            // Metrics Grid
                            MetricsGridSection(viewModel: viewModel)
                            
                            // Circular Sleep Chart
                            MainChartCard(viewModel: viewModel)
                            
                            // Sleep Blocks Section
                            SleepBlocksSection(viewModel: viewModel)
                            
                            // Daily Tip Section (Nimmy)
                            DailyTipSection(viewModel: viewModel)
                        }
                        .padding(.horizontal, PSSpacing.lg)
                        .padding(.top, PSSpacing.xl)
                        .padding(.bottom, PSSpacing.xxxl)
                    }
                }
                
                // Error Overlay
                if let errorMessage = viewModel.errorMessage {
                    VStack {
                        Spacer()
                        ErrorOverlayCard(errorMessage: errorMessage, viewModel: viewModel)
                    }
                }
                
                // Sleep Quality Rating Card
                if viewModel.showSleepQualityRating, let lastBlock = viewModel.lastSleepBlock {
                    if let startTime = TimeFormatter.time(from: lastBlock.startTime),
                       let endTime = TimeFormatter.time(from: lastBlock.endTime) {
                        let now = Date()
                        let startDate = Calendar.current.date(
                            bySettingHour: startTime.hour, minute: startTime.minute, second: 0, of: now
                        ) ?? now
                        let endDate = Calendar.current.date(
                            bySettingHour: endTime.hour, minute: endTime.minute, second: 0, of: now
                        ) ?? now
                        VStack {
                            Spacer()
                            SleepQualityRatingCard(
                                startTime: startDate,
                                endTime: endDate,
                                isPresented: $viewModel.showSleepQualityRating,
                                viewModel: viewModel
                            )
                            .padding(.horizontal, PSSpacing.lg)
                            .padding(.bottom, PSSpacing.lg)
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                        }
                        .zIndex(100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if viewModel.isChartEditMode {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            viewModel.cancelChartEdit()
                        }) {
                            Text(L("common.cancel", table: "Common"))
                                .font(.system(.caption, design: .rounded).weight(.medium))
                                .foregroundColor(.appTextSecondary)
                                .padding(.horizontal, PSSpacing.sm)
                                .padding(.vertical, PSSpacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: PSCornerRadius.small)
                                        .fill(Color.appTextSecondary.opacity(0.1))
                                )
                        }
                        .transition(.move(edge: .leading).combined(with: .opacity))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isChartEditMode {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            viewModel.saveChartEdit()
                        }) {
                            HStack(spacing: PSSpacing.xs) {
                                Image(systemName: "checkmark")
                                    .symbolRenderingMode(.hierarchical)
                                    .font(.system(size: 16, weight: .medium))
                                Text(L("mainScreen.chart.save", table: "MainScreen"))
                                    .font(.system(.caption, design: .rounded).weight(.medium))
                            }
                            .foregroundColor(.appSuccess)
                            .padding(.horizontal, PSSpacing.sm)
                            .padding(.vertical, PSSpacing.xs)
                            .background(RoundedRectangle(cornerRadius: PSCornerRadius.small).fill(Color.appSuccess.opacity(0.1)))
                        }
                        .animation(.easeInOut(duration: 0.2), value: viewModel.isChartEditMode)
                    }
                }
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
                if !hasLoggedScreenView {
                    analyticsManager.logScreenView(screenName: "main_screen", screenClass: "MainScreenView")
                    hasLoggedScreenView = true
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddBlockSheet) {
            AddSleepBlockSheet(viewModel: viewModel)
        }
        .onChange(of: viewModel.showAddBlockSheet) { isPresented in
            if isPresented {
                analyticsManager.logFeatureUsed(featureName: "add_sleep_block", action: "sheet_opened")
            }
        }
        .sheet(isPresented: $viewModel.showScheduleSelection) {
            ScheduleSelectionView(
                availableSchedules: viewModel.availableSchedules,
                selectedSchedule: Binding(
                    get: { viewModel.model.schedule },
                    set: { _ in }
                ),
                onScheduleSelected: viewModel.selectSchedule,
                isPremiumUser: viewModel.isPremium
            )
            .environmentObject(languageManager)
        }
    }
}

// MARK: - Hero Section
struct MainHeroSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.sm) {
            // Greeting + Date row
            HStack {
                Text(viewModel.greetingText)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(.white.opacity(0.6))
                Text("·")
                    .foregroundColor(.white.opacity(0.4))
                Text(currentDateFormatted)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(.white.opacity(0.6))
                Spacer()
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 8)
            
            // Name + Adaptation badge
            HStack(alignment: .center, spacing: PSSpacing.sm) {
                let name = viewModel.userDisplayName
                Text(name.isEmpty ? L("mainScreen.title", table: "MainScreen") : name)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Spacer()
                
                // Adaptation day badge
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 13))
                    Text(adaptationLabel)
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, PSSpacing.sm)
                .padding(.vertical, 5)
                .background(Color.metricAmber.opacity(0.3), in: Capsule())
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 8)
            
            Spacer().frame(height: PSSpacing.md)
            
            // "Next Sleep" label
            Text(L("mainScreen.nextSleepBlock", table: "MainScreen"))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)
                .opacity(appeared ? 1 : 0)
            
            // Big countdown
            Text(viewModel.nextSleepBlockFormatted)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared || reduceMotion ? 0 : 12)
            
            // Status pill
            HStack(spacing: 6) {
                Image(systemName: viewModel.isInSleepTime ? "moon.fill" : "sun.max.fill")
                    .font(.system(size: 12, weight: .semibold))
                Text(viewModel.sleepStatusMessage)
                    .font(.system(.caption, design: .rounded).weight(.semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, PSSpacing.md)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.15), in: Capsule())
            .opacity(appeared ? 1 : 0)
        }
        .padding(.horizontal, 20)
        .padding(.top, PSSpacing.lg)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.heroTop, Color.heroBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea(edges: .top)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(heroAccessibilityLabel)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                appeared = true
            }
        }
    }
    
    private var adaptationLabel: String {
        let day = viewModel.adaptationDayCount
        if LanguageManager.shared.currentLanguage == "tr" {
            return "Gün \(day)"
        } else {
            return "Day \(day)"
        }
    }
    
    private var currentDateFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LanguageManager.shared.currentLanguage == "tr" ? "tr_TR" : "en_US")
        formatter.dateFormat = LanguageManager.shared.currentLanguage == "tr" ? "EEEE, d MMM" : "EEEE, MMM d"
        return formatter.string(from: Date())
    }
    
    private var heroAccessibilityLabel: String {
        let next = viewModel.nextSleepBlockFormatted
        let status = viewModel.sleepStatusMessage
        return "\(viewModel.greetingText). \(L("mainScreen.nextSleepBlock", table: "MainScreen")) \(next). \(status)"
    }
}

// MARK: - Metrics Grid Section
struct MetricsGridSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    
    private let columns = [
        GridItem(.flexible(), spacing: PSSpacing.md),
        GridItem(.flexible(), spacing: PSSpacing.md)
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: PSSpacing.md) {
            HomeMetricCard(
                emoji: "🌙",
                title: L("mainScreen.totalSleep", table: "MainScreen"),
                value: viewModel.totalSleepTimeFormatted,
                accentColor: .appPrimary,
                appeared: appeared,
                reduceMotion: reduceMotion,
                delay: 0.0
            )
            
            HomeMetricCard(
                emoji: "🔥",
                title: adaptationTitle,
                value: adaptationValue,
                accentColor: .metricAmber,
                appeared: appeared,
                reduceMotion: reduceMotion,
                delay: 0.08
            )
            
            HomeMetricCard(
                emoji: "📋",
                title: scheduleTitle,
                value: viewModel.model.schedule.name,
                accentColor: .metricTeal,
                appeared: appeared,
                reduceMotion: reduceMotion,
                delay: 0.16,
                onTap: { viewModel.showScheduleSelectionSheet() }
            )
            
            HomeMetricCard(
                emoji: viewModel.isInSleepTime ? "😴" : "⏰",
                title: statusTitle,
                value: viewModel.sleepStatusMessage,
                accentColor: viewModel.isInSleepTime ? .metricEmerald : .metricPurple,
                appeared: appeared,
                reduceMotion: reduceMotion,
                delay: 0.24
            )
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.35).delay(0.2)) {
                appeared = true
            }
        }
    }
    
    private var scheduleTitle: String {
        LanguageManager.shared.currentLanguage == "tr" ? "Program" : "Schedule"
    }
    
    private var adaptationTitle: String {
        LanguageManager.shared.currentLanguage == "tr" ? "Adaptasyon" : "Adaptation"
    }
    
    private var adaptationValue: String {
        let day = viewModel.adaptationDayCount
        return LanguageManager.shared.currentLanguage == "tr" ? "Gün \(day)" : "Day \(day)"
    }
    
    private var statusTitle: String {
        LanguageManager.shared.currentLanguage == "tr" ? "Durum" : "Status"
    }
}

// MARK: - Metric Card
struct HomeMetricCard: View {
    let emoji: String
    let title: String
    let value: String
    let accentColor: Color
    let appeared: Bool
    let reduceMotion: Bool
    var delay: Double = 0
    var onTap: (() -> Void)? = nil
    
    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: PSSpacing.sm) {
                // Emoji circle
                Text(emoji)
                    .font(.system(size: 20))
                    .frame(width: 36, height: 36)
                    .background(accentColor.opacity(0.12), in: Circle())
                
                // Value + Title
                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.appText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    
                    Text(title)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .frame(minHeight: 90)
            .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared || reduceMotion ? 1 : 0.95)
        .animation(.easeOut(duration: 0.3).delay(delay), value: appeared)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
        .accessibilityAddTraits(onTap != nil ? .isButton : .isStaticText)
    }
}

// MARK: - Chart Card
struct MainChartCard: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @State private var chartDragInfo: String? = nil
    
    var body: some View {
        VStack(spacing: PSSpacing.sm) {
            // Header row with edit button
            HStack {
                Text(L("mainScreen.segment.overview", table: "MainScreen"))
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.appTextSecondary)
                Spacer()
                if !viewModel.isChartEditMode {
                    Button(action: { viewModel.startChartEdit() }) {
                        HStack(spacing: 4) {
                            Image(systemName: "pencil")
                                .font(.system(size: 12, weight: .medium))
                            Text(L("mainScreen.chart.edit", table: "MainScreen"))
                                .font(.system(.caption, design: .rounded).weight(.medium))
                        }
                        .foregroundColor(.appPrimary)
                        .padding(.horizontal, PSSpacing.sm)
                        .padding(.vertical, PSSpacing.xs)
                        .background(Color.appPrimary.opacity(0.1), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Chart
            EditableCircularSleepChart(
                viewModel: viewModel,
                chartSize: .extraLarge,
                activeDragInfo: $chartDragInfo
            )
            .aspectRatio(1, contentMode: .fit)
            .frame(minHeight: 260)
            
            // Chart edit feedback
            if viewModel.isChartEditMode {
                if let dragInfo = chartDragInfo {
                    Text(dragInfo)
                        .font(.system(.caption, design: .monospaced).weight(.medium))
                        .foregroundColor(.appPrimary)
                        .transition(.opacity)
                        .id(dragInfo)
                } else {
                    ChartEditControls(viewModel: viewModel)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .padding(PSSpacing.md)
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: PSCornerRadius.extraLarge))
        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
        .animation(.easeInOut(duration: 0.3), value: viewModel.isChartEditMode)
    }
}

// MARK: - Chart Edit UI Components
struct ChartEditControls: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        VStack(spacing: PSSpacing.xs) {
            HStack(spacing: PSSpacing.xs) {
                Image(systemName: "hand.draw")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextSecondary)
                Text(L("mainScreen.chart.instruction.move", table: "MainScreen"))
                    .font(PSTypography.caption)
                    .foregroundColor(.appTextSecondary)
            }
            
            HStack(spacing: PSSpacing.xs) {
                Image(systemName: "trash")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextSecondary)
                Text(L("mainScreen.chart.instruction.delete", table: "MainScreen"))
                    .font(PSTypography.caption)
                    .foregroundColor(.appTextSecondary)
            }
            
            HStack(spacing: PSSpacing.xs) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextSecondary)
                Text(L("mainScreen.chart.instruction.add", table: "MainScreen"))
                    .font(PSTypography.caption)
                    .foregroundColor(.appTextSecondary)
            }
        }
        .padding(.horizontal, PSSpacing.md)
        .padding(.vertical, PSSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                .fill(Color.appTextSecondary.opacity(0.05))
        )
    }
}

// MARK: - Sleep Blocks Section
struct SleepBlocksSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        VStack(spacing: PSSpacing.sm) {
            HStack {
                PSSectionHeader(
                    L("mainScreen.sleepBlocks", table: "MainScreen"),
                    icon: "bed.double.fill"
                )
                
                Spacer()
                
                if viewModel.isEditing {
                    HStack(spacing: PSSpacing.sm) {
                        PSStatusBadge(
                            L("mainScreen.editing.mode", table: "MainScreen"),
                            color: .appSecondary
                        )
                        
                        PSIconButton(
                            icon: "checkmark",
                            backgroundColor: Color.appSecondary.opacity(0.15),
                            foregroundColor: .appSecondary
                        ) {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.isEditing.toggle()
                            }
                        }
                    }
                } else {
                    PSIconButton(icon: "pencil") {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.isEditing.toggle()
                        }
                    }
                }
            }
            .padding(.horizontal, PSSpacing.md)
            
            // Vertical block list
            VStack(spacing: 0) {
                ForEach(Array(viewModel.model.schedule.schedule.enumerated()), id: \.element.id) { index, block in
                    SleepBlockRow(
                        block: block,
                        isNext: block.id == viewModel.model.schedule.nextBlock?.id,
                        nextBlockTime: viewModel.nextSleepBlockFormatted,
                        viewModel: viewModel
                    )
                    
                    if index < viewModel.model.schedule.schedule.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
                
                if viewModel.isEditing {
                    Divider()
                        .padding(.leading, 56)
                    AddSleepBlockRow(viewModel: viewModel)
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .opacity
                        ))
                }
            }
            .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 18))
            .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 3)
            .animation(.spring(response: 0.45, dampingFraction: 0.8), value: viewModel.isEditing)
        }
    }
}

// MARK: - Daily Tip Section
struct DailyTipSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        VStack(spacing: PSSpacing.sm) {
            HStack(spacing: PSSpacing.xs) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.appAccent)
                Text(L("mainScreen.dailyTip.title", table: "MainScreen"))
                    .font(.system(.caption, design: .rounded).weight(.semibold))
                    .foregroundColor(.appAccent)
                Spacer()
            }
            .padding(.horizontal, PSSpacing.md)
            
            HStack(alignment: .top, spacing: PSSpacing.md) {
                NimmyImage(.meditation, size: 64)
                
                Text(viewModel.dailyTip, tableName: "Tips")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.appText)
                    .lineSpacing(4)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(PSSpacing.md)
            .background(
                LinearGradient(
                    colors: [Color.appAccent.opacity(0.08), Color.appAccent.opacity(0.03)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18)
            )
        }
    }
}

// MARK: - Sleep Quality Rating Card
struct SleepQualityRatingCard: View {
    let startTime: Date
    let endTime: Date
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        PSCard {
            SleepQualityRatingView(
                startTime: startTime,
                endTime: endTime,
                isPresented: $isPresented,
                viewModel: viewModel
            )
        }
    }
}

// MARK: - Error Overlay Card
struct ErrorOverlayCard: View {
    let errorMessage: String
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        PSErrorState(
            title: L("mainscreen.error.title", table: "MainScreen"),
            message: errorMessage
        ) {
            Task {
                await viewModel.loadScheduleFromRepository()
            }
        }
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: PSCornerRadius.extraLarge))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, PSSpacing.xxxl)
    }
}

// MARK: - Add Sleep Block Row
struct AddSleepBlockRow: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        Button(action: {
            viewModel.showAddBlockSheet = true
        }) {
            HStack(spacing: PSSpacing.md) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.appAccent)
                    .frame(width: 36, height: 36)
                
                Text(L("mainScreen.addSleepBlock", table: "MainScreen"))
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                    .foregroundColor(.appAccent)
                
                Spacer()
            }
            .padding(.horizontal, PSSpacing.lg)
            .padding(.vertical, PSSpacing.md)
            .frame(minHeight: 56)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L("mainScreen.addSleepBlock", table: "MainScreen"))
        .accessibilityAddTraits(.isButton)
    }
}

// MARK: - Sleep Block Row
struct SleepBlockRow: View {
    let block: SleepBlock
    let isNext: Bool
    let nextBlockTime: String
    
    @State private var showingEditSheet = false
    @State private var showDeleteConfirmation = false
    @ObservedObject var viewModel: MainScreenViewModel
    
    private var coreEmoji: String {
        UserDefaults.standard.string(forKey: "selectedCoreEmoji") ?? "🌙"
    }
    
    private var napEmoji: String {
        UserDefaults.standard.string(forKey: "selectedNapEmoji") ?? "💤"
    }
    
    var body: some View {
        HStack(spacing: PSSpacing.md) {
            // Emoji circle
            Text(block.isCore ? coreEmoji : napEmoji)
                .font(.system(size: 18))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(block.isCore ? Color.appPrimary.opacity(0.12) : Color.appSecondary.opacity(0.12))
                )
            
            // Time + type
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: PSSpacing.xs) {
                    Text(TimeFormatter.formattedString(from: block.startTime))
                        .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                        .foregroundColor(.appText)
                    
                    Text("—")
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.appTextSecondary)
                    
                    Text(TimeFormatter.formattedString(from: block.endTime))
                        .font(.system(.subheadline, design: .monospaced).weight(.semibold))
                        .foregroundColor(.appText)
                }
                
                Text(block.isCore ? L("mainScreen.sleepBlockCore", table: "MainScreen") : L("mainScreen.sleepBlockNap", table: "MainScreen"))
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.appTextSecondary)
            }
            
            Spacer()
            
            // Next badge
            if isNext {
                PSStatusBadge(
                    nextBlockTime,
                    icon: "arrow.right",
                    color: .appPrimary,
                    style: .compact
                )
            }
            
            // Edit menu (visible when editing)
            if viewModel.isEditing {
                Menu {
                    Button(action: {
                        viewModel.prepareForEditing(block)
                        showingEditSheet = true
                    }) {
                        Label(L("general.edit", table: "MainScreen"), systemImage: "pencil")
                    }
                    
                    Button(role: .destructive, action: {
                        showDeleteConfirmation = true
                    }) {
                        Label(L("general.delete", table: "MainScreen"), systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.appTextSecondary)
                        .frame(width: 32, height: 32)
                        .background(Color.appBackground.opacity(0.8), in: Circle())
                }
                .transition(.scale(scale: 0.8).combined(with: .opacity))
            }
        }
        .padding(.horizontal, PSSpacing.lg)
        .padding(.vertical, PSSpacing.md)
        .frame(minHeight: 64)
        .contentShape(Rectangle())
        .sheet(isPresented: $showingEditSheet) {
            EditSleepBlockSheet(viewModel: viewModel)
        }
        .confirmationDialog(
            L("sleepBlock.delete.title", table: "MainScreen"),
            isPresented: $showDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(L("sleepBlock.delete.confirm", table: "MainScreen"), role: .destructive) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.deleteBlock(block)
                }
            }
            Button(L("general.cancel", table: "MainScreen"), role: .cancel) {}
        } message: {
            Text(L("sleepBlock.delete.message", table: "MainScreen"))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(block.isCore ? L("mainScreen.sleepBlockCore", table: "MainScreen") : L("mainScreen.sleepBlockNap", table: "MainScreen")). \(TimeFormatter.formattedString(from: block.startTime)) — \(TimeFormatter.formattedString(from: block.endTime))")
    }
}

// MARK: - Edit Sleep Block Sheet
struct EditSleepBlockSheet: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker(
                        L("sleepBlock.startTime", table: "MainScreen"),
                        selection: $viewModel.editingBlockStartTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(PSTypography.body)
                    
                    DatePicker(
                        L("sleepBlock.endTime", table: "MainScreen"),
                        selection: $viewModel.editingBlockEndTime,
                        displayedComponents: .hourAndMinute
                    )
                    .font(PSTypography.body)
                }
                
                Section(header: Text(L("sleepBlock.typeTitle", table: "MainScreen")).font(PSTypography.caption)) {
                    Text(L("sleepBlock.autoType", table: "MainScreen"))
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                }
            }
            .navigationTitle(L("sleepBlock.edit", table: "MainScreen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: { dismiss() }) {
                        Text(L("general.cancel", table: "MainScreen"))
                            .font(PSTypography.button)
                            .foregroundColor(.appPrimary)
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        if viewModel.validateEditingBlock() {
                            viewModel.updateBlock()
                            dismiss()
                        }
                    }) {
                        Text(L("general.save", table: "MainScreen"))
                            .font(PSTypography.button)
                    }
                }
            }
            .alert(
                L("sleepBlock.error.title", table: "MainScreen"),
                isPresented: $viewModel.showBlockError
            ) {
                Button(L("general.ok", table: "MainScreen"), role: .cancel) {}
            } message: {
                Text(viewModel.blockErrorMessage)
            }
        }
    }
}



#Preview {
    let config = ModelConfiguration()
    let container = try! ModelContainer(for: SleepScheduleStore.self, configurations: config)
    MainScreenView(viewModel: MainScreenViewModel(languageManager: LanguageManager.shared))
        .modelContainer(container)
        .environmentObject(LanguageManager.shared)
}




// MARK: - FloatingSleepBlockView
struct FloatingSleepBlockView: View {
    let block: SleepBlock
    let position: CGPoint
    let isReadyToDelete: Bool
    let isValidDrop: Bool
    
    var body: some View {
        VStack(spacing: PSSpacing.xs) {
            Text(block.isCore ? "Core" : "Nap")
                .font(PSTypography.caption.weight(.bold))
                .foregroundColor(isReadyToDelete ? .white : .appText)
            
            Text("\(block.startTime) - \(block.endTime)")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(isReadyToDelete ? .white.opacity(0.8) : .appTextSecondary)
        }
        .padding(.horizontal, PSSpacing.md)
        .padding(.vertical, PSSpacing.sm)
        .background(
            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                .fill(isReadyToDelete ? Color.appError : (isValidDrop ? Color.appSuccess.opacity(0.2) : Color.appCardBackground))
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                .stroke(isReadyToDelete ? Color.clear : (isValidDrop ? Color.appSuccess : Color.appPrimary.opacity(0.2)), lineWidth: 1)
        )
        .scaleEffect(isReadyToDelete ? 1.1 : 1.0)
        .animation(.spring(response: 0.4, dampingFraction: 0.6), value: isReadyToDelete)
        .position(position)
        .allowsHitTesting(false)
        .drawingGroup() // Animasyon performansı için
    }
}

// MARK: - PlusButtonView
struct PlusButtonView: View {
    @ObservedObject var viewModel: MainScreenViewModel
    let center: CGPoint
    let radius: CGFloat
    
    var body: some View {
        Image(systemName: "plus.circle.fill")
            .font(.system(size: 44))
            .foregroundColor(.appAccent)
            .background(Circle().fill(Color.appBackground))
            .position(x: center.x + radius + 40, y: center.y + radius + 40)
            .allowsHitTesting(!viewModel.isDraggingNewBlock)
            .gesture(
                DragGesture(minimumDistance: 5, coordinateSpace: .local)
                    .onChanged { value in
                        if !viewModel.isDraggingNewBlock {
                            viewModel.startDraggingNewBlock(at: value.location, center: center, radius: radius)
                        }
                        viewModel.updateNewBlockDrag(to: value.location, center: center, radius: radius)
                    }
                    .onEnded { _ in
                        viewModel.endNewBlockDrag()
                    }
            )
    }
}

// MARK: - TrashAreaView
struct TrashAreaView: View {
    @ObservedObject var viewModel: MainScreenViewModel
    let center: CGPoint
    let radius: CGFloat
    
    var body: some View {
        let trashRadius: CGFloat = viewModel.isInTrashZone ? 45 : 40
        
        ZStack {
            Circle()
                .fill(viewModel.isInTrashZone ? Color.appError.opacity(0.3) : Color.appTextSecondary.opacity(0.1))
                .frame(width: trashRadius * 2, height: trashRadius * 2)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: viewModel.isInTrashZone)
                .allowsHitTesting(false)
            
            Image(systemName: "trash.fill")
                .font(.system(size: viewModel.isInTrashZone ? 28 : 24))
                .foregroundColor(viewModel.isInTrashZone ? .white : .appTextSecondary)
                .animation(.spring(response: 0.3, dampingFraction: 0.5), value: viewModel.isInTrashZone)
                .allowsHitTesting(false)
        }
        .position(x: center.x - radius - 40, y: center.y + radius + 40)
        .transition(.scale.combined(with: .opacity))
        .allowsHitTesting(false)
    }
}



// MARK: - ArcGestureArea
struct ArcGestureArea: Shape {
    let startAngle: Double
    let endAngle: Double
    let center: CGPoint
    let radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(
            center: center,
            radius: radius,
            startAngle: .degrees(startAngle),
            endAngle: .degrees(endAngle),
            clockwise: false
        )
        return path.strokedPath(.init(lineWidth: 40)) // Geniş bir dokunma alanı
    }
}

// MARK: - TimeMarkersView
struct TimeMarkersView: View {
    let center: CGPoint
    let radius: CGFloat
    
    var body: some View {
        ForEach(0..<24) { hour in
            let angle = Double(hour) * 15.0 - 90
            let position = CGPoint(
                x: center.x + radius * cos(angle * .pi / 180),
                y: center.y + radius * sin(angle * .pi / 180)
            )
            
            Text("\(hour)")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .foregroundColor(.appTextSecondary)
                .position(position)
        }
    }
}

// MARK: - CurrentTimeIndicator
struct CurrentTimeIndicator: View {
    let center: CGPoint
    let radius: CGFloat
    
    var body: some View {
        let now = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: now)
        let minute = calendar.component(.minute, from: now)
        let totalMinutes = hour * 60 + minute
        let angle = (Double(totalMinutes) / 1440.0) * 360.0 - 90
        
        let indicatorPosition = CGPoint(
            x: center.x + radius * cos(angle * .pi / 180),
            y: center.y + radius * sin(angle * .pi / 180)
        )
        
        Circle()
            .fill(Color.appAccent)
            .frame(width: 10, height: 10)
            .position(indicatorPosition)
    }
}



