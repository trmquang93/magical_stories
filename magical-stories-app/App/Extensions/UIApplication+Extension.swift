import SwiftUI
import UIKit

extension UIApplication {
    func dismissKeyboard() {
        sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

// SwiftUI extension for View to add keyboard dismissal
extension View {
    func dismissKeyboardOnTap() -> some View {
        modifier(DismissKeyboardOnTapModifier())
    }

    func dismissKeyboardOnDrag() -> some View {
        modifier(DismissKeyboardOnDragModifier())
    }
}

// Modifier for dismiss keyboard on tap outside text field
struct DismissKeyboardOnTapModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onTapGesture {
                UIApplication.shared.dismissKeyboard()
            }
    }
}

// Modifier for dismiss keyboard on drag (swipe)
struct DismissKeyboardOnDragModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .gesture(
                DragGesture(minimumDistance: 20)
                    .onChanged { _ in
                        UIApplication.shared.dismissKeyboard()
                    }
            )
    }
}

// Keyboard toolbar with done button
struct KeyboardToolbar: ToolbarContent {
    var onDone: (() -> Void)? = nil

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .keyboard) {
            Spacer()
            Button("Done") {
                UIApplication.shared.dismissKeyboard()
                onDone?()
            }
            .foregroundColor(Color(hex: "#7B61FF"))
            .font(.headline)
        }
    }
}
