import SwiftUI

struct SleepQualityRatingView: View {
    let startTime: Date
    let endTime: Date
    @Binding var isPresented: Bool
    @State private var sliderValue: Double = 2 // 0-4 arası değer (5 emoji için)
    @State private var showSnackbar = false
    @State private var previousEmojiLabel: String = ""
    @State private var labelOffset: CGFloat = 0
    @ObservedObject private var notificationManager = SleepQualityNotificationManager.shared
    @ObservedObject var viewModel: MainScreenViewModel
    @State private var emoji: String = "😐" // Varsayılan emoji
    
    private let emojis = ["😩", "😪", "😐", "😊", "😄"]
    private let emojiLabels = [
        "😩": "awful",
        "😪": "bad", 
        "😐": "okay",
        "😊": "good",
        "😄": "great"
    ]
    
    // Slider değerine göre emoji seçimi
    private var currentEmoji: String {
        let index = min(Int(sliderValue.rounded()), emojis.count - 1)
        return emojis[index]
    }
    
    // Slider değerine göre emoji etiketi
    private var currentEmojiLabel: String {
        return emojiLabels[currentEmoji] ?? ""
    }
    
    var body: some View {
        VStack(spacing: 20) {
            // Minimal Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(L("mainScreen.sleepQuality.title", table: "MainScreen"))
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.appText)
                    
                    Text(String(format: L("mainScreen.sleepQuality.subtitle", table: "MainScreen"), formatTimeOnly(startTime), formatTimeOnly(endTime)))
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    HapticFeedbackManager.shared.trigger(.softCommit)
                    isPresented = false
                }) {
                    Image(systemName: "xmark")
                        .font(.title3)
                        .foregroundColor(Color("SecondaryTextColor"))
                }
            }
            
            // Rating Section - Kompakt design
            VStack(spacing: 16) {
                // Emoji
                Text(currentEmoji)
                    .font(.system(size: 60))
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentEmoji)
                
                // Yıldız Puanlama
                HStack(spacing: 6) {
                    ForEach(0..<5) { index in
                        let starValue = Double(index)
                        let isFilled = sliderValue >= starValue
                        let isHalfFilled = !isFilled && sliderValue >= starValue - 0.5
                        
                        Image(systemName: isFilled ? "star.fill" : (isHalfFilled ? "star.leadinghalf.filled" : "star"))
                            .foregroundColor(isFilled || isHalfFilled ? getSliderColor() : Color("SecondaryTextColor").opacity(0.3))
                            .font(.title3)
                    }
                }
                
                // Slider (0.5 increment'li)
                VStack(spacing: 6) {
                    Slider(value: $sliderValue, in: 0...4, step: 0.5)
                        .tint(getSliderColor())
                        .onChange(of: sliderValue) { newValue in
                            HapticFeedbackManager.shared.trigger(.selection)
                            emoji = currentEmoji
                        }
                    
                    // Slider Labels
                    HStack {
                        Text(L("sleepQuality.rating.bad", table: "SleepQuality"))
                            .font(.caption2)
                            .foregroundColor(Color("SecondaryTextColor"))
                        
                        Spacer()
                        
                        Text(L("sleepQuality.rating.excellent", table: "SleepQuality"))
                            .font(.caption2)
                            .foregroundColor(Color("SecondaryTextColor"))
                    }
                }
            }
            
            // Action Buttons - Kompakt
            HStack(spacing: 12) {
                Button(action: {
                    HapticFeedbackManager.shared.trigger(.softCommit)
                    AnalyticsManager.shared.logNudgeActionTapped(
                        type: "sleep_quality_prompt",
                        action: "defer"
                    )
                    viewModel.deferSleepQualityRating()
                    isPresented = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.spring(response: 0.3)) {
                            showSnackbar = true
                            notificationManager.addPendingRating(startTime: startTime, endTime: endTime)
                        }
                    }
                }) {
                    Text(L("sleepQuality.button.later", table: "SleepQuality"))
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("CardBackground"))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color("SecondaryTextColor").opacity(0.3), lineWidth: 1)
                                )
                        )
                        .foregroundColor(Color("TextColor"))
                }
                
                Button(action: {
                    HapticFeedbackManager.shared.trigger(.strongCommit)
                    AnalyticsManager.shared.logNudgeActionTapped(
                        type: "sleep_quality_prompt",
                        action: "save"
                    )
                    viewModel.markSleepQualityRatingAsCompleted()
                    isPresented = false
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        saveSleepQuality()
                    }
                }) {
                    Text(L("sleepQuality.button.save", table: "SleepQuality"))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color("AccentColor"))
                        )
                        .foregroundColor(.white)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color("CardBackground"))
                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
    
    private func saveSleepQuality() {
        guard let lastBlock = viewModel.lastSleepBlock else {
            print("❌ Son uyku bloğu bulunamadı")
            HapticFeedbackManager.shared.trigger(.error)
            return
        }
        
        let rating = Double(sliderValue + 1.0) // 1-5 arası puanlama (0.5 increment'li)
        print("💾 Uyku kalitesi kaydediliyor: \(rating)")

        Task { @MainActor in
            do {
                try SleepQualityPersistenceService.shared.saveRating(
                    rating: rating,
                    startTime: startTime,
                    endTime: endTime,
                    isCore: lastBlock.isCore,
                    blockId: lastBlock.id.uuidString,
                    source: "sheet_prompt"
                )
                print("✅ Uyku girdisi başarıyla kaydedildi - Rating: \(rating), Emoji: \(currentEmoji)")
                HapticFeedbackManager.shared.trigger(.success)
                notificationManager.removePendingRating(startTime: startTime, endTime: endTime)
            } catch {
                print("❌ SleepEntry kaydedilirken hata: \(error.localizedDescription)")
                HapticFeedbackManager.shared.trigger(.error)
            }
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
    
    private func formatTimeOnly(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.locale = Locale(identifier: "en_GB") // 24 saatlik format için zorla
        return formatter.string(from: date)
    }
}
