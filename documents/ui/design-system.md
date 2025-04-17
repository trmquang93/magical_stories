/// [2025-04-16 Modern Calm Update]
# Modern Calm with Magical Accents — Design System Update

## Expanded Color Palette
```swift
extension Color {
    // Brand
    static let magicalPrimary = Color("MagicalPrimary") // #7B61FF
    static let magicalSecondary = Color("MagicalSecondary") // #FFB443
    static let magicalAccent = Color("MagicalAccent") // #FF617B
    // Modern Calm
    static let calmBlue = Color(hex: "4F8CFF")
    static let gentleGreen = Color(hex: "6DD6A7")
    static let softGold = Color(hex: "FFD86B")
    static let deepNavy = Color(hex: "222B45")
    static let coolGray = Color(hex: "6B7280")
    static let surface = Color(hex: "FFFFFF")
    static let background = Color(hex: "F7F9FB")
    static let border = Color(hex: "E3E8EF")
    // Magical Accents (Reading/Playful)
    static let magicPurple = Color(hex: "A259FF")
    static let skyBlue = Color(hex: "38BDF8")
    static let fairyPink = Color(hex: "FF7EB9")
    static let sparkleWhite = Color.white
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
    // Modern Calm
    static let displayLarge = Font.system(size: 34, weight: .bold, design: .rounded)
    static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headingLarge = Font.system(size: 22, weight: .semibold, design: .rounded)
    static let headingMedium = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let bodyLarge = Font.system(size: 17, design: .rounded)
    static let bodyMedium = Font.system(size: 15, design: .rounded)
    // Playful/Storybook (Reading)
    static let storyTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let storyText = Font.system(size: 20, design: .rounded)
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

## Patterns

### Destructive Actions: Swipe-to-Delete

For destructive actions such as deleting a collection, use the native SwiftUI swipe-to-delete pattern in lists. This provides a familiar and accessible experience for users.

**Example:**

```
List {
    ForEach(items) { item in
        // ...
    }
    .onDelete(perform: deleteItems)
}
```

In Magical Stories, users can delete a Growth Collection by swiping left on a collection in the Collections tab. An error alert is shown if deletion fails.

**Accessibility:**
- The swipe-to-delete action is accessible via VoiceOver and supports standard iOS gestures.
- Always provide an alert or confirmation for destructive actions if accidental deletion is a concern.

**Error Handling:**
- If deletion fails, present an alert with the error message and a dismiss button.

See: `CollectionsListView.swift` for implementation details.

/// [2025-04-16 Modern Calm Update] End of section

/// [2025-04-16 Modern Calm Update: Home View]
# Home View — Hi-Fi Design Documentation

## Visual Description
- **Background:** #F7F9FB, subtle magical sparkles in corners (low opacity, animated if possible)
- **Header:**
  - Greeting: Large, friendly ("Welcome back, [Name]!")
    - Font: .displayMedium (28pt, bold, rounded), color: deepNavy (#222B45)
    - 16pt top margin
  - Subheading: "What magical story will you create today?"
    - Font: .bodyMedium (15pt, rounded), color: coolGray (#6B7280)
    - 4pt below greeting
- **Primary Action Card:**
  - White, 16pt radius, soft shadow, border #E3E8EF, 20pt padding
  - HStack: Left — icon (wand/book, 48pt, magicalPrimary bg), Right — title, subtitle, button
  - Button: "Start", PrimaryButton style, full width
- **Growth Collections Preview:**
  - Section header: .headingMedium (20pt, semibold, deepNavy)
  - Horizontal scroll of CollectionCardView cards (2.2 on screen, peek effect)
- **Your Library Preview:**
  - Section header: .headingMedium, deepNavy
  - Up to 3 StoryCard previews, "See All" SecondaryButton at end
- **Footer Tip:**
  - "Tip: Reading together builds magical memories!"
    - .bodySmall, magicalAccent (#FF617B), centered, 16pt bottom margin
- **Spacing:** 16pt horizontal, 24pt between major sections

## Component Breakdown & Code Snippets

### Header
```swift
VStack(alignment: .leading, spacing: 4) {
    Text("Welcome back, [Name]!")
        .font(.displayMedium)
        .foregroundColor(.deepNavy)
        .padding(.top, 16)
    Text("What magical story will you create today?")
        .font(.bodyMedium)
        .foregroundColor(.coolGray)
}
.padding(.horizontal, 16)
```

### Primary Action Card
```swift
HStack(spacing: 16) {
    ZStack {
        Circle()
            .fill(Color.magicalPrimary)
            .frame(width: 48, height: 48)
        Image(systemName: "wand.and.stars")
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(.white)
    }
    VStack(alignment: .leading, spacing: 4) {
        Text("Create a New Story")
            .font(.headingLarge)
            .foregroundColor(.deepNavy)
        Text("Personalize a bedtime adventure")
            .font(.bodySmall)
            .foregroundColor(.coolGray)
        PrimaryButton(title: "Start") {
            // Action
        }
        .padding(.top, 8)
    }
    Spacer()
}
.padding(20)
.background(Color.white)
.cornerRadius(16)
.shadow(color: Color.black.opacity(0.05), radius: 8, y: 4)
.overlay(
    RoundedRectangle(cornerRadius: 16)
        .stroke(Color.border, lineWidth: 1)
)
.padding(.horizontal, 16)
.padding(.vertical, 8)
```

### Growth Collections Preview
```swift
VStack(alignment: .leading, spacing: 8) {
    Text("Growth Path Collections")
        .font(.headingMedium)
        .foregroundColor(.deepNavy)
        .padding(.horizontal, 16)
    ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 12) {
            ForEach(collections) { collection in
                CollectionCardView(collection: collection)
                    .frame(width: 220)
            }
        }
        .padding(.horizontal, 16)
    }
}
.padding(.top, 16)
```

### Your Library Preview
```swift
VStack(alignment: .leading, spacing: 8) {
    Text("Your Story Library")
        .font(.headingMedium)
        .foregroundColor(.deepNavy)
        .padding(.horizontal, 16)
    ForEach(recentStories.prefix(3)) { story in
        StoryCard(story: story)
            .padding(.horizontal, 16)
    }
    HStack {
        Spacer()
        SecondaryButton(title: "See All") {
            // Action
        }
        .frame(width: 120)
        .padding(.trailing, 16)
    }
}
.padding(.top, 24)
```

### Footer Tip
```swift
Text("Tip: Reading together builds magical memories!")
    .font(.bodySmall)
    .foregroundColor(.magicalAccent)
    .multilineTextAlignment(.center)
    .padding(.vertical, 16)
    .frame(maxWidth: .infinity)
```

### Background Sparkles (Optional)
```swift
ZStack {
    Color.background.ignoresSafeArea()
    SparkleAnimationView() // Custom view for animated sparkles
    // ...rest of HomeView content
}
```

## Interaction & Animation Guidelines
- Primary card button: bounces on tap, color darkens briefly
- Collection cards: scale up slightly on tap, progress bar animates
- Sparkles: gently float and fade in/out in the background
- Section transitions: fade/slide in on appear

## Accessibility & Responsiveness
- All text supports Dynamic Type
- Buttons/cards have at least 44pt tap targets
- VoiceOver labels for all actionable elements
- Layout adapts to iPad (wider cards, more spacing) and landscape

## Figma Handoff Notes
- Use color and typography tokens from the design system
- Card/button radii: 16pt, shadow: 0,4,8, #0000000D
- Spacing: 16pt standard horizontal, 24pt between major sections
- Icons: SF Symbols, bold weight, white on colored backgrounds
- Sparkles: ellipse/star shapes, 10–20% opacity, animate with floating motion

/// [2025-04-16 Modern Calm Update: Home View] End of section

# UI Testing and Snapshot Testing for LibraryView

## Automated UI Tests
- LibraryView is covered by device-level UI tests (XCUITest) in the `magical-storiesUITests` target.
- These tests validate the presence and accessibility of the header, subtitle, search bar, recent stories, and categories.
- UI tests also take screenshots for visual inspection and can be extended for pixel-diff automation.

## Snapshot Testing
- Pixel-perfect snapshot tests are implemented using the [SnapshotTesting](https://github.com/pointfreeco/swift-snapshot-testing) library in the `magical-storiesTests` (unit test) target.
- Snapshots are taken for both light and dark mode, at iPhone 11 size (375x812).
- The following UI elements are validated:
  - Header ("Library")
  - Subtitle ("Your magical story collection")
  - Search bar ("Search stories")
  - Recent stories section and cards
  - Categories section and cards
  - Overall layout and spacing
- Reference images are committed to the repo and reviewed on every UI change.

## Best Practices
- Keep snapshot reference images up to date with intentional UI changes.
- Review diffs on every PR to catch unintentional UI regressions.
- Run both logic/unit and UI/snapshot tests in CI for full coverage.
- Use descriptive snapshot names and test on all relevant device sizes and color schemes.
- Maintain test constants (e.g., category names) in sync with production code for reliability.

---

*Last updated: 2025-04-16*
