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