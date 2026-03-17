import SwiftUI

// MARK: - Stars View Component (Yarım yıldız desteği)
struct StarsView: View {
    let rating: Double
    let size: CGFloat
    let maxRating: Int
    let primaryColor: Color
    let emptyColor: Color
    
    init(
        rating: Double,
        size: CGFloat = 16,
        maxRating: Int = 5,
        primaryColor: Color = Color("AppSecondaryColor"),
        emptyColor: Color = Color.gray.opacity(0.3)
    ) {
        self.rating = rating
        self.size = size
        self.maxRating = maxRating
        self.primaryColor = primaryColor
        self.emptyColor = emptyColor
    }
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(1...maxRating, id: \.self) { star in
                let starDouble = Double(star)
                let fillPercentage = max(0, min(1, rating - starDouble + 1))
                
                if fillPercentage > 0.75 {
                    // Tam yıldız
                    Image(systemName: "star.fill")
                        .font(.system(size: size))
                        .foregroundColor(primaryColor)
                } else if fillPercentage > 0.25 {
                    // Yarım yıldız
                    ZStack {
                        Image(systemName: "star")
                            .font(.system(size: size))
                            .foregroundColor(emptyColor)
                        
                        Image(systemName: "star.lefthalf.fill")
                            .font(.system(size: size))
                            .foregroundColor(primaryColor)
                    }
                } else {
                    // Boş yıldız
                    Image(systemName: "star")
                        .font(.system(size: size))
                        .foregroundColor(emptyColor)
                }
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        StarsView(rating: 1.5)
        StarsView(rating: 2.7)
        StarsView(rating: 3.3)
        StarsView(rating: 4.8)
        StarsView(rating: 5.0)
    }
    .padding()
} 
