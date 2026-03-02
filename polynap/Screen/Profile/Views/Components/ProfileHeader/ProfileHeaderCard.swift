import SwiftUI

// MARK: - Profile Header Card
struct ProfileHeaderCard: View {
    @Binding var showLoginSheet: Bool
    @Binding var showLogoutSheet: Bool
    @Binding var navigateToSettings: Bool
    @ObservedObject var authManager: AuthManager
    @EnvironmentObject private var revenueCatManager: RevenueCatManager
    @State private var showImagePicker = false
    @State private var showActionSheet = false
    
    private func hasDisplayName() -> Bool {
        guard let user = authManager.currentUser else { return false }
        return !user.displayName.isEmpty
    }
    
    private func getUserInitials() -> String {
        guard let user = authManager.currentUser, !user.displayName.isEmpty else {
            return "U"
        }
        let names = user.displayName.split(separator: " ")
        if names.count >= 2 {
            return String(names[0].prefix(1)) + String(names[1].prefix(1))
        } else {
            return String(user.displayName.prefix(1))
        }
    }
    
    // Avatar ve Kamera İkonu Bölümü
    @ViewBuilder
    private func avatarSection() -> some View {
        ZStack(alignment: .bottomTrailing) {
            Button(action: {
                showActionSheet = true
            }) {
                Group {
                    if let user = authManager.currentUser, let imageData = user.profileImageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 88, height: 88)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.appPrimary.opacity(0.8), lineWidth: 3)
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 3)
                    } else if let user = authManager.currentUser, !user.displayName.isEmpty {
                        Text(getUserInitials().uppercased())
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.appTextOnPrimary)
                            .frame(width: 88, height: 88)
                            .background(
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.appPrimary, Color.appAccent]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.appTextOnPrimary.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 3)
                    } else {
                        Text("U")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.appTextOnPrimary)
                            .frame(width: 88, height: 88)
                            .background(
                                Circle()
                                    .fill(LinearGradient(
                                        gradient: Gradient(colors: [Color.appPrimary, Color.appAccent]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                            )
                            .overlay(
                                Circle()
                                    .stroke(Color.appTextOnPrimary.opacity(0.2), lineWidth: 1)
                            )
                            .shadow(color: Color.black.opacity(0.15), radius: 5, x: 0, y: 3)
                    }
                }
            }
            .buttonStyle(.plain)
            
            // Kamera ikonu overlay
            Button(action: {
                showActionSheet = true
            }) {
                Image(systemName: "camera.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.appAccent)
                    .background(Circle().fill(Color.appBackground).scaleEffect(1.2))
                    .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .offset(x: 4, y: 4)
        }
        .padding(.leading, PSSpacing.xs)
    }

    // Kullanıcı Bilgileri ve Düzenleme Butonu Bölümü
    @ViewBuilder
    private func userInfoSection() -> some View {
        VStack(alignment: .leading, spacing: PSSpacing.xs) {
            if let user = authManager.currentUser {
                HStack(alignment: .firstTextBaseline, spacing: PSSpacing.sm) { // İsim ve Düzenle ikonu için
                    let displayName = user.displayName.isEmpty ? L("profile.user.localAccount", table: "Profile") : user.displayName
                    Text(displayName)
                        .font(dynamicDisplayNameFont(forName: displayName))
                        .foregroundColor(.appText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7) // Daha fazla küçülmeye izin ver
                    
                    Button(action: { // Düzenleme Butonu
                        showLoginSheet = true
                    }) {
                        Image(systemName: "pencil.circle.fill")
                            .font(.title2) // Ayarlar ikonuyla benzer büyüklükte
                            .foregroundColor(Color.appAccent)
                    }
                }
                
                // Only show badge for premium users
                if revenueCatManager.userState == .premium {
                    HStack(spacing: PSSpacing.xs) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.appAccent)
                        Text(L("profile.premium.status.active", table: "Profile"))
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(.appAccent)
                    }
                    .padding(.vertical, PSSpacing.xs)
                    .padding(.horizontal, PSSpacing.sm)
                    .background(Capsule().fill(Color.appAccent.opacity(0.15)))
                }
            }
        }
    }
    
    // Ayarlar Butonu Bölümü
    @ViewBuilder
    private func settingsButtonSection() -> some View {
        Button(action: {
            navigateToSettings = true
        }) {
            Image(systemName: "gearshape.fill")
                .font(.title2)
                .foregroundColor(.appTextSecondary)
        }
        .padding(PSSpacing.sm)
        .background(Color.appTextSecondary.opacity(0.1))
        .clipShape(Circle())
    }
    
    // Kullanıcı adı için dinamik font boyutu hesaplayan fonksiyon
    private func dynamicDisplayNameFont(forName name: String) -> Font {
        let length = name.count
        if length <= 12 {
            return PSTypography.title1
        } else if length <= 18 {
            return .system(size: 26, weight: .bold)
        } else if length <= 25 {
            return .system(size: 20, weight: .bold)
        } else {
            return .system(size: 18, weight: .bold)
        }
    }
    
    var body: some View {
        VStack(spacing: PSSpacing.lg) {
            // Profile Avatar & Info
            HStack(alignment: .center, spacing: PSSpacing.lg) { // Ana HStack için genel boşluk
                avatarSection()
                userInfoSection() // İsim, düzenle ikonu ve hesap tipini içerir
                Spacer() // Butonları sağa iter
                
                settingsButtonSection()
            }
            .padding(.horizontal, PSSpacing.lg)
            .padding(.vertical, PSSpacing.md)
            
        }
        .background(Color.appCardBackground)
        .cornerRadius(PSCornerRadius.extraLarge)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 5)
        .confirmationDialog(L("profile.avatar.options.title", table: "Profile"), isPresented: $showActionSheet) {
            Button(L("profile.avatar.options.selectPhoto", table: "Profile")) {
                showImagePicker = true
            }
            
            if authManager.currentUser?.profileImageData != nil {
                Button(L("profile.avatar.options.removePhoto", table: "Profile"), role: .destructive) {
                    authManager.updateProfileImage(nil)
                }
            }
            
            Button(L("profile.avatar.options.editProfile", table: "Profile")) {
                showLoginSheet = true
            }
            
            Button(L("profile.avatar.options.cancel", table: "Profile"), role: .cancel) { }
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker { image in
                if let image = image,
                   let imageData = image.jpegData(compressionQuality: 0.8) {
                    authManager.updateProfileImage(imageData)
                }
            }
        }
    }
} 
