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
                        
                        // Zaman Aralığı Seçici
                        timeRangePicker
                        

                        
                        if viewModel.isLoading {
                            loadingView
                        } else if viewModel.hasEnoughData {
                            // Ana Analiz İçeriği
                            VStack(spacing: PSSpacing.xl) {
                                // Free kullanıcılar için temel özellikler
                                AnalyticsSummaryCard(viewModel: viewModel)
                                
                                // Sleep Trends Section (Tüm kullanıcılar için)
                                AnalyticsSleepTrendsSection(
                                    viewModel: viewModel,
                                    isPremiumUser: isPremiumUser,
                                    selectedTrendDataPoint: $selectedTrendDataPoint,
                                    selectedBarDataPoint: $selectedBarDataPoint,
                                    tooltipPosition: $tooltipPosition
                                )
                                
                                AnalyticsBestWorstDays(viewModel: viewModel)
                                
                                // Premium özellikler - kilitli gösterim
                                if isPremiumUser {
                                    // ✅ DOĞRU VERİLERLE ÇALIŞAN GRAFİKLER
                                    AnalyticsQualityDistribution(viewModel: viewModel)
                                    AnalyticsSleepBreakdown(
                                        viewModel: viewModel,
                                        selectedPieSlice: $selectedPieSlice,
                                        tooltipPosition: $tooltipPosition
                                    )
                                    AnalyticsTimeGained(viewModel: viewModel)
                                    
                                    // ❌ YANILTICI GRAFİKLER KALDIRILDI:
                                    // - Uyku Isı Haritası (varsayımsal saatler)
                                    // - Tutarlılık Trendi (bilinmeyen hedef saat)
                                    // - Uyku Borcu (yanlış hedef: 8 saat)  
                                    // - Kalite-Tutarlılık Korelasyonu (yetersiz veri)
                                } else {
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
    
    // MARK: - Actions
    
    private func loadPremiumStatus() {
        isPremiumUser = RevenueCatManager.shared.userState == .premium
    }
}

#Preview {
    AnalyticsView()
}

