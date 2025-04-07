# Google AI (Gemini Pro) Integration Guide

## Overview
This document outlines the integration of Google AI models (Gemini Pro for text, Gemini Flash 2.0 for images) for generating personalized children's stories and illustrations in the Magical Stories app.

## API Setup

### Prerequisites
1. Google AI Studio account
2. API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
3. Gemini Pro model access

### Configuration

The API key is managed via a `Config.plist` file (NOT `Config.xcconfig` as initially suggested here) which should be added to `.gitignore`. The key is then loaded into the app via `AppConfig.swift`.

```xml
<!-- Config.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GeminiAPIKey</key>
    <string>YOUR_API_KEY_HERE</string>
    <!-- Add other keys like GoogleCloudProjectID if needed -->
</dict>
</plist>
```

```swift
// AppConfig.swift (Simplified Example)
public struct AppConfig {
    private static func value<T>(forKey key: String) throws -> T { ... } // Implementation details...

    public static var geminiApiKey: String {
        do { return try value(forKey: "GeminiAPIKey") }
        catch { fatalError(error.localizedDescription) }
    }
    // Add other config properties...
}
```

**Note:** Ensure `Config.plist` is included in the target's "Copy Bundle Resources" build phase.

## Service Implementation

### Text Generation (`StoryService`)

The `StoryService` utilizes the `GoogleGenerativeAI` Swift SDK for text generation, likely using a model like "gemini-pro". (Implementation details omitted for brevity, see `StoryService.swift`).

### Image Generation (`IllustrationService`)

The `IllustrationService` uses direct REST API calls to the Google Generative Language API for image generation, utilizing the `gemini-2.0-flash-exp-image-generation` model. It does **not** use the `GoogleGenerativeAI` Swift SDK's `GenerativeModel` for this purpose, as the SDK might not directly support this specific model endpoint or the required request structure at the time of implementation.

**Endpoint:**
`https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-exp-image-generation:generateContent`

**Implementation:**
- The service constructs a `URLRequest` manually.
- The request body is encoded from custom `Codable` structs (`GeminiImageGenRequest`) matching the API's expected JSON format (using `contents`, `parts`, `generationConfig`).
- The response is decoded into custom `Codable` structs (`GeminiImageGenResponse`).
- Image data (base64 encoded) is extracted from the `inlineData` field within the response parts.
- The same API key (`AppConfig.geminiApiKey`) is used.

*(See `IllustrationService.swift` for detailed implementation)*

### Error Handling (`IllustrationError`)

Similar error handling patterns are used, mapping SDK errors (`GenerateContentError`) to custom service errors (`IllustrationError`).
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

<!-- Error Handling section for GeminiService removed as specific implementation is now in IllustrationService -->

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
<!-- Response Filtering section for GeminiService removed -->
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
<!-- Retry Logic section for GeminiService removed -->
```

## Testing

### Testing (`IllustrationServiceTests`)

Unit testing `IllustrationService` currently involves initializing the real service and making direct REST calls with a dummy API key. This primarily tests the error handling path where the API call fails due to an invalid key (expecting an `IllustrationError.apiError` wrapping an HTTP 4xx error). Mocking the network interaction (e.g., using `URLProtocol`) would be required for comprehensive unit testing of the request construction and response parsing logic without hitting the actual API. Tests for specific error conditions like prompt blocking are currently skipped as they require real API interaction or network mocking.

## Monitoring

### Analytics
```swift
<!-- Analytics section for GeminiService removed -->
```

## Best Practices

1. **API Key Security**
   - Store API key in `Config.plist` (and add to `.gitignore`)
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
   - Verify key in `Config.plist`
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
