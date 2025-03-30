import SwiftUI

// MARK: - MagicalCard
struct MagicalCard<Content: View>: View {
    let content: Content
    var padding: EdgeInsets = EdgeInsets(
        top: Theme.Spacing.md,
        leading: Theme.Spacing.md,
        bottom: Theme.Spacing.md,
        trailing: Theme.Spacing.md
    )
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(Theme.Colors.surfacePrimary)
            .cornerRadius(Theme.Layout.cornerRadiusMedium)
            .shadow(
                color: Color.black.opacity(0.05),
                radius: 8,
                x: 0,
                y: 2
            )
    }
}

// MARK: - MagicalSection
struct MagicalSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            Text(title)
                .font(Theme.Typography.headingMedium)
                .foregroundColor(Theme.Colors.textPrimary)
            
            content
        }
    }
}

// MARK: - MagicalDivider
struct MagicalDivider: View {
    var body: some View {
        Rectangle()
            .fill(Theme.Colors.surfaceSecondary)
            .frame(height: 1)
    }
}

// MARK: - MagicalLoadingView
struct MagicalLoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(message)
                .font(Theme.Typography.bodyMedium)
                .foregroundColor(Theme.Colors.textSecondary)
        }
    }
}

// MARK: - MagicalErrorView
struct MagicalErrorView: View {
    let message: String
    let retryAction: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.error)
            
            Text(message)
                .font(Theme.Typography.bodyLarge)
                .foregroundColor(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
            
            PrimaryButton(title: "Try Again") {
                retryAction()
            }
            .frame(maxWidth: 200)
        }
        .padding()
    }
}

// MARK: - MagicalEmptyStateView
struct MagicalEmptyStateView: View {
    let title: String
    let message: String
    let buttonTitle: String
    let action: () -> Void
    
    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(Theme.Colors.primary)
            
            VStack(spacing: Theme.Spacing.xs) {
                Text(title)
                    .font(Theme.Typography.headingMedium)
                    .foregroundColor(Theme.Colors.textPrimary)
                
                Text(message)
                    .font(Theme.Typography.bodyMedium)
                    .foregroundColor(Theme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            PrimaryButton(title: buttonTitle, action: action)
                .frame(maxWidth: 200)
        }
        .padding()
    }
}

// MARK: - Preview
struct CommonComponents_Previews: PreviewProvider {
    static var previews: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.lg) {
                MagicalCard {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        Text("Card Title")
                            .font(Theme.Typography.headingMedium)
                        Text("This is a card with some content inside it.")
                            .font(Theme.Typography.bodyMedium)
                    }
                }
                
                MagicalSection("Section Title") {
                    Text("This is a section with content.")
                        .font(Theme.Typography.bodyMedium)
                }
                
                MagicalDivider()
                
                MagicalLoadingView(message: "Generating your story...")
                
                MagicalErrorView(
                    message: "Something went wrong. Please try again."
                ) {
                    print("Retry tapped")
                }
                
                MagicalEmptyStateView(
                    title: "No Stories Yet",
                    message: "Create your first magical story to get started!",
                    buttonTitle: "Create Story"
                ) {
                    print("Create story tapped")
                }
            }
            .padding()
        }
        .background(Theme.Colors.background)
    }
} 