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
            theme: "Friendship",
            childAge: 4,
            childName: "Emma",
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
        #expect(prompt.contains("Problem Solving"))  // Updated assertion
        #expect(prompt.contains("joy"))
        #expect(prompt.contains("sharing"))
    }

    @Test("Test build prompt for intermediate child")
    func testBuildPromptForIntermediateChild() {
        // Given
        let parameters = StoryParameters(
            theme: "Adventure",
            childAge: 6,
            childName: "Alex",
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
            theme: "Mystery",
            childAge: 8,
            childName: "Maya",
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
            theme: "Nature",
            childAge: 5,
            childName: "Sam",
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
            theme: "Space",
            childAge: 7,
            childName: "Pat",
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
            theme: "Sports",
            childAge: 6,
            childName: "Jordan",
            favoriteCharacter: "Coach Bear"
        )

        // When
        let prompt = promptBuilder.buildPrompt(parameters: parameters)

        // Then
        #expect(prompt.contains("Format Requirements"))
        #expect(prompt.contains("Use clear paragraph breaks"))
        #expect(prompt.contains("Include dialogue when appropriate"))
    }

    @Test("Prompt includes page break delimiter instructions")
    func testPromptIncludesPageBreakDelimiterInstructions() {
        // Given
        let parameters = StoryParameters(
            theme: "Adventure",
            childAge: 5,
            childName: "Jamie",
            favoriteCharacter: "Explorer Fox"
        )

        // When
        let prompt = promptBuilder.buildPrompt(parameters: parameters)

        // Then
        // Check in story structure guidelines
        #expect(
            prompt.contains("Insert \"---\" (three hyphens) on a separate line between segments"))
        #expect(prompt.contains("page breaks"))

        // Check in format guidelines
        #expect(prompt.contains("VERY IMPORTANT: Use \"---\" (three hyphens) on a separate line"))
        #expect(prompt.contains("to indicate where a new page should begin"))
    }

    @Test("PromptBuilder should include category instructions")
    func testPromptBuilderIncludesCategoryInstructions() {
        // Arrange
        let promptBuilder = PromptBuilder()
        let parameters = StoryParameters(
            theme: "Adventure",
            childAge: 7,
            childName: "Alex",
            favoriteCharacter: "Dragon"
        )

        // Act
        let prompt = promptBuilder.buildPrompt(parameters: parameters)

        // Assert
        #expect(
            prompt.contains(
                "After writing the story, analyze its content and select the single most appropriate category"
            ))
        #expect(prompt.contains("Fantasy"))
        #expect(prompt.contains("Animals"))
        #expect(prompt.contains("Bedtime"))
        #expect(prompt.contains("Adventure"))
        #expect(prompt.contains("Return your response as XML with the following tags:"))
        #expect(prompt.contains("<content>"))
        #expect(prompt.contains("<category>"))
    }

    @Test("PromptBuilder category list matches LibraryView categories")
    func testPromptBuilderCategoryListMatchesLibraryCategories() {
        // Arrange
        let promptBuilder = PromptBuilder()
        let parameters = StoryParameters(
            theme: "Adventure",
            childAge: 7,
            childName: "Alex",
            favoriteCharacter: "Dragon"
        )

        // Act
        let prompt = promptBuilder.buildPrompt(parameters: parameters)

        // Get the category names from LibraryView (these are the expected categories)
        let expectedCategoryNames = ["Fantasy", "Animals", "Bedtime", "Adventure"]

        // Assert that all expected category names are included in the prompt
        for categoryName in expectedCategoryNames {
            #expect(
                prompt.contains(categoryName), "Prompt should include category '\(categoryName)'")
        }
    }

    @Test("Prompt includes language instruction")
    func testPromptIncludesLanguageInstruction() {
        // Given
        let parameters = StoryParameters(
            theme: "Magic",
            childAge: 6,
            childName: "Léa",
            favoriteCharacter: "Fairy",
            languageCode: "fr-FR" // French
        )

        // When
        let prompt = promptBuilder.buildPrompt(parameters: parameters)

        // Then
        // Check for the core instruction structure and the language code
        #expect(prompt.contains("- Generate the story in"))
        #expect(prompt.contains("(fr-FR)."))
    }

    @Test("Prompt defaults to English if language code is missing or empty")
    func testPromptDefaultsToEnglish() {
        // Given
        let parameters1 = StoryParameters(
            theme: "Animals",
            childAge: 5,
            childName: "Tom",
            favoriteCharacter: "Lion",
            languageCode: nil // Missing language code
        )
        let parameters2 = StoryParameters(
            theme: "Space",
            childAge: 7,
            childName: "Sue",
            favoriteCharacter: "Astronaut",
            languageCode: "" // Empty language code
        )

        // When
        let prompt1 = promptBuilder.buildPrompt(parameters: parameters1)
        let prompt2 = promptBuilder.buildPrompt(parameters: parameters2)

        // Then
        // Check for the core instruction structure and the language code for both cases
        #expect(prompt1.contains("- Generate the story in"))
        #expect(prompt1.contains("(en-US)."))
        #expect(prompt2.contains("- Generate the story in"))
        #expect(prompt2.contains("(en-US)."))
    }
}
