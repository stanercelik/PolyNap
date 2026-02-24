import SwiftUI
import SwiftData

struct SleepScheduleDescriptionCard: View {
    let schedule: SleepScheduleModel
    let isRecommended: Bool
    @Binding var selectedSchedule: SleepScheduleModel
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        Button(action: {
            withAnimation {
                selectedSchedule = schedule
                let store = SleepScheduleStore(scheduleId: schedule.id)
                modelContext.insert(store)
                do {
                    try modelContext.save()
                } catch {
                    print("Error saving schedule: \(error)")
                }
            }
        }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(schedule.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(Color.appText)
                    Spacer()
                    if isRecommended {
                        RecommendedBadge()
                    }
                }
                HStack(spacing: 8) {
                    let currentLang = LanguageManager.shared.currentLanguage
                    let localizedDesc = schedule.description.localized(for: currentLang)
                    
                    Text(localizedDesc)
                        .font(.body)
                        .foregroundColor(Color.appTextSecondary)
                        .onAppear {
                            print("🔍 SleepScheduleDescriptionCard - Schedule ID: '\(schedule.id)', Current Language: '\(currentLang)'")
                            print("🔍 SleepScheduleDescriptionCard - Final description: '\(localizedDesc.prefix(100))...'")
                        }
                    Spacer()
                }
                ScheduleDetails(schedule: schedule)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(cardBackgroundColor)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: schedule.id == selectedSchedule.id ? 2 : 0)
            )
        }
    }
    
    private var cardBackgroundColor: Color {
        schedule.id == selectedSchedule.id ? Color.appCardBackground : Color.appCardBackground.opacity(0.5)
    }
    
    private var borderColor: Color {
        schedule.id == selectedSchedule.id ? Color.appPrimary : Color.clear
    }
}

struct RecommendedBadge: View {
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "star.fill")
                .font(.caption)
            Text(String(localized: "Recommended"))
                .font(.caption)
                .fontWeight(.medium)
        }
        .foregroundColor(.white)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.appPrimary)
        )
    }
}

struct ScheduleDetails: View {
    let schedule: SleepScheduleModel
    var body: some View {
        VStack(spacing: 12) {
            ScheduleInfoRow(
                icon: "bed.double.fill",
                title: NSLocalizedString("sleepSchedule.totalSleep", tableName: "Onboarding", comment: ""),
                value: String(format: "%.1f h", schedule.totalSleepHours)
            )
            if schedule.coreSleepHours > 0 {
                ScheduleInfoRow(
                    icon: "moon.fill",
                    title: NSLocalizedString("sleepSchedule.core", tableName: "Onboarding", comment: ""),
                    value: String(format: "%.1f h", schedule.coreSleepHours)
                )
            }
            ScheduleInfoRow(
                icon: "powersleep",
                title: NSLocalizedString("sleepSchedule.naps", tableName: "Onboarding", comment: ""),
                value: schedule.napCount > 0
                    ? "\(schedule.napCount) (\(schedule.napDurationSummary))"
                    : "0"
            )
            ScheduleInfoRow(
                icon: "gauge.medium",
                title: NSLocalizedString("sleepSchedule.difficulty", tableName: "Onboarding", comment: ""),
                value: schedule.difficulty.localizedDescription
            )
        }
    }
}

struct ScheduleInfoRow: View {
    let icon: String, title: String, value: String
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Color.appAccent)
                .frame(width: 24)
            Text(title)
                .font(.subheadline)
                .foregroundColor(Color.appText)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundColor(Color.appTextSecondary)
        }
    }
}
