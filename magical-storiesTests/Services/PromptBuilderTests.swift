import Testing
import XCTest

@testable import magical_stories

struct PromptBuilderTests {

    var promptBuilder: PromptBuilder!

    init() {
        promptBuilder = PromptBuilder()
    }

    @Test("Test build prompt for young child")
    func testBuildPromptForYoungChild() {
        // Given
        let parameters = StoryParameters(
            childName: "Emma",
            childAge: 4,
            theme: "Friendship",
            favoriteCharacter: "Bunny",
            storyLength: "short",
            developmentalFocus: [.problemSolving, .socialSkills],
            emotionalThemes: ["joy", "sharing"]
        )

        // When
        let prompt = promptBuilder.buildPrompt(parameters: parameters)

        // Then
        #expect(prompt.contains("Use simple, concrete words and short sentences"))
        #expect(prompt.contains("Create a linear story with clear cause-and-effect"))
        #expect(prompt.contains("Emma"))
        #expect(prompt.contains("Bunny"))
        #expect(prompt.contains("Friendship"))
        #expect(prompt.contains("Social Skills"))
        #expect(prompt.contains("Problem Solving")) // Updated assertion
        #expect(prompt.contains("joy"))
        #expect(prompt.contains("sharing"))
    }

    @Test("Test build prompt for intermediate child")
    func testBuildPromptForIntermediateChild() {
        // Given
        let parameters = StoryParameters(
            childName: "Alex",
            childAge: 6,
            theme: "Adventure",
            favoriteCharacter: "Dragon",
            storyLength: "medium",
            developmentalFocus: [.socialSkills],
            emotionalThemes: ["courage", "determination"]
        )

        // When
        let prompt = promptBuilder.buildPrompt(parameters: parameters)

        // Then
        #expect(prompt.contains("Use a mix of familiar and new vocabulary"))
        #expect(prompt.contains("Include minor subplots"))
        #expect(prompt.contains("Alex"))
        #expect(prompt.contains("Dragon"))
        #expect(prompt.contains("Adventure"))
        #expect(prompt.contains("Social Skills"))
        #expect(prompt.contains("courage"))
        #expect(prompt.contains("determination"))
    }

    @Test("Test build prompt for advanced child")
    func testBuildPromptForAdvancedChild() {
        // Given
        let parameters = StoryParameters(
            childName: "Maya",
            childAge: 8,
            theme: "Mystery",
            favoriteCharacter: "Detective Cat",
            storyLength: "long",
            developmentalFocus: [.cognitiveDevelopment],
            emotionalThemes: ["curiosity", "perseverance"]
        )

        // When
        let prompt = promptBuilder.buildPrompt(parameters: parameters)

        // Then
        #expect(prompt.contains("Use rich vocabulary"))
        #expect(prompt.contains("Develop multiple story layers"))
        #expect(prompt.contains("Maya"))
        #expect(prompt.contains("Detective Cat"))
        #expect(prompt.contains("Mystery"))
        #expect(prompt.contains("Cognitive Development"))
        #expect(prompt.contains("curiosity"))
        #expect(prompt.contains("perseverance"))
    }

    @Test("Test build prompt without optional parameters")
    func testBuildPromptWithoutOptionalParameters() {
        // Given
        let parameters = StoryParameters(
            childName: "Sam",
            childAge: 5,
            theme: "Nature",
            favoriteCharacter: "Wise Owl"
        )

        // When
        let prompt = promptBuilder.buildPrompt(parameters: parameters)

        // Then
        #expect(prompt.contains("Sam"))
        #expect(prompt.contains("Wise Owl"))
        #expect(prompt.contains("Nature"))
        #expect(!prompt.contains("Developmental Focus"))  // Should not include this section
        #expect(!prompt.contains("Emotional Elements"))  // Should not include this section
    }

    @Test("Prompt includes story structure guidelines")
    func testPromptIncludesStoryStructureGuidelines() {
        // Given
        let parameters = StoryParameters(
            childName: "Pat",
            childAge: 7,
            theme: "Space",
            favoriteCharacter: "Star"
        )

        // When
        let prompt = promptBuilder.buildPrompt(parameters: parameters)

        // Then
        #expect(prompt.contains("Story Structure Requirements"))
        #expect(prompt.contains("Title: [Your Story Title]"))
        #expect(prompt.contains("Divide the story into clear, logical segments"))
    }

    @Test("Prompt includes character development guidelines")
    func testPromptIncludesFormatGuidelines() {
        // Given
        let parameters = StoryParameters(
            childName: "Jordan",
            childAge: 6,
            theme: "Sports",
            favoriteCharacter: "Coach Bear"
        )

        // When
        let prompt = promptBuilder.buildPrompt(parameters: parameters)

        // Then
        #expect(prompt.contains("Format Requirements"))
        #expect(prompt.contains("Use clear paragraph breaks"))
        #expect(prompt.contains("Include dialogue when appropriate"))
    }
}
