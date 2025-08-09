import SwiftUI

/// Enhanced toggle with standardized styling
struct EnhancedToggle: View {
    let title: String
    @Binding var isOn: Bool
    var onChange: ((Bool) -> Void)?
    
    var body: some View {
        Toggle(isOn: $isOn) {
            Text(title)
                .font(UITheme.Typography.bodyMedium)
                .foregroundColor(UITheme.Colors.textPrimary)
        }
        .toggleStyle(SwitchToggleStyle(tint: UITheme.Colors.primary))
        .onChange(of: isOn) { _, newValue in
            onChange?(newValue)
        }
    }
}

/// Reusable link component for about section
struct AboutLink: View {
    let title: String
    let url: String
    
    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack {
                Text(title)
                    .font(UITheme.Typography.bodyMedium)
                    .foregroundColor(UITheme.Colors.primary)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 14))
                    .foregroundColor(UITheme.Colors.textSecondary)
            }
        }
    }
}

/// Share app button component
struct ShareAppButton: View {
    let title: String
    let appStoreId: String
    
    @EnvironmentObject private var ratingService: RatingService
    
    var body: some View {
        Button(action: shareApp) {
            HStack {
                Text(title)
                    .font(UITheme.Typography.bodyMedium)
                    .foregroundColor(UITheme.Colors.primary)
                
                Spacer()
                
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 14))
                    .foregroundColor(UITheme.Colors.textSecondary)
            }
        }
    }
    
    private func shareApp() {
        let appStoreURL = "https://apps.apple.com/app/id\(appStoreId)"
        let shareMessage = R.string.localizable.shareApp()
        
        let activityViewController = UIActivityViewController(
            activityItems: [shareMessage, URL(string: appStoreURL)!],
            applicationActivities: nil
        )
        
        // Set completion handler to track sharing engagement
        activityViewController.completionWithItemsHandler = { (activityType, completed, returnedItems, error) in
            if completed && error == nil {
                // User successfully shared the app - record high-value engagement event
                Task { @MainActor in
                    await ratingService.handleStoryShared()
                }
            }
        }
        
        // Get the current window and present the share sheet
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootViewController = window.rootViewController {
            
            // For iPad, configure the popover presentation
            if let popover = activityViewController.popoverPresentationController {
                popover.sourceView = window
                popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootViewController.present(activityViewController, animated: true)
        }
    }
}

/// Counter stepper component
struct CounterStepper: View {
    let title: String
    @Binding var value: Int
    let range: ClosedRange<Int>
    var onChange: ((Int) -> Void)?
    
    var body: some View {
        HStack {
            Text(title)
                .font(UITheme.Typography.bodyMedium)
                .foregroundColor(UITheme.Colors.textPrimary)
            
            Spacer()
            
            HStack(spacing: UITheme.Spacing.sm) {
                Button(action: {
                    if value > range.lowerBound {
                        value -= 1
                        onChange?(value)
                    }
                }) {
                    Image(systemName: "minus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(UITheme.Colors.primary)
                        .frame(width: 28, height: 28)
                        .background(UITheme.Colors.surfaceSecondary)
                        .cornerRadius(UITheme.Layout.cornerRadiusSmall)
                }
                
                Text("\(value)")
                    .font(UITheme.Typography.bodyMedium)
                    .foregroundColor(UITheme.Colors.textPrimary)
                    .frame(minWidth: 24, alignment: .center)
                
                Button(action: {
                    if value < range.upperBound {
                        value += 1
                        onChange?(value)
                    }
                }) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(UITheme.Colors.primary)
                        .frame(width: 28, height: 28)
                        .background(UITheme.Colors.surfaceSecondary)
                        .cornerRadius(UITheme.Layout.cornerRadiusSmall)
                }
            }
        }
    }
}