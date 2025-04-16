# Design System: Magical Stories

## Overview
This document outlines the design system for the Magical Stories app, ensuring consistent UI/UX across all features.

## Colors

### Brand Colors
```swift
extension Color {
    static let magicalPrimary = Color("MagicalPrimary") // #7B61FF
    static let magicalSecondary = Color("MagicalSecondary") // #FFB443
    static let magicalAccent = Color("MagicalAccent") // #FF617B
}

// Theme Colors
struct ThemeColors {
    static let light = ColorTheme(
        background: .white,
        surface: Color(hex: "F9F9F9"),
        text: Color(hex: "1A1A1A"),
        softText: Color(hex: "6B6B6B")
    )
    
    static let dark = ColorTheme(
        background: Color(hex: "1A1A1A"),
        surface: Color(hex: "2C2C2C"),
        text: .white,
        softText: Color(hex: "B4B4B4")
    )
}

struct ColorTheme {
    let background: Color
    let surface: Color
    let text: Color
    let softText: Color
}
```

### Semantic Colors
```swift
extension Color {
    static let success = Color("Success") // #4CAF50
    static let warning = Color("Warning") // #FF9800
    static let error = Color("Error") // #F44336
    static let info = Color("Info") // #2196F3
}
```

## Typography

### Font Styles
```swift
extension Font {
    // Display
    static let displayLarge = Font.system(size: 34, weight: .bold)
    static let displayMedium = Font.system(size: 28, weight: .bold)
    static let displaySmall = Font.system(size: 24, weight: .bold)
    
    // Heading
    static let headingLarge = Font.system(size: 22, weight: .semibold)
    static let headingMedium = Font.system(size: 20, weight: .semibold)
    static let headingSmall = Font.system(size: 18, weight: .semibold)
    
    // Body
    static let bodyLarge = Font.system(size: 17)
    static let bodyMedium = Font.system(size: 15)
    static let bodySmall = Font.system(size: 13)
    
    // Special
    static let storyTitle = Font.custom("SFRounded", size: 24, relativeTo: .title)
    static let storyText = Font.custom("SFRounded", size: 17, relativeTo: .body)
}
```

### Text Styles
```swift
struct TextStyles {
    static func title(_ text: String) -> some View {
        Text(text)
            .font(.displayMedium)
            .foregroundColor(.primary)
    }
    
    static func heading(_ text: String) -> some View {
        Text(text)
            .font(.headingMedium)
            .foregroundColor(.primary)
    }
    
    static func body(_ text: String) -> some View {
        Text(text)
            .font(.bodyMedium)
            .foregroundColor(.primary)
    }
    
    static func caption(_ text: String) -> some View {
        Text(text)
            .font(.bodySmall)
            .foregroundColor(.secondary)
    }
}
```

## Layout

### Spacing
```swift
enum Spacing {
    static let xxxs: CGFloat = 2
    static let xxs: CGFloat = 4
    static let xs: CGFloat = 8
    static let sm: CGFloat = 12
    static let md: CGFloat = 16
    static let lg: CGFloat = 24
    static let xl: CGFloat = 32
    static let xxl: CGFloat = 40
    static let xxxl: CGFloat = 48
}
```

### Container Sizes
```swift
enum ContainerSize {
    static let maxWidth: CGFloat = 414 // iPhone Pro Max width
    static let contentPadding: CGFloat = 16
    static let cardPadding: CGFloat = 12
    static let modalPadding: CGFloat = 20
}
```

## Components

### Buttons

#### Primary Button
```swift
struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headingSmall)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.magicalPrimary)
                .cornerRadius(12)
        }
    }
}
```

#### Secondary Button
```swift
struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headingSmall)
                .foregroundColor(.magicalPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.md)
                .background(Color.magicalPrimary.opacity(0.1))
                .cornerRadius(12)
        }
    }
}
```

### Cards

#### Story Card
```swift
struct StoryCard: View {
    let story: Story
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text(story.title)
                .font(.storyTitle)
                .foregroundColor(.primary)
            
            Text(story.preview)
                .font(.bodyMedium)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            HStack {
                Image(systemName: "book.fill")
                Text("\(story.readCount) reads")
                    .font(.bodySmall)
            }
            .foregroundColor(.secondary)
        }
        .padding(Spacing.md)
        .background(ThemeColors.light.surface)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}
```

### Input Fields

#### Themed TextField
```swift
struct ThemedTextField: View {
    let label: String
    @Binding var text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            Text(label)
                .font(.bodySmall)
                .foregroundColor(.secondary)
            
            TextField("", text: $text)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .font(.bodyLarge)
        }
    }
}
```

### Navigation

#### Navigation Bar
```swift
struct ThemedNavigationBar: ViewModifier {
    func body(content: Content) -> some View {
        content
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    backButton
                }
            }
    }
    
    private var backButton: some View {
        Button(action: {}) {
            Image(systemName: "chevron.left")
                .foregroundColor(.primary)
        }
    }
}
```

## Animations

### Transition Constants
```swift
enum AnimationDuration {
    static let fast: Double = 0.2
    static let standard: Double = 0.3
    static let slow: Double = 0.5
}

enum AnimationCurve {
    static let standard = Animation.easeInOut
    static let springy = Animation.spring(
        response: 0.3,
        dampingFraction: 0.6,
        blendDuration: 0
    )
}
```

### Common Animations
```swift
extension Animation {
    static let magical = Animation.spring(
        response: 0.3,
        dampingFraction: 0.7,
        blendDuration: 0
    )
    
    static let pageTransition = Animation.easeInOut(
        duration: AnimationDuration.standard
    )
}
```

## Icons

### System Icons
```swift
enum SystemIcon {
    static let home = "house.fill"
    static let library = "books.vertical.fill"
    static let settings = "gear"
    static let read = "book.fill"
    static let favorite = "heart.fill"
    static let share = "square.and.arrow.up"
    static let achievement = "star.fill"
}
```

## Modifiers

### Card Modifier
```swift
struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Spacing.md)
            .background(ThemeColors.light.surface)
            .cornerRadius(16)
            .shadow(
                color: .black.opacity(0.05),
                radius: 8,
                x: 0,
                y: 4
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardModifier())
    }
}
```

### Input Field Modifier
```swift
struct InputFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(RoundedBorderTextFieldStyle())
            .font(.bodyLarge)
            .padding(.vertical, Spacing.xs)
    }
}

extension View {
    func inputFieldStyle() -> some View {
        modifier(InputFieldModifier())
    }
}
```

## Usage Examples

### Story View
```swift
struct StoryView: View {
    let story: Story
    
    var body: some View {
        VStack(spacing: Spacing.md) {
            Text(story.title)
                .font(.storyTitle)
            
            Text(story.content)
                .font(.storyText)
            
            HStack {
                PrimaryButton(title: "Read Now") {
                    // Action
                }
                
                SecondaryButton(title: "Save") {
                    // Action
                }
            }
        }
        .padding(Spacing.md)
        .cardStyle()
    }
}
```

### Settings View
```swift
struct SettingsView: View {
    @State private var name = ""
    
    var body: some View {
        Form {
            Section("Profile") {
                ThemedTextField(label: "Child's Name", text: $name)
            }
            
            Section("Preferences") {
                Toggle("Dark Mode", isOn: .constant(false))
                Toggle("Text-to-Speech", isOn: .constant(true))
            }
        }
        .navigationTitle("Settings")
    }
}
```

## Accessibility

### Text Sizes
- Support Dynamic Type
- Use appropriate semantic styles
- Maintain readable contrast ratios

### Color Contrast
- Ensure WCAG 2.1 compliance
- Test with various color blindness simulations
- Provide sufficient contrast in dark mode

### VoiceOver
- Add meaningful accessibility labels
- Group related elements
- Provide clear navigation hints

## Best Practices

1. **Consistency**
   - Use predefined styles
   - Follow spacing guidelines
   - Maintain visual hierarchy

2. **Accessibility**
   - Support Dynamic Type
   - Maintain contrast ratios
   - Implement VoiceOver

3. **Performance**
   - Optimize animations
   - Use appropriate image sizes
   - Minimize layout changes

4. **Maintenance**
   - Document style changes
   - Update examples
   - Review periodically

---

This document should be updated when:
- New components are added
- Visual style changes
- Accessibility requirements change
- Best practices evolve

## UI Patterns for Growth Path Collections

### Navigation
- Collections are accessed via a dedicated tab in the main TabView
- Uses `NavigationStack` for intra-tab navigation
- `CollectionCardView` for list items, `CollectionDetailView` for detail, `StoryDetailView` for reading
- Modal presentation (`.sheet`) for `CollectionFormView` (collection creation)

### Visual Elements
- **CollectionCardView:**
  - Displays collection title, theme, and progress indicator (e.g., progress bar or fraction)
  - Tappable to navigate to detail
- **CollectionDetailView:**
  - Shows collection summary, list of stories, and overall progress
  - Each story row shows completion status
  - Progress bar updates as stories are completed
- **StoryDetailView:**
  - Paginated reading interface
  - Progress tracked and updated on completion

### Feedback & Accessibility
- Progress indicators update in real time as stories are completed
- (Planned) Achievements/badges shown on collection completion or milestones
- All controls and indicators support Dynamic Type and VoiceOver
- Loading and error states use overlay indicators and alerts for consistency

### Outstanding UI Tasks
- Finalize polish for all collection-related views (cards, detail, progress bars)
- Add feedback/animations for progress and achievements (if feasible)
- Ensure accessibility for all new UI elements
- Extract reusable loading/error overlay component for forms (future improvement)

---

## Related Components
- `CollectionsListView.swift`
- `CollectionCardView.swift`
- `CollectionDetailView.swift`
- `CollectionFormView.swift`
- `StoryDetailView.swift`
