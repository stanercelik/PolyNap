import SwiftUI
import SwiftData

// MARK: - Duration Adjustment Enum
enum DurationAdjustment: Equatable {
    case none
    case differentTime(minutes: Int) // positive for longer, negative for shorter
    case custom(startTime: Date, endTime: Date)
    case skipped
    
    var displayText: String {
        switch self {
        case .none:
            return L("sleepModification.asScheduled", table: "AddSleepEntrySheet")
        case .differentTime(let minutes):
            if minutes > 0 {
                return String(format: L("sleepModification.sleptLonger", table: "AddSleepEntrySheet"), abs(minutes))
            } else {
                return String(format: L("sleepModification.sleptShorter", table: "AddSleepEntrySheet"), abs(minutes))
            }
        case .custom:
            return L("sleepModification.customTime", table: "AddSleepEntrySheet")
        case .skipped:
            return L("sleepModification.skipped", table: "AddSleepEntrySheet")
        }
    }
    
    var iconName: String {
        switch self {
        case .none: return "checkmark.circle.fill"
        case .differentTime(let minutes):
            return minutes > 0 ? "plus.circle.fill" : "minus.circle.fill"
        case .custom: return "slider.horizontal.3"
        case .skipped: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .none: return .appSuccess
        case .differentTime(let minutes):
            return minutes > 0 ? .appPrimary : .metricAmber
        case .custom: return .appSecondary
        case .skipped: return .appError
        }
    }
}

struct AddSleepEntrySheet: View {
    @ObservedObject var viewModel: HistoryViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var languageManager: LanguageManager
    
    // Analytics
    private let analyticsManager = AnalyticsManager.shared
    
    // State
    @State private var selectedDate: Date
    @State private var selectedBlockFromSchedule: SleepBlock?
    @State private var durationAdjustment: DurationAdjustment = .none
    @State private var customStartTime: Date = Date()
    @State private var customEndTime: Date = Date()
    @State private var showCustomAdjustment = false
    @State private var adjustmentMinutes: Double = 0
    
    // Sleep Quality State
    @State private var sliderValue: Double = 3 // Default to "Good"
    
    // UI State
    @State private var showBlockError = false
    @State private var blockErrorMessage = ""
    @State private var showDateWarning = false
    @State private var dateWarningMessage = ""
    @State private var animateSelection: Bool = false

    let availableBlocks: [SleepBlock]
    
    init(viewModel: HistoryViewModel, availableBlocks: [SleepBlock], initialDate: Date? = nil) {
        self.viewModel = viewModel
        self.availableBlocks = availableBlocks
        _selectedDate = State(initialValue: initialDate ?? Date())
    }
    
    // MARK: - Computed Properties
    private var isDateInFuture: Bool {
        Calendar.current.compare(selectedDate, to: Date(), toGranularity: .day) == .orderedDescending
    }
    
    private var isValidEntry: Bool {
        (selectedBlockFromSchedule != nil || showCustomAdjustment) && !isDateInFuture
    }
    
    private var scheduledDuration: Int {
        guard let block = selectedBlockFromSchedule,
              let times = calculateBlockTimes(for: block, on: selectedDate) else {
            return 0
        }
        return Int(times.end.timeIntervalSince(times.start) / 60)
    }
    
    private var actualDuration: Int {
        guard let block = selectedBlockFromSchedule else { return 0 }
        
        switch durationAdjustment {
        case .none:
            return scheduledDuration
        case .differentTime(let minutes):
            return max(0, scheduledDuration + minutes)
        case .custom(let startTime, let endTime):
            return Int(endTime.timeIntervalSince(startTime) / 60)
        case .skipped:
            return 0
        }
    }
    
    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: PSSpacing.md) {
                        datePickerCard
                        blockSelectionCard
                        
                        if selectedBlockFromSchedule != nil {
                            durationAdjustmentCard
                            
                            if durationAdjustment != .skipped {
                                qualityCard
                            }
                        } else if showCustomAdjustment {
                            customOnlyCard
                            qualityCard
                        }
                        
                        Spacer(minLength: PSSpacing.xl)
                    }
                    .padding(.horizontal, PSSpacing.lg)
                    .padding(.top, PSSpacing.sm)
                    .padding(.bottom, PSSpacing.xxl)
                    .fontDesign(.rounded)
                }
            }
            .navigationTitle(L("sleepEntry.add", table: "AddSleepEntrySheet"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
            .alert(isPresented: $showBlockError) {
                Alert(
                    title: Text(L("sleepEntry.error.title", table: "AddSleepEntrySheet")),
                    message: Text(L(blockErrorMessage, table: "AddSleepEntrySheet")),
                    dismissButton: .default(Text(L("general.ok", table: "AddSleepEntrySheet")))
                )
            }
            .alert(isPresented: $showDateWarning) {
                Alert(
                    title: Text(L("sleepEntry.error.title", table: "AddSleepEntrySheet")),
                    message: Text(L(dateWarningMessage, table: "AddSleepEntrySheet")),
                    dismissButton: .default(Text(L("general.ok", table: "AddSleepEntrySheet")))
                )
            }
            .onAppear {
                analyticsManager.logScreenView(screenName: "add_sleep_entry_sheet", screenClass: "AddSleepEntrySheet")
            }
            .onChange(of: selectedDate) {
                handleDateChange()
            }
            .onChange(of: selectedBlockFromSchedule) {
                handleBlockChange()
            }
        }
        .accentColor(Color.appPrimary)
    }
    
    // MARK: - Flexible Duration Adjustment
    private func FlexibleDurationAdjustment() -> some View {
        VStack(spacing: PSSpacing.md) {
            // Compact duration summary
            HStack(spacing: PSSpacing.sm) {
                VStack(spacing: 2) {
                    Text(L("sleepModification.scheduled", table: "AddSleepEntrySheet"))
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.appTextSecondary)
                        .textCase(.uppercase)
                    Text(formatDuration(scheduledDuration))
                        .font(.headline.weight(.bold))
                        .foregroundColor(.appText)
                        .contentTransition(.numericText())
                }
                .frame(maxWidth: .infinity)
                
                Image(systemName: "arrow.right")
                    .font(.caption)
                    .foregroundColor(.appTextTertiary)
                
                VStack(spacing: 2) {
                    Text(L("sleepModification.actual", table: "AddSleepEntrySheet"))
                        .font(.caption2.weight(.medium))
                        .foregroundColor(.appTextSecondary)
                        .textCase(.uppercase)
                    Text(formatDuration(actualDuration))
                        .font(.headline.weight(.bold))
                        .foregroundColor(adjustmentMinutes == 0 ? .appText : (adjustmentMinutes > 0 ? .appPrimary : .metricAmber))
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: actualDuration)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(PSSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: PSCornerRadius.small)
                    .fill(Color.appBackground)
            )
            
            VStack(spacing: PSSpacing.sm) {
                // Title only
                Text(L("sleepModification.howMuchDiff", table: "AddSleepEntrySheet"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.appText)
                
                // Duration Slider
                VStack(spacing: PSSpacing.xs) {
                    HStack {
                        Text("-60m")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                        
                        Spacer()
                        
                        Text("\(Int(adjustmentMinutes) > 0 ? "+" : "")\(Int(adjustmentMinutes))m")
                            .font(.headline.weight(.semibold))
                            .foregroundColor(adjustmentMinutes == 0 ? .appText : (adjustmentMinutes > 0 ? .appPrimary : .metricAmber))
                        
                        Spacer()
                        
                        Text("+120m")
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    Slider(value: $adjustmentMinutes, in: -60...120, step: 5)
                        .tint(adjustmentMinutes == 0 ? .appPrimary : (adjustmentMinutes > 0 ? .appPrimary : .metricAmber))
                        .onChange(of: adjustmentMinutes) { _ in
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                                durationAdjustment = .differentTime(minutes: Int(adjustmentMinutes))
                            }
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        }
                }
                
                // Hint at bottom
                Text(L("sleepModification.howMuchDiffHint", table: "AddSleepEntrySheet"))
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
        }
        .padding(PSSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                .fill(Color.appBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                        .stroke(Color.appPrimary.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    // MARK: - Toolbar
    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(L("general.cancel", table: "AddSleepEntrySheet")) {
                HapticFeedbackManager.shared.trigger(.softCommit)
                dismiss()
            }
            .foregroundColor(Color.appPrimary)
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button(L("general.save", table: "AddSleepEntrySheet")) {
                saveEntry()
            }
            .disabled(!isValidEntry)
            .font(.headline)
            .foregroundColor(isValidEntry ? Color.appPrimary : Color.appTextSecondary)
        }
    }
    
    // MARK: - Card Components
    private var datePickerCard: some View {
        PSCard(padding: PSSpacing.md) {
            HStack(alignment: .center, spacing: PSSpacing.sm) {
                VStack(alignment: .leading, spacing: 3) {
                    Label {
                        Text(L("sleepEntry.date", table: "AddSleepEntrySheet"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.appText)
                    } icon: {
                        Image(systemName: "calendar.circle.fill")
                            .foregroundColor(.appPrimary)
                    }
                    
                    Text(L("sleepEntry.dateInfo", table: "AddSleepEntrySheet"))
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                DatePicker(
                    "",
                    selection: $selectedDate,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(Color.appPrimary)
            }
        }
    }
    
    private var blockSelectionCard: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.md) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L("sleepEntry.whichBlock", table: "AddSleepEntrySheet"))
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.appText)
                    
                    Text(L("sleepEntry.whichBlock.hint", table: "AddSleepEntrySheet"))
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
                
                if availableBlocks.isEmpty {
                    EmptyBlocksView()
                } else {
                    VStack(spacing: PSSpacing.xs) {
                        ForEach(availableBlocks, id: \.id) { block in
                            let alreadyAdded = isBlockAlreadyAdded(block)
                            ModernBlockSelectionButton(
                                block: block,
                                isSelected: selectedBlockFromSchedule?.id == block.id,
                                isAlreadyAdded: alreadyAdded,
                                onTap: {
                                    handleBlockTapped(block, isAlreadyAdded: alreadyAdded)
                                }
                            )
                        }
                        
                        // Custom Block Option
                        CustomBlockSelectionButton(
                            isSelected: selectedBlockFromSchedule == nil && showCustomAdjustment,
                            onTap: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    selectedBlockFromSchedule = nil
                                    showCustomAdjustment = true
                                    setupCustomAdjustment()
                                }
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            }
                        )
                    }
                }
            }
        }
    }
    
    private var durationAdjustmentCard: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.md) {
                Text(L("sleepEntry.howWasYourSleep", table: "AddSleepEntrySheet"))
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.appText)
                
                // Primary Adjustment Options
                primaryAdjustmentOptions
                
                // Flexible Duration Adjustment
                if case .differentTime = durationAdjustment {
                    FlexibleDurationAdjustment()
                        .transition(.asymmetric(
                            insertion: .opacity.combined(with: .scale(scale: 0.97, anchor: .top)),
                            removal: .opacity.combined(with: .scale(scale: 0.97, anchor: .top))
                        ))
                }
            }
        }
    }
    
    private var qualityCardBackground: Color {
        switch Int(sliderValue.rounded()) {
        case 0: return Color.appError.opacity(0.10)
        case 1: return Color.metricAmber.opacity(0.08)
        case 2: return Color.appCardBackground
        case 3: return Color.appPrimary.opacity(0.07)
        case 4: return Color.appSuccess.opacity(0.10)
        default: return Color.appCardBackground
        }
    }
    
    private var qualityCard: some View {
        VStack(alignment: .leading, spacing: PSSpacing.md) {
            Text(L("sleepEntry.yourFeeling", table: "AddSleepEntrySheet"))
                .font(.headline.weight(.semibold))
                .foregroundColor(.appText)
            
            SleepQualitySlider(sliderValue: $sliderValue)
        }
        .padding(PSSpacing.lg)
        .background(
            RoundedRectangle(cornerRadius: PSCornerRadius.large)
                .fill(qualityCardBackground)
        )
        .animation(.easeInOut(duration: 0.3), value: sliderValue)
    }
    
    // MARK: - Supporting Views
    private var primaryAdjustmentOptions: some View {
        VStack(spacing: PSSpacing.xs) {
            sleepStatusOptionRow(
                title: L("sleepModification.asScheduled.subtitle", table: "AddSleepEntrySheet"),
                description: scheduledDuration > 0 ? formatDuration(scheduledDuration) : L("sleepModification.fullDuration", table: "AddSleepEntrySheet"),
                icon: "checkmark.circle.fill",
                color: .appSuccess,
                isSelected: durationAdjustment == .none && !showCustomAdjustment
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    durationAdjustment = .none
                    showCustomAdjustment = false
                    adjustmentMinutes = 0
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            
            sleepStatusOptionRow(
                title: L("sleepModification.differentTime.subtitle", table: "AddSleepEntrySheet"),
                description: L("sleepModification.differentTime.hint", table: "AddSleepEntrySheet"),
                icon: "clock.arrow.circlepath",
                color: .appPrimary,
                isSelected: {
                    if case .differentTime = durationAdjustment, !showCustomAdjustment { return true }
                    return false
                }()
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if adjustmentMinutes == 0 { adjustmentMinutes = 5 }
                    durationAdjustment = .differentTime(minutes: Int(adjustmentMinutes))
                    showCustomAdjustment = false
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
            
            sleepStatusOptionRow(
                title: L("sleepModification.skipped.subtitle", table: "AddSleepEntrySheet"),
                description: L("sleepModification.skipped.hint", table: "AddSleepEntrySheet"),
                icon: "xmark.circle.fill",
                color: .appError,
                isSelected: durationAdjustment == .skipped && !showCustomAdjustment
            ) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    durationAdjustment = .skipped
                    showCustomAdjustment = false
                    adjustmentMinutes = 0
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
    }
    
    private func sleepStatusOptionRow(
        title: String,
        description: String,
        icon: String,
        color: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: PSSpacing.md) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isSelected ? .white : color)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(isSelected ? color : color.opacity(0.12))
                    )
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.appText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? color : .appBorder)
            }
            .padding(.horizontal, PSSpacing.md)
            .padding(.vertical, 10)
            .frame(minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                    .fill(isSelected ? color.opacity(0.06) : Color.appCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                            .stroke(isSelected ? color.opacity(0.5) : Color.appBorder.opacity(0.25), lineWidth: isSelected ? 1.5 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.01 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isSelected)
    }
    
    private func DurationStatusView(scheduledDuration: Int, actualDuration: Int, adjustment: DurationAdjustment) -> some View {
        VStack(spacing: PSSpacing.lg) {
            // Duration Cards Row - Full Width
            HStack(spacing: PSSpacing.md) {
                // Scheduled Duration Card
                VStack(spacing: PSSpacing.sm) {
                    Text(L("sleepModification.scheduled", table: "AddSleepEntrySheet"))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.appTextSecondary)
                        .textCase(.uppercase)
                    
                    Text(formatDuration(scheduledDuration))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.appText)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, PSSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                        .fill(Color.appCardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                                .stroke(Color.appBorder.opacity(0.3), lineWidth: 1)
                        )
                )
                
                // Actual Duration Card
                VStack(spacing: PSSpacing.sm) {
                    Text(L("sleepModification.actual", table: "AddSleepEntrySheet"))
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.appTextSecondary)
                        .textCase(.uppercase)
                    
                    Text(formatDuration(actualDuration))
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(adjustment == .none ? .appText : adjustment.color)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: actualDuration)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, PSSpacing.lg)
                .background(
                    RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                        .fill(adjustment == .none ? Color.appCardBackground : adjustment.color.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                                .stroke(adjustment == .none ? Color.appBorder.opacity(0.3) : adjustment.color.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Difference Indicator (if any adjustment)
            if adjustment != .none {
                HStack(spacing: PSSpacing.sm) {
                    Image(systemName: adjustment.iconName)
                        .font(.caption)
                        .foregroundColor(adjustment.color)
                    
                    let difference = actualDuration - scheduledDuration
                    Text(difference > 0 ? "+\(difference) min" : "\(difference) min")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(adjustment.color)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: difference)
                    
                    Spacer()
                }
                .padding(.horizontal, PSSpacing.md)
                .padding(.vertical, PSSpacing.sm)
                .background(
                    RoundedRectangle(cornerRadius: PSCornerRadius.small)
                        .fill(adjustment.color.opacity(0.1))
                )
            }
        }
        .padding(PSSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                .fill(Color.appBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                        .stroke(Color.appBorder.opacity(0.2), lineWidth: 1)
                )
        )
    }
    
    private func QuickAdjustmentGrid() -> some View {
        VStack(spacing: PSSpacing.sm) {
            // Primary Options Row
            HStack(spacing: PSSpacing.sm) {
                QuickAdjustmentButton(
                    title: L("sleepModification.asScheduled", table: "AddSleepEntrySheet"),
                    subtitle: L("sleepModification.fullDuration", table: "AddSleepEntrySheet"),
                    icon: "checkmark.circle.fill",
                    color: .appSuccess,
                    isSelected: durationAdjustment == .none
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        durationAdjustment = .none
                        showCustomAdjustment = false
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                
                QuickAdjustmentButton(
                    title: L("sleepModification.skipped", table: "AddSleepEntrySheet"),
                    subtitle: L("sleepModification.didntSleep", table: "AddSleepEntrySheet"),
                    icon: "xmark.circle.fill",
                    color: .appError,
                    isSelected: durationAdjustment == .skipped
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        durationAdjustment = .skipped
                        showCustomAdjustment = false
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
            
            // Common Adjustments Row
            HStack(spacing: PSSpacing.sm) {
                QuickAdjustmentButton(
                    title: L("sleepModification.early5", table: "AddSleepEntrySheet"),
                    subtitle: L("sleepModification.wokeEarly", table: "AddSleepEntrySheet"),
                    icon: "arrow.up.circle.fill",
                    color: .metricAmber,
                    isSelected: durationAdjustment == .differentTime(minutes: -5)
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        durationAdjustment = .differentTime(minutes: -5)
                        showCustomAdjustment = false
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
                
                QuickAdjustmentButton(
                    title: L("sleepModification.late10", table: "AddSleepEntrySheet"),
                    subtitle: L("sleepModification.sleptLonger", table: "AddSleepEntrySheet"),
                    icon: "arrow.down.circle.fill",
                    color: .appPrimary,
                    isSelected: durationAdjustment == .differentTime(minutes: 10)
                ) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        durationAdjustment = .differentTime(minutes: 10)
                        showCustomAdjustment = false
                    }
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
            }
            
            // Custom Adjustment Toggle
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    showCustomAdjustment.toggle()
                    if showCustomAdjustment {
                        setupCustomAdjustment()
                    }
                }
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }) {
                HStack(spacing: PSSpacing.sm) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.caption)
                        .foregroundColor(.appPrimary)
                    
                    Text(L("sleepModification.customAdjustment", table: "AddSleepEntrySheet"))
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.appPrimary)
                    
                    Spacer()
                    
                    Image(systemName: showCustomAdjustment ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                        .foregroundColor(.appPrimary)
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: showCustomAdjustment)
                }
                .padding(.vertical, PSSpacing.sm)
            }
        }
    }
    
    private func QuickAdjustmentButton(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: PSSpacing.xs) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : color)
                    .frame(width: PSIconSize.large, height: PSIconSize.large)
                    .background(
                        Circle()
                            .fill(isSelected ? color : color.opacity(0.1))
                    )
                
                VStack(spacing: 2) {
                    Text(title)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? color : .appText)
                        .multilineTextAlignment(.center)
                    
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(isSelected ? color.opacity(0.8) : .appTextSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, PSSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                    .fill(isSelected ? color.opacity(0.1) : Color.appCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                            .stroke(isSelected ? color : Color.appBorder.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(
                        color: isSelected ? color.opacity(0.2) : Color.clear,
                        radius: isSelected ? 4 : 0,
                        x: 0,
                        y: isSelected ? 2 : 0
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private func primaryOptionButton(
        title: String,
        icon: String,
        color: Color,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: PSSpacing.sm) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : color)
                    .frame(width: 28, height: 28)
                    .background(
                        Circle()
                            .fill(isSelected ? color : color.opacity(0.1))
                    )
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? color : .appText)
                    .multilineTextAlignment(.leading)
                
                Spacer()
            }
            .padding(.horizontal, PSSpacing.md)
            .padding(.vertical, PSSpacing.md)
            .background(
                RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                    .fill(isSelected ? color.opacity(0.08) : Color.appCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                            .stroke(isSelected ? color : Color.appBorder.opacity(0.3), lineWidth: 1.5)
                    )
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private func CustomAdjustmentView() -> some View {
        VStack(spacing: PSSpacing.md) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L("sleepModification.customTimes", table: "AddSleepEntrySheet"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.appText)
                    
                    Text(L("sleepModification.customTimesHint", table: "AddSleepEntrySheet"))
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
                Spacer()
            }
            
            HStack(alignment: .center, spacing: PSSpacing.sm) {
                VStack(alignment: .center, spacing: PSSpacing.xs) {
                    Text(L("sleepModification.startTime", table: "AddSleepEntrySheet"))
                        .font(.caption.weight(.medium))
                        .foregroundColor(.appTextSecondary)
                    
                    DatePicker("", selection: $customStartTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(Color.appPrimary)
                        .onChange(of: customStartTime) { _ in
                            // Automatically update when time changes
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                durationAdjustment = .custom(startTime: customStartTime, endTime: customEndTime)
                            }
                        }
                }
                .frame(maxWidth: .infinity)
                
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.appTextTertiary)
                
                VStack(alignment: .center, spacing: PSSpacing.xs) {
                    Text(L("sleepModification.endTime", table: "AddSleepEntrySheet"))
                        .font(.caption.weight(.medium))
                        .foregroundColor(.appTextSecondary)
                    
                    DatePicker("", selection: $customEndTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(Color.appPrimary)
                        .onChange(of: customEndTime) { _ in
                            // Automatically update when time changes
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                durationAdjustment = .custom(startTime: customStartTime, endTime: customEndTime)
                            }
                        }
                }
                .frame(maxWidth: .infinity)
            }
            
            // Duration preview
            if case .custom(let start, let end) = durationAdjustment {
                let mins = Int(max(0, end.timeIntervalSince(start)) / 60)
                HStack(spacing: PSSpacing.xs) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.appPrimary)
                    Text(formatDuration(mins))
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.appPrimary)
                }
                .padding(.horizontal, PSSpacing.sm)
                .padding(.vertical, PSSpacing.xs)
                .background(
                    Capsule()
                        .fill(Color.appPrimary.opacity(0.1))
                )
            }
        }
        .padding(PSSpacing.md)
        .background(
            RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                .fill(Color.appBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                        .stroke(Color.appSecondary.opacity(0.3), lineWidth: 1)
                )
        )
    }
    
    private func ModernBlockSelectionButton(
        block: SleepBlock,
        isSelected: Bool,
        isAlreadyAdded: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack(spacing: PSSpacing.md) {
                // Block Type Icon
                Text(block.isCore ? getUserCoreEmoji() : getUserNapEmoji())
                    .font(.title3)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill((block.isCore ? Color.appPrimary : Color.appSecondary).opacity(isSelected ? 1.0 : 0.15))
                    )
                
                // Block Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(block.isCore ? L("sleep.type.core", table: "DayDetail") : L("sleep.type.nap", table: "DayDetail"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(isAlreadyAdded ? .appTextSecondary : .appText)
                    
                    HStack(spacing: PSSpacing.xs) {
                        Text("\(block.startTime) – \(block.endTime)")
                            .font(.caption)
                            .foregroundColor(isAlreadyAdded ? .appTextSecondary.opacity(0.7) : .appTextSecondary)
                        
                        if let duration = calculateBlockDuration(block) {
                            Text("·")
                                .font(.caption)
                                .foregroundColor(.appTextTertiary)
                            Text(formatDuration(duration))
                                .font(.caption.weight(.medium))
                                .foregroundColor(.appAccent)
                        }
                    }
                }
                
                Spacer()
                
                // Selection Indicator
                Group {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.appPrimary)
                            .scaleEffect(animateSelection ? 1.2 : 1.0)
                    } else if isAlreadyAdded {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.gray.opacity(0.5))
                    } else {
                        Image(systemName: "circle")
                            .font(.title3)
                            .foregroundColor(.appBorder)
                    }
                }
            }
            .padding(.horizontal, PSSpacing.md)
            .padding(.vertical, PSSpacing.sm + 2)
            .frame(minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                    .fill(
                        isSelected ? Color.appPrimary.opacity(0.08) :
                        isAlreadyAdded ? Color.gray.opacity(0.04) : Color.appCardBackground
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                            .stroke(
                                isSelected ? Color.appPrimary :
                                isAlreadyAdded ? Color.gray.opacity(0.2) : Color.appBorder.opacity(0.2),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
                    .shadow(
                        color: isSelected ? Color.appPrimary.opacity(0.08) : Color.clear,
                        radius: isSelected ? 4 : 0,
                        x: 0,
                        y: isSelected ? 2 : 0
                    )
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
            .opacity(isAlreadyAdded ? 0.55 : 1.0)
        }
        .disabled(isAlreadyAdded)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private func CustomBlockSelectionButton(
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        Button(action: onTap) {
            HStack(spacing: PSSpacing.md) {
                // Custom Icon
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .appSecondary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(Color.appSecondary.opacity(isSelected ? 1.0 : 0.15))
                    )
                
                // Custom Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("sleepModification.customTime", table: "AddSleepEntrySheet"))
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.appText)
                    
                    Text(L("sleepModification.customTimeDescription", table: "AddSleepEntrySheet"))
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                // Selection Indicator
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundColor(isSelected ? .appSecondary : .appBorder)
            }
            .padding(.horizontal, PSSpacing.md)
            .padding(.vertical, PSSpacing.sm + 2)
            .frame(minHeight: 52)
            .background(
                RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                    .fill(isSelected ? Color.appSecondary.opacity(0.08) : Color.appCardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                            .stroke(isSelected ? Color.appSecondary.opacity(0.5) : Color.appBorder.opacity(0.2), lineWidth: isSelected ? 1.5 : 1)
                    )
            )
            .scaleEffect(isSelected ? 1.01 : 1.0)
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
    
    private var customOnlyCard: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.md) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L("sleepModification.customTimes", table: "AddSleepEntrySheet"))
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.appText)
                    
                    Text(L("sleepModification.customTimesHint", table: "AddSleepEntrySheet"))
                        .font(.caption)
                        .foregroundColor(.appTextSecondary)
                }
                
                CustomAdjustmentView()
            }
        }
    }
    
    private func EmptyBlocksView() -> some View {
        VStack(spacing: PSSpacing.xl) {
            ZStack {
                Circle()
                    .fill(Color.appSecondary.opacity(0.1))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(Color.appSecondary.opacity(0.6))
            }
            
            VStack(spacing: PSSpacing.sm) {
                Text(L("sleepEntry.noBlocks", table: "AddSleepEntrySheet"))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.appText)
                    .multilineTextAlignment(.center)
                
                Text(L("sleepEntry.noBlocks.suggestion", table: "AddSleepEntrySheet"))
                    .font(.body)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PSSpacing.xxl)
    }
    
    // MARK: - Event Handlers
    private func handleDateChange() {
        selectedBlockFromSchedule = nil
        durationAdjustment = .none
        showCustomAdjustment = false
        
        if isDateInFuture {
            dateWarningMessage = "sleepEntry.error.futureDate"
            showDateWarning = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                selectedDate = Date()
            }
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }
    
    private func handleBlockChange() {
        guard let block = selectedBlockFromSchedule else { return }
        
        durationAdjustment = .none
        showCustomAdjustment = false
        
        if let times = calculateBlockTimes(for: block, on: selectedDate) {
            customStartTime = times.start
            customEndTime = times.end
        }
    }
    
    private func handleBlockTapped(_ block: SleepBlock, isAlreadyAdded: Bool) {
        if isAlreadyAdded {
            showBlockAlreadyAddedError(for: block)
        } else {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedBlockFromSchedule = block
                animateSelection = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateSelection = false
            }
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        }
    }
    
    private func setupCustomAdjustment() {
        if let block = selectedBlockFromSchedule,
           let times = calculateBlockTimes(for: block, on: selectedDate) {
            customStartTime = times.start
            customEndTime = times.end
        } else {
            // For custom entries without scheduled block, set reasonable defaults
            let calendar = Calendar.current
            let now = Date()
            customStartTime = calendar.date(byAdding: .hour, value: -8, to: now) ?? now
            customEndTime = now
        }
        durationAdjustment = .custom(startTime: customStartTime, endTime: customEndTime)
    }
    
    private func saveEntry() {
        guard isValidEntry else {
            HapticFeedbackManager.shared.trigger(.warning)
            return
        }

        HapticFeedbackManager.shared.trigger(.strongCommit)
        let didSave = saveSleepEntry()
        if didSave {
            HapticFeedbackManager.shared.trigger(.success)
            dismiss()
        } else {
            HapticFeedbackManager.shared.trigger(.error)
        }
    }
    
    // MARK: - Helper Methods
    private func getUserCoreEmoji() -> String {
        UserDefaults.standard.string(forKey: "selectedCoreEmoji") ?? "🌙"
    }
    
    private func getUserNapEmoji() -> String {
        UserDefaults.standard.string(forKey: "selectedNapEmoji") ?? "💤"
    }
    
    private func calculateBlockDuration(_ block: SleepBlock) -> Int? {
        guard let times = calculateBlockTimes(for: block, on: selectedDate) else { return nil }
        return Int(times.end.timeIntervalSince(times.start) / 60)
    }
    
    private func formatDuration(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60
        if hours > 0 {
            return String(format: "%dh %dm", hours, mins)
        } else {
            return String(format: "%dm", mins)
        }
    }
    
    // MARK: - Logic (Existing)
    private func isBlockAlreadyAdded(_ block: SleepBlock) -> Bool {
        guard let modelContext = viewModel.modelContext,
              let times = calculateBlockTimes(for: block, on: selectedDate) else { return false }
        
        let targetDayStart = Calendar.current.startOfDay(for: selectedDate)
        guard let nextDayStart = Calendar.current.date(byAdding: .day, value: 1, to: targetDayStart) else { return false }
        
        // Block hasn't finished yet
        if Calendar.current.isDateInToday(selectedDate) && times.end > Date() {
            return true
        }
        
        let blockIDString = block.id.uuidString
        let predicate = #Predicate<SleepEntry> { entry in
            entry.date >= targetDayStart && entry.date < nextDayStart && entry.blockId == blockIDString
        }
        let descriptor = FetchDescriptor(predicate: predicate)
        
        do {
            let count = try modelContext.fetchCount(descriptor)
            return count > 0
        } catch {
            print("isBlockAlreadyAdded fetch failed: \(error)")
            return false
        }
    }
    
    private func showBlockAlreadyAddedError(for block: SleepBlock) {
        if Calendar.current.isDateInToday(selectedDate),
           let times = calculateBlockTimes(for: block, on: selectedDate),
           times.end > Date() {
            blockErrorMessage = "sleepEntry.error.notFinished"
        } else {
            blockErrorMessage = "sleepEntry.error.alreadyAdded"
        }
        showBlockError = true
    }
    
    private func calculateBlockTimes(for block: SleepBlock, on date: Date) -> (start: Date, end: Date)? {
        let calendar = Calendar.current
        guard let scheduleStartTimeComponents = TimeFormatter.time(from: block.startTime),
              let scheduleEndTimeComponents = TimeFormatter.time(from: block.endTime) else { return nil }
        
        var startComponents = calendar.dateComponents([.year, .month, .day], from: date)
        startComponents.hour = scheduleStartTimeComponents.hour
        startComponents.minute = scheduleStartTimeComponents.minute
        
        var endComponents = calendar.dateComponents([.year, .month, .day], from: date)
        endComponents.hour = scheduleEndTimeComponents.hour
        endComponents.minute = scheduleEndTimeComponents.minute
        
        guard let finalStartTime = calendar.date(from: startComponents),
              var finalEndTime = calendar.date(from: endComponents) else { return nil }
        
        if finalEndTime <= finalStartTime {
            finalEndTime = calendar.date(byAdding: .day, value: 1, to: finalEndTime)!
        }
        
        return (finalStartTime, finalEndTime)
    }
    
    private func saveSleepEntry() -> Bool {
        // For custom entries, create a temporary block or use nil
        let scheduledBlock = selectedBlockFromSchedule
        
        let finalStartTime: Date
        let finalEndTime: Date
        let finalEmoji: String
        let finalRating: Double
        let adjustmentType: String
        let adjustmentMinutes: Int?
        let originalScheduledTimes = scheduledBlock != nil ? calculateBlockTimes(for: scheduledBlock!, on: selectedDate) : nil
        
        // For custom entries without scheduled block, use custom times directly
        if scheduledBlock == nil && showCustomAdjustment {
            finalStartTime = customStartTime
            finalEndTime = customEndTime < customStartTime ? Calendar.current.date(byAdding: .day, value: 1, to: customEndTime)! : customEndTime
            finalEmoji = SleepQualitySlider.getEmoji(for: sliderValue)
            finalRating = sliderValue + 1.0
            adjustmentType = SleepAdjustmentType.custom.rawValue
            adjustmentMinutes = nil
        } else {
            // Original logic for scheduled blocks
            switch durationAdjustment {
            case .none:
                guard let times = originalScheduledTimes else { return false }
                finalStartTime = times.start
                finalEndTime = times.end
                finalEmoji = SleepQualitySlider.getEmoji(for: sliderValue)
                finalRating = sliderValue + 1.0
                adjustmentType = SleepAdjustmentType.asScheduled.rawValue
                adjustmentMinutes = nil
                
            case .differentTime(let minutes):
                guard let times = originalScheduledTimes else { return false }
                finalStartTime = times.start
                finalEndTime = Calendar.current.date(byAdding: .minute, value: minutes, to: times.end)!
                finalEmoji = SleepQualitySlider.getEmoji(for: sliderValue)
                finalRating = sliderValue + 1.0
                adjustmentType = SleepAdjustmentType.differentTime.rawValue
                adjustmentMinutes = minutes
                
            case .custom(let startTime, let endTime):
                finalStartTime = startTime
                finalEndTime = endTime < startTime ? Calendar.current.date(byAdding: .day, value: 1, to: endTime)! : endTime
                finalEmoji = SleepQualitySlider.getEmoji(for: sliderValue)
                finalRating = sliderValue + 1.0
                adjustmentType = SleepAdjustmentType.custom.rawValue
                adjustmentMinutes = nil
                
            case .skipped:
                guard let times = originalScheduledTimes else { return false }
                finalStartTime = times.start
                finalEndTime = times.start // Zero duration
                finalEmoji = "🚫"
                finalRating = 0 // Represents skipped
                adjustmentType = SleepAdjustmentType.skipped.rawValue
                adjustmentMinutes = nil
            }
        }
        
        let durationMinutes = Int(finalEndTime.timeIntervalSince(finalStartTime) / 60)
        
        let newEntry = SleepEntry(
            date: Calendar.current.startOfDay(for: selectedDate),
            startTime: finalStartTime,
            endTime: finalEndTime,
            durationMinutes: durationMinutes,
            isCore: scheduledBlock?.isCore ?? true, // Default to core for custom entries
            blockId: scheduledBlock?.id.uuidString,
            emoji: finalEmoji,
            rating: finalRating,
            adjustmentType: adjustmentType,
            adjustmentMinutes: adjustmentMinutes,
            originalScheduledStartTime: originalScheduledTimes?.start,
            originalScheduledEndTime: originalScheduledTimes?.end
        )
        
        viewModel.addSleepEntry(newEntry)
        
        // Log analytics
        let isCore = scheduledBlock?.isCore ?? true
        analyticsManager.logSleepEntryAdded(
            sleepType: isCore ? "core" : "nap",
            duration: durationMinutes,
            quality: finalRating
        )
        
        if durationAdjustment != .skipped {
            analyticsManager.logSleepQualityRated(
                rating: finalRating,
                sleepType: isCore ? "core" : "nap"
            )
            
            // Save to HealthKit only if not skipped
            Task {
                let sleepType: SleepType = isCore ? .core : .powerNap
                await ScheduleManager.shared.saveSleepSessionToHealthKit(
                    startDate: finalStartTime,
                    endDate: finalEndTime,
                    sleepType: sleepType
                )
            }
        }

        return true
    }
}

// MARK: - Sleep Quality Slider (Unchanged)
private struct SleepQualitySlider: View {
    @Binding var sliderValue: Double
    @EnvironmentObject private var languageManager: LanguageManager
    
    private static let emojis = ["😩", "😪", "😐", "😊", "😄"]
    private let emojiDescriptions = [
        "😩": "sleep.quality.veryBad",
        "😪": "sleep.quality.bad",
        "😐": "sleep.quality.okay",
        "😊": "sleep.quality.good",
        "😄": "sleep.quality.veryGood"
    ]
    
    static func getEmoji(for value: Double) -> String {
        let index = min(Int(value.rounded()), emojis.count - 1)
        return emojis[index]
    }
    
    // Slider değerine göre emoji seçimi
    private var currentEmoji: String {
        let index = min(Int(sliderValue.rounded()), SleepQualitySlider.emojis.count - 1)
        return SleepQualitySlider.emojis[index]
    }
    
    // Slider değerine göre emoji açıklaması
    private var currentEmojiDescription: String {
        return L(emojiDescriptions[currentEmoji] ?? "", table: "SleepQuality")
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Emoji
            Text(currentEmoji)
                .font(.system(size: 60))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentEmoji)
            
            // Emoji Description
            Text(currentEmojiDescription)
                .font(.headline)
                .fontWeight(.medium)
                .foregroundColor(.appText)
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentEmojiDescription)
            
            // Yıldız Puanlama
            HStack(spacing: 6) {
                ForEach(0..<5) { index in
                    let starValue = Double(index)
                    let isFilled = sliderValue >= starValue
                    let isHalfFilled = !isFilled && sliderValue >= starValue - 0.5
                    
                    Image(systemName: isFilled ? "star.fill" : (isHalfFilled ? "star.leadinghalf.filled" : "star"))
                        .foregroundColor(isFilled || isHalfFilled ? Color.appPrimary : Color.appTextSecondary.opacity(0.25))
                        .font(.title3)
                }
            }
            
            // Slider (0.5 increment'li)
            VStack(spacing: 6) {
                Slider(value: $sliderValue, in: 0...4, step: 0.5)
                    .tint(Color.appPrimary)
                    .onChange(of: sliderValue) { newValue in
                        HapticFeedbackManager.shared.trigger(.selection)
                    }
                
                // Slider Labels
                HStack {
                    Text(L("sleepQuality.rating.bad", table: "SleepQuality"))
                        .font(.caption2)
                        .foregroundColor(.appTextSecondary)
                    
                    Spacer()
                    
                    Text(L("sleepQuality.rating.excellent", table: "SleepQuality"))
                        .font(.caption2)
                        .foregroundColor(.appTextSecondary)
                }
            }
        }
    }
    
    private func getSliderColor() -> Color {
        let index = Int(sliderValue.rounded())
        switch index {
        case 0:
            return Color.appError
        case 1:
            return Color.metricAmber
        case 2:
            return Color.appTextSecondary
        case 3:
            return Color.appPrimary
        case 4:
            return Color.appSuccess
        default:
            return Color.appPrimary
        }
    }
}
