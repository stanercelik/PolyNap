import SwiftUI

struct NapEnvironmentInfoScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Spacer()
                .frame(height: OBSpacing.xxxl)
            
            AutoScrollView {
                VStack(alignment: .leading, spacing: OBSpacing.xl) {
                    FadeInText("merak etme.", font: OBFont.title, delay: 0.5)
                    
                    VStack(alignment: .leading, spacing: OBSpacing.md) {
                        FadeInText("\"ya ofiste, ya arabada,ya da sadece sandalyem varsa?\"", font: OBFont.body, color: OBColors.textSecondary, delay: 2.0)
                        Spacer()
                            .frame(height: OBSpacing.md)
                        
                        FadeInText("10–20 dakikalık kısa nap'ler bile fark yaratıyor.", delay: 5)
                        
                        FadeInText("tuvalet kabini (ne kadar tavsiye etmesem de), arabanın içi, kanepenin bir köşesi — hepsi sayılır.", delay: 7.5)
                        
                        FadeInText("planı imkansıza göre değil,gerçeğe göre yapacağız.", delay: 9.5)
                    }
                }
                .padding(.horizontal, OBSpacing.lg)
                .padding(.top, OBSpacing.xl)
            }
            
            Spacer()
            
            FadeIn(delay: 11) {
                OBButton("anladım →") { viewModel.goToNext() }
            }
            .padding(.horizontal, OBSpacing.lg)
            .padding(.bottom, OBSpacing.xl)
        }
    }
}

#Preview {
    NapEnvironmentInfoScreen(viewModel: NewOnboardingViewModel())
}
