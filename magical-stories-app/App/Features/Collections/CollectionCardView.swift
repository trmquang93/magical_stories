/// CollectionCardView displays summary information for a StoryCollection, including title, description, category, age group, and progress.
import SwiftUI

struct CollectionCardView: View {
    let collection: StoryCollection

    // State properties for hover and animation effects
    @State private var isHovering = false
    @State private var animateProgress = false

    var storyCountText: String {
        let count = collection.stories?.count ?? 0
        return "\(count) \(count == 1 ? "story" : "stories")"
    }

    // Compute a thematic color based on the collection category
    var thematicColor: Color {
        switch collection.category {
        case "emotionalIntelligence": return Color.magicalPrimary
        case "socialSkills": return Color.blue
        case "cognitiveDevelopment": return Color.purple
        case "creativityImagination": return Color(hex: "#FF617B")
        case "problemSolving": return Color(hex: "#00B8A9")
        case "resilienceGrit": return Color(hex: "#F9A826")
        case "kindnessEmpathy": return Color(hex: "#7ED957")
        default: return Color.magicalAccent
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
            // Background card with gradient
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        gradient: Gradient(
                            colors: [
                                Color(.systemBackground),
                                Color(.systemBackground).opacity(0.95),
                            ]
                        ),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    // Top decorative accent
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(
                                    colors: [
                                        thematicColor.opacity(0.8),
                                        thematicColor.opacity(0.5),
                                        thematicColor.opacity(0.2),
                                        Color.clear,
                                    ]
                                ),
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 80)
                        .clipped()
                        .mask(
                            RoundedRectangle(cornerRadius: 20)
                                .frame(height: 80)
                        ),
                    alignment: .top
                )
                .overlay(
                    // Border with subtle gradient
                    RoundedRectangle(cornerRadius: 20)
                        .strokeBorder(
                            LinearGradient(
                                gradient: Gradient(
                                    colors: [
                                        thematicColor.opacity(0.5),
                                        Color(.separator).opacity(0.2),
                                    ]
                                ),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: isHovering ? 12 : 6,
                    x: 0,
                    y: isHovering ? 8 : 4
                )

            // Content
            VStack(alignment: .leading, spacing: 12) {
                // Top icon and category badge
                HStack(alignment: .top) {
                    // Icon with thematic background
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(
                                        colors: [
                                            thematicColor,
                                            thematicColor.opacity(0.8),
                                        ]
                                    ),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                            .shadow(color: thematicColor.opacity(0.3), radius: 5, x: 0, y: 3)

                        Image(systemName: categoryIcon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .accessibilityIdentifier("categoryIcon")
                    }

                    Spacer()

                    // Age group badge
                    Text(ageGroupDisplay)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(
                            Capsule()
                                .fill(thematicColor.opacity(0.8))
                        )
                }
                .padding(.bottom, 4)

                // Title with vertically stacked text for better hierarchy
                VStack(alignment: .leading, spacing: 4) {
                    Text(collection.title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(Color.primary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                        .accessibilityAddTraits(.isHeader)

                    Text(storyCountText)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.secondary)
                }

                Spacer()

                // Progress section
                VStack(alignment: .leading, spacing: 6) {
                    // Progress indicator with text
                    if collection.stories?.isEmpty == false {
                        HStack {
                            Text("Progress")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color.secondary)

                            Spacer()

                            Text("\(Int(collection.completionProgress * 100))%")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(thematicColor)
                        }

                        // Custom animated progress bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                // Background track
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color(.systemGray5))
                                    .frame(height: 8)

                                // Progress bar with animation
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            gradient: Gradient(
                                                colors: [
                                                    thematicColor.opacity(0.8),
                                                    thematicColor,
                                                ]
                                            ),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: geometry.size.width
                                            * (animateProgress ? collection.completionProgress : 0),
                                        height: 8
                                    )
                                    .animation(
                                        .spring(response: 0.8, dampingFraction: 0.7),
                                        value: animateProgress)
                            }
                        }
                        .frame(height: 8)
                    }

                    // Completed badge with animation
                    if collection.completionProgress >= 1.0 {
                        HStack(spacing: 6) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(Color(hex: "#FFD700"))
                                .font(.system(size: 16))
                                .symbolEffect(.bounce, options: .repeating, value: isHovering)

                            Text("Collection Completed!")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [Color(hex: "#FFD700"), Color(hex: "#FFA500")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                        .padding(.vertical, 5)
                        .padding(.horizontal, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color(.systemBackground))
                                .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                        .accessibilityLabel("Collection completed")
                    }
                }
            }
            .padding(16)
        }
        .aspectRatio(0.75, contentMode: .fit)
        .frame(minWidth: 160, maxWidth: 220)
        .onAppear {
            // Delay the animation slightly for a nice effect
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                animateProgress = true
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovering = hovering
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("CollectionCardView-\(collection.id)")
        // Add haptic feedback on press
        .sensoryFeedback(.impact(weight: .light), trigger: isHovering)
        .scaleEffect(isHovering ? 1.03 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovering)
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
