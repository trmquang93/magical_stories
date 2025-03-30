# Google AI (Gemini Pro) Integration Guide

## Overview
This document outlines the integration of Google AI's Gemini Pro model for generating personalized children's stories in the Magical Stories app.

## API Setup

### Prerequisites
1. Google AI Studio account
2. API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
3. Gemini Pro model access

### Configuration
```swift
// Config.xcconfig
GOOGLE_AI_API_KEY = your_api_key_here
```

```swift
// Environment.swift
enum Environment {
    static let googleAIApiKey = Bundle.main.infoDictionary?["GOOGLE_AI_API_KEY"] as? String ?? ""
}
```

## Service Implementation

### GeminiService
```swift
class GeminiService {
    private let apiKey: String
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models"
    private let model = "gemini-pro"
    
    init(apiKey: String = Environment.googleAIApiKey) {
        self.apiKey = apiKey
    }
    
    func generateStory(prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)/\(model):generateContent?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        let request = StoryRequest(prompt: prompt)
        // Implementation details...
    }
}
```

### Error Handling
```swift
enum GeminiError: Error {
    case invalidURL
    case apiError(String)
    case invalidResponse
    case rateLimitExceeded
    case contentFiltered
    
    var userMessage: String {
        switch self {
        case .rateLimitExceeded:
            return "Too many stories generated. Please try again later."
        case .contentFiltered:
            return "Unable to generate story. Please try different parameters."
        default:
            return "Something went wrong. Please try again."
        }
    }
}
```

## Prompt Engineering

### Story Generation Template
```swift
struct StoryPrompt {
    static func generate(
        childName: String,
        age: Int,
        theme: String,
        character: String
    ) -> String {
        """
        Create a children's bedtime story with these requirements:
        - Main character: \(character)
        - Child's name: \(childName)
        - Age group: \(age) years old
        - Theme/moral: \(theme)
        
        Guidelines:
        - Keep the story length appropriate for bedtime (300-500 words)
        - Use age-appropriate language and concepts
        - Include positive messages and learning opportunities
        - Maintain a gentle, soothing tone
        - Avoid scary elements or negative themes
        - Include natural places for parent interaction
        
        Format the story with clear paragraphs and child-friendly pacing.
        """
    }
}
```

### Content Safety

#### Proactive Filtering
```swift
extension StoryPrompt {
    static let forbiddenThemes = [
        "violence",
        "death",
        "scary",
        "inappropriate",
        // Add more as needed
    ]
    
    static func validateTheme(_ theme: String) -> Bool {
        !forbiddenThemes.contains(where: { theme.lowercased().contains($0) })
    }
}
```

#### Response Filtering
```swift
extension GeminiService {
    func filterResponse(_ content: String) -> Bool {
        // Implementation of content safety checks
        // Returns true if content is safe, false otherwise
    }
}
```

## Rate Limiting

### Implementation
```swift
class RateLimiter {
    private var requestCount = 0
    private let maxRequests = 50 // Adjust based on API tier
    private var resetDate = Date()
    
    func checkLimit() throws {
        guard requestCount < maxRequests else {
            throw GeminiError.rateLimitExceeded
        }
        
        if Calendar.current.isDateInToday(resetDate) {
            requestCount += 1
        } else {
            requestCount = 1
            resetDate = Date()
        }
    }
}
```

## Caching

### Story Cache
```swift
class StoryCache {
    private let cache = NSCache<NSString, NSString>()
    private let maxCacheSize = 50 // Number of stories to cache
    
    func getCachedStory(for prompt: String) -> String? {
        cache.object(forKey: prompt as NSString) as? String
    }
    
    func cacheStory(_ story: String, for prompt: String) {
        cache.setObject(story as NSString, forKey: prompt as NSString)
    }
}
```

## Error Recovery

### Retry Logic
```swift
extension GeminiService {
    private func executeWithRetry<T>(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        operation: () async throws -> T
    ) async throws -> T {
        var attempts = 0
        var lastError: Error?
        
        while attempts < maxAttempts {
            do {
                return try await operation()
            } catch {
                attempts += 1
                lastError = error
                
                if attempts < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? GeminiError.apiError("Max retry attempts reached")
    }
}
```

## Testing

### Mock Service
```swift
class MockGeminiService: GeminiServiceProtocol {
    var shouldSucceed = true
    var mockResponse: String?
    
    func generateStory(prompt: String) async throws -> String {
        guard shouldSucceed else {
            throw GeminiError.apiError("Mock error")
        }
        return mockResponse ?? "Mock story for testing"
    }
}
```

### Unit Tests
```swift
class GeminiServiceTests: XCTestCase {
    var service: GeminiService!
    
    override func setUp() {
        super.setUp()
        service = GeminiService(apiKey: "test_key")
    }
    
    func testStoryGeneration() async throws {
        let story = try await service.generateStory(prompt: "Test prompt")
        XCTAssertFalse(story.isEmpty)
        // Additional assertions...
    }
}
```

## Monitoring

### Analytics
```swift
extension GeminiService {
    private func logAPICall(
        prompt: String,
        duration: TimeInterval,
        success: Bool,
        error: Error?
    ) {
        Analytics.logEvent("story_generation", parameters: [
            "duration": duration,
            "success": success,
            "error_type": error?.localizedDescription ?? "",
            "prompt_length": prompt.count
        ])
    }
}
```

## Best Practices

1. **API Key Security**
   - Store API key in `Config.xcconfig`
   - Never commit API key to version control
   - Use different keys for development and production

2. **Error Handling**
   - Implement comprehensive error handling
   - Provide user-friendly error messages
   - Log errors for debugging

3. **Performance**
   - Implement caching for frequently used stories
   - Use retry logic for failed requests
   - Monitor API usage and costs

4. **Content Safety**
   - Implement content filtering
   - Validate prompts before sending
   - Filter responses for inappropriate content

5. **Testing**
   - Write unit tests for all API interactions
   - Use mock services for testing
   - Test error scenarios

## Troubleshooting

### Common Issues

1. **API Key Invalid**
   - Verify key in Config.xcconfig
   - Check API key permissions
   - Ensure key is properly loaded

2. **Rate Limiting**
   - Monitor daily usage
   - Implement exponential backoff
   - Consider upgrading API tier

3. **Content Filtering**
   - Review prompt guidelines
   - Check forbidden themes
   - Adjust content filtering rules

---

This documentation should be updated when:
- API version changes
- New features are added
- Security requirements change
- Performance optimizations are implemented
