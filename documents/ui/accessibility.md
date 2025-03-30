# Accessibility Guidelines

## Overview
This document outlines the accessibility implementation guidelines for the Magical Stories app, ensuring it's usable by everyone, including children with different abilities.

## Dynamic Type Support

### Font Implementation
```swift
struct DynamicTypeText: View {
    let text: String
    let style: Font.TextStyle
    
    var body: some View {
        Text(text)
            .font(.system(style))
            .dynamicTypeSize(...DynamicTypeSize.accessibility5)
    }
}
```

### Custom Font Scaling
```swift
extension Font {
    static func scaledFont(
        name: String,
        size: CGFloat,
        relativeTo style: Font.TextStyle
    ) -> Font {
        let metrics = UIFontMetrics(forTextStyle: UIFont.TextStyle(style))
        let font = UIFont(name: name, size: size)!
        let scaledFont = metrics.scaledFont(for: font)
        return Font(scaledFont)
    }
}

// Usage Example
struct StoryText: View {
    var body: some View {
        Text("Once upon a time...")
            .font(.scaledFont(
                name: "SFRounded-Regular",
                size: 17,
                relativeTo: .body
            ))
    }
}
```

## VoiceOver Support

### Accessibility Labels
```swift
struct AccessibleStoryCard: View {
    let story: Story
    
    var body: some View {
        StoryCard(story: story)
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Story: \(story.title)")
            .accessibilityValue("\(story.readCount) times read")
            .accessibilityHint("Double tap to read story")
    }
}
```

### Custom Actions
```swift
struct StoryActions: View {
    let story: Story
    
    var body: some View {
        HStack {
            Button("Read") { /* Action */ }
            Button("Save") { /* Action */ }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Story actions")
        .accessibilityAction(named: "Read Story") {
            // Read action
        }
        .accessibilityAction(named: "Save Story") {
            // Save action
        }
    }
}
```

### Grouped Content
```swift
struct StorySection: View {
    let title: String
    let stories: [Story]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title)
                .font(.headline)
            
            ForEach(stories) { story in
                StoryCard(story: story)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(title) section")
        .accessibilityHint("Contains \(stories.count) stories")
    }
}
```

## Audio Descriptions

### Text-to-Speech Integration
```swift
class StoryReader: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isReading = false
    
    func read(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.8
        utterance.pitchMultiplier = 1.1
        utterance.volume = 0.8
        
        synthesizer.speak(utterance)
        isReading = true
    }
    
    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
        isReading = false
    }
}

struct ReadingControls: View {
    @StateObject private var reader = StoryReader()
    let story: Story
    
    var body: some View {
        HStack {
            Button(action: {
                reader.isReading ? reader.stop() : reader.read(story.content)
            }) {
                Image(systemName: reader.isReading ? "pause.circle" : "play.circle")
                    .accessibilityLabel(reader.isReading ? "Stop reading" : "Start reading")
            }
            
            if reader.isReading {
                ProgressView()
                    .accessibilityLabel("Reading in progress")
            }
        }
    }
}
```

## Color and Contrast

### High Contrast Colors
```swift
struct AccessibleColors {
    static let highContrastPrimary = Color("HighContrastPrimary")
    static let highContrastSecondary = Color("HighContrastSecondary")
    
    static func getTextColor(for background: Color) -> Color {
        // Implement contrast calculation
        return .white
    }
}

struct AccessibleText: View {
    let text: String
    let backgroundColor: Color
    
    var body: some View {
        Text(text)
            .foregroundColor(
                AccessibleColors.getTextColor(for: backgroundColor)
            )
            .background(backgroundColor)
    }
}
```

### Color Blindness Support
```swift
struct ColorBlindFriendlyView: View {
    var body: some View {
        HStack {
            // Use patterns in addition to colors
            Image(systemName: "circle.fill")
                .foregroundColor(.green)
                .overlay(Image(systemName: "checkmark"))
            
            Image(systemName: "circle.fill")
                .foregroundColor(.red)
                .overlay(Image(systemName: "xmark"))
        }
    }
}
```

## Focus Management

### Focus Areas
```swift
struct FocusableStoryList: View {
    @Namespace private var namespace
    @FocusState private var focusedItem: UUID?
    
    var body: some View {
        ScrollView {
            LazyVStack {
                ForEach(stories) { story in
                    StoryCard(story: story)
                        .focused($focusedItem, equals: story.id)
                        .onTapGesture {
                            focusedItem = story.id
                        }
                }
            }
        }
        .onChange(of: focusedItem) { newValue in
            withAnimation {
                // Scroll to focused item
            }
        }
    }
}
```

### Focus Order
```swift
struct FocusableForm: View {
    @FocusState private var focusedField: Field?
    
    enum Field {
        case childName
        case age
        case interests
    }
    
    var body: some View {
        Form {
            TextField("Child's Name", text: $childName)
                .focused($focusedField, equals: .childName)
            
            TextField("Age", text: $age)
                .focused($focusedField, equals: .age)
            
            TextField("Interests", text: $interests)
                .focused($focusedField, equals: .interests)
        }
        .onSubmit {
            switch focusedField {
            case .childName:
                focusedField = .age
            case .age:
                focusedField = .interests
            default:
                focusedField = nil
            }
        }
    }
}
```

## Reduced Motion

### Motion Adaptation
```swift
struct AdaptiveAnimation: ViewModifier {
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    let animation: Animation
    
    func body(content: Content) -> some View {
        content.animation(reduceMotion ? nil : animation)
    }
}

extension View {
    func adaptiveAnimation(_ animation: Animation) -> some View {
        modifier(AdaptiveAnimation(animation: animation))
    }
}

// Usage
struct AnimatedStory: View {
    @State private var isRevealed = false
    
    var body: some View {
        VStack {
            if isRevealed {
                StoryContent()
                    .transition(.scale)
                    .adaptiveAnimation(.spring())
            }
        }
    }
}
```

## Testing Guidelines

### VoiceOver Testing
```swift
struct AccessibilityTest {
    static func performVoiceOverTest() -> [String] {
        var issues: [String] = []
        
        // Test navigation
        if !checkVoiceOverNavigation() {
            issues.append("VoiceOver navigation needs improvement")
        }
        
        // Test labels
        if !checkAccessibilityLabels() {
            issues.append("Missing accessibility labels")
        }
        
        return issues
    }
    
    static func checkVoiceOverNavigation() -> Bool {
        // Implementation
        return true
    }
    
    static func checkAccessibilityLabels() -> Bool {
        // Implementation
        return true
    }
}
```

### Dynamic Type Testing
```swift
struct DynamicTypeTest {
    static func testTextScaling() -> [String] {
        var issues: [String] = []
        
        let sizes: [DynamicTypeSize] = [
            .xSmall,
            .large,
            .xxxLarge,
            .accessibility5
        ]
        
        for size in sizes {
            if !checkTextLayoutAt(size) {
                issues.append("Layout issues at size: \(size)")
            }
        }
        
        return issues
    }
    
    static func checkTextLayoutAt(_ size: DynamicTypeSize) -> Bool {
        // Implementation
        return true
    }
}
```

## Best Practices

1. **VoiceOver**
   - Provide meaningful labels
   - Use proper traits
   - Group related elements
   - Add helpful hints

2. **Dynamic Type**
   - Support text scaling
   - Test extreme sizes
   - Maintain readability
   - Use proper text styles

3. **Color and Contrast**
   - Meet WCAG guidelines
   - Support dark mode
   - Consider color blindness
   - Use patterns with colors

4. **Motion**
   - Respect reduce motion setting
   - Provide alternatives
   - Keep animations subtle
   - Allow animation control

5. **Focus**
   - Logical focus order
   - Clear focus indicators
   - Keyboard navigation
   - Focus management

## Testing Checklist

- [ ] VoiceOver navigation
- [ ] Dynamic Type support
- [ ] Color contrast
- [ ] Motion reduction
- [ ] Focus management
- [ ] Audio descriptions
- [ ] Keyboard navigation
- [ ] Custom actions
- [ ] Error messages
- [ ] Loading states

---

This document should be updated when:
- New UI components are added
- Accessibility guidelines change
- Testing reveals issues
- User feedback is received
