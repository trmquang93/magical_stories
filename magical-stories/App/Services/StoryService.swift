import GoogleGenerativeAI
import SwiftData
import SwiftUI

// MARK: - Story Models
@Model
final class Story: Identifiable {
    public var id: UUID
    public var title: String
    public var content: String
    @Attribute(originalName: "theme") private var themeRawValue: String
    var theme: StoryTheme {
        get { StoryTheme(rawValue: themeRawValue) ?? .adventure }
        set { themeRawValue = newValue.rawValue }
    }
    public var childName: String
    public var ageGroup: Int
    public var favoriteCharacter: String
    public var createdAt: Date

    public init(
        id: UUID = UUID(),
        title: String,
        content: String,
        theme: StoryTheme,
        childName: String,
        ageGroup: Int,
        favoriteCharacter: String,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.themeRawValue = theme.rawValue
        self.childName = childName
        self.ageGroup = ageGroup
        self.favoriteCharacter = favoriteCharacter
        self.createdAt = createdAt
    }
}

struct StoryParameters {
    let childName: String
    let ageGroup: Int
    let favoriteCharacter: String
    let theme: StoryTheme
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

    @Published private(set) var stories: [Story] = []
    @Published private(set) var isGenerating = false

    init(
        apiKey: String = ProcessInfo.processInfo.environment["GEMINI_API_KEY"] ?? "",
        persistenceService: PersistenceServiceProtocol = PersistenceService(),
        model: GenerativeModelProtocol? = nil
    ) {
        self.model = model ?? GenerativeModelWrapper(name: "gemini-2.0-flash", apiKey: apiKey)
        self.promptBuilder = PromptBuilder()
        self.persistenceService = persistenceService

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
            let prompt = promptBuilder.buildPrompt(
                childName: parameters.childName,
                ageGroup: parameters.ageGroup,
                favoriteCharacter: parameters.favoriteCharacter,
                theme: parameters.theme
            )

            let response = try await model.generateContent(prompt)
            guard let text = response.text else {
                throw StoryServiceError.generationFailed("No content generated")
            }

            // Extract title and content from the generated text
            let (title, content) = try extractTitleAndContent(from: text)

            let story = Story(
                title: title,
                content: content,
                theme: parameters.theme,
                childName: parameters.childName,
                ageGroup: parameters.ageGroup,
                favoriteCharacter: parameters.favoriteCharacter
            )

            try await saveStory(story)
            return story

        } catch {
            throw StoryServiceError.generationFailed(error.localizedDescription)
        }
    }

    func loadStories() async {
        do {
            stories = try await persistenceService.loadStories()
        } catch {
            print("Failed to load stories: \(error)")
            stories = []
        }
    }

    private func saveStory(_ story: Story) async throws {
        try await persistenceService.saveStory(story)
        stories.append(story)
        stories.sort { $0.createdAt > $1.createdAt }
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
    func buildPrompt(
        childName: String,
        ageGroup: Int,
        favoriteCharacter: String,
        theme: StoryTheme
    ) -> String {
        """
        Create a bedtime story for a child with the following parameters:
        - Child's name: \(childName)
        - Age group: \(ageGroup)
        - Favorite character: \(favoriteCharacter)
        - Theme: \(theme.title)

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
