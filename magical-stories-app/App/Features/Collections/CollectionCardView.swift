/// CollectionCardView displays summary information for a StoryCollection, including title, description, category, age group, and progress.
import SwiftUI

struct CollectionCardView: View {
    let collection: StoryCollection

    // State properties for animation and interaction
    @State private var isHovering = false
    @State private var isPressing = false
    @State private var animateProgress = false
    @State private var showTitleReveal = false

    // Environment for color scheme
    @Environment(\.colorScheme) private var colorScheme

    // Derived properties
    var storyCountText: String {
        let count = collection.stories?.count ?? 0
        return "\(count) \(count == 1 ? "story" : "stories")"
    }

    // Compute a thematic color based on the collection category
    var thematicColor: Color {
        switch collection.category {
        case "emotionalIntelligence": return UITheme.Colors.primary
        case "socialSkills": return Color.blue
        case "cognitiveDevelopment": return Color.purple
        case "creativityImagination": return Color(hex: "#FF617B")
        case "problemSolving": return Color(hex: "#00B8A9")
        case "resilienceGrit": return Color(hex: "#F9A826")
        case "kindnessEmpathy": return Color(hex: "#7ED957")
        default: return UITheme.Colors.accent
        }
    }

    var categoryIcon: String {
        switch collection.category {
        case "emotionalIntelligence": return "heart.fill"
        case "socialSkills": return "person.2.fill"
        case "cognitiveDevelopment": return "brain"
        case "creativityImagination": return "sparkles"
        case "problemSolving": return "puzzlepiece.fill"
        case "resilienceGrit": return "figure.walk.motion"
        case "kindnessEmpathy": return "hands.sparkles"
        default: return "book.pages"
        }
    }

    var ageGroupDisplay: String {
        switch collection.ageGroup {
        case "preschool": return "3-5 years"
        case "earlyReader": return "6-8 years"
        case "middleGrade": return "9-12 years"
        default: return collection.ageGroup
        }
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Clean background with soft shadow and accent top
            RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusLarge)
                .fill(UITheme.Colors.surfacePrimary)
                .overlay(
                    // Top accent indicator - thin elegant line
                    VStack {
                        Rectangle()
                            .fill(thematicColor)
                            .frame(height: 6)
                        Spacer()
                    }
                    .mask(
                        RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusLarge)
                    )
                )
                .overlay(
                    // Elegant border
                    RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusLarge)
                        .strokeBorder(
                            thematicColor.opacity(isHovering ? 0.2 : 0.1),
                            lineWidth: 1
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: isHovering ? 10 : 5,
                    x: 0,
                    y: isHovering ? 5 : 2
                )
                .scaleEffect(isPressing ? 0.98 : (isHovering ? 1.02 : 1.0))
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressing)

            // Content with clean layout
            VStack(alignment: .leading, spacing: UITheme.Spacing.md) {
                // Top section with aligned icon and badge
                HStack(alignment: .center) {
                    // Minimal icon with thematic background
                    ZStack {
                        Circle()
                            .fill(thematicColor.opacity(0.1))
                            .frame(width: 44, height: 44)

                        Image(systemName: categoryIcon)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(thematicColor)
                            .accessibilityIdentifier("categoryIcon")
                    }
                    .offset(y: showTitleReveal ? 0 : -5)
                    .opacity(showTitleReveal ? 1 : 0)
                    .animation(.easeOut.delay(0.1), value: showTitleReveal)

                    Spacer()

                    // Clean age group badge
                    Text(ageGroupDisplay)
                        .font(UITheme.Typography.bodySmall.weight(.medium))
                        .foregroundColor(thematicColor)
                        .padding(.horizontal, UITheme.Spacing.sm)
                        .padding(.vertical, UITheme.Spacing.xxs)
                        .background(
                            Capsule()
                                .fill(thematicColor.opacity(0.1))
                        )
                        .offset(y: showTitleReveal ? 0 : -5)
                        .opacity(showTitleReveal ? 1 : 0)
                        .animation(.easeOut.delay(0.2), value: showTitleReveal)
                }

                // Title and story count with reveal animation
                VStack(alignment: .leading, spacing: UITheme.Spacing.xxs) {
                    Text(collection.title)
                        .font(UITheme.Typography.headingSmall)
                        .foregroundStyle(UITheme.Colors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .offset(y: showTitleReveal ? 0 : 10)
                        .opacity(showTitleReveal ? 1 : 0)
                        .animation(.easeOut.delay(0.3), value: showTitleReveal)

                    // Story count with subtle icon
                    HStack(spacing: UITheme.Spacing.xxs) {
                        Image(systemName: "book")
                            .font(.system(size: 12))
                            .foregroundStyle(UITheme.Colors.textSecondary.opacity(0.8))

                        Text(storyCountText)
                            .font(UITheme.Typography.bodySmall.weight(.medium))
                            .foregroundStyle(UITheme.Colors.textSecondary)
                    }
                    .offset(y: showTitleReveal ? 0 : 10)
                    .opacity(showTitleReveal ? 1 : 0)
                    .animation(.easeOut.delay(0.4), value: showTitleReveal)
                }

                Spacer()

                // Progress section with clean visuals
                if collection.stories?.isEmpty == false {
                    VStack(alignment: .leading, spacing: UITheme.Spacing.xs) {
                        // Progress indicator with text
                        HStack {
                            Text("Progress")
                                .font(UITheme.Typography.bodySmall.weight(.medium))
                                .foregroundColor(UITheme.Colors.textSecondary)

                            Spacer()

                            Text("\(Int(collection.completionProgress * 100))%")
                                .font(UITheme.Typography.bodySmall.weight(.bold))
                                .foregroundColor(thematicColor)
                        }
                        .opacity(animateProgress ? 1 : 0)
                        .animation(.easeIn.delay(0.6), value: animateProgress)

                        // Clean, elegant progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background track
                                RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusSmall)
                                    .fill(UITheme.Colors.surfaceSecondary.opacity(0.3))
                                    .frame(height: 6)

                                // Progress indicator
                                RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusSmall)
                                    .fill(thematicColor)
                                    .frame(
                                        width: geometry.size.width
                                            * (animateProgress ? collection.completionProgress : 0),
                                        height: 6
                                    )
                                    .animation(
                                        .easeInOut(duration: 1.0).delay(0.5), value: animateProgress
                                    )
                            }
                        }
                        .frame(height: 6)
                        .opacity(animateProgress ? 1 : 0)
                        .animation(.easeIn.delay(0.5), value: animateProgress)
                    }
                }

                // Minimal completion indicator
                if collection.completionProgress >= 1.0 {
                    HStack(spacing: UITheme.Spacing.xs) {
                        // Subtle checkmark indicator
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(thematicColor)
                            .font(.system(size: 16))

                        Text("Collection Completed")
                            .font(UITheme.Typography.bodySmall.weight(.medium))
                            .foregroundStyle(thematicColor)
                    }
                    .padding(.vertical, UITheme.Spacing.xxs)
                    .padding(.horizontal, UITheme.Spacing.sm)
                    .background(
                        RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusSmall)
                            .fill(thematicColor.opacity(0.1))
                    )
                    .accessibilityLabel("Collection completed")
                    .opacity(animateProgress ? 1 : 0)
                    .offset(y: animateProgress ? 0 : 10)
                    .animation(.easeOut.delay(0.7), value: animateProgress)
                }
            }
            .padding(UITheme.Spacing.md)
        }
        .frame(minWidth: 140, maxWidth: 180)
        .onAppear {
            // Subtle, elegant animations
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showTitleReveal = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateProgress = true
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .pressAction {
            isPressing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isPressing = false
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("CollectionCardView-\(collection.id)")
    }
}

// Conditional symbol effect modifier
struct ConditionalSymbolEffect: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        if isActive {
            content.symbolEffect(.bounce.byLayer, options: .speed(1.5))
        } else {
            content
        }
    }
}

// Conditional star effect modifier
struct ConditionalStarEffect: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        if isActive {
            content.symbolEffect(.bounce.up.byLayer, options: .repeating)
        } else {
            content
        }
    }
}

#Preview("Light Mode", traits: .sizeThatFitsLayout) {
    VStack(spacing: 20) {
        // Preview different categories and progress levels
        CollectionCardView(
            collection: StoryCollection(
                title: "Forest Friends",
                descriptionText: "Stories about friendship and nature",
                category: "emotionalIntelligence",
                ageGroup: "preschool",
                stories: Array(repeating: Story.previewStory(), count: 8),
                createdAt: Date(),
                updatedAt: Date()
            ))

        CollectionCardView(
            collection: {
                let collection = StoryCollection(
                    title: "Problem Solving Adventures",
                    descriptionText: "Learn to solve problems through stories",
                    category: "problemSolving",
                    ageGroup: "earlyReader",
                    stories: Array(repeating: Story.previewStory(), count: 5),
                    createdAt: Date(),
                    updatedAt: Date()
                )
                collection.completionProgress = 0.6
                return collection
            }())

        CollectionCardView(
            collection: {
                let collection = StoryCollection(
                    title: "Creativity Workshop",
                    descriptionText: "Explore imagination and creativity",
                    category: "creativityImagination",
                    ageGroup: "middleGrade",
                    stories: Array(repeating: Story.previewStory(), count: 3),
                    createdAt: Date(),
                    updatedAt: Date()
                )
                collection.completionProgress = 1.0
                return collection
            }())
    }
    .padding()
    .preferredColorScheme(.light)
}

#Preview("Dark Mode", traits: .sizeThatFitsLayout) {
    VStack(spacing: 20) {
        CollectionCardView(
            collection: StoryCollection(
                title: "Kindness Journey",
                descriptionText: "Explore kindness and empathy",
                category: "kindnessEmpathy",
                ageGroup: "preschool",
                stories: Array(repeating: Story.previewStory(), count: 4),
                createdAt: Date(),
                updatedAt: Date()
            ))

        CollectionCardView(
            collection: {
                let collection = StoryCollection(
                    title: "Brain Builders",
                    descriptionText: "Fun ways to develop thinking",
                    category: "cognitiveDevelopment",
                    ageGroup: "earlyReader",
                    stories: Array(repeating: Story.previewStory(), count: 6),
                    createdAt: Date(),
                    updatedAt: Date()
                )
                collection.completionProgress = 0.33
                return collection
            }())

        CollectionCardView(
            collection: {
                let collection = StoryCollection(
                    title: "Social Stars",
                    descriptionText: "Stories about making friends",
                    category: "socialSkills",
                    ageGroup: "middleGrade",
                    stories: Array(repeating: Story.previewStory(), count: 3),
                    createdAt: Date(),
                    updatedAt: Date()
                )
                collection.completionProgress = 1.0
                return collection
            }())
    }
    .padding()
    .preferredColorScheme(.dark)
}
