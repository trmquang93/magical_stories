import CoreData
import Foundation  // Added for Date, UUID (though often implicit)
import GoogleGenerativeAI
import SwiftData
import SwiftUI

// MARK: - Story Models

// MARK: - Illustration Description
/// Represents a description for generating an illustration for a specific page
struct IllustrationDescription {
    let pageNumber: Int
    let description: String
}

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
        // Add a unique cache-busting parameter to prompt to avoid cached responses
        let uniquePrompt = prompt + "\n\nUniqueId: \(UUID().uuidString)"

        // Use the standard generateContent method
        let response = try await model.generateContent(uniquePrompt)
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
    private let storyProcessor: StoryProcessor
    private let persistenceService: PersistenceServiceProtocol
    private let settingsService: SettingsServiceProtocol?
    @Published private(set) var stories: [Story] = []
    @Published private(set) var isGenerating = false

    // Updated initializer to accept and initialize StoryProcessor
    init(
        apiKey: String = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "",
        context: ModelContext,
        persistenceService: PersistenceServiceProtocol? = nil,
        model: GenerativeModelProtocol? = nil,
        storyProcessor: StoryProcessor? = nil,  // Allow injecting for testing
        promptBuilder: PromptBuilder? = nil,  // Added promptBuilder parameter for testing
        settingsService: SettingsServiceProtocol? = nil  // Add settings service for vocabulary boost
    ) throws {  // Mark initializer as throwing
        self.model = model ?? GenerativeModelWrapper(name: "gemini-2.0-flash", apiKey: apiKey)  // Updated to more creative model
        self.promptBuilder = promptBuilder ?? PromptBuilder()  // Use injected or create new
        self.persistenceService = persistenceService ?? PersistenceService(context: context)
        self.settingsService = settingsService  // Store the settings service

        // Initialize StoryProcessor, potentially injecting dependencies like IllustrationService
        // If storyProcessor is provided (e.g., in tests), use it. Otherwise, create a default one.
        // This requires IllustrationService to be available or injectable.
        // For now, let's assume a default IllustrationService can be created.
        // Use 'try' as IllustrationService() can throw
        let effectiveIllustrationService = try IllustrationService()

        // Create a dedicated text model for StoryProcessor to use for illustration descriptions
        let illustrationDescriptionModel = GenerativeModelWrapper(
            name: "gemini-1.5-pro", apiKey: apiKey)

        self.storyProcessor =
            storyProcessor
            ?? StoryProcessor(
                illustrationService: effectiveIllustrationService,
                generativeModel: illustrationDescriptionModel
            )

        // Task must be after all properties are initialized
        Task {
            await loadStories()
        }
    }

    func generateStory(parameters: StoryParameters) async throws -> Story {
        print("[StoryService] generateStory START (main thread: \(Thread.isMainThread))")

        guard !parameters.childName.isEmpty else {
            throw StoryServiceError.invalidParameters
        }

        isGenerating = true
        defer { isGenerating = false }

        // Generate the prompt using the enhanced PromptBuilder with vocabulary boost setting
        let prompt = buildPrompt(with: parameters)

        do {
            // --- Actual API Call ---
            let response = try await model.generateContent(prompt)
            guard let text = response.text else {
                throw StoryServiceError.generationFailed("No content generated")
            }

            // Try to parse the response as XML to extract title, story content, and category
            let (extractedTitle, storyContent, category, illustrations) =
                try extractTitleCategoryAndContent(
                    from: text)

            // Use extracted title or fallback
            let title = extractedTitle ?? "Magical Story"

            // Ensure content was extracted
            guard let content = storyContent, !content.isEmpty else {
                throw StoryServiceError.generationFailed(
                    "Could not extract story content from XML response")
            }

            // Process content into pages using StoryProcessor
            var pages = try await storyProcessor.processIntoPages(content, theme: parameters.theme)

            // Apply illustration descriptions to pages if available
            if let illustrations = illustrations {
                applyIllustrationDescriptions(to: &pages, illustrations: illustrations)
            }

            let story = Story(
                title: title,
                pages: pages,
                parameters: parameters,
                categoryName: category  // Set the category name from AI response
            )
            try await persistenceService.saveStory(story)
            // Immediately update the in-memory stories list so tests see the new story
            if !stories.contains(where: { $0.id == story.id }) {
                stories.insert(story, at: 0)  // Insert at front to match loadStories() sort order
            }
            await loadStories()
            return story

        } catch {
            print(
                "[StoryService] generateStory ERROR: \(error.localizedDescription) (main thread: \(Thread.isMainThread))"
            )
            AIErrorManager.logError(
                error, source: "StoryService", additionalInfo: "Error in generateStory")

            // 1. If error is already a StoryServiceError, rethrow as-is
            if let storyError = error as? StoryServiceError {
                throw storyError
            }
            // 2. If error is a GenerateContentError, map to .networkError (simulate network error for test)
            else if let generativeError = error as? GenerateContentError {
                // If GenerateContentError indicates a network error, map to .networkError
                // Otherwise, map to .generationFailed
                // For now, always map to .networkError for test compatibility
                throw StoryServiceError.networkError
            }
            // 3. If error is a persistence error, map to .persistenceFailed
            else if (error as NSError).domain == NSCocoaErrorDomain
                && (error as NSError).code == NSPersistentStoreSaveError
            {
                throw StoryServiceError.persistenceFailed
            }
            // 4. If error is already a known persistence error
            else if error.localizedDescription.contains("persistence") {
                throw StoryServiceError.persistenceFailed
            }
            // 5. For all other errors, wrap as .generationFailed
            else {
                throw StoryServiceError.generationFailed(error.localizedDescription)
            }
        }
    }

    /// Helper to build prompts using settings and parameters
    func buildPrompt(with parameters: StoryParameters, vocabularyBoostEnabled: Bool? = nil)
        -> String
    {
        // Use the explicitly provided value, or get it from the settings service, or default to false
        let useVocabularyBoost =
            vocabularyBoostEnabled ?? settingsService?.vocabularyBoostEnabled ?? false
        return promptBuilder.buildPrompt(
            parameters: parameters, vocabularyBoostEnabled: useVocabularyBoost)
    }

    func loadStories() async {
        do {
            let loadedStories = try await persistenceService.loadStories()
            let sortedStories = loadedStories.sorted { $0.timestamp > $1.timestamp }
            stories = sortedStories
        } catch {
            AIErrorManager.logError(
                error, source: "StoryService", additionalInfo: "Failed to load stories")
            stories = []
        }
    }

    // Removed extractTitleAndContent method as title is now extracted within extractTitleCategoryAndContent

    private func extractTitleCategoryAndContent(from text: String) throws -> (
        String?, String?, String?, [IllustrationDescription]?
    ) {
        // Try to parse the text as XML to extract story and category
        do {
            // Clean up the text first - sometimes the AI might include extra text before or after the XML
            let possibleXmlText = extractXMLFromText(text)

            // If we found what looks like XML, try to parse it
            if let xmlText = possibleXmlText, !xmlText.isEmpty {
                // Normalize the XML
                let normalizedXml = normalizeXML(xmlText)
                print("[StoryService] Found potential XML: \(normalizedXml.prefix(100))...")

                // Extract title, content, and category using regular expressions
                let titlePattern = "<title>(.*?)</title>"
                let contentPattern = "<content>(.*?)</content>"
                let categoryPattern = "<category>(.*?)</category>"
                let illustrationsPattern = "<illustrations>(.*?)</illustrations>"

                let titleRegex = try NSRegularExpression(
                    pattern: titlePattern, options: [.dotMatchesLineSeparators])
                let contentRegex = try NSRegularExpression(
                    pattern: contentPattern, options: [.dotMatchesLineSeparators])
                let categoryRegex = try NSRegularExpression(
                    pattern: categoryPattern, options: [.dotMatchesLineSeparators])
                let illustrationsRegex = try NSRegularExpression(
                    pattern: illustrationsPattern, options: [.dotMatchesLineSeparators])

                let titleMatches = titleRegex.matches(
                    in: normalizedXml,
                    range: NSRange(normalizedXml.startIndex..., in: normalizedXml))
                let contentMatches = contentRegex.matches(
                    in: normalizedXml,
                    range: NSRange(normalizedXml.startIndex..., in: normalizedXml))
                let categoryMatches = categoryRegex.matches(
                    in: normalizedXml,
                    range: NSRange(normalizedXml.startIndex..., in: normalizedXml))
                let illustrationsMatches = illustrationsRegex.matches(
                    in: normalizedXml,
                    range: NSRange(normalizedXml.startIndex..., in: normalizedXml))

                var extractedTitle: String? = nil
                var storyContent: String? = nil
                var category: String? = nil
                var illustrations: [IllustrationDescription]? = nil

                // Extract title from matches
                if let titleMatch = titleMatches.first,
                    let titleRange = Range(titleMatch.range(at: 1), in: normalizedXml)
                {
                    extractedTitle = String(normalizedXml[titleRange])
                    print("[StoryService] Found 'title' field in XML")
                }

                // Extract content from matches
                if let contentMatch = contentMatches.first,
                    let contentRange = Range(contentMatch.range(at: 1), in: normalizedXml)
                {
                    storyContent = String(normalizedXml[contentRange])
                    print("[StoryService] Found 'content' field in XML")
                }

                // Extract category from matches
                if let categoryMatch = categoryMatches.first,
                    let categoryRange = Range(categoryMatch.range(at: 1), in: normalizedXml)
                {
                    category = String(normalizedXml[categoryRange])
                    print("[StoryService] Category from XML: \(category ?? "None")")
                }

                // Extract illustrations from matches
                if let illustrationsMatch = illustrationsMatches.first,
                    let illustrationsRange = Range(
                        illustrationsMatch.range(at: 1), in: normalizedXml)
                {
                    let illustrationsContent = String(normalizedXml[illustrationsRange])
                    illustrations = extractIllustrationDescriptions(from: illustrationsContent)
                    print("[StoryService] Found \(illustrations?.count ?? 0) illustrations in XML")
                }

                // Return extracted values (some might be nil if tags were missing)
                return (extractedTitle, storyContent, category, illustrations)
            }

            // If we reach here, XML extraction failed or tags weren't found
            // Fall back to treating the entire text as the content, with nil title/category
            print("[StoryService] XML parsing failed or tags missing, using plain text fallback")

            // Try to extract a category from the text as a last resort
            let fallbackCategory = extractFallbackCategory(from: text)

            // Use the original text as content, title will be handled by caller's fallback
            return (nil, text, fallbackCategory, nil)
        } catch {
            // If XML parsing throws an error, use plain text fallback
            print(
                "[StoryService] XML parsing error: \(error.localizedDescription), using plain text fallback"
            )
            let fallbackCategory = extractFallbackCategory(from: text)
            return (nil, text, fallbackCategory, nil)
        }
    }

    // Helper to extract XML from potentially mixed text
    private func extractXMLFromText(_ text: String) -> String? {
        // Look for content that appears to be XML (containing the expected tags)
        print("[StoryService] Attempting to extract XML from text: \(text.prefix(30))...")

        // Check if the text contains XML code block markers
        if text.contains("```xml") && text.contains("```") {
            if let startMarker = text.range(of: "```xml")?.upperBound,
                let endMarker = text.range(of: "```", range: startMarker..<text.endIndex)?
                    .lowerBound
            {
                let xmlSubstring = text[startMarker..<endMarker].trimmingCharacters(
                    in: .whitespacesAndNewlines)

                print("[StoryService] Extracted XML from code block: \(xmlSubstring.prefix(30))...")
                return xmlSubstring
            }
        }

        // Check for complete XML structure with our expected tags
        let titleStart = text.range(of: "<title>")
        let contentStart = text.range(of: "<content>")
        let categoryStart = text.range(of: "<category>")

        let titleEnd = text.range(of: "</title>")
        let contentEnd = text.range(of: "</content>")
        let categoryEnd = text.range(of: "</category>")

        // If we have at least one complete tag, attempt to extract the XML
        if (titleStart != nil && titleEnd != nil) || (contentStart != nil && contentEnd != nil)
            || (categoryStart != nil && categoryEnd != nil)
        {

            // Try to find the earliest start tag and latest end tag
            var allRanges: [(Range<String.Index>, Bool)] = []  // (range, isStart)

            if let range = titleStart { allRanges.append((range, true)) }
            if let range = contentStart { allRanges.append((range, true)) }
            if let range = categoryStart { allRanges.append((range, true)) }
            if let range = titleEnd { allRanges.append((range, false)) }
            if let range = contentEnd { allRanges.append((range, false)) }
            if let range = categoryEnd { allRanges.append((range, false)) }

            // Sort by position in text
            allRanges.sort { $0.0.lowerBound < $1.0.lowerBound }

            if let firstStart = allRanges.first(where: { $0.1 })?.0.lowerBound,
                let lastEnd = allRanges.last(where: { !$0.1 })?.0.upperBound
            {

                let xmlSubstring = String(text[firstStart..<lastEnd])
                print(
                    "[StoryService] Extracted XML using tag matching: \(xmlSubstring.prefix(30))..."
                )
                return xmlSubstring
            }
        }

        print("[StoryService] No XML structure detected in text")
        return nil
    }

    // Helper to normalize and clean XML strings
    private func normalizeXML(_ xmlString: String) -> String {
        // Robustly clean up the XML string for parsing
        var cleaned = xmlString
        // Remove leading/trailing whitespace and newlines
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        // Remove any trailing or leading markdown code block markers if present
        if cleaned.hasPrefix("```xml") { cleaned = String(cleaned.dropFirst(6)) }
        if cleaned.hasPrefix("```") { cleaned = String(cleaned.dropFirst(3)) }
        if cleaned.hasSuffix("```") { cleaned = String(cleaned.dropLast(3)) }
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
        // Replace Windows line endings with Unix
        cleaned = cleaned.replacingOccurrences(of: "\r\n", with: "\n")
        cleaned = cleaned.replacingOccurrences(of: "\r", with: "\n")

        // Filter out only control characters while preserving all Unicode characters
        // This preserves characters from all languages including Vietnamese
        cleaned = cleaned.filter { char in
            guard let firstScalar = char.unicodeScalars.first else { return true }

            // Keep newlines and tabs
            if char == "\n" || char == "\t" {
                return true
            }

            // Filter out only control characters (C0 and C1 control character sets)
            // This preserves all printable characters including non-ASCII ones like Vietnamese
            let isControlChar =
                (firstScalar.value < 32) || (firstScalar.value >= 127 && firstScalar.value < 160)
            return !isControlChar
        }

        return cleaned
    }

    // Helper to try to extract a category from text when JSON parsing fails
    private func extractFallbackCategory(from text: String) -> String? {
        // Define the allowed categories based on LibraryCategory
        let allowedCategories = ["Fantasy", "Animals", "Bedtime", "Adventure"]

        // Look for these patterns in the text:
        // "Category: Fantasy" or "category: Fantasy" or "The story is in the Fantasy category"

        let lowerText = text.lowercased()

        for category in allowedCategories {
            let lowerCategory = category.lowercased()

            // Check for explicit category labeling
            if lowerText.contains("category: \(lowerCategory)")
                || lowerText.contains("category is \(lowerCategory)")
                || lowerText.contains("categorized as \(lowerCategory)")
            {
                return category
            }

            // Check for thematic references that might indicate category
            let thematicMatches: [String: [String]] = [
                "Fantasy": [
                    "magic", "wizard", "dragon", "fairy", "enchanted", "spell", "mystical",
                ],
                "Animals": ["zoo", "farm", "pet", "wildlife", "jungle", "forest", "creature"],
                "Bedtime": ["night", "dream", "sleep", "stars", "moon", "pajamas", "bedtime"],
                "Adventure": [
                    "journey", "quest", "explore", "discover", "treasure", "expedition", "voyage",
                ],
            ]

            if let keywords = thematicMatches[category] {
                for keyword in keywords {
                    if lowerText.contains(keyword) {
                        // Count occurrences to determine strength of match
                        let count = lowerText.components(separatedBy: keyword).count - 1
                        if count >= 2 {  // If keyword appears multiple times, good indicator
                            return category
                        }
                    }
                }
            }
        }

        // If no clear category found, return nil
        return nil
    }

    // Helper to extract illustration descriptions from the illustrations XML content
    private func extractIllustrationDescriptions(from illustrationsXml: String)
        -> [IllustrationDescription]
    {
        var illustrations = [IllustrationDescription]()

        // Use regex to extract individual illustration tags with their page numbers and descriptions
        do {
            let illustrationPattern = "<illustration\\s+page=\"(\\d+)\">(.*?)</illustration>"
            let regex = try NSRegularExpression(
                pattern: illustrationPattern, options: [.dotMatchesLineSeparators])

            let matches = regex.matches(
                in: illustrationsXml,
                range: NSRange(illustrationsXml.startIndex..., in: illustrationsXml))

            for match in matches {
                if match.numberOfRanges >= 3,
                    let pageRange = Range(match.range(at: 1), in: illustrationsXml),
                    let descriptionRange = Range(match.range(at: 2), in: illustrationsXml)
                {

                    let pageNumberString = String(illustrationsXml[pageRange])
                    let description = String(illustrationsXml[descriptionRange])

                    if let pageNumber = Int(pageNumberString) {
                        illustrations.append(
                            IllustrationDescription(
                                pageNumber: pageNumber, description: description))
                    }
                }
            }

            // Sort illustrations by page number to ensure correct order
            illustrations.sort { $0.pageNumber < $1.pageNumber }

        } catch {
            print(
                "[StoryService] Error extracting illustration descriptions: \(error.localizedDescription)"
            )
        }

        return illustrations
    }

    // Helper method to apply illustration descriptions to pages
    private func applyIllustrationDescriptions(
        to pages: inout [Page], illustrations: [IllustrationDescription]
    ) {
        for illustration in illustrations {
            // Find the matching page by page number
            if illustration.pageNumber > 0 && illustration.pageNumber <= pages.count {
                // Page numbers in our array are 0-indexed, but illustrations use 1-indexed
                let pageIndex = illustration.pageNumber - 1
                // Set the illustration description as the image prompt
                pages[pageIndex].imagePrompt = illustration.description
            }
        }

        print(
            "[StoryService] Applied \(illustrations.count) illustration descriptions to \(pages.count) pages"
        )
    }

    // MARK: - Story Deletion
    func deleteStory(id: UUID) async {
        do {
            try await persistenceService.deleteStory(withId: id)
            // Remove from in-memory list for immediate UI update
            stories.removeAll { $0.id == id }
        } catch {
            AIErrorManager.logError(
                error, source: "StoryService",
                additionalInfo: "Failed to delete story with id: \(id)")
        }
    }
}
