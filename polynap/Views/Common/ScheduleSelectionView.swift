import SwiftUI
import RevenueCat
import RevenueCatUI

/// Uyku düzeni seçimi için kompakt view
struct ScheduleSelectionView: View {
    let availableSchedules: [SleepScheduleModel]
    @Binding var selectedSchedule: UserScheduleModel
    let onScheduleSelected: (SleepScheduleModel) -> Void
    let isPremiumUser: Bool // Premium durumunu init'te alacağız
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var isProcessing = false
    @State private var scrollOffset: CGFloat = 0
    @State private var lastScrollTime = Date()
    @State private var isPremium: Bool = false
    @State private var scrollVelocity: CGFloat = 0
    @State private var isScrolling: Bool = false
    
    // FREE ÖNCE, PREMIUM SONRA + ALFABETİK SIRALAMA
    private var sortedSchedules: [SleepScheduleModel] {
        // Tüm schedule'ları al (premium durumu kontrol edilmeksizin - UI'da farklı şekilde göstereceğiz)
        let allSchedules = SleepScheduleService.shared.getAllSchedules()
        let freeSchedules = allSchedules.filter { !$0.isPremium }.sorted { $0.name < $1.name }
        let premiumSchedules = allSchedules.filter { $0.isPremium }.sorted { $0.name < $1.name }
        return freeSchedules + premiumSchedules
    }
    
    /// String ID'den deterministik UUID oluşturur (MainScreenViewModel ile aynı algoritma)
    private func generateDeterministicUUID(from stringId: String) -> UUID {
        // PolyNap namespace UUID'si (sabit bir UUID) - MainScreenViewModel ile aynı
        let namespace = UUID(uuidString: "6BA7B810-9DAD-11D1-80B4-00C04FD430C8") ?? UUID()
        
        // String'i Data'ya dönüştür
        let data = stringId.data(using: .utf8) ?? Data()
        
        // MD5 hash ile deterministik UUID oluştur
        var digest = [UInt8](repeating: 0, count: 16)
        
        // Basit hash algoritması
        let namespaceBytes = withUnsafeBytes(of: namespace.uuid) { Array($0) }
        let stringBytes = Array(data)
        
        for (index, byte) in (namespaceBytes + stringBytes).enumerated() {
            digest[index % 16] ^= byte
        }
        
        // UUID'nin version ve variant bitlerini ayarla (version 5 için)
        digest[6] = (digest[6] & 0x0F) | 0x50  // Version 5
        digest[8] = (digest[8] & 0x3F) | 0x80  // Variant 10
        
        // UUID oluştur
        let uuid = NSUUID(uuidBytes: digest) as UUID
        return uuid
    }
    
    /// Schedule'ın seçili olup olmadığını kontrol eder
    private func isScheduleSelected(_ schedule: SleepScheduleModel) -> Bool {
        let scheduleUUID = generateDeterministicUUID(from: schedule.id)
        let repositoryCompatibleId = scheduleUUID.uuidString
        return selectedSchedule.id == repositoryCompatibleId
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()

                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: PSSpacing.md) {
                            // Subtitle + difficulty legend
                            VStack(spacing: PSSpacing.sm) {
                                Text(L("scheduleSelection.subtitle", table: "MainScreen"))
                                    .font(OBFont.caption)
                                    .foregroundColor(.appTextSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, PSSpacing.md)

                                HStack(spacing: PSSpacing.sm) {
                                    DifficultyLegendItem(emoji: "🟢", text: "Kolay")
                                    DifficultyLegendItem(emoji: "🟡", text: "Orta")
                                    DifficultyLegendItem(emoji: "🟠", text: "Zor")
                                    DifficultyLegendItem(emoji: "🔴", text: "Uzman")
                                }
                                .padding(.horizontal, PSSpacing.md)
                                .padding(.vertical, PSSpacing.xs)
                                .background(Color.appCardBackground.opacity(0.5),
                                            in: RoundedRectangle(cornerRadius: PSCornerRadius.small))
                            }
                            .padding(.top, PSSpacing.xs)

                            // Free schedule section header
                            ScheduleSectionHeader(title: L("scheduleSelection.freeSchedules", table: "MainScreen"))

                            // Free schedule cards
                            let freeSchedules = sortedSchedules.filter { !$0.isPremium }
                            ForEach(freeSchedules.indices, id: \.self) { index in
                                let schedule = freeSchedules[index]
                                CompactScheduleCard(
                                    schedule: schedule,
                                    isSelected: isScheduleSelected(schedule),
                                    isProcessing: isProcessing,
                                    onSelect: { selectScheduleWithScrollCheck(schedule) }
                                )
                                .id(schedule.id)
                                .transition(.opacity.combined(with: .scale(0.97)))
                            }

                            // Premium section — single unlock banner for non-premium
                            let premiumSchedules = sortedSchedules.filter { $0.isPremium }
                            if !premiumSchedules.isEmpty {
                                if !isPremium {
                                    // Single unlock banner
                                    PremiumUnlockBannerCard(count: premiumSchedules.count)
                                        .transition(.opacity.combined(with: .scale(0.97)))
                                } else {
                                    // Premium user: show all premium schedules
                                    ScheduleSectionHeader(title: L("scheduleSelection.premiumSchedules", table: "MainScreen"))
                                    ForEach(premiumSchedules.indices, id: \.self) { index in
                                        let schedule = premiumSchedules[index]
                                        CompactScheduleCard(
                                            schedule: schedule,
                                            isSelected: isScheduleSelected(schedule),
                                            isProcessing: isProcessing,
                                            onSelect: { selectScheduleWithScrollCheck(schedule) }
                                        )
                                        .id(schedule.id)
                                        .transition(.opacity.combined(with: .scale(0.97)))
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, PSSpacing.lg)
                        .padding(.bottom, PSSpacing.lg)
                        .background(
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        scrollOffset = geo.frame(in: .global).minY
                                    }
                                    .onChange(of: geo.frame(in: .global).minY) { oldValue, newValue in
                                        let currentTime = Date()
                                        let timeDiff = currentTime.timeIntervalSince(lastScrollTime)
                                        if timeDiff > 0 {
                                            scrollVelocity = abs(newValue - oldValue) / timeDiff
                                            isScrolling = scrollVelocity > 50
                                        }
                                        scrollOffset = newValue
                                        lastScrollTime = currentTime
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                            if Date().timeIntervalSince(lastScrollTime) >= 0.5 {
                                                isScrolling = false
                                                scrollVelocity = 0
                                            }
                                        }
                                    }
                            }
                        )
                    }
                }
            }
            .navigationTitle(L("scheduleSelection.title", table: "MainScreen"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text(L("general.cancel", table: "MainScreen"))
                            .font(PSTypography.button)
                            .foregroundColor(.appPrimary)
                    }
                    .disabled(isProcessing)
                }
            }
            .onAppear {
                isPremium = isPremiumUser // İlk başta parametre değerini kullan
                loadPremiumStatus()
            }

        }
    }
    
    private func loadPremiumStatus() {
        // RevenueCat'den gerçek premium durumunu al
        let revenueCatPremium = RevenueCatManager.shared.userState == .premium
        isPremium = revenueCatPremium
        print("🔄 ScheduleSelectionView: Premium durumu RevenueCat'den güncellendi: \(isPremium)")
    }
    
    private func selectScheduleWithScrollCheck(_ schedule: SleepScheduleModel) {
        // Aktif scroll kontrolü - hem zaman hem de velocity bazlı
        let timeSinceLastScroll = Date().timeIntervalSince(lastScrollTime)
        
        if isScrolling || timeSinceLastScroll < 0.4 || scrollVelocity > 30 {
            print("🚫 Scroll sırasında tıklama engellendi - isScrolling: \(isScrolling), timeSince: \(timeSinceLastScroll), velocity: \(scrollVelocity)")
            return
        }
        
        // Çift tıklamayı önle
        guard !isProcessing else { 
            print("🚫 İşlem devam ediyor, çift tıklama engellendi")
            return 
        }
        
        print("✅ Schedule seçimi onaylandı: \(schedule.name)")
        
        withAnimation(.easeInOut(duration: 0.2)) {
            isProcessing = true
        }
        
        // Hafif gecikme ile kullanıcı feedback'i ver
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            onScheduleSelected(schedule)
            
            // İşlem tamamlandıktan sonra dismiss et
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                dismiss()
            }
        }
    }
}

/// Kompakt uyku düzeni kartı
struct CompactScheduleCard: View {
    let schedule: SleepScheduleModel
    let isSelected: Bool
    let isProcessing: Bool
    let onSelect: () -> Void
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var isExpanded = false
    
    var scheduleDescription: String {
        let currentLang = languageManager.currentLanguage
        return schedule.description.localized(for: currentLang)
    }
    
    var body: some View {
        Button(action: onSelect) {
            VStack(spacing: PSSpacing.sm) {
                // Ana header - kompakt
                HStack(spacing: PSSpacing.md) {
                    // Zorluk derecesi emojisi
                    Text(getDifficultyEmoji())
                        .font(.system(size: 20))
                        .frame(width: 24, height: 24)
                    
                    // İsim ve bilgiler
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: PSSpacing.xs) {
                            Text(schedule.name)
                                .font(PSTypography.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.appText)
                                .lineLimit(1)
                            
                            if schedule.isPremium {
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.yellow)
                            }
                        }
                        
                        Text(String(format: "%.1f %@", schedule.totalSleepHours, L("scheduleSelection.hours", table: "MainScreen")))
                            .font(.system(size: 12))
                            .foregroundColor(.appTextSecondary)
                    }
                    
                    Spacer()
                    
                    // Block bilgileri - kompakt
                    HStack(spacing: PSSpacing.xs) {
                        if schedule.coreCount > 0 {
                            CompactBlockInfo(
                                icon: "moon.fill",
                                count: schedule.coreCount,
                                color: .appPrimary
                            )
                        }
                        
                        if schedule.napCount > 0 {
                            CompactBlockInfo(
                                icon: "powersleep",
                                count: schedule.napCount,
                                color: .appAccent
                            )
                        }
                    }
                    
                    // Seçili indikator - küçük
                    ZStack {
                        Circle()
                            .stroke(
                                isSelected ? Color.appPrimary : Color.appTextSecondary.opacity(0.3),
                                lineWidth: 1.5
                            )
                            .frame(width: 18, height: 18)
                        
                        if isSelected {
                            Circle()
                                .fill(Color.appPrimary)
                                .frame(width: 8, height: 8)
                                .scaleEffect(isProcessing ? 0.8 : 1.0)
                                .animation(.easeInOut(duration: 0.2), value: isProcessing)
                        }
                    }
                }
                
                // Açıklama toggle butonu - isteğe bağlı
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        isExpanded.toggle()
                    }
                }) {
                    HStack(spacing: PSSpacing.xs) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 12))
                        
                        Text(isExpanded ? L("scheduleSelection.hide", table: "MainScreen") : L("scheduleSelection.details", table: "MainScreen"))
                            .font(.system(size: 11, weight: .medium))
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10))
                    }
                    .foregroundColor(.appTextSecondary)
                }
                .buttonStyle(.plain)
                
                // Genişletilmiş açıklama
                if isExpanded {
                    VStack(alignment: .leading, spacing: PSSpacing.xs) {
                        Text(scheduleDescription)
                            .font(.system(size: 13))
                            .foregroundColor(.appText)
                            .lineSpacing(1)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        if schedule.coreSleepHours > 0 {
                            HStack(spacing: PSSpacing.xs) {
                                Image(systemName: "moon.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.appPrimary)
                                Text(String(format: "Core: %.1f h", schedule.coreSleepHours))
                                    .font(.system(size: 11))
                                    .foregroundColor(.appTextSecondary)
                                
                                if schedule.napCount > 0 {
                                    Text("·")
                                        .foregroundColor(.appTextSecondary)
                                    Image(systemName: "powersleep")
                                        .font(.system(size: 10))
                                        .foregroundColor(.appAccent)
                                    Text("Naps: \(schedule.napDurationSummary)")
                                        .font(.system(size: 11))
                                        .foregroundColor(.appTextSecondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, PSSpacing.sm)
                    .padding(.vertical, PSSpacing.xs)
                    .background(
                        RoundedRectangle(cornerRadius: PSCornerRadius.small)
                            .fill(Color.appBackground.opacity(0.5))
                    )
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                }
            }
            .padding(PSSpacing.md)
            .background(cardBackground)
            .shadow(
                color: isSelected ? Color.appPrimary.opacity(0.1) : Color.black.opacity(0.03),
                radius: isSelected ? 4 : 2,
                x: 0,
                y: isSelected ? 2 : 1
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 0.99 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        .disabled(isProcessing)
        .opacity(isProcessing && !isSelected ? 0.6 : 1.0)
    }
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: PSCornerRadius.large)
            .fill(Color.appCardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: PSCornerRadius.large)
                    .stroke(
                        isSelected ? Color.appPrimary : Color.clear,
                        lineWidth: 1.5
                    )
            )
    }
    
    private func getDifficultyEmoji() -> String {
        switch schedule.difficulty {
        case .beginner:     return "🟢"
        case .intermediate: return "🟡"
        case .advanced:     return "🟠"
        case .extreme:      return "🔴"
        }
    }
}

// MARK: - Kompakt Block Info
struct CompactBlockInfo: View {
    let icon: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)
            
            Text("\(count)")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.appText)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(
            RoundedRectangle(cornerRadius: 4)
                .fill(color.opacity(0.1))
        )
    }
}

/// Premium kilitli schedule kartı
struct PremiumLockedScheduleCard: View {
    let schedule: SleepScheduleModel
    let isSelected: Bool
    @EnvironmentObject private var languageManager: LanguageManager
    @State private var isExpanded = false
    @State private var isPulsing = false
    @StateObject private var paywallManager = PaywallManager.shared
    
    var scheduleDescription: String {
        let currentLang = languageManager.currentLanguage
        return schedule.description.localized(for: currentLang)
    }
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isPulsing = true
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPulsing = false
                paywallManager.presentPaywall(trigger: .premiumFeatureAccess)
            }
        }) {
            VStack(spacing: PSSpacing.sm) {
                // Ana kart içeriği
                ZStack {
                    // Background content - blurred
                    VStack(spacing: PSSpacing.sm) {
                        // Ana header - kompakt
                        HStack(spacing: PSSpacing.md) {
                            // Zorluk derecesi emojisi
                            Text(getDifficultyEmoji())
                                .font(.system(size: 20))
                                .frame(width: 24, height: 24)
                            
                            // İsim ve bilgiler
                            VStack(alignment: .leading, spacing: 2) {
                                Text(schedule.name)
                                    .font(PSTypography.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.appText)
                                    .lineLimit(1)
                                
                                Text(String(format: "%.1f %@", schedule.totalSleepHours, L("scheduleSelection.hours", table: "MainScreen")))
                                    .font(.system(size: 12))
                                    .foregroundColor(.appTextSecondary)
                            }
                            
                            Spacer()
                            
                            // Block bilgileri - kompakt
                            HStack(spacing: PSSpacing.xs) {
                                if schedule.coreCount > 0 {
                                    CompactBlockInfo(
                                        icon: "moon.fill",
                                        count: schedule.coreCount,
                                        color: .appPrimary
                                    )
                                }
                                
                                if schedule.napCount > 0 {
                                    CompactBlockInfo(
                                        icon: "powersleep",
                                        count: schedule.napCount,
                                        color: .appAccent
                                    )
                                }
                            }
                        }
                        
                        // Açıklama toggle butonu
                        Button(action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isExpanded.toggle()
                            }
                        }) {
                            HStack(spacing: PSSpacing.xs) {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 12))
                                
                                Text(isExpanded ? L("scheduleSelection.hide", table: "MainScreen") : L("scheduleSelection.details", table: "MainScreen"))
                                    .font(.system(size: 11, weight: .medium))
                                
                                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.appTextSecondary)
                        }
                        .buttonStyle(.plain)
                        
                        // Genişletilmiş açıklama
                        if isExpanded {
                            Text(scheduleDescription)
                                .font(.system(size: 13))
                                .foregroundColor(.appText)
                                .lineSpacing(1)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, PSSpacing.sm)
                                .padding(.vertical, PSSpacing.xs)
                                .background(
                                    RoundedRectangle(cornerRadius: PSCornerRadius.small)
                                        .fill(Color.appBackground.opacity(0.5))
                                )
                                .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .top)))
                        }
                    }
                    .blur(radius: 2.5)
                    .opacity(0.4)
                    
                    // Premium overlay - minimal ve şık
                    VStack(spacing: PSSpacing.sm) {
                        // Premium crown icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [.yellow, .orange]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .shadow(color: .yellow.opacity(0.3), radius: 8, x: 0, y: 4)
                            
                            Image(systemName: "crown.fill")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(isPulsing ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 0.15), value: isPulsing)
                        
                        // Minimal metin
                        VStack(spacing: 4) {
                                                         Text(L("scheduleSelection.premium.title", table: "MainScreen"))
                                 .font(.system(size: 16, weight: .bold, design: .rounded))
                                 .foregroundColor(.appText)
                            
                                                         Text(L("scheduleSelection.premium.tapToUpgrade", table: "MainScreen"))
                                 .font(.system(size: 12, weight: .medium))
                                 .foregroundColor(.appTextSecondary)
                        }
                    }
                    .padding(.vertical, PSSpacing.sm)
                }
            }
            .padding(PSSpacing.md)
            .background(premiumCardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: PSCornerRadius.large)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [.yellow.opacity(0.6), .orange.opacity(0.6)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
            )
            .shadow(
                color: Color.yellow.opacity(0.15),
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isPulsing ? 0.98 : 1.0)
    }
    
    private var premiumCardBackground: some View {
        RoundedRectangle(cornerRadius: PSCornerRadius.large)
            .fill(Color.appCardBackground)
    }
    
    private func getDifficultyEmoji() -> String {
        switch schedule.difficulty {
        case .beginner:     return "🟢"
        case .intermediate: return "🟡"
        case .advanced:     return "🟠"
        case .extreme:      return "🔴"
        }
    }
}

/// Schedule bölüm başlığı
struct ScheduleSectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(OBFont.captionBold)
                .foregroundColor(.appTextSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
            Spacer()
        }
        .padding(.horizontal, PSSpacing.xs)
        .padding(.top, PSSpacing.md)
        .padding(.bottom, PSSpacing.xs)
    }
}

/// Single premium unlock banner (replaces N individual locked cards)
struct PremiumUnlockBannerCard: View {
    let count: Int
    @StateObject private var paywallManager = PaywallManager.shared
    @State private var isPulsing = false
    @State private var isPressed = false

    var body: some View {
        Button(action: {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) { isPulsing = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                isPulsing = false
                paywallManager.presentPaywall(trigger: .premiumFeatureAccess)
            }
        }) {
            VStack(spacing: 0) {
                // Gradient background header
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: "1A3366"), Color(hex: "2D5A9E")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    VStack(spacing: PSSpacing.sm) {
                        // Crown + count badge
                        HStack(spacing: PSSpacing.sm) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 44, height: 44)
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(Color(hex: "F59E0B"))
                            }
                            .scaleEffect(isPulsing ? 1.12 : 1.0)
                            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPulsing)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(LanguageManager.shared.currentLanguage == "tr"
                                     ? "\(count)+ Premium Program"
                                     : "\(count)+ Premium Sleep Schedules")
                                    .font(OBFont.bodyBold)
                                    .foregroundColor(.white)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)

                                Text(LanguageManager.shared.currentLanguage == "tr"
                                     ? "Uberman, Dymaxion ve daha fazlası"
                                     : "Uberman, Dymaxion & more")
                                    .font(OBFont.small)
                                    .foregroundColor(.white.opacity(0.7))
                                    .lineLimit(1)
                            }

                            Spacer()

                            // Chevron arrow
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }
                        .padding(.horizontal, PSSpacing.md)
                        .padding(.top, PSSpacing.md)
                        .padding(.bottom, PSSpacing.sm)
                    }
                }
                .clipShape(RoundedRectangle(cornerRadius: 18))

                // CTA strip
                HStack(spacing: PSSpacing.xs) {
                    Image(systemName: "lock.open.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(hex: "F59E0B"))
                    Text(LanguageManager.shared.currentLanguage == "tr"
                         ? "Premium'a Geç · Tümünü Aç"
                         : "Upgrade to Premium · Unlock All")
                        .font(OBFont.captionBold)
                        .foregroundColor(Color(hex: "F59E0B"))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(Color(hex: "F59E0B").opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .padding(.top, 4)
            }
        }
        .buttonStyle(.plain)
        .scaleEffect(isPulsing ? 0.97 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: isPulsing)
        .accessibilityLabel("Unlock \(count) premium sleep schedules")
        .accessibilityHint("Tap to upgrade to premium")
    }
}


/// Zorluk derecesi gösterge öğesi
struct DifficultyLegendItem: View {
    let emoji: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(emoji)
                .font(.system(size: 12))
            
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
    }
}
