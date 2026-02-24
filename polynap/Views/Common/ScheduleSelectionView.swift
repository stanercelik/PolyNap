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
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollViewReader { proxy in
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: PSSpacing.md) {
                            // Başlık ve açıklama - daha kompakt
                            VStack(spacing: PSSpacing.sm) {
                                Text(L("scheduleSelection.subtitle", table: "MainScreen"))
                                    .font(PSTypography.caption)
                                    .foregroundColor(.appTextSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, PSSpacing.md)
                                
                                // Zorluk derecesi açıklaması
                                HStack(spacing: PSSpacing.sm) {
                                    DifficultyLegendItem(emoji: "🟢", text: "Kolay")
                                    DifficultyLegendItem(emoji: "🟡", text: "Orta")
                                    DifficultyLegendItem(emoji: "🟠", text: "Zor")
                                    DifficultyLegendItem(emoji: "🔴", text: "Uzman")
                                }
                                .padding(.horizontal, PSSpacing.md)
                                .padding(.vertical, PSSpacing.xs)
                                .background(Color.appCardBackground.opacity(0.5), in: RoundedRectangle(cornerRadius: PSCornerRadius.small))
                            }
                            .padding(.top, PSSpacing.xs)
                            
                            // Schedule kartları
                            ForEach(sortedSchedules.indices, id: \.self) { index in
                                let schedule = sortedSchedules[index]
                                
                                // Bölüm başlığı - Free'den Premium'a geçerken
                                if index == 0 {
                                    // İlk free schedule
                                    ScheduleSectionHeader(title: L("scheduleSelection.freeSchedules", table: "MainScreen"))
                                } else if index > 0 && !sortedSchedules[index-1].isPremium && schedule.isPremium {
                                    // Premium bölümü başlangıcı
                                    ScheduleSectionHeader(title: L("scheduleSelection.premiumSchedules", table: "MainScreen"))
                                }
                                
                                if schedule.isPremium && !isPremium {
                                    // Premium schedule for free users - kilitli
                                    PremiumLockedScheduleCard(
                                        schedule: schedule,
                                        isSelected: isScheduleSelected(schedule)
                                    )
                                    .id(schedule.id)
                                } else {
                                    // Available schedule (free schedules for all users, premium schedules for premium users)
                                    CompactScheduleCard(
                                        schedule: schedule,
                                        isSelected: isScheduleSelected(schedule),
                                        isProcessing: isProcessing,
                                        onSelect: {
                                            selectScheduleWithScrollCheck(schedule)
                                        }
                                    )
                                    .id(schedule.id)
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
                                            isScrolling = scrollVelocity > 50 // 50 points/second threshold
                                        }
                                        
                                        scrollOffset = newValue
                                        lastScrollTime = currentTime
                                        
                                        // Auto-stop scroll detection after 0.5 seconds of no movement
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
                .font(PSTypography.headline)
                .fontWeight(.bold)
                .foregroundColor(.appText)
            
            Spacer()
        }
        .padding(.horizontal, PSSpacing.xs)
        .padding(.top, PSSpacing.md)
        .padding(.bottom, PSSpacing.xs)
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
