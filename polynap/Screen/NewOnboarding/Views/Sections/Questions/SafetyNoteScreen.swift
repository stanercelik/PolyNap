import SwiftUI

struct SafetyNoteScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: -32) {
            HStack {
                FadeIn(delay: 0.3) {
                    NimmyImage(.tired, size: 180)
                    
                }
                Spacer()
            }
            .padding(.horizontal, OBSpacing.lg)
            .padding(.top, OBSpacing.md)
            
            AutoScrollView {
                VStack(alignment: .leading, spacing: OBSpacing.xxl) {
                    FadeInText("küçük ama önemli bir not:", font: OBFont.title, delay: 0.5)
                    
                    VStack(alignment: .leading, spacing: OBSpacing.lg) {
                        FadeInText("polifazik uyku bazı durumlarda doktor gözetiminde denenmelidir.", delay: 2.0)
                        
                        FadeInText("aktif bir sağlık durumun varsa başlamadan önce bir profesyonele danışmanı öneririm.", delay: 3.5)
                        
                        FadeInText("adaptasyon sürecinde (özellikle ilk 3–5 gün) araç kullanmana dikkat et. uyku basabilir.", delay: 5.0)
                    }
                }
                .padding(.horizontal, OBSpacing.lg)
                .padding(.top, OBSpacing.xl)
            }
            
            Spacer()
            
            FadeIn(delay: 6.5) {
                OBButton("anladım, devam et →") { viewModel.goToNext() }
            }
            .padding(.horizontal, OBSpacing.lg)
            .padding(.bottom, OBSpacing.xl)
        }
    }
}

#Preview {
    SafetyNoteScreen(viewModel: NewOnboardingViewModel())
}
