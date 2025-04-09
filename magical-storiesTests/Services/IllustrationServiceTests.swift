import Testing
import Foundation
import GoogleGenerativeAI
@testable import magical_stories

@Suite("IllustrationService Tests")
struct IllustrationServiceTests {
    let testApiKey = "TEST_API_KEY"
    let testPageText = "A brave knight facing a friendly dragon."
    let testTheme = "Courage and Friendship"
    let sampleBase64Image = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="

    @Test("Generate Illustration Success returns relative path")
    @MainActor
    func testGenerateIllustrationSuccess() async throws {
        let mockURLSession = createMockURLSession()
        let testableService = TestableIllustrationService(apiKey: testApiKey, urlSession: mockURLSession)
        setupMockResponses(urlSession: mockURLSession, apiKey: testApiKey)

        let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict"
        let urlString = "\(apiEndpoint)?key=\(testApiKey)"
        MockURLProtocol.registerJSONResponse(
            for: urlString,
            statusCode: 200,
            data: createMockImagenSuccessResponse(base64EncodedImage: sampleBase64Image)
        )

        let resultPath = try await testableService.generateIllustration(for: testPageText, theme: testTheme)

        #expect(resultPath != nil, "Should return a non-nil relative path")
        #expect(resultPath!.hasPrefix("Illustrations/"), "Returned path should be inside Illustrations directory")

        let appSupportURL = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        let fullURL = appSupportURL.appendingPathComponent(resultPath!)

        let fileManager = FileManager.default
        #expect(fileManager.fileExists(atPath: fullURL.path), "Image file should exist at saved path")

        let fileData = try Data(contentsOf: fullURL)
        #expect(!fileData.isEmpty, "Image file should not be empty")

        try? fileManager.removeItem(at: fullURL)
    }

    @Test("Invalid JSON response throws invalidResponse error")
    @MainActor
    func testInvalidJSONResponse() async throws {
        let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict"
        let urlString = "\(apiEndpoint)?key=\(testApiKey)"
        let invalidJSON = "{ this is not valid JSON }"
        MockURLProtocol.registerJSONResponse(
            for: urlString,
            statusCode: 200,
            data: invalidJSON.data(using: .utf8)!
        )

        let mockURLSession = createMockURLSession()
        let testableService = TestableIllustrationService(apiKey: testApiKey, urlSession: mockURLSession)

        do {
            _ = try await testableService.generateIllustration(for: testPageText, theme: testTheme)
            Issue.record("Expected error for invalid JSON but got success")
        } catch let error as IllustrationError {
            guard case .apiError(let underlyingError) = error,
                  underlyingError is DecodingError else {
                Issue.record("Expected .apiError wrapping DecodingError, got \(error)")
                return
            }
        }
    }

    @Test("Empty predictions throws noImageDataFound")
    @MainActor
    func testEmptyPredictions() async throws {
        let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict"
        let urlString = "\(apiEndpoint)?key=\(testApiKey)"
        let emptyPredictionsJSON = """
        {
            "predictions": []
        }
        """
        MockURLProtocol.registerJSONResponse(
            for: urlString,
            statusCode: 200,
            data: emptyPredictionsJSON.data(using: .utf8)!
        )

        let mockURLSession = createMockURLSession()
        let testableService = TestableIllustrationService(apiKey: testApiKey, urlSession: mockURLSession)

        do {
            _ = try await testableService.generateIllustration(for: testPageText, theme: testTheme)
            Issue.record("Expected error for empty predictions but got success")
        } catch let error as IllustrationError {
            guard case .noImageDataFound = error else {
                Issue.record("Expected .noImageDataFound error, got \(error)")
                return
            }
        }
    }

    @Test("Invalid API key returns apiError with 401")
    @MainActor
    func testInvalidAPIKey() async throws {
        let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict"
        let urlString = "\(apiEndpoint)?key=\(testApiKey)"
        MockURLProtocol.registerJSONResponse(
            for: urlString,
            statusCode: 401,
            data: createMockImagenErrorResponse(
                errorMessage: "API key not valid. Please pass a valid API key.",
                statusCode: 401
            )
        )

        let mockURLSession = createMockURLSession()
        let testableService = TestableIllustrationService(apiKey: testApiKey, urlSession: mockURLSession)

        do {
            _ = try await testableService.generateIllustration(for: testPageText, theme: testTheme)
            Issue.record("Expected API error for invalid API key but got success")
        } catch let error as IllustrationError {
            guard case .apiError(let underlyingError) = error else {
                Issue.record("Expected .apiError error, got \(error)")
                return
            }
            if let nsError = underlyingError as? NSError {
                #expect(nsError.code == 401, "Expected status code 401")
            }
        }
    }

    @Test("Content filtering returns apiError")
    @MainActor
    func testContentFiltering() async throws {
        let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict"
        let urlString = "\(apiEndpoint)?key=\(testApiKey)"
        let safetyBlockJSON = """
        {
            "error": {
                "code": 400,
                "message": "The request was blocked by content filtering system.",
                "status": "FAILED_PRECONDITION",
                "details": [
                    {
                        "reason": "SAFETY",
                        "help": "Please ensure content complies with content policy."
                    }
                ]
            }
        }
        """
        MockURLProtocol.registerJSONResponse(
            for: urlString,
            statusCode: 400,
            data: safetyBlockJSON.data(using: .utf8)!
        )

        let mockURLSession = createMockURLSession()
        let testableService = TestableIllustrationService(apiKey: testApiKey, urlSession: mockURLSession)

        do {
            _ = try await testableService.generateIllustration(for: "unsafe content", theme: "unsafe theme")
            Issue.record("Expected error for blocked content but got success")
        } catch let error as IllustrationError {
            guard case .apiError = error else {
                Issue.record("Expected .apiError for content filtering, got \(error)")
                return
            }
        }
    }

    @Test("Internal server error returns apiError with 500")
    @MainActor
    func testInternalServerError() async throws {
        let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict"
        let urlString = "\(apiEndpoint)?key=\(testApiKey)"
        MockURLProtocol.registerJSONResponse(
            for: urlString,
            statusCode: 500,
            data: createMockImagenErrorResponse(
                errorMessage: "Internal server error",
                statusCode: 500
            )
        )

        let mockURLSession = createMockURLSession()
        let testableService = TestableIllustrationService(apiKey: testApiKey, urlSession: mockURLSession)

        do {
            _ = try await testableService.generateIllustration(for: testPageText, theme: testTheme)
            Issue.record("Expected API error for internal server error but got success")
        } catch let error as IllustrationError {
            guard case .apiError(let underlyingError) = error else {
                Issue.record("Expected .apiError error, got \(error)")
                return
            }
            if let nsError = underlyingError as? NSError {
                #expect(nsError.code == 500, "Expected status code 500")
            }
        }
    }

    @Test("Network error returns networkError")
    @MainActor
    func testNetworkError() async throws {
        let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict"
        let urlString = "\(apiEndpoint)?key=\(testApiKey)"
        let networkError = URLError(.notConnectedToInternet)
        MockURLProtocol.registerError(for: urlString, error: networkError)

        let mockURLSession = createMockURLSession()
        let testableService = TestableIllustrationService(apiKey: testApiKey, urlSession: mockURLSession)

        do {
            _ = try await testableService.generateIllustration(for: testPageText, theme: testTheme)
            Issue.record("Expected network error but got success")
        } catch let error as IllustrationError {
            guard case .networkError(let underlyingError) = error else {
                Issue.record("Expected .networkError error, got \(error)")
                return
            }
            guard let urlError = underlyingError as? URLError else {
                Issue.record("Expected URLError as underlying error")
                return
            }
            #expect(urlError.code == .notConnectedToInternet)
        }
    }

    @Test("Invalid base64 throws imageProcessingError")
    @MainActor
    func testInvalidBase64() async throws {
        let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict"
        let urlString = "\(apiEndpoint)?key=\(testApiKey)"
        let invalidBase64JSON = """
        {
            "predictions": [
                {
                    "bytesBase64Encoded": "this-is-not-valid-base64!",
                    "mimeType": "image/png"
                }
            ]
        }
        """
        MockURLProtocol.registerJSONResponse(
            for: urlString,
            statusCode: 200,
            data: invalidBase64JSON.data(using: .utf8)!
        )

        let mockURLSession = createMockURLSession()
        let testableService = TestableIllustrationService(apiKey: testApiKey, urlSession: mockURLSession)

        do {
            _ = try await testableService.generateIllustration(for: testPageText, theme: testTheme)
            Issue.record("Expected error for invalid base64 but got success")
        } catch let error as IllustrationError {
            guard case .imageProcessingError = error else {
                Issue.record("Expected .imageProcessingError error, got \(error)")
                return
            }
        }
    }

    @Test("Initializer with empty API key throws ConfigurationError.keyMissing")
    func testInitializerWithEmptyAPIKey() throws {
        do {
            _ = try IllustrationService(apiKey: "")
            Issue.record("Expected error for empty API key but got success")
        } catch let error as ConfigurationError {
            guard case .keyMissing(let key) = error else {
                Issue.record("Expected .keyMissing error, got \(error)")
                return
            }
            #expect(key == "GeminiAPIKey", "Expected missing key to be GeminiAPIKey")
        } catch {
            Issue.record("Expected ConfigurationError but got \(error)")
        }
    }
}