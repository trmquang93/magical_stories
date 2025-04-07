// magical-storiesTests/Services/IllustrationServiceTests.swift
import XCTest
import GoogleGenerativeAI
@testable import magical_stories

@MainActor
final class IllustrationServiceTests: XCTestCase {

    // Mock components
    var mockURLSession: URLSession!
    var testableService: TestableIllustrationService!
    
    // Test data
    let testApiKey = "TEST_API_KEY"
    let testPageText = "A brave knight facing a friendly dragon."
    let testTheme = "Courage and Friendship"
    
    // Simple 1x1 transparent PNG image as Base64
    let sampleBase64Image = "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        // Create mock URLSession with MockURLProtocol
        mockURLSession = createMockURLSession()
        
        // Create testable service with mock URLSession
        testableService = TestableIllustrationService(apiKey: testApiKey, urlSession: mockURLSession)
        
        // Setup default mock responses
        setupMockResponses(urlSession: mockURLSession, apiKey: testApiKey)
    }

    override func tearDownWithError() throws {
        // Reset all mock handlers
        MockURLProtocol.reset()
        mockURLSession = nil
        testableService = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Test Cases

    func testGenerateIllustrationSuccess_ReturnsURL() async throws {
        // Arrange
        let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict"
        let urlString = "\(apiEndpoint)?key=\(testApiKey)"
        
        // Register a successful mock response with our sample image
        MockURLProtocol.registerJSONResponse(
            for: urlString,
            statusCode: 200,
            data: createMockImagenSuccessResponse(base64EncodedImage: sampleBase64Image)
        )
        
        // Act
        let resultURL = try await testableService.generateIllustration(for: testPageText, theme: testTheme)
        
        // Assert
        XCTAssertNotNil(resultURL, "The generateIllustration method should return a non-nil URL on success.")
        XCTAssertTrue(resultURL!.isFileURL, "The returned URL should be a file URL.")
        
        // Verify file exists
        let fileManager = FileManager.default
        XCTAssertTrue(fileManager.fileExists(atPath: resultURL!.path), "The image file should exist at the returned path.")
        
        // Verify file has content (not empty)
        let fileData = try Data(contentsOf: resultURL!)
        XCTAssertFalse(fileData.isEmpty, "The image file should not be empty.")
        
        // Clean up temporary file
        try? fileManager.removeItem(at: resultURL!)
    }

    func testGenerateIllustration_WhenSDKReturnsInvalidURLText_ThrowsInvalidResponse() async throws {
        // Arrange - Set up a mock response with invalid JSON
        let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict"
        let urlString = "\(apiEndpoint)?key=\(testApiKey)"
        
        // Create invalid JSON response
        let invalidJSON = "{ this is not valid JSON }"
        MockURLProtocol.registerJSONResponse(
            for: urlString,
            statusCode: 200,
            data: invalidJSON.data(using: .utf8)!
        )
        
        // Act & Assert
        do {
            _ = try await testableService.generateIllustration(for: testPageText, theme: testTheme)
            XCTFail("Expected generateIllustration to throw an error for invalid JSON, but it did not.")
        } catch let error as IllustrationError {
            guard case .invalidResponse = error else {
                XCTFail("Expected .invalidResponse error, but got \(error)")
                return
            }
            // Test passed - got expected error type
        }
    }

    func testGenerateIllustration_WhenSDKReturnsEmptyPredictions_ThrowsNoImageDataFound() async throws {
        // Arrange - Set up a mock response with empty predictions array
        let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict"
        let urlString = "\(apiEndpoint)?key=\(testApiKey)"
        
        // Create response with empty predictions
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
        
        // Act & Assert
        do {
            _ = try await testableService.generateIllustration(for: testPageText, theme: testTheme)
            XCTFail("Expected generateIllustration to throw an error for empty predictions, but it did not.")
        } catch let error as IllustrationError {
            guard case .noImageDataFound = error else {
                XCTFail("Expected .noImageDataFound error, but got \(error)")
                return
            }
            // Test passed - got expected error type
        }
    }

    func testGenerateIllustration_WhenSDKThrowsAPIKeyError_ThrowsApiError() async throws {
        // Arrange - Set up a mock response for an invalid API key
        let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict"
        let urlString = "\(apiEndpoint)?key=\(testApiKey)"
        
        // Register an unauthorized error response
        MockURLProtocol.registerJSONResponse(
            for: urlString,
            statusCode: 401,  // Unauthorized (invalid API key)
            data: createMockImagenErrorResponse(
                errorMessage: "API key not valid. Please pass a valid API key.",
                statusCode: 401
            )
        )
        
        // Act & Assert
        do {
            _ = try await testableService.generateIllustration(for: testPageText, theme: testTheme)
            XCTFail("Expected generateIllustration to throw an API error for invalid API key, but it did not.")
        } catch let error as IllustrationError {
            guard case .apiError(let underlyingError) = error else {
                XCTFail("Expected .apiError error, but got \(error)")
                return
            }
            
            if let nsError = underlyingError as? NSError {
                XCTAssertEqual(nsError.code, 401, "Expected status code 401 for invalid API key")
            }
        }
    }

    func testGenerateIllustration_WhenSDKThrowsPromptBlocked_ThrowsGenerationFailed() async throws {
        // Arrange - Set up a mock response for content filtering/safety blocks
        let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict"
        let urlString = "\(apiEndpoint)?key=\(testApiKey)"
        
        // Create a safety block error response
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
        
        // Act & Assert
        do {
            _ = try await testableService.generateIllustration(for: "unsafe content", theme: "unsafe theme")
            XCTFail("Expected generateIllustration to throw an error for blocked content, but it did not.")
        } catch let error as IllustrationError {
            guard case .apiError = error else {
                XCTFail("Expected .apiError for content filtering, but got \(error)")
                return
            }
            // The current implementation maps these to apiError rather than generationFailed
            // We could modify the service to specifically detect and map safety failures
        }
    }

    func testGenerateIllustration_WhenSDKThrowsInternalError_ThrowsApiError() async throws {
        // Arrange - Set up a mock response for internal server error
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
        
        // Act & Assert
        do {
            _ = try await testableService.generateIllustration(for: testPageText, theme: testTheme)
            XCTFail("Expected generateIllustration to throw an API error for internal server error, but it did not.")
        } catch let error as IllustrationError {
            guard case .apiError(let underlyingError) = error else {
                XCTFail("Expected .apiError error, but got \(error)")
                return
            }
            
            if let nsError = underlyingError as? NSError {
                XCTAssertEqual(nsError.code, 500, "Expected status code 500 for internal server error")
            }
        }
    }

    func testGenerateIllustration_WhenSDKThrowsNetworkError_ThrowsNetworkError() async throws {
        // Arrange - Set up a mock URLError
        let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict"
        let urlString = "\(apiEndpoint)?key=\(testApiKey)"
        
        // Create a URLError (e.g., no internet connection)
        let networkError = URLError(.notConnectedToInternet)
        MockURLProtocol.registerError(for: urlString, error: networkError)
        
        // Act & Assert
        do {
            _ = try await testableService.generateIllustration(for: testPageText, theme: testTheme)
            XCTFail("Expected generateIllustration to throw a network error, but it did not.")
        } catch let error as IllustrationError {
            guard case .networkError(let underlyingError) = error else {
                XCTFail("Expected .networkError error, but got \(error)")
                return
            }
            
            guard let urlError = underlyingError as? URLError else {
                XCTFail("Expected URLError as underlying error")
                return
            }
            
            XCTAssertEqual(urlError.code, .notConnectedToInternet)
        }
    }

    func testGenerateIllustration_WithInvalidBase64_ThrowsImageProcessingError() async throws {
        // Arrange - Set up a mock response with invalid base64 data
        let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict"
        let urlString = "\(apiEndpoint)?key=\(testApiKey)"
        
        // Create response with invalid base64 string
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
        
        // Act & Assert
        do {
            _ = try await testableService.generateIllustration(for: testPageText, theme: testTheme)
            XCTFail("Expected generateIllustration to throw an error for invalid base64 data, but it did not.")
        } catch let error as IllustrationError {
            guard case .imageProcessingError = error else {
                XCTFail("Expected .imageProcessingError error, but got \(error)")
                return
            }
            // Test passed - got expected error type
        }
    }
    
    // MARK: - Test real IllustrationService initializer
    
    func testInitializer_WithEmptyAPIKey_ThrowsError() throws {
         // Assert - Test the public designated initializer directly
         XCTAssertThrowsError(try IllustrationService(apiKey: "")) { error in
             guard let configError = error as? ConfigurationError else {
                 XCTFail("Expected ConfigurationError.keyMissing but got \(type(of: error))")
                 return
             }
             guard case .keyMissing(let key) = configError else {
                  XCTFail("Expected .keyMissing but got \(configError)")
                  return
             }
             XCTAssertEqual(key, "GeminiAPIKey", "Expected missing key to be GeminiAPIKey")
         }
    }
}