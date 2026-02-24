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
                FadeInText("önce şunu soralım", font: OBFont.caption, color: OBColors.textMuted, delay: 0.5)
                
                FadeInText("sana nasıl seslenelim?", font: OBFont.largeTitle, delay: 1.5)
                
                FadeIn(delay: 2.5) {
                    VStack(alignment: .leading, spacing: OBSpacing.sm) {
                        TextField("adını yaz", text: $viewModel.userName)
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
                        
                        Text("istersen boş geç, \"arkadaş\" derim")
                            .font(OBFont.small)
                            .foregroundColor(OBColors.textMuted)
                    }
                }
            }
            .padding(.horizontal, OBSpacing.lg)
            .padding(.top, OBSpacing.xl)
            
            Spacer()
            
            FadeIn(delay: 3.0) {
                OBButton("devam") { viewModel.goToNext() }
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
