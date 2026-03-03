import SwiftUI

// MARK: - Çıkış Sheet Görünümü
struct LogoutSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authManager: AuthManager
    
    var body: some View {
        return VStack(spacing: PSSpacing.xl) {
            // Başlık
            Text(L("profile.logout.title", table: "Profile"))
                .font(PSTypography.headline)
                .foregroundColor(.appText)
                .padding(.top, PSSpacing.xl)
            
            // Kullanıcı email bilgisi
            if let user = authManager.currentUser {
                Text(user.email)
                    .font(PSTypography.subheadline)
                    .foregroundColor(.appTextSecondary)
            }
            
            // Çıkış butonu
            PSPrimaryButton(L("profile.login.signout", table: "Profile"), destructive: true, customBackgroundColor: Color.red.opacity(0.8)) {
                Task {
                    await authManager.signOut()
                    dismiss()
                }
            }
            .padding(.horizontal, PSSpacing.xl)
            
            Spacer()
        }
    }
}

// MARK: - Giriş Sheet Görünümü
struct LoginSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var authManager: AuthManager
    var onSuccessfulLogin: () -> Void
    
    @State private var displayName: String = ""
    private let maxDisplayNameLength = 25
    
    var body: some View {
        return VStack(spacing: PSSpacing.xl) {
            // Başlık
            Text(L("profile.edit.title", table: "Profile"))
                .font(.system(.headline, design: .rounded, weight: .semibold))
                .foregroundColor(.appText)
                .padding(.top, PSSpacing.xl)
            
            // Açıklama
            Text(L("profile.edit.description", table: "Profile"))
                .font(.system(.subheadline, design: .rounded))
                .multilineTextAlignment(.center)
                .foregroundColor(.appTextSecondary)
                .padding(.horizontal, PSSpacing.xl)
            
            // Kullanıcı adı düzenleme formu
            VStack(spacing: PSSpacing.lg) {
                // İsim girişi
                TextField(
                    L("profile.edit.name.placeholder", table: "Profile"),
                    text: $displayName
                )
                .font(.system(.body, design: .rounded))
                .padding(PSSpacing.md)
                .background(Color.appCardBackground)
                .cornerRadius(PSCornerRadius.medium)
                .overlay(
                    RoundedRectangle(cornerRadius: PSCornerRadius.medium)
                        .stroke(Color.appBorder, lineWidth: 1)
                )
                .onChange(of: displayName) { oldValue, newValue in
                    if newValue.count > maxDisplayNameLength {
                        displayName = String(newValue.prefix(maxDisplayNameLength))
                    }
                }
                
                // Kaydet butonu
                PSPrimaryButton(L("profile.edit.save", table: "Profile")) {
                    if !displayName.isEmpty {
                        authManager.updateDisplayName(displayName)
                        dismiss()
                        onSuccessfulLogin()
                    }
                }
                .disabled(displayName.isEmpty || authManager.isLoading)
            }
            .padding(.horizontal, PSSpacing.xl)
            
            // Hata mesajı
            if let error = authManager.authError {
                Text(error)
                    .font(PSTypography.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, PSSpacing.xl)
            }
            
            // Yükleniyor göstergesi
            if authManager.isLoading {
                ProgressView()
                    .padding(.top, PSSpacing.sm)
            }
            
            Spacer()
        }
        .onAppear {
            // Mevcut kullanıcı adını yükle
            if let currentUser = authManager.currentUser {
                displayName = currentUser.displayName
            }
        }
    }
} 