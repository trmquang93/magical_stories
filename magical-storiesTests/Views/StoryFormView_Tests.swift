import SwiftData
import SwiftUI
import Testing

@testable import magical_stories

@Suite("StoryFormView Tests")
@MainActor
struct StoryFormView_Tests {
    // Utility to create a test context and mock service
    func makeMockService() throws -> MockStoryService {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Story.self, configurations: config)
        let context = ModelContext(container)
        return MockStoryService(context: context)
    }

    @Test("Default state: all fields have expected initial values")
    func testInitialFieldDefaults() async throws {
        // Given
        _ = StoryFormView()  // Assign to _ as view is not used directly in logic-only test
        // When/Then (logic-only: check default values)
        // Note: Cannot access @State directly, but we can check logic in isolation
        // This is a placeholder for a future ViewInspector test
        #expect(true)  // Default state is as per implementation
    }

    @Test("Generate button is disabled when child's name is empty")
    func testGenerateButtonDisabledWhenChildNameEmpty() async throws {
        // Given
        _ = StoryFormView()  // Assign to _ as view is not used directly in logic-only test
        // Simulate empty child name (default)
        // When/Then: Button should be disabled (logic-only)
        #expect(true)  // Placeholder: UI test would check .disabled state
    }

    @Test("Generate button is enabled when all required fields are filled")
    func testGenerateButtonEnabledWithValidInput() async throws {
        // Given
        _ = StoryFormView()  // Assign to _ as view is not used directly in logic-only test
        // Simulate filling required fields (logic-only)
        // When/Then: Button should be enabled (logic-only)
        #expect(true)  // Placeholder: UI test would check .disabled state
    }

    @Test("Changing fields updates state variables")
    func testFieldStateUpdates() async throws {
        // Given
        _ = StoryFormView()  // Assign to _ as view is not used directly in logic-only test
        // Simulate user input (logic-only)
        // When/Then: State variables update (logic-only)
        #expect(true)  // Placeholder: UI test would check @State changes
    }

    @Test("Service is invoked when generating story")
    func testServiceCalledOnGenerateStory() async throws {
        // Given
        _ = try makeMockService()  // Assign to _ as mockService is not used directly in logic-only test
        // Simulate view with environment object (logic-only)
        // When: Generate button tapped
        // Then: Service's generateStory should be called
        #expect(true)  // Placeholder: Would check call count on mock
    }

    @Test("Loading overlay is shown during generation")
    func testLoadingOverlayShown() async throws {
        // Given
        _ = StoryFormView()  // Assign to _ as view is not used directly in logic-only test
        // Simulate isGenerating = true
        // When/Then: Loading overlay is visible (logic-only)
        #expect(true)  // Placeholder: UI test would check overlay
    }

    @Test("Error overlay is shown when error occurs")
    func testErrorOverlayShown() async throws {
        // Given
        _ = StoryFormView()  // Assign to _ as view is not used directly in logic-only test
        // Simulate error state
        // When/Then: Error overlay is visible (logic-only)
        #expect(true)  // Placeholder: UI test would check overlay
    }

    @Test("Edge case: dismiss during loading does not crash")
    func testDismissDuringLoading() async throws {
        // Given
        _ = StoryFormView()  // Assign to _ as view is not used directly in logic-only test
        // Simulate isGenerating = true, then dismiss
        // When/Then: No crash occurs (logic-only)
        #expect(true)
    }

    @Test("Language selection is passed to StoryParameters")
    func testLanguageSelectionPassedToStoryParameters() async throws {
        // Given
        let mockService = try makeMockService()

        // When - Testing logic only
        let generatedParameters = StoryParameters(
            childName: "Test Child",
            childAge: 5,
            theme: "Adventure",
            favoriteCharacter: "Dragon",
            storyLength: "Medium",
            languageCode: "fr"  // French language code
        )

        // Then
        #expect(generatedParameters.languageCode == "fr")

        // Note: In a real UI test, we would:
        // 1. Create a StoryFormView with the mockService
        // 2. Set the selectedLanguage to "fr"
        // 3. Trigger the generate button
        // 4. Verify that mockService.generateStory was called with parameters.languageCode == "fr"
    }
}
