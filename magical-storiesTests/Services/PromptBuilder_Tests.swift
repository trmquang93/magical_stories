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
        #expect(prompt.contains("Return your response as XML with the following tags:"))
        #expect(prompt.contains("<content>"))
        #expect(prompt.contains("<category>"))
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

    @Test("PromptBuilder integration: buildPrompt without optional fields")
    func testBuildPromptWithoutOptionalFields() {
        let builder = PromptBuilder()
        let parameters = StoryParameters(
            childName: "Alice",
            childAge: 4,
            theme: "Magic",
            favoriteCharacter: "Rabbit",
            storyLength: "short",
            developmentalFocus: nil,
            emotionalThemes: nil
        )
        let prompt = builder.buildPrompt(parameters: parameters)

        #expect(
            prompt.contains("Create an engaging children's story with the following requirements:"))
        #expect(prompt.contains("Vocabulary Guidelines:"))
        #expect(
            prompt.contains(
                "Use simple, concrete words and short sentences. Repeat key words. Avoid complex tenses."
            ))
        #expect(prompt.contains("Narrative Guidelines:"))
        #expect(prompt.contains("Story Structure Requirements:"))
        #expect(prompt.contains("Category Selection Instructions:"))
        #expect(prompt.contains("Variability Requirements:"))
    }

    @Test("PromptBuilder integration: buildPrompt with optional fields")
    func testBuildPromptWithOptionalFields() {
        let builder = PromptBuilder()
        let focus: [GrowthCategory] = [.cognitiveDevelopment]
        let emotionalThemes = ["Happiness", "Courage"]
        let parameters = StoryParameters(
            childName: "Bob",
            childAge: 6,
            theme: "Adventure",
            favoriteCharacter: "Lion",
            storyLength: "medium",
            developmentalFocus: focus,
            emotionalThemes: emotionalThemes
        )
        let prompt = builder.buildPrompt(parameters: parameters)

        #expect(
            prompt.contains("Create an engaging children's story with the following requirements:"))
        #expect(
            prompt.contains(
                "Use a mix of familiar and new vocabulary. Include some compound sentences. Introduce metaphors sparingly."
            ))
        #expect(
            prompt.contains(
                "Include minor subplots. Show character motivations. Include problem-solving sequences. Balance action and reflection."
            ))
        #expect(prompt.contains("Developmental Focus:"))
        #expect(prompt.contains("Emotional Elements:"))
        #expect(prompt.contains("Category Selection Instructions:"))
    }

    @Test("PromptBuilder integration: buildFallbackIllustrationPrompt")
    func testBuildFallbackIllustrationPrompt() {
        let page1 = Page(content: "The knight approaches the castle.", pageNumber: 1)
        let page2 = Page(content: "A dragon appears in the sky.", pageNumber: 2)
        let page3 = Page(content: "The battle reaches its climax.", pageNumber: 3)
        let pages = [page1, page2, page3]
        let prompt = PromptBuilder.buildFallbackIllustrationPrompt(
            page: page2, pageIndex: 1, pages: pages, theme: "Adventure")

        #expect(prompt.contains("page 2 of 3"))
        #expect(prompt.contains("Previous pages include:"))
        #expect(prompt.contains("Upcoming pages include:"))
        #expect(prompt.contains("Theme: Adventure"))
    }

    @Test("PromptBuilder integration: buildIllustrationDescriptionsPrompt")
    func testBuildIllustrationDescriptionsPrompt() {
        let page1 = Page(
            content: "Once upon a time, a princess explored a mystical forest.", pageNumber: 1)
        let page2 = Page(
            content: "She encountered magical creatures and breathtaking landscapes.", pageNumber: 2
        )
        let pages = [page1, page2]
        let prompt = PromptBuilder.buildIllustrationDescriptionsPrompt(
            theme: "Fantasy", pages: pages)

        #expect(
            prompt.contains(
                "Create detailed, visually consistent illustration descriptions for a children's story."
            ))
        #expect(prompt.contains("THEME: Fantasy"))
        #expect(prompt.contains("TOTAL PAGES: 2"))
        #expect(prompt.contains("FULL STORY CONTENT"))
        #expect(prompt.contains("Return EXACTLY 2 descriptions"))
    }
}
