import Foundation // Added for Date, UUID (though often implicit)
import GoogleGenerativeAI
import SwiftData
import SwiftUI

// MARK: - Story Models


// MARK: - Story Service Errors
enum StoryServiceError: LocalizedError, Equatable {
    case generationFailed(String)
    case invalidParameters
    case persistenceFailed
    case networkError

    var errorDescription: String? {
        switch self {
        case .generationFailed(let message):
            return "Failed to generate story: \(message)"
        case .invalidParameters:
            return "Invalid story parameters provided"
        case .persistenceFailed:
            return "Failed to save or load story"
        case .networkError:
            return "Network error occurred"
        }
    }
}

// MARK: - Response Types
protocol StoryGenerationResponse {
    var text: String? { get }
}

// MARK: - Generative Model Protocol
protocol GenerativeModelProtocol {
    func generateContent(_ prompt: String) async throws -> StoryGenerationResponse
}

// MARK: - Generative Model Wrapper
class GenerativeModelWrapper: GenerativeModelProtocol {
    private let model: GenerativeModel

    init(name: String, apiKey: String) {
        self.model = GenerativeModel(name: name, apiKey: apiKey)
    }

    func generateContent(_ prompt: String) async throws -> StoryGenerationResponse {
        let response = try await model.generateContent(prompt)
        return StoryGenerationResponseWrapper(response: response)
    }
}

private struct StoryGenerationResponseWrapper: StoryGenerationResponse {
    let response: GoogleGenerativeAI.GenerateContentResponse

    var text: String? {
        return response.text
    }
}

// MARK: - Story Service
@MainActor
class StoryService: ObservableObject {
    private let model: GenerativeModelProtocol
    private let promptBuilder: PromptBuilder
    private let persistenceService: PersistenceServiceProtocol
    private let storyProcessor: StoryProcessor // Added StoryProcessor

    @Published private(set) var stories: [Story] = []
    @Published private(set) var isGenerating = false

    // Updated initializer to accept and initialize StoryProcessor
    init(
        apiKey: String = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "",
        persistenceService: PersistenceServiceProtocol = PersistenceService(),
        model: GenerativeModelProtocol? = nil,
        storyProcessor: StoryProcessor? = nil // Allow injecting for testing
    ) throws { // Mark initializer as throwing
        self.model = model ?? GenerativeModelWrapper(name: "gemini-1.5-flash", apiKey: apiKey) // Updated model name
        self.promptBuilder = PromptBuilder()
        self.persistenceService = persistenceService

        // Initialize StoryProcessor, potentially injecting dependencies like IllustrationService
        // If storyProcessor is provided (e.g., in tests), use it. Otherwise, create a default one.
        // This requires IllustrationService to be available or injectable.
        // For now, let's assume a default IllustrationService can be created.
        // TODO: Improve dependency injection for IllustrationService if needed.
        // Use 'try' as IllustrationService() can throw
        let effectiveIllustrationService = try IllustrationService()
        self.storyProcessor = storyProcessor ?? StoryProcessor(illustrationService: effectiveIllustrationService)

        // Task must be after all properties are initialized
        Task {
            await loadStories()
        }
    }

    func generateStory(parameters: StoryParameters) async throws -> Story {
        guard !parameters.childName.isEmpty else {
            throw StoryServiceError.invalidParameters
        }

        isGenerating = true
        defer { isGenerating = false }

        do {
            // Corrected parameters based on StoryModels.swift
            // The prompt variable was removed as it's unused due to the simulated API response below.
            // If the actual API call (line 118) is re-enabled, the prompt generation needs to be uncommented/restored.

            // --- Placeholder API Call ---
            // Simulate network delay
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay

            // Simulate a successful API response string
            // TODO: Replace this with the actual API call to Google AI (Gemini Pro)
            let simulatedApiResponse = """
            Title: The Magical Forest Adventure
            Content: Once upon a time, in a land not far away, lived a brave child named \(parameters.childName). \(parameters.childName) loved exploring with their favorite friend, \(parameters.favoriteCharacter). One sunny morning, they ventured into the Whispering Woods, following a path sparkling with dew.

            Deep in the woods, they found a talking squirrel who needed help finding his hidden acorns before the rain came. Remembering the theme of '\(parameters.theme)', \(parameters.childName) knew that helping others was important. Working together, \(parameters.childName) and \(parameters.favoriteCharacter) helped the squirrel gather all his acorns just as the first drops began to fall.

            The squirrel thanked them warmly, and \(parameters.childName) felt happy knowing they had done a good deed. As they walked home, the forest seemed even more magical, filled with the glow of kindness.
            """
            // let response = try await model.generateContent(prompt) // Actual API call commented out
            // guard let text = response.text else { // Actual response handling commented out
            //     throw StoryServiceError.generationFailed("No content generated")
            // }

            // Extract title and content from the *simulated* response
            let (title, content) = try extractTitleAndContent(from: simulatedApiResponse)

            // Process content into pages using StoryProcessor
            let pages = try await storyProcessor.processIntoPages(content, theme: parameters.theme)

            // Use the primary Story initializer with the generated pages
            let story = Story(
                title: title,
                pages: pages, // Use the processed pages array
                parameters: parameters // Pass the whole parameters object
                // timestamp defaults to Date()
            )

            // Save the new story using the persistence service
            try persistenceService.saveStory(story)

            // Reload stories to update the @Published array
            await loadStories()

            return story

        } catch {
            throw StoryServiceError.generationFailed(error.localizedDescription)
        }
    }

    func loadStories() async {
        do {
            // Load stories and sort them immediately (descending by timestamp)
            stories = try persistenceService.loadStories().sorted { $0.timestamp > $1.timestamp }
        } catch {
            print("Failed to load stories: \(error)")
            stories = []
        }
    }


    private func extractTitleAndContent(from text: String) throws -> (String, String) {
        // Assuming the AI returns the story in a format like:
        // Title: The Great Adventure
        // Content: Once upon a time...

        let components = text.components(separatedBy: "\n")
        guard components.count >= 2,
            let titleLine = components.first,
            titleLine.hasPrefix("Title: ")
        else {
            throw StoryServiceError.generationFailed("Invalid story format")
        }

        let title = String(titleLine.dropFirst(7))
        let content = components.dropFirst().joined(separator: "\n").trimmingCharacters(
            in: .whitespacesAndNewlines)

        return (title, content)
    }
}

// MARK: - Prompt Builder
private struct PromptBuilder {
    // Corrected PromptBuilder parameters based on StoryModels.swift
    func buildPrompt(
        childName: String,
        ageGroup: Int, // Renamed from ageGroup to match StoryParameters
        favoriteCharacter: String,
        theme: String // Theme is now String
        // language parameter removed
    ) -> String {
        """
        Create a bedtime story for a child with the following parameters:
        - Child's name: \(childName)
        - Age group: \(ageGroup)
        - Favorite character: \(favoriteCharacter)
        - Theme: \(theme)
        // Language removed

        Requirements:
        1. The story should be appropriate for the age group
        2. Include the child's name and favorite character in the story
        3. Convey a moral lesson related to the theme
        4. Use simple language and short paragraphs
        5. Create an engaging and magical atmosphere
        6. The story should be 3-5 paragraphs long
        7. Start with "Title: " followed by a creative title
        8. Skip a line after the title before starting the story

        Make the story engaging, magical, and appropriate for bedtime reading.
        """
    }
}
