import SwiftUI

/// A reusable card component for settings sections
struct SettingsCard<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: UITheme.Spacing.sm) {
            // Header
            HStack {
                Label {
                    Text(title)
                        .font(UITheme.Typography.headingMedium)
                        .foregroundColor(UITheme.Colors.textPrimary)
                } icon: {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .foregroundColor(UITheme.Colors.primary)
                }
                
                Spacer()
            }
            
            Divider()
                .padding(.vertical, UITheme.Spacing.xxs)
            
            // Content
            content
        }
        .padding(UITheme.Spacing.lg)
        .background(UITheme.Colors.surfacePrimary)
        .cornerRadius(UITheme.Layout.cornerRadiusLarge)
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
    }
}