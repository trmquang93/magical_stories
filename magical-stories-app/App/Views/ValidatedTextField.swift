import SwiftUI

struct ValidatedTextField: View {
    @Binding var text: String
    var label: String
    var validation: (String) -> Bool
    var errorMessage: String
    var labelColor: Color = .primary
    var showValidationImageWhenValid: Bool = true
    var onSubmit: (() -> Void)? = nil

    @State private var isValid: Bool = true
    @State private var isFocused: Bool = false
    @FocusState private var fieldIsFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(labelColor)
                .padding(.horizontal, 4)

            HStack {
                TextField(label, text: $text)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.systemBackground))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(borderColor, lineWidth: 1.5)
                            )
                    )
                    .onChange(of: text) { newValue in
                        isValid = validation(newValue)
                    }
                    .focused($fieldIsFocused)
                    .onSubmit {
                        onSubmit?()
                    }
                    .submitLabel(.next)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("\(label)TextField")
                    .onAppear {
                        // Initial validation
                        isValid = validation(text)
                    }

                // Validation indicator
                if !text.isEmpty && (showValidationImageWhenValid || !isValid) {
                    validationImage
                        .padding(.trailing, 8)
                }

                // Clear button
                if !text.isEmpty && fieldIsFocused {
                    Button(action: {
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                            .font(.system(size: 18))
                    }
                    .padding(.trailing, 8)
                    .transition(.opacity)
                    .contentShape(Rectangle())
                    .buttonStyle(BorderlessButtonStyle())
                    .accessibilityLabel("Clear \(label) text")
                }
            }

            // Error message (only shown when invalid and not empty)
            if !isValid && !text.isEmpty {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 4)
                    .transition(.opacity)
                    .accessibilityIdentifier("validationError")
            }
        }
        .onChange(of: fieldIsFocused) { newValue in
            isFocused = newValue
        }
    }

    // Computed properties for visual styling
    private var borderColor: Color {
        if fieldIsFocused {
            return Color(hex: "#7B61FF")  // Accent color when focused
        } else if text.isEmpty {
            return Color(.systemGray4)
        } else if isValid {
            return .green
        } else {
            return .red
        }
    }

    private var validationImage: some View {
        Image(systemName: isValid ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
            .foregroundColor(isValid ? .green : .red)
            .font(.system(size: 20))
            .symbolEffect(.pulse, options: .nonRepeating, value: text)
            .accessibilityLabel(isValid ? "Valid" : "Invalid")
    }
}

#Preview {
    VStack(spacing: 20) {
        ValidatedTextField(
            text: .constant(""),
            label: "Username",
            validation: { !$0.isEmpty },
            errorMessage: "Username is required"
        )

        ValidatedTextField(
            text: .constant("john"),
            label: "Email",
            validation: { $0.contains("@") },
            errorMessage: "Please enter a valid email address"
        )

        ValidatedTextField(
            text: .constant("john@example.com"),
            label: "Email (Valid)",
            validation: { $0.contains("@") },
            errorMessage: "Please enter a valid email address"
        )
    }
    .padding()
}
