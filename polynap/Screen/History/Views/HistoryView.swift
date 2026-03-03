import SwiftUI
import SwiftData

struct HistoryView: View {
    @StateObject private var viewModel = HistoryViewModel()
    @StateObject private var profileViewModel = ProfileScreenViewModel()
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    @EnvironmentObject private var mainScreenViewModel: MainScreenViewModel
    
    // Analytics
    private let analyticsManager = AnalyticsManager.shared
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero Header
                        HistoryHeroHeader(viewModel: viewModel)
                            .tourTarget("tour.history.content")
                        
                        VStack(spacing: PSSpacing.xl) {
                            // Filter Section
                            FilterSectionCard(viewModel: viewModel)
                            
                            // Unified Sleep Timeline - includes both manual and HealthKit data
                            let healthKitDataToUse = viewModel.filteredHealthKitData.isEmpty ? viewModel.healthKitData : viewModel.filteredHealthKitData
                            if viewModel.historyItems.isEmpty && healthKitDataToUse.isEmpty {
                                EmptyStateCard()
                            } else {
                                HistoryTimelineSection(viewModel: viewModel, profileViewModel: profileViewModel)
                            }
                        }
                        .padding(.horizontal, PSSpacing.lg)
                        .padding(.top, PSSpacing.xl)
                        .padding(.bottom, 100)
                    }
                }
                .ignoresSafeArea(.container, edges: .top)
                
                // Floating Action Button
                ModernFloatingActionButton(action: {
                    // Analytics: FAB Add Sleep Entry button tap
                    analyticsManager.logFeatureUsed(
                        featureName: "add_sleep_entry_fab",
                        action: "button_tap"
                    )
                    
                    // Önce tüm sheet state'lerini sıfırla
                    viewModel.isDayDetailPresented = false
                    viewModel.selectedDay = nil
                    
                    // Sonra add sheet'i aç
                    DispatchQueue.main.async {
                        viewModel.isAddSleepEntryPresented = true
                    }
                })
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $viewModel.isDayDetailPresented) {
                viewModel.selectedDay = nil
            } content: {
                if viewModel.selectedDay != nil {
                    DayDetailView(viewModel: viewModel)
                }
            }
            .onChange(of: viewModel.isDayDetailPresented) { isPresented in
                if isPresented {
                    // Analytics: Day detail navigation
                    analyticsManager.logFeatureUsed(
                        featureName: "day_detail_navigation",
                        action: "day_selected"
                    )
                }
            }
            .sheet(isPresented: $viewModel.isAddSleepEntryPresented) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    viewModel.reloadData()
                }
            } content: {
                AddSleepEntrySheet(
                    viewModel: viewModel,
                    availableBlocks: mainScreenViewModel.model.schedule.schedule
                )
            }
            .onAppear {
                viewModel.setModelContext(modelContext)
                profileViewModel.setModelContext(modelContext)
                
                // HealthKit verilerini direkt yükle (first load için) - küçük delay ile
                Task {
                    // Context'in set edilmesini bekle
                    try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 saniye
                    await viewModel.loadHealthKitData()
                }
                
                // Analytics: History screen görüntüleme
                analyticsManager.logScreenView(
                    screenName: "history_screen",
                    screenClass: "HistoryView"
                )
            }
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("EmojiPreferencesChanged"))) { notification in
                // Emoji tercihleri değiştiğinde ProfileViewModel'i güncelle
                if let userInfo = notification.userInfo,
                   let coreEmoji = userInfo["selectedCoreEmoji"] as? String,
                   let napEmoji = userInfo["selectedNapEmoji"] as? String {
                    profileViewModel.selectedCoreEmoji = coreEmoji
                    profileViewModel.selectedNapEmoji = napEmoji
                    print("HistoryView: Emoji tercihleri güncellendi - Core: \(coreEmoji), Nap: \(napEmoji)")
                }
            }

        }
        .accentColor(Color.appPrimary)
        .id(languageManager.currentLanguage)
    }
}

// MARK: - History Hero Header
struct HistoryHeroHeader: View {
    @ObservedObject var viewModel: HistoryViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    private var statusBarHeight: CGFloat {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.statusBarManager?.statusBarFrame.height ?? 54
    }

    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.sm) {
            Text(L("Sleep History", table: "History"))
                .font(.system(.title3, design: .rounded).weight(.bold))
                .foregroundColor(.white)

            HStack(spacing: PSSpacing.xs) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                let count = viewModel.historyItems.count
                Text(languageManager.currentLanguage == "tr"
                     ? "\(count) kayıt"
                     : "\(count) records")
                    .font(.system(.caption, design: .rounded).weight(.medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared || reduceMotion ? 0 : 8)
        .padding(.horizontal, 20)
        .padding(.top, statusBarHeight + PSSpacing.lg)
        .padding(.bottom, 28)
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
        .onAppear {
            withAnimation(.easeOut(duration: 0.4).delay(0.1)) {
                appeared = true
            }
        }
    }
}

// MARK: - Filter Section Card
struct FilterSectionCard: View {
    @ObservedObject var viewModel: HistoryViewModel
    @State private var showAdvancedFilters = false
    
    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                // Header with expand/collapse button
                HStack {
                    PSSectionHeader(
                        L("history.filter.title", table: "History"),
                        icon: "line.3.horizontal.decrease.circle.fill"
                    )
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showAdvancedFilters.toggle()
                        }
                    }) {
                        HStack(spacing: PSSpacing.xs) {
                            Text(showAdvancedFilters ? "Less" : "More")
                                .font(PSTypography.caption)
                                .foregroundColor(.appPrimary)
                            
                            Image(systemName: showAdvancedFilters ? "chevron.up" : "chevron.down")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.appPrimary)
                        }
                    }
                    .buttonStyle(.plain)
                }
                
                // Time filters (always visible)
                VStack(alignment: .leading, spacing: PSSpacing.md) {
                    Text("Time Range")
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                        .fontWeight(.semibold)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: PSSpacing.sm) {
                            ForEach(TimeFilter.allCases, id: \.self) { filter in
                                FilterChip(
                                    title: filter == .specificDate ? "Specific Date" : filter.localizedTitle,
                                    isSelected: viewModel.selectedFilter == filter,
                                    action: { 
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            viewModel.setFilter(filter)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, PSSpacing.xs)
                    }
                    
                    // Date picker for specific date filter
                    if viewModel.selectedFilter == .specificDate {
                        DatePicker(
                            "Select Date",
                            selection: Binding(
                                get: { viewModel.selectedSpecificDate },
                                set: { viewModel.setSpecificDate($0) }
                            ),
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                        .padding(.top, PSSpacing.xs)
                        .transition(.opacity.combined(with: .slide))
                    }
                }
                
                // Advanced filters (collapsible)
                if showAdvancedFilters {
                    VStack(alignment: .leading, spacing: PSSpacing.lg) {
                        Divider()
                            .background(Color.appBorder.opacity(0.3))
                        
                        // Sleep Type Filter
                        FilterSection(
                            title: "Sleep Type",
                            filters: SleepTypeFilter.allCases,
                            selectedFilter: viewModel.selectedSleepTypeFilter,
                            onFilterSelected: { viewModel.setSleepTypeFilter($0) }
                        )
                        
                        // Rating Filter
                        FilterSection(
                            title: "Rating",
                            filters: RatingFilter.allCases,
                            selectedFilter: viewModel.selectedRatingFilter,
                            onFilterSelected: { viewModel.setRatingFilter($0) }
                        )
                        
                        // Source Filter
                        FilterSection(
                            title: "Data Source",
                            filters: SourceFilter.allCases,
                            selectedFilter: viewModel.selectedSourceFilter,
                            onFilterSelected: { viewModel.setSourceFilter($0) }
                        )
                        
                        // Adjustment Filter
                        FilterSection(
                            title: "Adjustment Type",
                            filters: AdjustmentFilter.allCases,
                            selectedFilter: viewModel.selectedAdjustmentFilter,
                            onFilterSelected: { viewModel.setAdjustmentFilter($0) }
                        )
                        
                        // Reset filters button
                        HStack {
                            Spacer()
                            Button(action: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    viewModel.resetAllFilters()
                                }
                            }) {
                                HStack(spacing: PSSpacing.xs) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.system(size: 12))
                                    Text("Reset All")
                                        .font(PSTypography.caption)
                                }
                                .foregroundColor(.appSecondary)
                                .padding(.horizontal, PSSpacing.md)
                                .padding(.vertical, PSSpacing.sm)
                                .background(
                                    RoundedRectangle(cornerRadius: PSCornerRadius.small)
                                        .fill(Color.appSecondary.opacity(0.1))
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .transition(.asymmetric(
                        insertion: .opacity.combined(with: .move(edge: .top)),
                        removal: .opacity.combined(with: .move(edge: .top))
                    ))
                }
            }
        }
    }
}

// MARK: - Filter Section Component
struct FilterSection<T: RawRepresentable & CaseIterable & Hashable>: View where T.RawValue == String {
    let title: String
    let filters: [T]
    let selectedFilter: T
    let onFilterSelected: (T) -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: PSSpacing.sm) {
            Text(title)
                .font(PSTypography.caption)
                .foregroundColor(.appTextSecondary)
                .fontWeight(.semibold)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PSSpacing.sm) {
                    ForEach(filters, id: \.self) { filter in
                        FilterChip(
                            title: getLocalizedTitle(for: filter),
                            isSelected: selectedFilter == filter,
                            action: { 
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    onFilterSelected(filter)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, PSSpacing.xs)
            }
        }
    }
    
    private func getLocalizedTitle(for filter: T) -> String {
        if let timeFilter = filter as? TimeFilter {
            return timeFilter.localizedTitle
        } else if let sleepTypeFilter = filter as? SleepTypeFilter {
            return sleepTypeFilter.localizedTitle
        } else if let ratingFilter = filter as? RatingFilter {
            return ratingFilter.localizedTitle
        } else if let sourceFilter = filter as? SourceFilter {
            return sourceFilter.localizedTitle
        } else if let adjustmentFilter = filter as? AdjustmentFilter {
            return adjustmentFilter.localizedTitle
        }
        return filter.rawValue
    }
}

// MARK: - Filter Chip
struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .semibold : .medium, design: .rounded))
                .foregroundColor(isSelected ? .appTextOnPrimary : .appTextSecondary)
                .lineLimit(1)
            .padding(.horizontal, PSSpacing.md)
            .padding(.vertical, PSSpacing.sm)
            .background(
                RoundedRectangle(cornerRadius: PSCornerRadius.small)
                    .fill(isSelected ? Color.appPrimary : Color.appCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: PSCornerRadius.small)
                            .stroke(
                                isSelected ? Color.clear : Color.appBorder.opacity(0.3),
                                lineWidth: 1
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.25, dampingFraction: 0.85), value: isSelected)
    }
}

// MARK: - Empty State Card
struct EmptyStateCard: View {
    var body: some View {
        PSEmptyState(
            icon: "bed.double",
            title: L("history.noRecords.title", table: "History"),
            message: L("history.noRecords.message", table: "History"),
            actionTitle: L("history.addNewRecord", table: "History"),
            action: {
                // Add new record action will be handled by parent
            }
        )
    }
}

// MARK: - Modern Sleep Timeline Section
struct HistoryTimelineSection: View {
    @ObservedObject var viewModel: HistoryViewModel
    @ObservedObject var profileViewModel: ProfileScreenViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    
    var body: some View {
        PSCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: PSSpacing.lg) {
                    PSSectionHeader(
                        L("history.timeline.title", table: "History"),
                        icon: "calendar",
                        action: nil,
                        actionIcon: nil
                    )
                    
                    PSStatusBadge(
                        String(format: L("history.timeline.count", table: "History"), getTotalDaysCount()),
                        color: .appAccent
                    )
                }
                .padding(.horizontal, PSSpacing.lg)
                .padding(.top, PSSpacing.lg)
                
                // Unified Timeline Content with Visual Connectors
                // Using PSSpacing.sm (8pt) for tighter timeline flow as requested by UX designer
                LazyVStack(spacing: PSSpacing.sm) {
                    let unifiedDays = getUnifiedDailyData()
                    ForEach(Array(unifiedDays.enumerated()), id: \.element.date) { index, dayData in
                        TimelineCardWrapper(
                            dayData: dayData,
                            viewModel: viewModel,
                            profileViewModel: profileViewModel,
                            isFirst: index == 0,
                            isLast: index == unifiedDays.count - 1
                        )
                        .padding(.horizontal, PSSpacing.sm)
                        .id(dayData.date) // Stable identity for better animation performance
                    }
                }
                .padding(.vertical, PSSpacing.md)
                .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: viewModel.historyItems.count)
            }
        }
    }
    
    private func getTotalDaysCount() -> Int {
        return getUnifiedDailyData().count
    }
    
    private func getUnifiedDailyData() -> [UnifiedDayData] {
        var unifiedDays: [UnifiedDayData] = []
        
        // Use filtered HealthKit data instead of raw data
        let healthKitDataToUse = viewModel.filteredHealthKitData.isEmpty ? viewModel.healthKitData : viewModel.filteredHealthKitData
        
        // Merge manual entries and HealthKit data with time-based deduplication
        let allDates = Set(viewModel.historyItems.map { Calendar.current.startOfDay(for: $0.date) })
            .union(Set(healthKitDataToUse.map { Calendar.current.startOfDay(for: $0.startDate) }))
        
        for date in allDates.sorted(by: >) {
            let manualEntries = viewModel.historyItems.filter { 
                Calendar.current.isDate($0.date, inSameDayAs: date) 
            }
            
            let healthKitEntries = healthKitDataToUse.filter { 
                Calendar.current.isDate($0.startDate, inSameDayAs: date) 
            }
            
            // Separate manual entries from health entries based on source field
            let allSleepEntries = manualEntries.first?.sleepEntries ?? []
            let filteredManualEntries = applyManualEntryFilters(allSleepEntries.filter { $0.source == "manual" })
            
            // Smart deduplication: Filter out HealthKit entries that overlap with manual entries
            let filteredHealthKitEntries = filterOverlappingHealthKitEntries(
                healthKitEntries: healthKitEntries,
                manualEntries: filteredManualEntries
            )
            
            // Skip this day if no entries remain after filtering
            if filteredManualEntries.isEmpty && filteredHealthKitEntries.isEmpty {
                continue
            }
            
            // Calculate combined rating including both manual and HealthKit ratings
            let combinedRating = calculateCombinedDayRating(
                manualEntries: filteredManualEntries,
                healthKitEntries: filteredHealthKitEntries
            )
            
            let dayData = UnifiedDayData(
                date: date,
                manualEntries: filteredManualEntries,
                healthKitEntries: filteredHealthKitEntries,
                rating: combinedRating
            )
            
            unifiedDays.append(dayData)
        }
        
        return unifiedDays
    }
    
    private func applyManualEntryFilters(_ entries: [SleepEntry]) -> [SleepEntry] {
        return entries.filter { entry in
            // Apply sleep type filter
            if viewModel.selectedSleepTypeFilter != .all {
                switch viewModel.selectedSleepTypeFilter {
                case .core:
                    if !entry.isCore { return false }
                case .nap:
                    if entry.isCore { return false }
                case .all:
                    break
                }
            }
            
            // Apply rating filter
            if viewModel.selectedRatingFilter != .all {
                let rating = entry.rating
                switch viewModel.selectedRatingFilter {
                case .zeroOne:
                    if rating < 0 || rating > 1 { return false }
                case .oneTwo:
                    if rating < 1 || rating > 2 { return false }
                case .twoThree:
                    if rating < 2 || rating > 3 { return false }
                case .threeFour:
                    if rating < 3 || rating > 4 { return false }
                case .fourFive:
                    if rating < 4 || rating > 5 { return false }
                case .unrated:
                    if rating > 0 { return false }
                case .all:
                    break
                }
            }
            
            // Apply source filter
            if viewModel.selectedSourceFilter != .all {
                switch viewModel.selectedSourceFilter {
                case .manual:
                    if entry.source != "manual" { return false }
                case .health:
                    if entry.source != "health" { return false }
                case .all:
                    break
                }
            }
            
            // Apply adjustment filter
            if viewModel.selectedAdjustmentFilter != .all {
                let adjustmentType = entry.adjustmentInfo
                switch viewModel.selectedAdjustmentFilter {
                case .asScheduled:
                    if adjustmentType != .asScheduled { return false }
                case .differentTime:
                    if adjustmentType != .differentTime { return false }
                case .custom:
                    if adjustmentType != .custom { return false }
                case .skipped:
                    if adjustmentType != .skipped { return false }
                case .all:
                    break
                }
            }
            
            return true
        }
    }
    
    /// Filters HealthKit entries that overlap with manual entries
    private func filterOverlappingHealthKitEntries(
        healthKitEntries: [HealthKitSleepSample],
        manualEntries: [SleepEntry]
    ) -> [HealthKitSleepSample] {
        return healthKitEntries.filter { healthKitEntry in
            // Check if this HealthKit entry overlaps with any manual entry
            !manualEntries.contains { manualEntry in
                timeRangesOverlap(
                    start1: healthKitEntry.startDate,
                    end1: healthKitEntry.endDate,
                    start2: manualEntry.startTime,
                    end2: manualEntry.endTime
                )
            }
        }
    }
    
    /// Checks if two time ranges overlap
    private func timeRangesOverlap(start1: Date, end1: Date, start2: Date, end2: Date) -> Bool {
        // Two ranges overlap if start1 < end2 AND start2 < end1
        return start1 < end2 && start2 < end1
    }
    
    /// Calculates combined day rating including both manual and HealthKit entries
    private func calculateCombinedDayRating(
        manualEntries: [SleepEntry],
        healthKitEntries: [HealthKitSleepSample]
    ) -> Double {
        var totalRating: Double = 0
        var ratedEntriesCount: Int = 0
        
        // Add manual entry ratings (skip edilmiş entry'leri hariç tut)
        for entry in manualEntries {
            if entry.rating > 0 && entry.adjustmentInfo != .skipped {
                totalRating += entry.rating
                ratedEntriesCount += 1
            }
        }
        
        // Add HealthKit entry ratings
        for sample in healthKitEntries {
            if let rating = sample.rating, rating > 0 {
                totalRating += rating
                ratedEntriesCount += 1
            }
        }
        
        // Return average rating or 0 if no rated entries
        return ratedEntriesCount > 0 ? totalRating / Double(ratedEntriesCount) : 0
    }
}

// MARK: - Unified Day Data Model
struct UnifiedDayData {
    let date: Date
    let manualEntries: [SleepEntry]
    let healthKitEntries: [HealthKitSleepSample]
    let rating: Double
    
    var totalSleepDuration: TimeInterval {
        let manualDuration = manualEntries.reduce(0) { $0 + $1.duration }
        let healthKitDuration = healthKitEntries.reduce(0) { $0 + $1.duration }
        return manualDuration + healthKitDuration
    }
    
    var coreBlocksCount: Int {
        return manualEntries.filter { $0.isCore }.count
    }
    
    var napBlocksCount: Int {
        return manualEntries.filter { !$0.isCore }.count + healthKitEntries.count
    }
    
    var totalBlocksCount: Int {
        return manualEntries.count + healthKitEntries.count
    }
}

// MARK: - Timeline Card Wrapper with Visual Connectors
struct TimelineCardWrapper: View {
    let dayData: UnifiedDayData
    @ObservedObject var viewModel: HistoryViewModel
    @ObservedObject var profileViewModel: ProfileScreenViewModel
    let isFirst: Bool
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: PSSpacing.md) {
            // Timeline Connector
            TimelineConnector(
                isFirst: isFirst,
                isLast: isLast,
                hasData: dayData.totalBlocksCount > 0
            )
            
            // Main Card Content
            DailySleepCard(
                dayData: dayData,
                viewModel: viewModel,
                profileViewModel: profileViewModel
            )
        }
    }
}

// MARK: - Timeline Visual Connector
struct TimelineConnector: View {
    let isFirst: Bool
    let isLast: Bool
    let hasData: Bool
    
    private let lineWidth: CGFloat = 1.5
    
    var body: some View {
        VStack(spacing: 0) {
            // Top line (hidden for first item)
            Rectangle()
                .fill(isFirst ? Color.clear : Color.appBorder.opacity(0.25))
                .frame(width: lineWidth, height: PSSpacing.lg)
            
            // Bottom line (hidden for last item)
            Rectangle()
                .fill(isLast ? Color.clear : Color.appBorder.opacity(0.25))
                .frame(width: lineWidth)
                .frame(minHeight: PSSpacing.lg)
        }
        .frame(width: lineWidth + 4)
    }
}

// MARK: - Daily Sleep Card - Expandable Design
struct DailySleepCard: View {
    let dayData: UnifiedDayData
    @ObservedObject var viewModel: HistoryViewModel
    @ObservedObject var profileViewModel: ProfileScreenViewModel
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var isExpanded = false
    @State private var showingDeleteAlert = false
    @State private var entryToDelete: SleepEntry?

    private var displayRating: Double {
        // Hem manual hem HealthKit verileri varsa kombine rating'i göster
        // Hiç veri yoksa 0.0 döndür
        return (dayData.manualEntries.isEmpty && dayData.healthKitEntries.isEmpty) ? 0.0 : dayData.rating
    }
    
    private var hasAdjustments: Bool {
        return !getCompactAdjustmentIndicators().isEmpty
    }
    
    private func getCompactAdjustmentIndicators() -> [AdjustmentIndicator] {
        var indicators: [AdjustmentIndicator] = []
        
        // Check manual entries for adjustments
        for entry in dayData.manualEntries {
            if entry.blockId == nil {
                indicators.append(AdjustmentIndicator(color: .purple)) // Custom
            }
            // TODO: Add schedule comparison for time adjustments
        }
        
        // HealthKit entries are typically custom
        if !dayData.healthKitEntries.isEmpty {
            indicators.append(AdjustmentIndicator(color: .purple))
        }
        
        return Array(Set(indicators)) // Remove duplicates
    }
    
    private struct AdjustmentIndicator: Hashable {
        let color: Color
    }

    var body: some View {
        PSCard {
            VStack(alignment: .leading, spacing: 0) {
                closedCardContent
                
                if isExpanded {
                    expandedCardContent
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)).combined(with: .offset(y: -10)),
                            removal: .opacity.combined(with: .scale(scale: 0.95, anchor: .top)).combined(with: .offset(y: -10))
                        ))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: isExpanded)
                }
            }
        }
        .shadow(color: .black.opacity(0.18), radius: 8, x: 0, y: 3)
        .alert(L("history.alert.delete.title", table: "History"), isPresented: $showingDeleteAlert) {
            Button(L("history.alert.delete.cancel", table: "History"), role: .cancel) {}
            Button(L("history.alert.delete.confirm", table: "History"), role: .destructive) {
                if let entry = entryToDelete {
                    viewModel.deleteSleepEntry(entry)
                    entryToDelete = nil
                }
            }
        }
    }
    
    private var closedCardContent: some View {
        // Removed button action - expand now handled by chevron button
            HStack(alignment: .center, spacing: PSSpacing.sm) {
                // MARK: - Date Section
                VStack(alignment: .leading, spacing: 2) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(Calendar.current.component(.day, from: dayData.date))")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.appText)
                        
                        Text(monthString(from: dayData.date, format: "MMM"))
                            .font(.system(size: 15, weight: .semibold, design: .rounded))
                            .foregroundColor(.appTextSecondary)
                            .padding(.top, 5) // Align with day number
                    }
                    
                    // Day of week - abbreviated
                    Text(dayOfWeekString(from: dayData.date))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.appTextSecondary.opacity(0.8))
                        .padding(.leading, 2)
                    
                    Text(relativeTimeString(from: dayData.date))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(relativeTimeColor(from: dayData.date))
                        .padding(.leading, 2)
                }
                .padding(.trailing, PSSpacing.xxs)
                .frame(maxHeight: .infinity, alignment: .top)
                
                // MARK: - Sleep Details Section
                VStack(alignment: .leading, spacing: 0) {
                    // Top part: Total duration and block counts
                    VStack(alignment: .leading, spacing: PSSpacing.xs) {
                        Text("\(L("history.card.total", table: "History")): \(formatDuration(Int(dayData.totalSleepDuration / 60)))")
                            .font(PSTypography.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.appText)
                            .fixedSize(horizontal: false, vertical: true)

                        HStack(spacing: PSSpacing.sm) {
                            if dayData.coreBlocksCount > 0 {
                                HStack(spacing: PSSpacing.xs) { Text(profileViewModel.selectedCoreEmoji).font(.system(size: 14)); Text("x \(dayData.coreBlocksCount)").font(PSTypography.caption).foregroundColor(.appTextSecondary) }
                            }
                            if dayData.coreBlocksCount > 0 && dayData.napBlocksCount > 0 {
                                Text("・").font(PSTypography.caption).foregroundColor(.appTextSecondary.opacity(0.5))
                            }
                            if dayData.napBlocksCount > 0 {
                                HStack(spacing: PSSpacing.xs) { Text(profileViewModel.selectedNapEmoji).font(.system(size: 14)); Text("x \(dayData.napBlocksCount)").font(PSTypography.caption).foregroundColor(.appTextSecondary) }
                            }
                        }
                    }
                    .padding(.top, PSSpacing.sm)
                    
                    
                    // Bottom part: Star rating
                    HStack(spacing: PSSpacing.sm) {
                        StarsView(rating: displayRating, size: PSIconSize.small, primaryColor: .appAccent, emptyColor: .appTextSecondary.opacity(0.2))
                        Text(String(format: "%.1f", displayRating))
                            .font(PSTypography.caption.weight(.semibold))
                            .foregroundColor(.appTextSecondary)
                            .lineLimit(1)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, PSSpacing.xs)
                }
                
                
                
                // MARK: - Action Buttons Section
                VStack(alignment: .trailing) {
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)) { 
                            isExpanded.toggle() 
                        }
                    }) {
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: PSIconSize.medium, weight: .medium))
                            .foregroundColor(.appTextSecondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                            .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0), value: isExpanded)
                            .frame(width: PSIconSize.medium, height: PSIconSize.medium) // Bigger tappable area
                    }
                    .contentShape(Rectangle())
                    .buttonStyle(.plain)
                }
                .padding(.leading, PSSpacing.xxs)
                .frame(maxHeight: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity, alignment: .center)
    }
    
    private var expandedCardContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Divider()
                .background(Color.appBorder.opacity(0.3))
                .padding(.horizontal, PSSpacing.lg)
                .padding(.vertical, PSSpacing.sm)
            
            LazyVStack(spacing: PSSpacing.xs) {
                ForEach(dayData.manualEntries) { entry in
                    SleepEntryDetailRow(
                        entry: .manual(entry), 
                        onDelete: {
                            entryToDelete = entry
                            showingDeleteAlert = true
                        },
                        viewModel: viewModel,
                        profileViewModel: profileViewModel
                    )
                    .drawingGroup() // GPU acceleration for complex views
                }
                ForEach(dayData.healthKitEntries, id: \.id) { sample in
                    SleepEntryDetailRow(
                        entry: .healthKit(sample), 
                        onDelete: nil,
                        viewModel: viewModel,
                        profileViewModel: profileViewModel
                    )
                        .drawingGroup() // GPU acceleration for complex views
                }
            }
            .padding(.vertical, PSSpacing.sm)
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .clipped() // Prevents layout issues during animation
    }
    
    private func monthString(from date: Date, format: String = "MMMM") -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = languageManager.currentLocale
        return formatter.string(from: date)
    }
    
    private func dayOfWeekString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE" // Abbreviated day name (Mon, Tue, etc.)
        formatter.locale = languageManager.currentLocale
        return formatter.string(from: date)
    }
    
    private func relativeTimeString(from date: Date) -> String {
        let calendar = Calendar.current, now = Date()
        if calendar.isDateInToday(date) { return L("history.relative.today", table: "History") }
        if calendar.isDateInYesterday(date) { return L("history.relative.yesterday", table: "History") }
        let days = calendar.dateComponents([.day], from: date, to: now).day ?? 0
        if days <= 7 { return String(format: L("history.relative.daysAgo", table: "History"), days) }
        let weeks = days / 7
        return weeks == 1 ? L("history.relative.oneWeekAgo", table: "History") : String(format: L("history.relative.weeksAgo", table: "Localizable"), weeks)
    }
    
    private func relativeTimeColor(from date: Date) -> Color {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) { return .appPrimary }
        if calendar.isDateInYesterday(date) { return .appTextSecondary }
        return .appTextTertiary
    }
}

// MARK: - Sleep Entry Detail Row for Expanded State
struct SleepEntryDetailRow: View {
    let entry: SleepEntryType
    let onDelete: (() -> Void)?
    let viewModel: HistoryViewModel
    let profileViewModel: ProfileScreenViewModel
    @State private var showingActionsMenu = false
    @State private var showingRatingSheet = false
    @State private var tempRating: Double = 3.0
    
    enum SleepEntryType {
        case manual(SleepEntry)
        case healthKit(HealthKitSleepSample)
    }
    
    var body: some View {
        // Modern vertical card layout for better readability
        VStack(spacing: 0) {
            // Header section with icon, time range and action button
            HStack(alignment: .center, spacing: PSSpacing.sm) {
                // Icon with type indicator
                HStack(spacing: PSSpacing.xs) {
                    Text(emojiIcon)
                        .font(.system(size: 18))
                        .frame(width: 24, height: 24)
                    
                    // Type indicator dot
                    Circle()
                        .fill(iconColor)
                        .frame(width: 4, height: 4)
                }
                .frame(width: 32, alignment: .leading)
                
                // Time range - prominent display
                Text(timeRange)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.appText)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                // Action menu button
                Button(action: {
                    showingActionsMenu = true
                }) {
                    Image(systemName: "ellipsis")
                        .font(.system(size: PSIconSize.medium, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                        .rotationEffect(.degrees(90))
                        .frame(width: 44, height: 44)
                }
                .contentShape(Rectangle())
                .buttonStyle(.plain)
            }
            .padding(.bottom, PSSpacing.sm)
            
            // Details section with duration, rating and badges
            HStack(alignment: .center, spacing: PSSpacing.md) {
                // Duration with icon
                HStack(spacing: PSSpacing.xs) {
                    Image(systemName: "clock.fill")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.appTextSecondary)
                    
                    Text(duration)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.appText)
                        .lineLimit(1)
                }
                
                // Separator dot
                Circle()
                    .fill(Color.appTextSecondary.opacity(0.4))
                    .frame(width: 3, height: 3)
                
                // Rating section - Skip edilmiş entry'ler için rating gösterme
                if !isSkipped {
                    if let rating = currentRating {
                        HStack(spacing: PSSpacing.xs) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.appAccent)
                            
                            Text(String(format: "%.1f", rating))
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.appAccent)
                                .lineLimit(1)
                        }
                    } else if !isFromHealthKit {
                        Button(action: {
                            tempRating = 3.0
                            showingRatingSheet = true
                        }) {
                            HStack(spacing: PSSpacing.xs) {
                                Image(systemName: "star")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.appTextSecondary)
                                
                                Text(L("history.action.rate", table: "Localizable"))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.appTextSecondary)
                                    .lineLimit(1)
                            }
                        }
                        .buttonStyle(.plain)
                    } else {
                        // HealthKit entry without rating - show warning icon with tooltip
                        UnratedHealthKitIndicator {
                            tempRating = 3.0
                            showingRatingSheet = true
                        }
                    }
                }
                
                Spacer()
                
                // Source and adjustment badges
                HStack(spacing: PSSpacing.xs) {
                    // Adjustment badge
                    if let adjustmentType = getAdjustmentType(), shouldShowAdjustmentBadge() {
                        SleepAdjustmentBadge(
                            adjustmentType: adjustmentType,
                            adjustmentMinutes: getCalculatedAdjustmentMinutes(),
                            isCompact: true
                        )
                    }
                    
                    // Source indicator badge
                    HStack(spacing: 4) {
                        Image(systemName: isFromHealthKit ? "heart.fill" : "pencil")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(isFromHealthKit ? .appSuccess : .appSecondary)
                        
                        Text(isFromHealthKit ? L("history.source.health", table: "History") : L("history.source.manual", table: "History"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(isFromHealthKit ? .appSuccess : .appSecondary)
                            .lineLimit(1)
                    }
                    .padding(.horizontal, PSSpacing.xs)
                    .padding(.vertical, 2)
                    .background(
                        RoundedRectangle(cornerRadius: 6)
                            .fill((isFromHealthKit ? Color.appSuccess : Color.appSecondary).opacity(0.1))
                    )
                }
            }
        }
        .padding(.vertical, PSSpacing.sm)
        .padding(.horizontal, PSSpacing.md)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                .fill(Color.appCardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                        .stroke(Color.appBorder.opacity(0.2), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
        .contentShape(Rectangle())
        .confirmationDialog(
            L("history.action.selectAction", table: "History"), 
            isPresented: $showingActionsMenu
        ) {
            // Skip edilmiş entry'ler için rating seçeneği gösterme
            if !isSkipped {
                Button(L("Rate", table: "Localizable")) {
                    tempRating = currentRating ?? 3.0
                    showingRatingSheet = true
                }
            }
            
            Button(L("general.delete", table: "Common"), role: .destructive) {
                deleteEntry()
            }
            
            Button(L("common.cancel", table: "Common"), role: .cancel) { }
        }
        .sheet(isPresented: $showingRatingSheet) {
            SleepEntryRatingSheet(
                rating: $tempRating,
                onSave: { newRating in
                    saveRating(newRating)
                }
            )
            .presentationDetents([.height(400), .medium])
            .presentationDragIndicator(.visible)
        }
    }
    
    private var emojiIcon: String {
        switch entry {
        case .manual(let sleepEntry): 
            return sleepEntry.isCore ? profileViewModel.selectedCoreEmoji : profileViewModel.selectedNapEmoji
        case .healthKit(let sample): 
            // HealthKit samples are usually naps (unless specifically core sleep)
            return sample.type == .asleep ? profileViewModel.selectedCoreEmoji : profileViewModel.selectedNapEmoji
        }
    }
    
    private var iconColor: Color {
        switch entry {
        case .manual(let sleepEntry): return sleepEntry.isCore ? .appPrimary : .appSecondary
        case .healthKit: return .green
        }
    }
    
    private var timeRange: String {
        switch entry {
        case .manual(let sleepEntry): 
            // For skipped entries, show original scheduled times if available
            if sleepEntry.adjustmentInfo == .skipped,
               let originalStart = sleepEntry.originalScheduledStartTime,
               let originalEnd = sleepEntry.originalScheduledEndTime {
                return "\(formatTime(originalStart)) - \(formatTime(originalEnd))"
            } else {
                return "\(formatTime(sleepEntry.startTime)) - \(formatTime(sleepEntry.endTime))"
            }
        case .healthKit(let sample): return "\(formatTime(sample.startDate)) - \(formatTime(sample.endDate))"
        }
    }
    
    private var duration: String {
        switch entry {
        case .manual(let sleepEntry): 
            return formatCompactDuration(Int(sleepEntry.duration / 60))
        case .healthKit(let sample):
            let totalMinutes = Int(sample.duration / 60)
            return formatCompactDuration(totalMinutes)
        }
    }
    
    /// Format duration in compact format for single-line display
    private func formatCompactDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        
        if hours > 0 && mins > 0 {
            return "\(hours)h\(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
    
    private var isFromHealthKit: Bool {
        switch entry {
        case .manual: return false
        case .healthKit: return true
        }
    }
    
    private var currentRating: Double? {
        switch entry {
        case .manual(let sleepEntry): return sleepEntry.rating > 0 ? sleepEntry.rating : nil
        case .healthKit(let sample): return sample.rating
        }
    }
    
    private var isSkipped: Bool {
        switch entry {
        case .manual(let sleepEntry): return sleepEntry.adjustmentInfo == .skipped
        case .healthKit: return false
        }
    }
    
    private func saveRating(_ rating: Double) {
        switch entry {
        case .manual(let sleepEntry):
            sleepEntry.rating = rating
            viewModel.updateSleepEntry(sleepEntry)
        case .healthKit(let sample):
            viewModel.updateHealthKitRating(for: sample.id, rating: rating)
        }
    }
    
    private func deleteEntry() {
        switch entry {
        case .manual(let sleepEntry):
            viewModel.deleteSleepEntry(sleepEntry)
        case .healthKit(let sample):
            viewModel.deleteHealthKitSample(sample)
        }
    }
    
    private func getAdjustmentType() -> SleepAdjustmentType? {
        switch entry {
        case .manual(let sleepEntry):
            // Use the stored adjustment type from SleepEntry
            return sleepEntry.adjustmentInfo
        case .healthKit:
            // HealthKit entries are typically custom unless matched with schedule
            return .custom
        }
    }
    
    private func getAdjustmentMinutes() -> Int? {
        switch entry {
        case .manual(let sleepEntry):
            return sleepEntry.adjustmentMinutes
        case .healthKit:
            return nil // HealthKit entries don't have specific minute adjustments
        }
    }
    
    // MARK: - New helper methods for improved UI
    
    /// Calculate actual adjustment minutes by comparing scheduled vs actual times
    private func getCalculatedAdjustmentMinutes() -> Int? {
        switch entry {
        case .manual(let sleepEntry):
            // If we have stored adjustment minutes, use them
            if let storedMinutes = sleepEntry.adjustmentMinutes, storedMinutes != 0 {
                return storedMinutes
            }
            
            // Otherwise, calculate from scheduled vs actual times
            if let originalStart = sleepEntry.originalScheduledStartTime,
               let originalEnd = sleepEntry.originalScheduledEndTime {
                let scheduledDuration = Int(originalEnd.timeIntervalSince(originalStart) / 60)
                let actualDuration = Int(sleepEntry.duration / 60)
                let difference = actualDuration - scheduledDuration
                return difference != 0 ? difference : nil
            }
            
            return nil
        case .healthKit:
            return nil
        }
    }
    
    /// Determine if adjustment badge should be shown (only for significant adjustments)
    private func shouldShowAdjustmentBadge() -> Bool {
        switch entry {
        case .manual(let sleepEntry):
            // Always show for skipped entries
            if sleepEntry.adjustmentInfo == .skipped {
                return true
            }
            
            // Show for custom entries
            if sleepEntry.adjustmentInfo == .custom {
                return true
            }
            
            // For time adjustments, only show if difference is > 5 minutes
            if let adjustmentMinutes = getCalculatedAdjustmentMinutes() {
                return abs(adjustmentMinutes) > 5
            }
            
            return false
        case .healthKit:
            return true // HealthKit entries are typically custom
        }
    }
}

// MARK: - Sleep Entry Rating Sheet
// @polynap/Components/LocalizedText.swift - All localization handled via L() function
struct SleepEntryRatingSheet: View {
    @Binding var rating: Double
    let onSave: (Double) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var sliderValue: Double = 2 // 0-4 arası değer (5 emoji için)
    
    private let emojis = ["😩", "😪", "😐", "😊", "😄"]
    private let emojiLabels = [
        "😩": L("sleep.quality.awful", table: "SleepQuality"),
        "😪": L("sleep.quality.bad", table: "SleepQuality"), 
        "😐": L("sleep.quality.okay", table: "SleepQuality"),
        "😊": L("sleep.quality.good", table: "SleepQuality"),
        "😄": L("sleep.quality.great", table: "SleepQuality")
    ]
    
    // Slider değerine göre emoji seçimi
    private var currentEmoji: String {
        let index = min(Int(sliderValue.rounded()), emojis.count - 1)
        return emojis[index]
    }
    
    // Slider değerine göre emoji etiketi
    private var currentEmojiLabel: String {
        return emojiLabels[currentEmoji] ?? L("sleep.quality.okay", table: "SleepQuality")
    }
    
    // 1-5 rating'e çevir (0.5 increment'li)
    private var finalRating: Double {
        return (sliderValue + 1.0) // 0-4 -> 1-5
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Compact Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    LocalizedText("history.rating.title", tableName: "History")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.appText)
                    
                    LocalizedText("history.rating.subtitle", tableName: "History")
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    dismiss()
                }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(.appTextSecondary)
                }
            }
            
            // Rating Section - Kompakt design
            VStack(spacing: 16) {
                // Emoji
                Text(currentEmoji)
                    .font(.system(size: 60))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentEmoji)
                
                // Emoji Label
                Text(currentEmojiLabel)
                    .font(PSTypography.subheadline)
                    .foregroundColor(.appTextSecondary)
                
                // Yıldız Puanlama
                HStack(spacing: 6) {
                    ForEach(0..<5) { index in
                        let starValue = Double(index)
                        let isFilled = finalRating >= starValue + 1.0
                        let isHalfFilled = !isFilled && finalRating >= starValue + 0.5
                        
                        Image(systemName: isFilled ? "star.fill" : (isHalfFilled ? "star.leadinghalf.filled" : "star"))
                            .foregroundColor(isFilled || isHalfFilled ? getSliderColor() : Color.appTextSecondary.opacity(0.3))
                            .font(.title3)
                    }
                }
                
                // Slider (0.5 increment'li)
                VStack(spacing: 6) {
                    Slider(value: $sliderValue, in: 0...4, step: 0.5)
                        .tint(getSliderColor())
                        .onChange(of: sliderValue) { newValue in
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                        }
                    
                    // Rating Display
                    Text("\(String(format: "%.1f", finalRating))/5")
                        .font(PSTypography.caption)
                        .foregroundColor(.appTextSecondary)
                    
                    // Slider Labels
                    HStack {
                        LocalizedText("sleep.quality.worst", tableName: "SleepQuality")
                            .font(.caption2)
                            .foregroundColor(.appTextSecondary)
                        
                        Spacer()
                        
                        LocalizedText("sleep.quality.best", tableName: "SleepQuality")
                            .font(.caption2)
                            .foregroundColor(.appTextSecondary)
                    }
                }
            }
            
            // Action Buttons - Kompakt
            HStack(spacing: 12) {
                Button(action: {
                    dismiss()
                }) {
                    LocalizedText("common.cancel", tableName: "Common")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appCardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.appTextSecondary.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.appText)
                }
                
                Button(action: {
                    onSave(finalRating)
                    dismiss()
                }) {
                    LocalizedText("history.rating.save", tableName: "History")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.appPrimary)
                        )
                        .foregroundColor(.appTextOnPrimary)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.appCardBackground)
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .onAppear {
            // Mevcut rating'i slider değerine çevir (1-5 -> 0-4)
            sliderValue = max(0, min(4, rating - 1.0))
        }
    }
    
    private func getSliderColor() -> Color {
        let index = Int(sliderValue.rounded())
        switch index {
        case 0:
            return Color.red
        case 1:
            return Color.orange
        case 2:
            return Color.yellow
        case 3:
            return Color.blue
        case 4:
            return Color.green
        default:
            return Color.yellow
        }
    }
}

// MARK: - Data Source Indicator
struct DataSourceIndicator: View {
    let isFromHealthKit: Bool
    
    var body: some View {
        HStack(spacing: PSSpacing.xs) {
            Image(systemName: isFromHealthKit ? "heart.circle.fill" : "pencil.circle.fill")
                .font(.system(size: PSIconSize.small - 2))
                .foregroundColor(isFromHealthKit ? .green : .appSecondary)
            
            Text(isFromHealthKit ? L("history.source.health", table: "History") : L("history.source.manual", table: "History"))
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, PSSpacing.xs)
        .padding(.vertical, 2)
        .background(RoundedRectangle(cornerRadius: PSCornerRadius.small - 2).fill(Color.appBackground.opacity(0.5)))
        .fixedSize(horizontal: true, vertical: false)
    }
}

// MARK: - Modern Floating Action Button
struct ModernFloatingActionButton: View {
    let action: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                
                Button(action: {
                    // UI feedback önce gelsin
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    
                    // Action'ı çağır
                    action()
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: PSIconSize.medium, weight: .bold))
                        .foregroundColor(.appTextOnPrimary)
                        .frame(width: PSIconSize.extraLarge + PSSpacing.sm, height: PSIconSize.extraLarge + PSSpacing.sm)
                        .background(
                            Circle()
                                .fill(Color.appAccent)
                                .shadow(color: Color.appAccent.opacity(0.3), radius: 8, x: 0, y: 3)
                        )
                }
                .buttonStyle(FloatingButtonStyle())
                .padding(.trailing, PSSpacing.xl)
                .padding(.bottom, PSSpacing.xl)
            }
        }
    }
}

// MARK: - Helper Functions
private func formatDuration(_ minutes: Int) -> String {
    let hours = minutes / 60
    let mins = minutes % 60
    if hours > 0 {
        return String(format: "%dh %dm", hours, mins)
    } else {
        return String(format: "%dm", mins)
    }
}

private func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    formatter.locale = LanguageManager.shared.currentLocale
    return formatter.string(from: date)
}

private func formatEntryDuration(_ duration: TimeInterval) -> String {
    let minutes = Int(duration / 60)
    return formatDuration(minutes)
}

// MARK: - Unrated HealthKit Indicator with Tooltip
struct UnratedHealthKitIndicator: View {
    let onTap: () -> Void
    @State private var showTooltip = false
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            HStack(spacing: PSSpacing.xs) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.orange)
                
                Text(L("history.action.rate", table: "Localizable"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.orange)
                    .lineLimit(1)
            }
        }
        .buttonStyle(.plain)
        .onLongPressGesture(minimumDuration: 0.5) {
            showTooltip = true
            
            // Auto-hide tooltip after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                showTooltip = false
            }
        }
        .overlay(
            tooltipOverlay,
            alignment: .topTrailing
        )
    }
    
    @ViewBuilder
    private var tooltipOverlay: some View {
        if showTooltip {
            VStack {
                Text(L("history.healthkit.unrated.tooltip", table: "History"))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextOnPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.appText.opacity(0.9))
                            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    )
                    .frame(maxWidth: 200)
                    .fixedSize(horizontal: false, vertical: true)
                
                // Arrow pointing down
                Path { path in
                    path.move(to: CGPoint(x: 0, y: 0))
                    path.addLine(to: CGPoint(x: 8, y: 8))
                    path.addLine(to: CGPoint(x: 16, y: 0))
                    path.closeSubpath()
                }
                .fill(Color.appText.opacity(0.9))
                .frame(width: 16, height: 8)
                .offset(x: -40) // Adjust arrow position
            }
            .offset(y: -60) // Position tooltip above the button
            .zIndex(1000)
            .transition(.opacity.combined(with: .scale(scale: 0.8)))
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showTooltip)
        }
    }
}
