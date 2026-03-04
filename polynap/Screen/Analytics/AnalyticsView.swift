import SwiftUI
import Charts

public struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var languageManager: LanguageManager
    
    // Tooltip için state değişkenleri
    @State private var selectedTrendDataPoint: SleepTrendData?
    @State private var selectedBarDataPoint: SleepTrendData?
    @State private var selectedPieSlice: SleepBreakdownData?
    @State private var tooltipPosition: CGPoint = .zero
    @State private var isPremiumUser = false
    @State private var healthDataRequested = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: PSSpacing.xl) {
                        // Başlık
                        Text(L("tabbar.analytics", table: "Common"))
                            .font(PSTypography.largeTitle)
                            .foregroundColor(.appText)
                            .padding(.horizontal, PSSpacing.lg)
                            .padding(.top, PSSpacing.sm)
                            .tourTarget("tour.analytics.content")
                        
                        // Zaman Aralığı Seçici
                        timeRangePicker
                        

                        
                        if viewModel.isLoading {
                            loadingView
                        } else if viewModel.hasEnoughData {
                            VStack(spacing: PSSpacing.xl) {
                                // ═══════════════════════════════════════
                                // SECTION 1: FREE — Temel Metrikler
                                // ═══════════════════════════════════════
                                
                                AnalyticsSummaryCard(viewModel: viewModel)
                                
                                // Adherence Summary (Uyum özeti)
                                if !viewModel.adherenceData.isEmpty {
                                    adherenceSummaryCard
                                }
                                
                                // Sleep Trends (Tüm kullanıcılar)
                                AnalyticsSleepTrendsSection(
                                    viewModel: viewModel,
                                    isPremiumUser: isPremiumUser,
                                    selectedTrendDataPoint: $selectedTrendDataPoint,
                                    selectedBarDataPoint: $selectedBarDataPoint,
                                    tooltipPosition: $tooltipPosition
                                )
                                
                                AnalyticsBestWorstDays(viewModel: viewModel)
                                
                                // Adherence Detail Chart (Uyum detay)
                                if !viewModel.adherenceData.isEmpty {
                                    PSCard {
                                        VStack(alignment: .leading, spacing: PSSpacing.lg) {
                                            PSSectionHeader(
                                                L("analytics.adherence.title", table: "Analytics"),
                                                icon: "checkmark.circle.fill",
                                                subtitle: L("analytics.adherence.subtitle", table: "Analytics")
                                            )
                                            AdherenceScoreChart(viewModel: viewModel)
                                        }
                                    }
                                    .padding(.horizontal, PSSpacing.lg)
                                }
                                
                                // ═══════════════════════════════════════
                                // SECTION 2: PREMIUM — Gelişmiş Analizler
                                // ═══════════════════════════════════════
                                
                                if isPremiumUser {
                                    AnalyticsQualityDistribution(viewModel: viewModel)
                                    
                                    AnalyticsSleepBreakdown(
                                        viewModel: viewModel,
                                        selectedPieSlice: $selectedPieSlice,
                                        tooltipPosition: $tooltipPosition
                                    )
                                    
                                    // Sleep Debt (Uyku borcu)
                                    if !viewModel.sleepDebtData.isEmpty {
                                        AnalyticsSleepDebtSection(viewModel: viewModel)
                                    }
                                    
                                    // Consistency Trend (Tutarlılık)
                                    if !viewModel.consistencyTrendData.isEmpty {
                                        AnalyticsConsistencyTrendSection(viewModel: viewModel)
                                    }
                                    
                                    // HeatMap (Actogram)
                                    AnalyticsHeatMapSection(viewModel: viewModel)
                                    
                                    AnalyticsTimeGained(viewModel: viewModel)
                                    
                                    // Quality-Consistency Correlation
                                    if !viewModel.qualityConsistencyData.isEmpty {
                                        AnalyticsQualityConsistencyCorrelation(viewModel: viewModel)
                                    }
                                    
                                    // ═══════════════════════════════════════
                                    // SECTION 3: PREMIUM + HEALTHKIT
                                    // ═══════════════════════════════════════
                                    
                                    // Sleep Stages (Uyku evreleri)
                                    if !viewModel.sleepStagesData.isEmpty {
                                        PSCard {
                                            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                                                PSSectionHeader(
                                                    L("analytics.sleepStages.title", table: "Analytics"),
                                                    icon: "moon.stars.fill",
                                                    subtitle: L("analytics.sleepStages.subtitle", table: "Analytics")
                                                )
                                                SleepStagesChart(viewModel: viewModel)
                                            }
                                        }
                                        .padding(.horizontal, PSSpacing.lg)
                                    }
                                    
                                    // Heart Rate
                                    if !viewModel.heartRateData.isEmpty {
                                        PSCard {
                                            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                                                PSSectionHeader(
                                                    L("analytics.heartRate.title", table: "Analytics"),
                                                    icon: "heart.fill",
                                                    subtitle: L("analytics.heartRate.subtitle", table: "Analytics")
                                                )
                                                HeartRateChart(viewModel: viewModel)
                                            }
                                        }
                                        .padding(.horizontal, PSSpacing.lg)
                                    }
                                    
                                    // HRV Recovery
                                    if !viewModel.hrvData.isEmpty {
                                        PSCard {
                                            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                                                PSSectionHeader(
                                                    L("analytics.hrv.title", table: "Analytics"),
                                                    icon: "waveform.path.ecg",
                                                    subtitle: L("analytics.hrv.subtitle", table: "Analytics")
                                                )
                                                HRVRecoveryChart(viewModel: viewModel)
                                            }
                                        }
                                        .padding(.horizontal, PSSpacing.lg)
                                    }
                                    
                                    // Sleep Regularity
                                    if !viewModel.sleepRegularityData.isEmpty {
                                        PSCard {
                                            VStack(alignment: .leading, spacing: PSSpacing.lg) {
                                                PSSectionHeader(
                                                    L("analytics.sleepRegularity.title", table: "Analytics"),
                                                    icon: "clock.badge.checkmark.fill",
                                                    subtitle: L("analytics.sleepRegularity.subtitle", table: "Analytics")
                                                )
                                                SleepRegularityChart(viewModel: viewModel)
                                            }
                                        }
                                        .padding(.horizontal, PSSpacing.lg)
                                    }
                                    
                                    // HealthKit erişimi yoksa bağlantı butonu göster
                                    if !viewModel.hasHealthKitAccess && !viewModel.isHealthDataLoading {
                                        PSCard {
                                            VStack(spacing: PSSpacing.md) {
                                                Image(systemName: "heart.circle")
                                                    .font(.system(size: 36))
                                                    .foregroundColor(.appPrimary)
                                                Text(L("analytics.health.access.title", table: "Analytics"))
                                                    .font(PSTypography.headline)
                                                    .foregroundColor(.appText)
                                                Text(L("analytics.health.access.message", table: "Analytics"))
                                                    .font(PSTypography.body)
                                                    .foregroundColor(.appTextSecondary)
                                                    .multilineTextAlignment(.center)
                                                PSPrimaryButton(L("analytics.health.access.button", table: "Analytics")) {
                                                    viewModel.loadHealthData()
                                                }
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, PSSpacing.lg)
                                        }
                                        .padding(.horizontal, PSSpacing.lg)
                                    }
                                    
                                    // HealthKit verisi yoksa bilgi
                                    if viewModel.hasHealthKitAccess && viewModel.heartRateData.isEmpty && viewModel.hrvData.isEmpty && viewModel.sleepStagesData.isEmpty && !viewModel.isHealthDataLoading {
                                        PSCard {
                                            VStack(spacing: PSSpacing.md) {
                                                Image(systemName: "heart.text.clipboard")
                                                    .font(.system(size: 32))
                                                    .foregroundColor(.appTextSecondary)
                                                Text(L("analytics.health.noData.title", table: "Analytics"))
                                                    .font(PSTypography.headline)
                                                    .foregroundColor(.appText)
                                                Text(L("analytics.health.noData.message", table: "Analytics"))
                                                    .font(PSTypography.body)
                                                    .foregroundColor(.appTextSecondary)
                                                    .multilineTextAlignment(.center)
                                            }
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, PSSpacing.lg)
                                        }
                                        .padding(.horizontal, PSSpacing.lg)
                                    }
                                    
                                    if viewModel.isHealthDataLoading {
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                            .padding(.vertical, PSSpacing.lg)
                                    }
                                } else {
                                    // Free kullanıcılar için premium upsell
                                    AnalyticsPremiumUpsell()
                                        .padding(.horizontal, PSSpacing.lg)
                                }
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        } else {
                            insufficientDataView
                        }
                    }
                    .padding(.bottom, PSSpacing.xxl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            print("📱 AnalyticsView appeared")
            viewModel.setModelContext(modelContext)
            loadPremiumStatus()
            
            // Premium kullanıcılar için Health verilerini yükle
            if isPremiumUser && !healthDataRequested {
                healthDataRequested = true
                viewModel.loadHealthData()
            }
        }

        .id(languageManager.currentLanguage)
    }
    
    // MARK: - UI Components
    
    private var timeRangePicker: some View {
        HStack(spacing: PSSpacing.sm) {
            ForEach(TimeRange.allCases) { range in
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        viewModel.changeTimeRange(to: range)
                    }
                }) {
                    Group {
                        if viewModel.isLoading && viewModel.selectedTimeRange == range {
                            ProgressView()
                                .scaleEffect(0.7)
                                .progressViewStyle(CircularProgressViewStyle(tint: .appTextOnPrimary))
                                .frame(width: 14, height: 14)
                        } else {
                            Text(range.displayName)
                                .font(.system(.subheadline, design: .rounded, weight: viewModel.selectedTimeRange == range ? .semibold : .medium))
                                .foregroundColor(viewModel.selectedTimeRange == range ? .appTextOnPrimary : .appText)
                        }
                    }
                    .padding(.horizontal, PSSpacing.lg)
                    .padding(.vertical, PSSpacing.sm + PSSpacing.xs)
                    .frame(maxWidth: .infinity)
                    .background(
                        RoundedRectangle(cornerRadius: PSCornerRadius.button)
                            .fill(viewModel.selectedTimeRange == range ? Color.appPrimary : Color.appCardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: PSCornerRadius.button)
                                    .stroke(viewModel.selectedTimeRange == range ? Color.clear : Color.appBorder.opacity(0.5), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.isLoading)
                .opacity(viewModel.isLoading && viewModel.selectedTimeRange != range ? 0.5 : 1.0)
                .animation(.easeInOut(duration: 0.2), value: viewModel.selectedTimeRange)
            }
        }
        .padding(.horizontal, PSSpacing.lg)
    }
    
    private var loadingView: some View {
        VStack(spacing: PSSpacing.lg) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
            
            Text(L("analytics.loading", table: "Analytics"))
                .font(PSTypography.body)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PSSpacing.xxxl)
    }
    
    private var insufficientDataView: some View {
        PSEmptyState(
            icon: "exclamationmark.triangle.fill",
            title: L("analytics.insufficientData.title", table: "Analytics"),
            message: L("analytics.insufficientData.message", table: "Analytics"),
            actionTitle: L("analytics.insufficientData.button", table: "Analytics"),
            action: {
                // History sayfasına yönlendir (Navigasyon eklenecek)
            }
        )
        .padding(.horizontal, PSSpacing.lg)
        .padding(.top, PSSpacing.xxl)
    }
    
    private var adherenceSummaryCard: some View {
        PSCard {
            VStack(alignment: .leading, spacing: PSSpacing.md) {
                PSSectionHeader(
                    L("analytics.adherence.summary.title", table: "Analytics"),
                    icon: "target",
                    subtitle: L("analytics.adherence.summary.subtitle", table: "Analytics")
                )
                
                HStack(spacing: PSSpacing.md) {
                    // Uyum skoru
                    VStack(spacing: PSSpacing.xs) {
                        Text(String(format: "%.0f%%", viewModel.adherenceSummary.overallScore))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(AdherenceLevel.fromScore(viewModel.adherenceSummary.overallScore).color)
                        Text(L("analytics.adherence.score", table: "Analytics"))
                            .font(PSTypography.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider().frame(height: 40)
                    
                    // Ortalama gecikme
                    VStack(spacing: PSSpacing.xs) {
                        Text(String(format: "%.0f", viewModel.adherenceSummary.averageLateness) + " " + L("analytics.adherence.min", table: "Analytics"))
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.appText)
                        Text(L("analytics.adherence.avgLateness", table: "Analytics"))
                            .font(PSTypography.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                    
                    Divider().frame(height: 40)
                    
                    // Tamamlanan bloklar
                    VStack(spacing: PSSpacing.xs) {
                        Text("\(viewModel.adherenceSummary.totalBlocksCompleted)")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .foregroundColor(.appText)
                        Text(L("analytics.adherence.blocks", table: "Analytics"))
                            .font(PSTypography.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, PSSpacing.lg)
    }
    
    private var healthDataEmptyState: some View {
        VStack(spacing: PSSpacing.sm) {
            Image(systemName: "chart.bar.xaxis.ascending")
                .font(.system(size: 24))
                .foregroundColor(.appTextSecondary)
            Text(L("analytics.sleepRegularity.noData", table: "Analytics"))
                .font(PSTypography.caption)
                .foregroundColor(.appTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PSSpacing.md)
    }
    
    // MARK: - Actions
    
    private func loadPremiumStatus() {
        isPremiumUser = RevenueCatManager.shared.userState == .premium
    }
}

#Preview {
    AnalyticsView()
}

