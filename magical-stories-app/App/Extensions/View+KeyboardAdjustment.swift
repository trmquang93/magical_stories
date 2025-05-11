import Combine
import SwiftUI
import UIKit

// Keep track of the active focus field
class KeyboardManager: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    @Published var isVisible = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        let keyboardWillShow = NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillShowNotification
        )
        .map { notification -> CGFloat in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
                as? CGRect
            {
                return keyboardFrame.height
            }
            return 0
        }

        let keyboardWillHide = NotificationCenter.default.publisher(
            for: UIResponder.keyboardWillHideNotification
        )
        .map { _ -> CGFloat in 0 }

        Publishers.Merge(keyboardWillShow, keyboardWillHide)
            .sink { [weak self] height in
                self?.isVisible = height > 0
                self?.keyboardHeight = height
            }
            .store(in: &cancellables)
    }
}

// ScrollView modifier for keyboard adjustment
struct KeyboardAwareModifier: ViewModifier {
    @StateObject private var keyboardManager = KeyboardManager()

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboardManager.keyboardHeight)
            .animation(.easeOut(duration: 0.16), value: keyboardManager.keyboardHeight)
            .environmentObject(keyboardManager)
    }
}

// View extension for keyboard awareness
extension View {
    func keyboardAware() -> some View {
        modifier(KeyboardAwareModifier())
    }

    func adaptToKeyboard() -> some View {
        self
            .keyboardAware()
            .dismissKeyboardOnTap()
            .toolbar {
                KeyboardToolbar()
            }
    }
}
