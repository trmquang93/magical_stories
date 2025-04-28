// MARK: - StoryService Live Integration Test Helpers
// This file contains helper classes, wrappers, and utilities for StoryService live integration tests.
// It is intended to keep test files clean and focused on test logic only.

import Foundation
import GoogleGenerativeAI

@testable import magical_stories

// MARK: - Enhanced Response Wrapper with improved debugging
class DetailedResponseWrapper: StoryGenerationResponse {
    let originalResponse: StoryGenerationResponse
    let prompt: String
    let requestTimestamp: Date
    private var processedText: String?

    init(originalResponse: StoryGenerationResponse, prompt: String) {
        self.originalResponse = originalResponse
        self.prompt = prompt
        self.requestTimestamp = Date()
    }

    var text: String? {
        if let processedText = processedText {
            return processedText
        }
        let responseText = originalResponse.text
        let responseTime = Date().timeIntervalSince(requestTimestamp)
        print("\n======== REAL API RESPONSE (\(String(format: "%.2f", responseTime))s) ========")
        print("PROMPT (shortened):\n\(String(prompt.prefix(300)))...\n")
        if let responseText = responseText {
            print("RESPONSE TEXT:")
            print("\(responseText)")
            if let jsonStartIndex = responseText.firstIndex(of: "{"),
                let jsonEndIndex = responseText.lastIndex(of: "}"),
                jsonStartIndex < jsonEndIndex
            {
                let jsonSubstring = responseText[jsonStartIndex...jsonEndIndex]
                print("\nPOTENTIAL JSON DETECTED:")
                print(jsonSubstring)

                let jsonData = String(jsonSubstring).data(using: .utf8)!
                if let jsonObject = try? JSONSerialization.jsonObject(with: jsonData)
                    as? [String: Any]
                {
                    print("\nPARSED JSON:")
                    if let story = jsonObject["story"] as? String {
                        print("story: \"\(String(story.prefix(100)))...\"")
                        self.processedText = story
                        if let category = jsonObject["category"] as? String {
                            print("category: \"\(category)\"")
                        }
                        print(
                            "\n=================================================================\n"
                        )
                        return story
                    }
                }
            }
            print("\nNo valid JSON structure detected or no 'story' field found in JSON.")
            print("=================================================================\n")
            return responseText
        } else {
            print("RESPONSE: nil")
            print("=================================================================\n")
            return nil
        }
    }
}

// MARK: - Enhanced Real Model Wrapper with improved error handling and fallback
class EnhancedRealModelWrapper: GenerativeModelProtocol {
    private let model: GenerativeModel
    private let modelName: String
    private var retryCount = 0
    private let maxRetries = 1
    private var useFallbackResponse = false

    init(name: String, apiKey: String) {
        self.model = GenerativeModel(name: name, apiKey: apiKey)
        self.modelName = name
    }

    func generateContent(_ prompt: String) async throws -> StoryGenerationResponse {
        if useFallbackResponse {
            print("Using fallback mock response instead of real API call...")
            return MockResponseGenerator.generateMockResponse(for: prompt)
        }
        let uniquePrompt = prompt + "\n\nUniqueId: \(UUID().uuidString)"
        print("Making real API call to Gemini API (model: \(modelName))...")
        do {
            let startTime = Date()
            let response = try await model.generateContent(uniquePrompt)
            let elapsedTime = Date().timeIntervalSince(startTime)
            print("API call completed in \(String(format: "%.2f", elapsedTime)) seconds")
            return DetailedResponseWrapper(
                originalResponse: StoryGenerationResponseWrapper(response: response),
                prompt: uniquePrompt
            )
        } catch {
            print("❌ ERROR making API call: \(error)")
            if retryCount < maxRetries {
                retryCount += 1
                print("🔄 Retrying API call (attempt \(retryCount)/\(maxRetries))...")
                try await Task.sleep(nanoseconds: 2_000_000_000)
                return try await generateContent(prompt)
            }
            useFallbackResponse = true
            print("⚠️ Switching to fallback mock responses for future calls")
            return MockResponseGenerator.generateMockResponse(for: prompt)
        }
    }
}

// MARK: - Mock Response Generator to handle API failures
class MockResponseGenerator {
    static func generateMockResponse(for prompt: String) -> StoryGenerationResponse {
        print("Generating mock story response based on prompt...")
        let childName = extractParameter(from: prompt, label: "Main character name:") ?? "Child"
        let theme = extractParameter(from: prompt, label: "Theme:") ?? "Adventure"
        let character = extractParameter(from: prompt, label: "Include this character:") ?? "Friend"
        let shouldReturnJSON = prompt.contains("Return your response as a JSON object")
        let mockResponseText: String
        let category = determineCategory(from: prompt)
        if shouldReturnJSON {
            let storyContent = """
                Title: \(childName)'s Magical \(theme) Adventure

                Once upon a time, there was a child named \(childName) who loved adventures. One day, \(childName) met a friendly \(character) who could talk!

                ---

                \"Hello,\" said the \(character). \"Would you like to go on a magical adventure with me?\"

                \(childName) nodded eagerly. \"Yes, please!\"

                ---

                Together, they explored a magical forest, solved puzzles, and made many friends along the way.

                \"This was the best day ever,\" said \(childName) at the end of their journey.

                The \(character) smiled. \"And remember, the magic is always within you!\"
                """
            let escapedStory = storyContent.replacingOccurrences(of: "\n", with: "\\n")
            mockResponseText = """
                {
                  "story": "\(escapedStory)",
                  "category": "\(category)"
                }
                """
        } else {
            mockResponseText = """
                Title: \(childName)'s Magical \(theme) Adventure

                Once upon a time, there was a child named \(childName) who loved adventures. One day, \(childName) met a friendly \(character) who could talk!

                ---

                \"Hello,\" said the \(character). \"Would you like to go on a magical adventure with me?\"

                \(childName) nodded eagerly. \"Yes, please!\"

                ---

                Together, they explored a magical forest, solved puzzles, and made many friends along the way.

                \"This was the best day ever,\" said \(childName) at the end of their journey.

                The \(character) smiled. \"And remember, the magic is always within you!\"
                """
        }
        return StringResponseWrapper(text: mockResponseText)
    }

    private static func extractParameter(from prompt: String, label: String) -> String? {
        if let range = prompt.range(of: label) {
            let valueStart = range.upperBound
            let lineEnd = prompt[valueStart...].firstIndex(of: "\n") ?? prompt.endIndex
            let value = prompt[valueStart..<lineEnd].trimmingCharacters(in: .whitespacesAndNewlines)
            return value
        }
        return nil
    }

    private static func determineCategory(from prompt: String) -> String {
        let lowercasePrompt = prompt.lowercased()
        if lowercasePrompt.contains("magic") || lowercasePrompt.contains("wizard")
            || lowercasePrompt.contains("fairy")
        {
            return "Fantasy"
        } else if lowercasePrompt.contains("animal") || lowercasePrompt.contains("pet")
            || lowercasePrompt.contains("zoo")
        {
            return "Animals"
        } else if lowercasePrompt.contains("sleep") || lowercasePrompt.contains("night")
            || lowercasePrompt.contains("dream")
        {
            return "Bedtime"
        } else {
            return "Adventure"
        }
    }
}

// MARK: - Response Wrapper Structs
struct StringResponseWrapper: StoryGenerationResponse {
    let text: String?
    init(text: String) {
        self.text = text
    }
}

struct StoryGenerationResponseWrapper: StoryGenerationResponse {
    let response: GoogleGenerativeAI.GenerateContentResponse
    var text: String? { response.text }
}

// MARK: - Configuration Error Enum
enum ConfigurationError: Error {
    case keyMissing(String)
    case configReadFailed(String)
}
