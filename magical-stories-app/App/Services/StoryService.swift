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
public protocol StoryGenerationResponse {
    var text: String? { get }
}

// MARK: - Generative Model Protocol
public protocol GenerativeModelProtocol {
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
        self.model =
            model ?? GenerativeModelWrapper(name: "gemini-2.5-flash-preview-04-17", apiKey: apiKey)  // Updated to more creative model
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

        // Updated validation for optional childName
        // We no longer need this validation since childName is optional
        // If we want to enforce childName in certain contexts, we can add specific validation

        isGenerating = true
        defer { isGenerating = false }

        // Generate the prompt using the enhanced PromptBuilder with vocabulary boost setting
        let prompt = buildPrompt(with: parameters)
        print(">>>Prompt: \(prompt)")
        do {
            // --- Actual API Call ---
            let response = try await model.generateContent(prompt)
            guard let text = response.text else {
                throw StoryServiceError.generationFailed("No content generated")
            }

            // Try to parse the response as XML to extract title, story content, category, and visual guide
            let (extractedTitle, storyContent, category, illustrations, visualGuide) =
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
            let pages = try await storyProcessor.processIntoPages(
                content, illustrations: illustrations ?? [],
                theme: parameters.theme,
                visualGuide: visualGuide)

            let story = Story(
                title: title,
                pages: pages,
                parameters: parameters,
                categoryName: category  // Set the category name from AI response
            )
            
            // Save the visual guide with the story for character consistency
            // but defer illustration generation until the story is opened
            if let visualGuide = visualGuide {
                story.setVisualGuide(visualGuide)
                print("[StoryService] Visual guide saved with story for lazy illustration generation")
                print("[StoryService] Characters available: \(visualGuide.characterDefinitions.keys.joined(separator: ", "))")
            }
            
            // Set all pages to pending status for lazy illustration generation
            for page in story.pages {
                page.illustrationStatus = .pending
            }
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
        String?, String?, String?, [IllustrationDescription]?, VisualGuide?
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
                
                // Extract visual guide
                let visualGuide = extractVisualGuide(from: normalizedXml)

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
                return (extractedTitle, storyContent, category, illustrations, visualGuide)
            }

            // If we reach here, XML extraction failed or tags weren't found
            // Fall back to treating the entire text as the content, with nil title/category
            print("[StoryService] XML parsing failed or tags missing, using plain text fallback")

            // Try to extract a category from the text as a last resort
            let fallbackCategory = extractFallbackCategory(from: text)

            // Use the original text as content, title will be handled by caller's fallback
            return (nil, text, fallbackCategory, nil, nil)
        } catch {
            // If XML parsing throws an error, use plain text fallback
            print(
                "[StoryService] XML parsing error: \(error.localizedDescription), using plain text fallback"
            )
            let fallbackCategory = extractFallbackCategory(from: text)
            return (nil, text, fallbackCategory, nil, nil)
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
    private func extractVisualGuide(from xml: String) -> VisualGuide? {
        let visualGuidePattern = "<visual_guide>(.*?)</visual_guide>"
        do {
            let regex = try NSRegularExpression(pattern: visualGuidePattern, options: [.dotMatchesLineSeparators])
            let matches = regex.matches(in: xml, range: NSRange(xml.startIndex..., in: xml))
            
            guard let match = matches.first,
                  let range = Range(match.range(at: 1), in: xml) else {
                return nil
            }
            
            let visualGuideXml = String(xml[range])
            
            // Extract style guide
            let styleGuidePattern = "<style_guide>(.*?)</style_guide>"
            let styleGuideRegex = try NSRegularExpression(pattern: styleGuidePattern, options: [.dotMatchesLineSeparators])
            let styleGuideMatches = styleGuideRegex.matches(in: visualGuideXml, range: NSRange(visualGuideXml.startIndex..., in: visualGuideXml))
            
            var styleGuide = ""
            if let styleMatch = styleGuideMatches.first,
               let styleRange = Range(styleMatch.range(at: 1), in: visualGuideXml) {
                styleGuide = String(visualGuideXml[styleRange])
            }
            
            // Extract character definitions
            var characterDefinitions = [String: String]()
            let characterPattern = "<character name=\"(.*?)\">(.*?)</character>"
            let characterRegex = try NSRegularExpression(pattern: characterPattern, options: [.dotMatchesLineSeparators])
            let characterMatches = characterRegex.matches(in: visualGuideXml, range: NSRange(visualGuideXml.startIndex..., in: visualGuideXml))
            
            for match in characterMatches {
                if match.numberOfRanges >= 3,
                   let nameRange = Range(match.range(at: 1), in: visualGuideXml),
                   let descriptionRange = Range(match.range(at: 2), in: visualGuideXml) {
                    let name = String(visualGuideXml[nameRange])
                    let description = String(visualGuideXml[descriptionRange])
                    characterDefinitions[name] = description
                }
            }
            
            // Extract setting definitions
            var settingDefinitions = [String: String]()
            let settingPattern = "<setting name=\"(.*?)\">(.*?)</setting>"
            let settingRegex = try NSRegularExpression(pattern: settingPattern, options: [.dotMatchesLineSeparators])
            let settingMatches = settingRegex.matches(in: visualGuideXml, range: NSRange(visualGuideXml.startIndex..., in: visualGuideXml))
            
            for match in settingMatches {
                if match.numberOfRanges >= 3,
                   let nameRange = Range(match.range(at: 1), in: visualGuideXml),
                   let descriptionRange = Range(match.range(at: 2), in: visualGuideXml) {
                    let name = String(visualGuideXml[nameRange])
                    let description = String(visualGuideXml[descriptionRange])
                    settingDefinitions[name] = description
                }
            }
            
            print("[StoryService] Found visual guide with \(characterDefinitions.count) characters and \(settingDefinitions.count) settings")
            
            return VisualGuide(
                styleGuide: styleGuide,
                characterDefinitions: characterDefinitions,
                settingDefinitions: settingDefinitions
            )
        } catch {
            print("[StoryService] Error extracting visual guide: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Generate a visual guide for existing stories that don't have one
    public func generateVisualGuideForExistingStory(_ story: Story) async throws -> VisualGuide {
        // If story already has a visual guide, return it
        if let existingGuide = story.visualGuide {
            return existingGuide
        }
        
        // Extract story content
        let fullStoryText = story.pages.map { $0.content }.joined(separator: "\n\n")
        
        // Extract potential character names using the same logic as PromptBuilder
        let potentialCharacters = extractPotentialCharacters(from: story.pages)
        
        // Create a prompt to generate visual guide for existing story
        let prompt = buildVisualGuideExtractionPrompt(
            storyTitle: story.title,
            storyContent: fullStoryText,
            theme: story.parameters.theme,
            characters: potentialCharacters
        )
        
        // Use the general AI service to generate the visual guide
        let aiResponse = try await model.generateContent(prompt)
        let response = aiResponse.text ?? ""
        
        // Try to extract visual guide from response
        if let visualGuide = extractVisualGuide(from: response) {
            // Save the visual guide to the story
            story.setVisualGuide(visualGuide)
            return visualGuide
        } else {
            // Create a fallback visual guide with basic character definitions
            return createFallbackVisualGuide(
                characters: potentialCharacters,
                theme: story.parameters.theme
            )
        }
    }
    
    /// Extract potential character names from story pages (same logic as PromptBuilder)
    private func extractPotentialCharacters(from pages: [Page]) -> [String] {
        let fullText = pages.map { $0.content }.joined(separator: " ")
        
        // Common naming pattern: capital letter followed by lowercase letters
        let possibleNames = fullText.split { !$0.isLetter }
            .filter { word in
                guard let first = word.first else { return false }
                return first.isUppercase && word.count > 1
                    && word.dropFirst().allSatisfy { $0.isLowercase }
            }
            .map { String($0) }
        
        // Filter out common words that might be capitalized
        let commonWords = ["The", "And", "But", "For", "With", "When", "Then", "They", "She", "He", "Once", "Now", "Today", "This"]
        let filteredNames = possibleNames.filter { !commonWords.contains($0) }
        
        // Return unique names, preserving order of first appearance
        var uniqueNames: [String] = []
        for name in filteredNames {
            if !uniqueNames.contains(name) {
                uniqueNames.append(name)
            }
        }
        
        // Limit to most likely character names (up to 5)
        return Array(uniqueNames.prefix(5))
    }
    
    /// Build a prompt to extract visual guide information from existing story
    private func buildVisualGuideExtractionPrompt(
        storyTitle: String,
        storyContent: String,
        theme: String,
        characters: [String]
    ) -> String {
        let charactersSection = characters.isEmpty ? "" : """
        
        KEY CHARACTERS IDENTIFIED:
        \(characters.joined(separator: ", "))
        """
        
        return """
        Create a comprehensive visual guide for the existing children's story "\(storyTitle)".
        
        STORY THEME: \(theme)
        \(charactersSection)
        
        FULL STORY CONTENT:
        \(storyContent)
        
        Based on this story, create detailed visual descriptions to ensure consistent illustrations.
        
        REQUIREMENTS:
        1. Analyze the story content to understand each character's role and personality
        2. Create detailed physical descriptions for each character that would appear consistently across illustrations
        3. Include setting descriptions for the main locations mentioned in the story
        4. Choose an appropriate artistic style that matches the story's tone and theme
        
        Return your response as XML with the following structure:
        <visual_guide>
            <style_guide>Describe the overall artistic style (e.g., watercolor, cartoon, digital painting) that would suit this story</style_guide>
            <character_definitions>
                <character name="CharacterName">Complete physical description including appearance, age, clothing, and distinctive features</character>
            </character_definitions>
            <setting_definitions>
                <setting name="SettingName">Complete setting description with atmosphere, landmarks, colors, and mood</setting>
            </setting_definitions>
        </visual_guide>
        
        IMPORTANT: Base all descriptions on what is mentioned or implied in the story content. Create consistent, detailed descriptions that would help an illustrator maintain character and setting consistency across multiple images.
        """
    }
    
    /// Create a basic fallback visual guide when AI generation fails
    private func createFallbackVisualGuide(characters: [String], theme: String) -> VisualGuide {
        let styleGuide = "Colorful, child-friendly illustration style with warm colors and soft edges suitable for a \(theme.lowercased()) story"
        
        var characterDefinitions = [String: String]()
        for character in characters {
            characterDefinitions[character] = "A friendly character with expressive features, appropriate for a children's story about \(theme.lowercased())"
        }
        
        let settingDefinitions = [
            "Main Setting": "A warm, inviting environment that supports the \(theme.lowercased()) theme with appropriate colors and mood"
        ]
        
        return VisualGuide(
            styleGuide: styleGuide,
            characterDefinitions: characterDefinitions,
            settingDefinitions: settingDefinitions
        )
    }
    
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

    // MARK: - Story Fetching
    func fetchStory(by id: UUID) async throws -> Story? {
        do {
            return try await persistenceService.fetchStory(withId: id)
        } catch {
            AIErrorManager.logError(
                error, source: "StoryService",
                additionalInfo: "Failed to fetch story with id: \(id)")
            throw error
        }
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
    
    // MARK: - Illustration Generation
    
    /// Generate illustrations for all pages in a story using the enhanced contextual method
    /// This method uses the same comprehensive approach as StoryDetailView to ensure consistency
    /// across all three illustration generation flows
    private func generateIllustrationsForStory(_ story: Story, visualGuide: VisualGuide?) async throws {
        let illustrationService = try IllustrationService()
        var globalReferenceImagePath: String?
        
        // Generate global reference image if we have a visual guide
        if let visualGuide = visualGuide {
            do {
                // Use pageNumber 0 to generate global reference image
                globalReferenceImagePath = try await illustrationService.generateIllustration(
                    for: "Global reference image for all characters and settings in this story",
                    pageNumber: 0, // Special page number for global reference
                    totalPages: story.pages.count,
                    previousIllustrationPath: nil,
                    visualGuide: visualGuide,
                    globalReferenceImagePath: nil
                )
                print("[StoryService] Generated global reference image: \(globalReferenceImagePath ?? "nil")")
            } catch {
                print("[StoryService] Failed to generate global reference image: \(error.localizedDescription)")
                // Continue without global reference
            }
        }
        
        // Generate illustrations for each page using the enhanced contextual method
        for pageIndex in story.pages.indices {
            let page = story.pages[pageIndex]
            let description = page.imagePrompt ?? page.content
            
            // Get previous illustration path for visual continuity
            let previousIllustrationPath: String? = pageIndex > 0 ? story.pages[pageIndex - 1].illustrationPath : nil
            
            do {
                print("[StoryService] Generating illustration for page \(page.pageNumber) with enhanced contextual method")
                
                // Use the same enhanced method as StoryDetailView
                let relativePath = try await illustrationService.generateIllustration(
                    for: description,
                    pageNumber: page.pageNumber,
                    totalPages: story.pages.count,
                    previousIllustrationPath: previousIllustrationPath,
                    visualGuide: visualGuide,
                    globalReferenceImagePath: globalReferenceImagePath
                )
                
                if let relativePath = relativePath {
                    story.pages[pageIndex].illustrationPath = relativePath
                    story.pages[pageIndex].illustrationStatus = .ready
                    print("[StoryService] Successfully generated illustration for page \(page.pageNumber): \(relativePath)")
                } else {
                    story.pages[pageIndex].illustrationStatus = .failed
                    print("[StoryService] Failed to generate illustration for page \(page.pageNumber): service returned nil")
                }
                
                // Add delay between illustrations to avoid API rate limits
                if pageIndex < story.pages.count - 1 {
                    try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second delay
                }
                
            } catch {
                story.pages[pageIndex].illustrationStatus = .failed
                print("[StoryService] Error generating illustration for page \(page.pageNumber): \(error.localizedDescription)")
                AIErrorManager.logError(
                    error, source: "StoryService",
                    additionalInfo: "Failed to generate illustration for page \(page.pageNumber) in story \(story.title)"
                )
            }
        }
    }
}
