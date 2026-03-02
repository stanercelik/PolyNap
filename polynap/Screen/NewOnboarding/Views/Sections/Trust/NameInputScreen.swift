import SwiftUI

struct NameInputScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    @FocusState private var isNameFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Spacer()
                FadeIn(delay: 0.3) {
                    NimmyImage(.meditation, size: 80)
                        .floating()
                }
            }
            .padding(.horizontal, OBSpacing.lg)
            .padding(.top, OBSpacing.md)
            
            VStack(alignment: .leading, spacing: OBSpacing.lg) {
                FadeInText(L("newOnboarding.nameInput.topLabel", table: "Onboarding"), font: OBFont.caption, color: OBColors.textMuted, delay: 0.5)
                
                FadeInText(L("newOnboarding.nameInput.title", table: "Onboarding"), font: OBFont.largeTitle, delay: 1.5)
                
                FadeIn(delay: 2.5) {
                    VStack(alignment: .leading, spacing: OBSpacing.sm) {
                        TextField(L("newOnboarding.nameInput.placeholder", table: "Onboarding"), text: $viewModel.userName)
                            .font(OBFont.body)
                            .foregroundColor(OBColors.darkNavy)
                            .padding(.horizontal, OBSpacing.md)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(OBColors.softGray)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(isNameFocused ? OBColors.accentBlue : Color.clear, lineWidth: 2)
                            )
                            .focused($isNameFocused)
                            .textInputAutocapitalization(.words)
                            .submitLabel(.done)
                            .onSubmit { isNameFocused = false }
                            .tint(OBColors.primaryColor)
                        
                        Text(L("newOnboarding.nameInput.hint", table: "Onboarding"))
                            .font(OBFont.small)
                            .foregroundColor(OBColors.textMuted)
                    }
                }
            }
            .padding(.horizontal, OBSpacing.lg)
            .padding(.top, OBSpacing.xl)
            
            Spacer()
            
            FadeIn(delay: 3.0) {
                OBButton(L("newOnboarding.common.continue", table: "Onboarding")) { viewModel.goToNext() }
            }
            .padding(.horizontal, OBSpacing.lg)
            .padding(.bottom, OBSpacing.xl)
        }
        .onTapGesture { isNameFocused = false }
    }
}

#Preview {
    NameInputScreen(viewModel: NewOnboardingViewModel())
}
