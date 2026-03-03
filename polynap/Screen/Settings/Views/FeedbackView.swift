import SwiftUI
import MessageUI

struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var languageManager: LanguageManager
    
    @State private var userName: String = ""
    @State private var subject: String = ""
    @State private var message: String = ""
    @State private var isShowingMailView = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var canSendMail = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: PSSpacing.lg) {
                // Name Field
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("feedback.name", table: "Profile").uppercased())
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.appTextSecondary)

                    TextField(L("feedback.name.placeholder", table: "Profile"), text: $userName)
                        .font(.system(.body, design: .rounded))
                        .padding(12)
                        .background(Color.appCardBackground)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
                        .submitLabel(.next)
                }

                // Subject Field
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("feedback.subject", table: "Profile").uppercased())
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.appTextSecondary)

                    TextField(L("feedback.subject.placeholder", table: "Profile"), text: $subject)
                        .font(.system(.body, design: .rounded))
                        .padding(12)
                        .background(Color.appCardBackground)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
                        .submitLabel(.next)
                }

                // Message Field
                VStack(alignment: .leading, spacing: 6) {
                    Text(L("feedback.message", table: "Profile").uppercased())
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.appTextSecondary)

                    ZStack(alignment: .topLeading) {
                        TextEditor(text: $message)
                            .font(.system(.body, design: .rounded))
                            .padding(8)
                            .frame(minHeight: 120)
                            .background(Color.clear)
                            .scrollContentBackground(.hidden)

                        if message.isEmpty {
                            Text(L("feedback.message.placeholder", table: "Profile"))
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.appTextSecondary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 16)
                                .allowsHitTesting(false)
                        }
                    }
                    .background(Color.appCardBackground)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.appBorder, lineWidth: 1))
                }

                // Footer note
                Text(L("feedback.info", table: "Profile"))
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)

                // Send Button
                Button(action: { sendFeedback() }) {
                    HStack {
                        Image(systemName: "paperplane.fill")
                            .font(.system(size: 15, weight: .medium))
                        Text(L("feedback.send", table: "Profile"))
                            .font(.system(.body, design: .rounded, weight: .semibold))
                    }
                    .foregroundColor(.appTextOnPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.appPrimary)
                    .cornerRadius(14)
                }
                .disabled(!isFormValid)
                .opacity(isFormValid ? 1.0 : 0.6)

                Spacer(minLength: PSSpacing.xl)
            }
            .padding(.horizontal, PSSpacing.lg)
            .padding(.top, PSSpacing.sm)
            .padding(.bottom, PSSpacing.xxl)
        }
        .background(Color.appBackground.ignoresSafeArea())
        .contentShape(Rectangle())
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
        .navigationTitle(L("feedback.title", table: "Profile"))
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            canSendMail = MFMailComposeViewController.canSendMail()
        }
        .alert(L("feedback.alert.title", table: "Profile"), isPresented: $showingAlert) {
            Button(L("general.ok", table: "Profile")) { }
        } message: {
            Text(alertMessage)
        }
        .sheet(isPresented: $isShowingMailView) {
            MailView(
                recipients: ["tanercelik2001@gmail.com"],
                subject: "In App Feedback - \(subject)",
                messageBody: createEmailBody(),
                isShowing: $isShowingMailView,
                onResult: { result in
                    handleMailResult(result)
                }
            )
        }
    }
    
    private var isFormValid: Bool {
        !userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func sendFeedback() {
        if canSendMail {
            isShowingMailView = true
        } else {
            // Mail app yoksa clipboard'a kopyala
            let feedbackText = createFeedbackText()
            UIPasteboard.general.string = feedbackText
            alertMessage = "Feedback has been copied to clipboard. You can manually send it to tanercelik2001@gmail.com"
            showingAlert = true
        }
    }
    
    private func createFeedbackText() -> String {
        return """
        Name: \(userName)
        Subject: \(subject)
        
        Message:
        \(message)
        
        ---
        Device Info:
        App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
        iOS Version: \(UIDevice.current.systemVersion)
        Device: \(UIDevice.current.model)
        Language: \(languageManager.currentLanguage)
        
        Please send this feedback to: tanercelik2001@gmail.com
        """
    }
    
    private func createEmailBody() -> String {
        let deviceInfo = """
        
        
        ---
        Device Info:
        App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
        iOS Version: \(UIDevice.current.systemVersion)
        Device: \(UIDevice.current.model)
        Language: \(languageManager.currentLanguage)
        
        User Message:
        \(message)
        """
        
        return deviceInfo
    }
    
    private func handleMailResult(_ result: Result<MFMailComposeResult, Error>) {
        switch result {
        case .success(let mailResult):
            switch mailResult {
            case .sent:
                alertMessage = L("feedback.alert.sent", table: "Profile")
                showingAlert = true
                // Clear form after successful send
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    userName = ""
                    subject = ""
                    message = ""
                }
            case .cancelled:
                break // User cancelled, no action needed
            case .failed:
                alertMessage = L("feedback.alert.failed", table: "Profile")
                showingAlert = true
            case .saved:
                alertMessage = L("feedback.alert.saved", table: "Profile")
                showingAlert = true
            @unknown default:
                break
            }
        case .failure(_):
            alertMessage = L("feedback.alert.failed", table: "Profile")
            showingAlert = true
        }
    }
}

// MARK: - Mail Compose View
struct MailView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let messageBody: String
    @Binding var isShowing: Bool
    let onResult: (Result<MFMailComposeResult, Error>) -> Void
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        var parent: MailView
        
        init(parent: MailView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            // Keyboard dismissal - delegate method zaten main thread'de çalışır
            controller.view.endEditing(true)
            
            // Tüm text view'ları güvenli bir şekilde dismiss et
            self.dismissAllTextViews(in: controller.view)
            
            // Result handling
            if let error = error {
                parent.onResult(.failure(error))
            } else {
                parent.onResult(.success(result))
            }
            parent.isShowing = false
        }
        
        // Helper method for recursive text view dismissal
        private func dismissAllTextViews(in view: UIView) {
            if let textView = view as? UITextView {
                textView.resignFirstResponder()
            }
            view.subviews.forEach { subview in
                dismissAllTextViews(in: subview)
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let mail = MFMailComposeViewController()
        
        // Delegate assignment (zaten main thread'deyiz)
        mail.mailComposeDelegate = context.coordinator
        
        // Mail content setup
        mail.setToRecipients(recipients)
        mail.setSubject(subject)
        mail.setMessageBody(messageBody, isHTML: false)
        
        // Presentation style - constraint sorunlarını önlemek için
        mail.modalPresentationStyle = .pageSheet
        if #available(iOS 15.0, *) {
            if let sheet = mail.sheetPresentationController {
                sheet.detents = [.large()]
                sheet.prefersGrabberVisible = false
            }
        }
        
        // Background ve appearance düzeltmeleri - view load olduktan sonra
        DispatchQueue.main.async {
            // Navigation bar düzeltmesi
            if let navigationBar = mail.navigationBar as UINavigationBar? {
                let appearance = UINavigationBarAppearance()
                appearance.configureWithOpaqueBackground()
                appearance.backgroundColor = UIColor.systemBackground
                navigationBar.standardAppearance = appearance
                navigationBar.scrollEdgeAppearance = appearance
            }
            
            // Background color
            mail.view.backgroundColor = UIColor.systemBackground
            
            // TextKit sorununu önlemek için - view hierarchy yüklendikten sonra
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let textView = self.findTextView(in: mail.view) {
                    textView.backgroundColor = UIColor.systemBackground
                }
            }
        }
        
        return mail
    }
    
    // TextKit sorunu için helper method
    private func findTextView(in view: UIView) -> UITextView? {
        if let textView = view as? UITextView {
            return textView
        }
        for subview in view.subviews {
            if let textView = findTextView(in: subview) {
                return textView
            }
        }
        return nil
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {
        
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FeedbackView()
        }
        .environmentObject(LanguageManager.shared)
    }
} 