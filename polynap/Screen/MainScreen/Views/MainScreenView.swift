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
    @StateObject private var tourManager = AppTourManager.shared
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
                
                ScrollViewReader { scrollProxy in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero Section (gradient header – extends behind status bar)
                        MainHeroSection(viewModel: viewModel)
                            .id("scroll.main.top")
                        
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
                            
                            // Weekly Streak Tracker
                            WeeklyStreakSection(viewModel: viewModel)
                            
                            // Metrics Grid (Total Sleep + Schedule)
                            MetricsGridSection(viewModel: viewModel)
                            
                            // Circular Sleep Chart
                            MainChartCard(viewModel: viewModel)
                                .tourTarget("tour.main.chartCard")
                                .id("tour.main.chartCard")
                            
                            // Daily Tip Section (Nimmy)
                            DailyTipSection(viewModel: viewModel)
                        }
                        .padding(.horizontal, PSSpacing.lg)
                        .padding(.top, PSSpacing.xl)
                        .padding(.bottom, PSSpacing.xxxl)
                    }
                }
                .ignoresSafeArea(.container, edges: .top)
                .onChange(of: tourManager.currentStepIndex) { _, newIndex in
                    handleTourScroll(newIndex: newIndex, proxy: scrollProxy)
                    handleTourEditMode(newIndex: newIndex)
                }
                .onChange(of: tourManager.isShowingTour) { _, isShowing in
                    if isShowing { handleTourStart(proxy: scrollProxy) }
                }
                } // end ScrollViewReader
                
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
                                .font(.system(.body, design: .rounded).weight(.regular))
                                .foregroundColor(.secondary)
                        }
                        .transition(.opacity.combined(with: .scale(0.9)))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if viewModel.isChartEditMode {
                        Button(action: {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            viewModel.saveChartEdit()
                        }) {
                            Text(L("mainScreen.chart.save", table: "MainScreen"))
                                .font(.system(.body, design: .rounded).weight(.semibold))
                                .foregroundColor(Color("SuccessColor"))
                        }
                        .transition(.opacity.combined(with: .scale(0.9)))
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

    // MARK: - Tour helpers

    private func handleTourScroll(newIndex: Int, proxy: ScrollViewProxy) {
        guard let step = TourStep(rawValue: newIndex), step.requiredTab == 0 else { return }
        let scrollId: String
        switch step {
        case .overview, .editButton:
            scrollId = "tour.main.chartCard"
        case .changeSchedule:
            scrollId = "scroll.main.top"
        default: return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeInOut(duration: 0.35)) {
                proxy.scrollTo(scrollId, anchor: scrollId == "scroll.main.top" ? .top : UnitPoint(x: 0.5, y: 0.25))
            }
        }
    }

    /// Fired when tour becomes active — handles the step-0 initial scroll since
    /// currentStepIndex is already 0, so onChange(of:) won't fire for it.
    private func handleTourStart(proxy: ScrollViewProxy) {
        guard tourManager.isShowingTour, tourManager.currentStepIndex == 0 else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.easeInOut(duration: 0.35)) {
                proxy.scrollTo("tour.main.chartCard", anchor: UnitPoint(x: 0.5, y: 0.25))
            }
        }
    }

    private func handleTourEditMode(newIndex: Int) {
        if newIndex == TourStep.editButton.rawValue {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                if !viewModel.isChartEditMode { viewModel.startChartEdit() }
            }
        } else if newIndex > TourStep.editButton.rawValue && viewModel.isChartEditMode {
            viewModel.cancelChartEdit()
        }
    }
}
struct MainHeroSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false
    @State private var descriptionExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Row 1: Greeting · Date
            HStack(alignment: .center, spacing: PSSpacing.xs) {
                Text(viewModel.greetingText)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(.white.opacity(0.6))
                Text("·")
                    .foregroundColor(.white.opacity(0.35))
                Text(currentDateFormatted)
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 8)

            Spacer().frame(height: PSSpacing.sm)

            // Row 2: Schedule name (prominent, tappable → schedule selection)
            HStack(spacing: PSSpacing.xs) {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    viewModel.showScheduleSelectionSheet()
                }) {
                    HStack(spacing: PSSpacing.xs) {
                        Text(viewModel.model.schedule.name)
                            .font(.system(.title3, design: .rounded).weight(.bold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                .buttonStyle(.plain)
                .tourTarget("tour.main.scheduleButton")

                Spacer()

                // Info toggle for schedule description
                if !viewModel.currentScheduleDescription.isEmpty {
                    Button(action: {
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                            descriptionExpanded.toggle()
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }) {
                        Image(systemName: descriptionExpanded ? "info.circle.fill" : "info.circle")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(descriptionExpanded ? 0.9 : 0.45))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(descriptionExpanded ? "Hide schedule description" : "Show schedule description")
                }
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared || reduceMotion ? 0 : 8)

            // Row 3: Collapsible description
            if descriptionExpanded {
                Text(viewModel.currentScheduleDescription)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.75))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, PSSpacing.sm)
                    .transition(.opacity.combined(with: .scale(0.97, anchor: .topLeading)))
            }

            Spacer().frame(height: descriptionExpanded ? PSSpacing.xl : PSSpacing.lg)

            // Row 4: NEXT SLEEP label
            Text(L("mainScreen.nextSleepBlock", table: "MainScreen"))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
                .textCase(.uppercase)
                .tracking(0.5)
                .opacity(appeared ? 1 : 0)

            // Row 5: Big countdown
            Text(viewModel.nextSleepBlockFormatted)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
                .minimumScaleFactor(0.7)
                .lineLimit(1)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared || reduceMotion ? 0 : 12)
        }
        .padding(.horizontal, 20)
        .padding(.top, statusBarHeight + PSSpacing.lg)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.heroTop, Color.heroBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(HeroShape())
        .shadow(color: Color.heroTop.opacity(0.35), radius: 20, x: 0, y: 12)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(heroAccessibilityLabel)
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                appeared = true
            }
        }
    }

    private var statusBarHeight: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.statusBarManager?.statusBarFrame.height ?? 54
    }

    private var currentDateFormatted: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: LanguageManager.shared.currentLanguage == "tr" ? "tr_TR" : "en_US")
        formatter.dateFormat = LanguageManager.shared.currentLanguage == "tr" ? "EEEE, d MMM" : "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    private var heroAccessibilityLabel: String {
        let next = viewModel.nextSleepBlockFormatted
        let schedule = viewModel.model.schedule.name
        return "\(viewModel.greetingText). \(schedule). \(L("mainScreen.nextSleepBlock", table: "MainScreen")) \(next)"
    }
}

// MARK: - Hero Shape (Rounded Bottom)
struct HeroShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: .zero)
        path.addLine(to: CGPoint(x: rect.maxX, y: 0))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - 24))
        path.addQuadCurve(
            to: CGPoint(x: 0, y: rect.maxY - 24),
            control: CGPoint(x: rect.midX, y: rect.maxY + 12)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Weekly Streak Section
struct WeeklyStreakSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    var body: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                Text(LanguageManager.shared.currentLanguage == "tr" ? "Adaptasyon Serisi" : "Adaptation Streak")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.appText)
                Spacer()
                // Total streak badge
                HStack(spacing: 4) {
                    Text("🔥")
                        .font(.system(size: 14))
                    Text(streakText)
                        .font(.system(.caption, design: .rounded).weight(.bold))
                        .foregroundColor(.metricAmber)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.metricAmber.opacity(0.12), in: Capsule())
            }
            
            // Week days row
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.dayName) { day in
                    VStack(spacing: 4) {
                        Text(day.dayName)
                            .font(.system(size: 10, weight: .medium, design: .rounded))
                            .foregroundColor(.appTextSecondary)
                        
                        Text(day.dateNum)
                            .font(.system(size: 12, weight: day.isToday ? .bold : .medium, design: .rounded))
                            .foregroundColor(day.isToday ? .white : (day.isCompleted ? .appText : .appTextTertiary))
                            .frame(width: 28, height: 28)
                            .background(
                                Circle()
                                    .fill(day.isToday ? Color.heroBottom : (day.isCompleted ? Color.metricAmber.opacity(0.15) : Color.clear))
                            )
                            .overlay(
                                Circle()
                                    .stroke(day.isCompleted && !day.isToday ? Color.metricAmber.opacity(0.4) : Color.clear, lineWidth: 1.5)
                            )
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, PSSpacing.lg)
        .padding(.vertical, 12)
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 18))
        .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 3)
    }
    
    private var streakText: String {
        let days = viewModel.adaptationDayCount
        return LanguageManager.shared.currentLanguage == "tr" ? "\(days) gün" : "\(days) days"
    }
    
    private struct WeekDay {
        let dayName: String
        let dateNum: String
        let isToday: Bool
        let isCompleted: Bool
    }
    
    private var weekDays: [WeekDay] {
        let calendar = Calendar.current
        let today = Date()
        let isTR = LanguageManager.shared.currentLanguage == "tr"
        
        // Find Monday of current week
        var comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        comps.weekday = 2 // Monday
        let monday = calendar.date(from: comps) ?? today
        
        let dayNames: [String] = isTR
            ? ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]
            : ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        
        let adaptationStart = viewModel.adaptationStartDate ?? today
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "d"
        
        return (0..<7).map { offset in
            let date = calendar.date(byAdding: .day, value: offset, to: monday) ?? today
            let isToday = calendar.isDateInToday(date)
            let isCompleted = date >= calendar.startOfDay(for: adaptationStart) && date <= calendar.startOfDay(for: today)
            return WeekDay(
                dayName: dayNames[offset],
                dateNum: dateFormatter.string(from: date),
                isToday: isToday,
                isCompleted: isCompleted
            )
        }
    }
}

// MARK: - Metrics Grid Section
struct MetricsGridSection: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 0) {
            CompactMetricItem(
                emoji: "🌙",
                value: viewModel.totalSleepTimeFormatted,
                label: LanguageManager.shared.currentLanguage == "tr" ? "Toplam Uyku" : "Total Sleep"
            )

            Rectangle()
                .fill(Color.appTextSecondary.opacity(0.2))
                .frame(width: 1, height: 32)

            CompactMetricItem(
                emoji: "🛏️",
                value: "\(viewModel.model.schedule.schedule.count)",
                label: LanguageManager.shared.currentLanguage == "tr" ? "Uyku Bloğu" : "Sleep Blocks"
            )
        }
        .padding(.vertical, PSSpacing.sm)
        .padding(.horizontal, PSSpacing.md)
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: 14))
        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 3)
        .opacity(appeared ? 1 : 0)
        .scaleEffect(appeared || reduceMotion ? 1 : 0.97)
        .animation(.spring(response: 0.4, dampingFraction: 0.85).delay(0.15), value: appeared)
        .onAppear {
            appeared = true
        }
    }
}

private struct CompactMetricItem: View {
    let emoji: String
    let value: String
    let label: String

    var body: some View {
        HStack(spacing: PSSpacing.sm) {
            Text(emoji)
                .font(.system(size: 20))
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.appText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.appTextSecondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
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
                    .font(.system(.headline, design: .rounded).weight(.semibold))
                    .foregroundColor(.appText)
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
                    .tourTarget("tour.main.editButton")
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
                        .transition(.opacity.combined(with: .scale(0.95, anchor: .bottom)))
                }
            }
        }
        .padding(PSSpacing.md)
        .background(Color.appCardBackground, in: RoundedRectangle(cornerRadius: PSCornerRadius.extraLarge))
        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 3)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: viewModel.isChartEditMode)
        .sheet(isPresented: $viewModel.showChartBlockEditSheet) {
            ChartBlockEditSheet(viewModel: viewModel)
        }
    }
}

// MARK: - Chart Edit UI Components
struct ChartEditControls: View {
    @ObservedObject var viewModel: MainScreenViewModel
    
    private var isDragging: Bool {
        viewModel.draggedBlockId != nil || viewModel.isResizing
    }
    
    var body: some View {
        HStack(spacing: PSSpacing.sm) {
            EditChip(
                icon: "hand.draw",
                label: LanguageManager.shared.currentLanguage == "tr" ? "Sürükle" : "Move",
                isActive: isDragging
            )
            EditChip(
                icon: "trash",
                label: LanguageManager.shared.currentLanguage == "tr" ? "Sil" : "Delete",
                isActive: false
            )
            EditChip(
                icon: "plus",
                label: LanguageManager.shared.currentLanguage == "tr" ? "Ekle" : "Add",
                isActive: false
            )
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isDragging)
    }
}

private struct EditChip: View {
    let icon: String
    let label: String
    let isActive: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .medium))
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
        }
        .foregroundColor(isActive ? Color.heroBottom : .appTextSecondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .frame(minHeight: 32)
        .background(
            Capsule()
                .fill(isActive ? Color.heroBottom.opacity(0.12) : Color.appTextSecondary.opacity(0.07))
        )
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isActive)
    }
}

// MARK: - Chart Block Tap Edit Sheet
struct ChartBlockEditSheet: View {
    @ObservedObject var viewModel: MainScreenViewModel
    @Environment(\.dismiss) private var dismiss
    private var isTR: Bool { LanguageManager.shared.currentLanguage == "tr" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Block type badge
                if let block = viewModel.chartEditingBlock {
                    HStack(spacing: PSSpacing.sm) {
                        Image(systemName: block.isCore ? "moon.fill" : "powersleep")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(block.isCore ? .appPrimary : .appSecondary)
                        Text(block.isCore
                             ? L("mainScreen.sleepBlockCore", table: "MainScreen")
                             : L("mainScreen.sleepBlockNap", table: "MainScreen"))
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(block.isCore ? .appPrimary : .appSecondary)
                    }
                    .padding(.horizontal, PSSpacing.lg)
                    .padding(.vertical, PSSpacing.sm)
                    .background((block.isCore ? Color.appPrimary : Color.appSecondary).opacity(0.1),
                                in: Capsule())
                    .padding(.top, PSSpacing.md)
                }

                // Stacked time pickers
                VStack(spacing: 0) {
                    Text(isTR ? "Başlangıç" : "Start Time")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundColor(.appTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, PSSpacing.lg)
                        .padding(.top, PSSpacing.md)

                    DatePicker("",
                               selection: $viewModel.chartEditStartDate,
                               displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, PSSpacing.sm)

                    Divider()
                        .padding(.horizontal, PSSpacing.lg)

                    Text(isTR ? "Bitiş" : "End Time")
                        .font(.system(.caption, design: .rounded).weight(.semibold))
                        .foregroundColor(.appTextSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, PSSpacing.lg)
                        .padding(.top, PSSpacing.sm)

                    DatePicker("",
                               selection: $viewModel.chartEditEndDate,
                               displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        .frame(maxWidth: .infinity)
                        .padding(.horizontal, PSSpacing.sm)
                }

                Divider()
                    .padding(.top, PSSpacing.sm)

                // Delete button
                Button(role: .destructive, action: {
                    viewModel.deleteChartBlock()
                }) {
                    HStack {
                        Spacer()
                        Label(isTR ? "Bloğu Sil" : "Delete Block",
                              systemImage: "trash")
                            .font(.system(.body, design: .rounded).weight(.medium))
                        Spacer()
                    }
                    .padding(.vertical, PSSpacing.md)
                }
                .padding(.horizontal, PSSpacing.md)

                Spacer()
            }
            .background(Color.appBackground)
            .navigationTitle(isTR ? "Bloğu Düzenle" : "Edit Block")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: {
                        viewModel.showChartBlockEditSheet = false
                        viewModel.chartEditingBlock = nil
                    }) {
                        Text(L("common.cancel", table: "Common"))
                            .font(.system(.body, design: .rounded).weight(.regular))
                            .foregroundColor(.secondary)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(action: {
                        viewModel.applyChartBlockEdit()
                    }) {
                        Text(isTR ? "Tamam" : "Done")
                            .font(.system(.body, design: .rounded).weight(.semibold))
                            .foregroundColor(Color("SuccessColor"))
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
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
            .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 3)
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
        ZStack {
            Circle()
                .fill(viewModel.isInTrashZone ? Color.appError.opacity(0.3) : Color.appTextSecondary.opacity(0.1))
                .frame(width: 80, height: 80)
                .scaleEffect(viewModel.isInTrashZone ? 1.125 : 1.0)
                .allowsHitTesting(false)
            
            Image(systemName: "trash.fill")
                .font(.system(size: 24))
                .scaleEffect(viewModel.isInTrashZone ? 28.0 / 24.0 : 1.0)
                .foregroundColor(viewModel.isInTrashZone ? .white : .appTextSecondary)
                .allowsHitTesting(false)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.5), value: viewModel.isInTrashZone)
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



