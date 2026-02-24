import SwiftUI

struct AgeRangeScreen: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    @State private var sliderValue: Double = 25
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: OBSpacing.lg) {
                    NimmyQuestionHeader(
                        nimmy: .sleepingNormal,
                        question: "kaç yaşındasın?",
                        microcopy: "adaptasyon hızı ve önerilen tempo yaşa göre değişiyor"
                    )
                    
                    AgeSlider(value: $sliderValue, range: 18...65, step: 1) { newValue in
                        let age = Int(newValue)
                        switch age {
                        case ..<18:
                            viewModel.ageRange = .under18
                        case 18...24:
                            viewModel.ageRange = .age18to24
                        case 25...34:
                            viewModel.ageRange = .age25to34
                        case 35...44:
                            viewModel.ageRange = .age35to44
                        case 45...54:
                            viewModel.ageRange = .age45to54
                        default:
                            viewModel.ageRange = .age55Plus
                        }
                    }
                }
                .padding(.horizontal, OBSpacing.lg)
                .padding(.top, OBSpacing.lg)
                .padding(.bottom, OBSpacing.xxl)
            }
            
            VStack(spacing: 0) {
                Divider().opacity(0.3)
                
                OBButton("devam") { viewModel.goToNext() }
                    .padding(.horizontal, OBSpacing.lg)
                    .padding(.vertical, OBSpacing.md)
            }
            .background(Color.white)
        }
        .onAppear {
            if viewModel.ageRange == nil {
                viewModel.ageRange = .age25to34
            }
        }
    }
}

#Preview {
    AgeRangeScreen(viewModel: NewOnboardingViewModel())
}
