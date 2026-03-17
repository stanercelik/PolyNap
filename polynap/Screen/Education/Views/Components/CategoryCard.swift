import SwiftUI

struct CategoryCard: View {
    let category: EducationCategory
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: PSSpacing.sm) {
                Image(systemName: category.icon)
                    .font(.system(size: PSIconSize.large * 0.6, weight: .medium))
                    .opacity(0.9)
                Spacer(minLength: 0)
                Text(category.title)
                    .font(PSTypography.headline)
                    .multilineTextAlignment(.leading)
            }
            .foregroundColor(.white)
            .padding(PSSpacing.lg)
            .frame(height: 120)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: PSCornerRadius.large)
                    .fill(category.color)
            )
            .shadow(color: category.color.opacity(0.35), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
#Preview(traits: .sizeThatFitsLayout) {
    CategoryCard(category: .basics) {}
        .padding()
}
