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

        // Generate the prompt using the builder
        let prompt = promptBuilder.buildPrompt(
            childName: parameters.childName,
            childAge: parameters.childAge, // Corrected parameter name
            favoriteCharacter: parameters.favoriteCharacter,
            theme: parameters.theme
        )

        do {
            // --- Actual API Call ---
            let response = try await model.generateContent(prompt) // Actual API call
            guard let text = response.text else { // Actual response handling
                throw StoryServiceError.generationFailed("No content generated")
            }

            // Extract title and content from the actual response
            let (title, content) = try extractTitleAndContent(from: text)

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
            // Log the error
            AIErrorManager.logError(error, source: "StoryService", additionalInfo: "Error in generateStory")
            
            // Catch specific errors if needed, otherwise rethrow a generic generation failure
            if let storyError = error as? StoryServiceError {
                throw storyError // Rethrow known StoryService errors
            } else if let generativeError = error as? GenerateContentError {
                 // Handle specific Google AI errors if necessary
                 let storyError = StoryServiceError.generationFailed("Google AI Error: \(generativeError.localizedDescription)")
                 throw storyError
            } else {
                 // Catch any other errors
                 let storyError = StoryServiceError.generationFailed(error.localizedDescription)
                 throw storyError
            }
        }
    }

    func loadStories() async {
        do {
            // Load stories and sort them immediately (descending by timestamp)
            stories = try persistenceService.loadStories().sorted { $0.timestamp > $1.timestamp }
        } catch {
            AIErrorManager.logError(error, source: "StoryService", additionalInfo: "Failed to load stories")
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
            // If title format is not found, handle it as an error
            let errorMessage = "Invalid story format received from AI (missing 'Title: ' prefix)"
            AIErrorManager.logError(StoryServiceError.generationFailed(errorMessage),
                                   source: "StoryService",
                                   additionalInfo: "Raw response: \(text.prefix(100))...")
            throw StoryServiceError.generationFailed(errorMessage)
        }

        let title = String(titleLine.dropFirst(7)).trimmingCharacters(in: .whitespacesAndNewlines)
        // Ensure content is not empty after removing title
        let contentStartIndex = text.index(text.startIndex, offsetBy: titleLine.count)
        let content = String(text[contentStartIndex...]).trimmingCharacters(in: .whitespacesAndNewlines)

        guard !title.isEmpty else {
             let errorMessage = "Invalid story format received from AI (empty title)"
             AIErrorManager.logError(StoryServiceError.generationFailed(errorMessage), source: "StoryService")
             throw StoryServiceError.generationFailed(errorMessage)
        }
        guard !content.isEmpty else {
             let errorMessage = "Invalid story format received from AI (empty content)"
             AIErrorManager.logError(StoryServiceError.generationFailed(errorMessage), source: "StoryService")
             throw StoryServiceError.generationFailed(errorMessage)
        }


        return (title, content)
    }
}

// MARK: - Prompt Builder
private struct PromptBuilder {
    // Corrected PromptBuilder parameters based on StoryModels.swift
    func buildPrompt(
        childName: String,
        childAge: Int, // Corrected parameter name to match StoryParameters
        favoriteCharacter: String,
        theme: String // Theme is now String
        // language parameter removed
    ) -> String {
        """
        Create a bedtime story for a child with the following parameters:
        - Child's name: \(childName)
        - Age group: \(childAge)
        - Favorite character: \(favoriteCharacter)
        - Theme: \(theme)
        // Language removed

        Requirements:
        1. The story should be appropriate for the age group specified.
        2. Include the child's name (\(childName)) and favorite character (\(favoriteCharacter)) naturally within the narrative.
        3. Convey a positive moral lesson or value related to the theme: '\(theme)'.
        4. Use simple, clear language suitable for the age group. Paragraphs should be relatively short.
        5. Create an engaging, slightly magical, and comforting atmosphere suitable for bedtime.
        6. The story should be approximately 3-5 paragraphs long.
        7. **IMPORTANT FORMATTING:** Start the entire response *immediately* with "Title: " followed by a creative title for the story on the first line.
        8. After the "Title: " line, skip exactly one line (a single newline character) before starting the main content of the story. Do not add any other text before "Title: " or between the title line and the content.

        Example Output Structure:
        Title: The Whispering Shell
        \n
        Once upon a time... (story content starts here)

        Make the story engaging, magical, and appropriate for bedtime reading. Ensure the formatting requirements (Title line, single blank line, content) are strictly followed.
        """
    }
}
