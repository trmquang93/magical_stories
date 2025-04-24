import Testing

@testable import magical_stories

struct PromptBuilder_Tests {

    @Test("PromptBuilder should include category instructions")
    func testPromptBuilderIncludesCategoryInstructions() {
        // Arrange
        let promptBuilder = PromptBuilder()
        let parameters = StoryParameters(
            childName: "Alex",
            childAge: 7,
            theme: "Adventure",
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
        #expect(prompt.contains("Return your response as a JSON object"))
        #expect(prompt.contains("\"story\":"))
        #expect(prompt.contains("\"category\":"))
    }

    @Test("PromptBuilder category list matches LibraryView categories")
    func testPromptBuilderCategoryListMatchesLibraryCategories() {
        // Arrange
        let promptBuilder = PromptBuilder()
        let parameters = StoryParameters(
            childName: "Alex",
            childAge: 7,
            theme: "Adventure",
            favoriteCharacter: "Dragon"
        )

        // Act
        let prompt = promptBuilder.buildPrompt(parameters: parameters)

        // Get the category names from LibraryView
        let categoryNames = ["Fantasy", "Animals", "Bedtime", "Adventure"]

        // Assert that all category names are included in the prompt
        for categoryName in categoryNames {
            #expect(
                prompt.contains(categoryName), "Prompt should include category '\(categoryName)'")
        }
    }
}
