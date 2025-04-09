# Google AI (Gemini) Integration Guide

## Overview
This document outlines the integration of Google AI models (Gemini Pro for text, `imagen-3.0-generate-002` for images) for generating personalized children's stories and illustrations in the Magical Stories app.

## API Setup

### Prerequisites
1. Google AI Studio account or Google Cloud Project with Vertex AI enabled.
2. API key generated from the appropriate console.
3. Access enabled for the required Gemini models.

### Configuration

The API key (`GeminiAPIKey`) is managed via a `Config.plist` file (added to `.gitignore`) and loaded securely via `AppConfig.swift`.

```xml
<!-- Config.plist -->
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>GeminiAPIKey</key>
    <string>YOUR_API_KEY_HERE</string>
    <!-- Add other keys if needed -->
</dict>
</plist>
```

```swift
// AppConfig.swift (Simplified Example)
public struct AppConfig {
    // ... loading logic ...
    public static var geminiApiKey: String {
        do { return try value(forKey: "GeminiAPIKey") }
        catch { fatalError("Missing or invalid GeminiAPIKey in Config.plist: \(error)") }
    }
}
```
**Note:** Ensure `Config.plist` is included in the target's "Copy Bundle Resources" build phase.

## Service Implementation

### Text Generation (`StoryService`)

The `StoryService` utilizes the `GoogleGenerativeAI` Swift SDK for text generation, using the "gemini-pro" model (or latest equivalent). It leverages the `GenerativeModelProtocol` for testability. (See `StoryService.swift`).

### Image Generation (`IllustrationService`)

The `IllustrationService` is responsible for generating illustrations using the Google AI platform. Unlike the `StoryService` which uses the Swift SDK, the `IllustrationService` interacts directly with the Google AI REST API.

**Model:** `imagen-3.0-generate-002`

**Interaction (REST API):**
- The service interacts directly with the appropriate Google AI REST API endpoint for image generation using the specified model.
- It constructs the necessary JSON request payload (including prompt, safety settings, generation config, and specifying the `imagen-3.0-generate-002` model) using custom `Codable` structs.
- It sends the HTTP request using `URLSession` or a similar networking layer.
- **Response Parsing:** The service parses the JSON response and extracts the base64-encoded image data from the relevant fields.
- The same API key (`AppConfig.geminiApiKey`) is used for authentication via HTTP headers or query parameters as required by the API.

*(See `IllustrationService.swift` for detailed implementation)*

### Error Handling (`IllustrationError`, `AIErrorManager`)

Custom errors (e.g., `IllustrationError`) are defined to represent specific failure scenarios (API errors, network issues, parsing errors, content safety blocks). The `AIErrorManager` helps centralize logging and potentially user-facing error presentation for AI-related issues.

## Prompt Engineering

### Story Generation Template
(Template remains the same - see previous version)
```swift
struct StoryPrompt { /* ... */ }
```

### Content Safety
(Filtering logic remains the same - see previous version)
```swift
extension StoryPrompt { /* ... forbiddenThemes, validateTheme ... */ }
```

## Rate Limiting
(Implementation concept remains the same - see previous version)
```swift
class RateLimiter { /* ... */ }
```

## Caching
(Implementation concept remains the same - see previous version)
```swift
class StoryCache { /* ... */ }
```

## Error Recovery
Retry logic is implemented within services like `IllustrationService` for transient network or API errors.

## Testing

### Unit Testing (`IllustrationServiceTests`, `StoryServiceTests`)

- **Mocking:** Services like `IllustrationService` and `StoryService` conform to protocols (`IllustrationServiceProtocol`, `StoryServiceProtocol`). Unit tests utilize **mock implementations** of these protocols.
- **Isolation:** Mocks are injected into the components under test (e.g., `StoryProcessor`), allowing testing of the component's logic in isolation without making actual network calls to the Google AI API.
- **Verification:** Tests verify that the component correctly interacts with the service protocol (e.g., calls the right methods with expected parameters) and handles the mocked success or error responses appropriately.
- **Coverage:** This approach enables comprehensive testing of request construction, response handling, error propagation, and integration with other components, independent of live API availability or behavior.

### Integration Testing
- Specific integration tests (tagged `.integration`, `.api`) may exist to verify the actual connection and basic interaction with the live Google AI API using a valid (potentially test-specific) API key. These are run selectively (e.g., in CI environments) and are documented in `memory_bank/techContext.md`.

## Monitoring
(Placeholder - Specific monitoring/analytics implementation details TBD)

## Best Practices

1.  **API Key Security:** Store securely (`Config.plist`, gitignored), never commit, use environment-specific keys.
2.  **Error Handling:** Implement robust handling, provide user feedback, log errors.
3.  **Performance:** Consider caching, implement retries, monitor usage/costs.
4.  **Content Safety:** Implement prompt and response filtering.
5.  **Testing:** Prioritize **unit tests with mocks**. Use selective integration tests for validation.

## Troubleshooting
(Common issues remain the same - API Key, Rate Limiting, Content Filtering)

---

This documentation should be updated when API versions change, models are updated, new features are added, or security/testing strategies evolve.
