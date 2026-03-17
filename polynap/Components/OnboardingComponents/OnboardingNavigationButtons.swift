import SwiftUI

struct OnboardingNavigationButtons: View {
    let canMoveNext: Bool
    let currentPage: Int
    let totalPages: Int
    let onNext: () -> Void
    let onBack: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            if currentPage > 0 {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onBack()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                        Text("onboarding.back", tableName: "Onboarding")
                            .font(.body.weight(.semibold))
                    }
                    .foregroundStyle(Color("AppPrimaryColor"))
                    .frame(minWidth: 44, minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(NSLocalizedString("accessibility.previousPage", tableName: "Onboarding", comment: ""))
            }
            
            Spacer()
        
        if currentPage < totalPages {
            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onNext()
            }) {
                HStack(spacing: 8) {
                    Text(currentPage == totalPages - 1 ? "onboarding.seeResults" : "onboarding.next", tableName: "Onboarding")
                        .font(.body.weight(.semibold))
                    
                    Image(systemName: "chevron.right")
                        .font(.body.weight(.semibold))
                }
                .padding(.horizontal, 16)
                .frame(minWidth: 44, minHeight: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(canMoveNext ? Color("AppPrimaryColor") : Color("AppPrimaryColor").opacity(0.5))
                )
                .foregroundColor(Color("TextOnPrimaryColor"))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(!canMoveNext)
            .accessibilityLabel(currentPage == totalPages - 1 ?
                                NSLocalizedString("accessibility.seeResults", tableName: "Onboarding", comment: "") :
                                    NSLocalizedString("accessibility.nextPage", tableName: "Onboarding", comment: ""))
            .accessibilityHint(canMoveNext ? "" : NSLocalizedString("accessibility.completeCurrentPage", tableName: "Onboarding", comment: ""))
        }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 8)
    .background(
        Rectangle()
            .fill(Color("BackgroundColor"))
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: -4)
    )
    }
}

#Preview {
    VStack(spacing: 32) {
        OnboardingNavigationButtons(
            canMoveNext: true,
            currentPage: 0,
            totalPages: 5,
            onNext: {},
            onBack: {}
        )
        
        OnboardingNavigationButtons(
            canMoveNext: true,
            currentPage: 2,
            totalPages: 5,
            onNext: {},
            onBack: {}
        )
        
        OnboardingNavigationButtons(
            canMoveNext: false,
            currentPage: 2,
            totalPages: 5,
            onNext: {},
            onBack: {}
        )
        
        OnboardingNavigationButtons(
            canMoveNext: true,
            currentPage: 4,
            totalPages: 5,
            onNext: {},
            onBack: {}
        )
    }
    .padding()
    .background(Color("BackgroundColor"))
}
