import SwiftUI

struct QuestionScreenLayout<Content: View>: View {
    @ObservedObject var viewModel: NewOnboardingViewModel
    let nimmy: NimmyImage.NimmyVariant
    let topLabel: String?
    let question: String
    let microcopy: String?
    let content: () -> Content
    
    init(
        viewModel: NewOnboardingViewModel,
        nimmy: NimmyImage.NimmyVariant = .sleepingNormal,
        topLabel: String? = nil,
        question: String,
        microcopy: String? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.viewModel = viewModel
        self.nimmy = nimmy
        self.topLabel = topLabel
        self.question = question
        self.microcopy = microcopy
        self.content = content
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: OBSpacing.lg) {
                    NimmyQuestionHeader(
                        nimmy: nimmy,
                        topLabel: topLabel,
                        question: question,
                        microcopy: microcopy
                    )
                    
                    VStack(spacing: OBSpacing.sm) {
                        content()
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
                    .opacity(viewModel.canProceed ? 1.0 : 0.4)
                    .disabled(!viewModel.canProceed)
            }
            .background(Color.white)
        }
    }
}
