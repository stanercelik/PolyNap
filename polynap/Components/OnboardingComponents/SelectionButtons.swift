import SwiftUI

struct SelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(isSelected ? Color("TextOnPrimaryColor") : Color("TextColor"))
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.8)
                    .lineLimit(2)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(Color("TextColor"))
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color("AppPrimaryColor") : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("AppPrimaryColor"), lineWidth: isSelected ? 0 : 2)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? NSLocalizedString("accessibility.selected", tableName: "Onboarding", comment: "") : NSLocalizedString("accessibility.notSelected", tableName: "Onboarding", comment: ""))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct MultiSelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Text(title)
                    .font(.body)
                    .foregroundStyle(isSelected ? Color("TextOnPrimaryColor") : Color("TextColor"))
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.8)
                    .lineLimit(2)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundStyle(Color("TextColor"))
                    .symbolRenderingMode(.hierarchical)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color("AppPrimaryColor") : .clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color("AppPrimaryColor"), lineWidth: isSelected ? 0 : 2)
                    )
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityValue(isSelected ? NSLocalizedString("accessibility.selected", tableName: "Onboarding", comment: "") : NSLocalizedString("accessibility.notSelected", tableName: "Onboarding", comment: ""))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    VStack(spacing: 16) {
        SelectionButton(
            title: "Regular Selection",
            isSelected: true,
            action: {}
        )
        
        SelectionButton(
            title: "Unselected Option with a very long text that might need multiple lines",
            isSelected: false,
            action: {}
        )
        
        MultiSelectionButton(
            title: "Multi Selection",
            isSelected: true,
            action: {}
        )
        
        MultiSelectionButton(
            title: "Unselected Multi Option",
            isSelected: false,
            action: {}
        )
    }
    .padding()
    .background(Color("BackgroundColor"))
}
