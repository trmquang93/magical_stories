import SwiftUI

/// View for entering and validating access codes (promo codes)
struct AccessCodeEntryView: View {
    @EnvironmentObject private var entitlementManager: EntitlementManager
    @Environment(\.dismiss) private var dismiss
    @State private var codeInput = ""
    @State private var isValidating = false
    @State private var validationError: AccessCodeValidationError?
    @State private var showSuccessAlert = false
    @State private var validatedAccessCode: AccessCode?
    
    var body: some View {
        NavigationView {
            VStack(spacing: UITheme.Spacing.xl) {
                // Header
                VStack(spacing: UITheme.Spacing.md) {
                    Image(systemName: "key.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                    
                    Text(R.string.localizable.promoCodeEntryTitle())
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(R.string.localizable.promoCodeEntrySubtitle())
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, UITheme.Spacing.xl)
                
                // Input Section
                VStack(spacing: UITheme.Spacing.lg) {
                    VStack(alignment: .leading, spacing: UITheme.Spacing.sm) {
                        Text(R.string.localizable.promoCodeTitle())
                            .font(.headline)
                        
                        TextField(R.string.localizable.promoCodeEntryPlaceholder(), text: $codeInput)
                            .textFieldStyle(.roundedBorder)
                            .autocapitalization(.allCharacters)
                            .autocorrectionDisabled()
                            .font(.monospaced(.body)())
                            .onReceive(codeInput.publisher.collect()) { _ in
                                codeInput = AccessCodeInputHelpers.formatInput(codeInput)
                            }
                        
                        // Input validation feedback
                        if !codeInput.isEmpty {
                            let validationResult = AccessCodeInputHelpers.validateInputLength(codeInput)
                            if let message = validationResult.message {
                                Text(message)
                                    .font(.caption)
                                    .foregroundColor(validationResult.isValid ? .green : .orange)
                            }
                        }
                    }
                    
                    // Error display
                    if let error = validationError {
                        VStack(alignment: .leading, spacing: UITheme.Spacing.sm) {
                            Text(AccessCodeValidationUtilities.userFriendlyErrorMessage(for: error))
                                .font(.body)
                                .foregroundColor(.red)
                            
                            Text(AccessCodeValidationUtilities.recoverySuggestion(for: error))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    // Redeem Button
                    Button(action: validateCode) {
                        HStack {
                            if isValidating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                            Text(isValidating ? R.string.localizable.promoCodeButtonValidating() : R.string.localizable.promoCodeButtonRedeem())
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(canValidate ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!canValidate || isValidating)
                }
                .padding(.horizontal, UITheme.Spacing.lg)
                
                Spacer()
                
                // Help Section
                VStack(spacing: UITheme.Spacing.md) {
                    Text("Need help?")
                        .font(.headline)
                    
                    VStack(alignment: .leading, spacing: UITheme.Spacing.sm) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Promo codes are 12 characters long")
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Format: XX-XXXX-XXXX-XX")
                        }
                        
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            Text("Contact support if you need assistance")
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal, UITheme.Spacing.lg)
                .padding(.bottom, UITheme.Spacing.xl)
            }
            .navigationTitle("Promo Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .alert("Code Redeemed Successfully!", isPresented: $showSuccessAlert) {
            Button("OK") {
                dismiss()
            }
        } message: {
            if let accessCode = validatedAccessCode {
                Text("You now have access to: \(AccessCodeFeatureUtilities.createFeatureSummary(accessCode.grantedFeatures))")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var canValidate: Bool {
        let validationResult = AccessCodeInputHelpers.validateInputLength(codeInput)
        return validationResult.isValid && !isValidating
    }
    
    // MARK: - Methods
    
    private func validateCode() {
        guard !codeInput.isEmpty else { return }
        
        isValidating = true
        validationError = nil
        
        Task {
            do {
                let success = try await entitlementManager.validateAndStoreAccessCode(codeInput)
                
                await MainActor.run {
                    isValidating = false
                    
                    if success {
                        // Get the validated access code for display
                        let activeCodes = entitlementManager.getActiveAccessCodes()
                        validatedAccessCode = activeCodes.first { $0.accessCode.code == codeInput.replacingOccurrences(of: "-", with: "").uppercased() }?.accessCode
                        showSuccessAlert = true
                        codeInput = ""
                    }
                }
            } catch let error as AccessCodeValidationError {
                await MainActor.run {
                    isValidating = false
                    validationError = error
                }
            } catch {
                await MainActor.run {
                    isValidating = false
                    validationError = .unknown(error.localizedDescription)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    AccessCodeEntryView()
        .environmentObject(EntitlementManager())
}