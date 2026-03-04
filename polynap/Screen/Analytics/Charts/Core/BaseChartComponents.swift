import SwiftUI
import Charts

// MARK: - Base Chart Components

// MARK: - Chart Header
struct ChartHeader: View {
    let title: String
    let subtitle: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.appText)
            
            Text(subtitle)
                .font(.system(size: 12))
                .foregroundColor(Color("SecondaryTextColor"))
        }
    }
}

// MARK: - Legend Item
struct LegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(color)
                .frame(width: 12, height: 12)
            
            Text(label)
                .font(.system(size: 12))
                .foregroundColor(.appText)
        }
    }
}

// MARK: - Heat Map Legend Item
struct HeatMapLegendItem: View {
    let color: Color
    let label: String
    
    var body: some View {
        HStack(spacing: PSSpacing.xs) {
            Rectangle()
                .fill(color.opacity(0.8))
                .frame(width: 12, height: 12)
                .cornerRadius(2)
            
            Text(label)
                .font(PSTypography.caption)
                .foregroundColor(.appText)
        }
    }
} 