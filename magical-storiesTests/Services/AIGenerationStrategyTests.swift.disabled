import XCTest
@testable import magical_stories

class AIGenerationStrategyTests: XCTestCase {
    
    // MARK: - Strategy Selection Tests
    
    func testStrategySelector_WithStoryRequest_ShouldSelectGeminiStrategy() {
        // Arrange
        let selector = AIStrategySelector()
        let request = GenerationRequest.story(
            prompt: "Test story prompt",
            parameters: StoryParameters(theme: "Adventure", childAge: 6)
        )
        
        // Act
        let strategy = selector.selectStrategy(for: request)
        
        // Assert
        XCTAssertTrue(strategy is GeminiTextStrategy)
    }
    
    func testStrategySelector_WithIllustrationRequest_ShouldSelectImagenStrategy() {
        // Arrange
        let selector = AIStrategySelector()
        let request = GenerationRequest.illustration(
            prompt: "Test illustration prompt",
            context: IllustrationContext(pageNumber: 1, totalPages: 5)
        )
        
        // Act
        let strategy = selector.selectStrategy(for: request)
        
        // Assert
        XCTAssertTrue(strategy is ImagenStrategy)
    }
    
    func testStrategySelector_WithGlobalReferenceRequest_ShouldSelectGeminiImageStrategy() {
        // Arrange
        let selector = AIStrategySelector()
        let request = GenerationRequest.globalReference(
            prompt: "Test global reference prompt",
            visualGuide: VisualGuide(styleGuide: "Test style", characterDefinitions: [:], settingDefinitions: [:])
        )
        
        // Act
        let strategy = selector.selectStrategy(for: request)
        
        // Assert
        XCTAssertTrue(strategy is GeminiImageStrategy)
    }
    
    func testStrategySelector_WithSequentialIllustrationRequest_ShouldSelectGeminiImageStrategy() {
        // Arrange
        let selector = AIStrategySelector()
        let request = GenerationRequest.sequentialIllustration(
            prompt: "Test sequential prompt",
            context: IllustrationContext(pageNumber: 2, totalPages: 5),
            previousImagePath: "path/to/previous.png",
            globalReferencePath: "path/to/global.png"
        )
        
        // Act
        let strategy = selector.selectStrategy(for: request)
        
        // Assert
        XCTAssertTrue(strategy is GeminiImageStrategy)
    }
    
    // MARK: - Gemini Text Strategy Tests
    
    func testGeminiTextStrategy_WithValidPrompt_ShouldReturnTextResult() async throws {
        // Arrange
        let mockModel = MockGenerativeModel()
        mockModel.generatedText = "A magical story about dragons..."
        
        let strategy = GeminiTextStrategy(model: mockModel)
        let request = GenerationRequest.story(
            prompt: "Create a magical story",
            parameters: StoryParameters(theme: "Fantasy", childAge: 7)
        )
        
        // Act
        let result = try await strategy.generate(request: request)
        
        // Assert
        XCTAssertEqual(mockModel.lastPrompt, "Create a magical story")
        switch result {
        case .text(let content):
            XCTAssertEqual(content, "A magical story about dragons...")
        default:
            XCTFail("Expected text result")
        }
    }
    
    func testGeminiTextStrategy_WithNetworkError_ShouldThrowError() async {
        // Arrange
        let mockModel = MockGenerativeModel()
        mockModel.error = NSError(domain: "TestError", code: 500, userInfo: nil)
        
        let strategy = GeminiTextStrategy(model: mockModel)
        let request = GenerationRequest.story(
            prompt: "Test prompt",
            parameters: StoryParameters(theme: "Adventure", childAge: 5)
        )
        
        // Act & Assert
        do {
            let _ = try await strategy.generate(request: request)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is GenerationError)
        }
    }
    
    // MARK: - Gemini Image Strategy Tests
    
    func testGeminiImageStrategy_WithValidPrompt_ShouldReturnImageResult() async throws {
        // Arrange
        let mockSession = MockURLSessionForStrategy()
        mockSession.mockImageData = "mock-base64-data".data(using: .utf8)!
        
        let strategy = GeminiImageStrategy(urlSession: mockSession, apiKey: "test-key")
        let request = GenerationRequest.illustration(
            prompt: "Create a beautiful illustration",
            context: IllustrationContext(pageNumber: 1, totalPages: 3)
        )
        
        // Act
        let result = try await strategy.generate(request: request)
        
        // Assert
        switch result {
        case .image(let imagePath):
            XCTAssertFalse(imagePath.isEmpty)
            XCTAssertTrue(imagePath.hasPrefix("Illustrations/"))
        default:
            XCTFail("Expected image result")
        }
    }
    
    func testGeminiImageStrategy_WithAPIError_ShouldThrowError() async {
        // Arrange
        let mockSession = MockURLSessionForStrategy()
        mockSession.shouldReturnError = true
        
        let strategy = GeminiImageStrategy(urlSession: mockSession, apiKey: "test-key")
        let request = GenerationRequest.illustration(
            prompt: "Test prompt",
            context: IllustrationContext(pageNumber: 1, totalPages: 1)
        )
        
        // Act & Assert
        do {
            let _ = try await strategy.generate(request: request)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is GenerationError)
        }
    }
    
    // MARK: - Imagen Strategy Tests
    
    func testImagenStrategy_WithValidPrompt_ShouldReturnImageResult() async throws {
        // Arrange
        let mockSession = MockURLSessionForStrategy()
        mockSession.mockImageData = "mock-imagen-data".data(using: .utf8)!
        
        let strategy = ImagenStrategy(urlSession: mockSession, apiKey: "test-key")
        let request = GenerationRequest.illustration(
            prompt: "Create a simple illustration",
            context: IllustrationContext(pageNumber: 1, totalPages: 1)
        )
        
        // Act
        let result = try await strategy.generate(request: request)
        
        // Assert
        switch result {
        case .image(let imagePath):
            XCTAssertFalse(imagePath.isEmpty)
            XCTAssertTrue(imagePath.hasPrefix("Illustrations/"))
        default:
            XCTFail("Expected image result")
        }
    }
    
    // MARK: - Integration Tests
    
    func testAICoordinator_WithMultipleRequests_ShouldUseCorrectStrategies() async throws {
        // Arrange
        let mockTextModel = MockGenerativeModel()
        mockTextModel.generatedText = "Generated story content"
        
        let mockSession = MockURLSessionForStrategy()
        mockSession.mockImageData = "mock-image-data".data(using: .utf8)!
        
        let coordinator = AICoordinator(
            textModel: mockTextModel,
            urlSession: mockSession,
            apiKey: "test-key"
        )
        
        let storyRequest = GenerationRequest.story(
            prompt: "Story prompt",
            parameters: StoryParameters(theme: "Adventure", childAge: 6)
        )
        let imageRequest = GenerationRequest.illustration(
            prompt: "Image prompt",
            context: IllustrationContext(pageNumber: 1, totalPages: 1)
        )
        
        // Act
        let storyResult = try await coordinator.generate(request: storyRequest)
        let imageResult = try await coordinator.generate(request: imageRequest)
        
        // Assert
        switch storyResult {
        case .text(let content):
            XCTAssertEqual(content, "Generated story content")
        default:
            XCTFail("Expected text result for story")
        }
        
        switch imageResult {
        case .image(let path):
            XCTAssertFalse(path.isEmpty)
        default:
            XCTFail("Expected image result for illustration")
        }
    }
    
    // MARK: - Performance Tests
    
    func testStrategySelection_WithManyRequests_ShouldBeEfficient() {
        // Arrange
        let selector = AIStrategySelector()
        let requests = (1...1000).map { i in
            GenerationRequest.story(
                prompt: "Prompt \(i)",
                parameters: StoryParameters(theme: "Theme \(i)", childAge: i % 10 + 3)
            )
        }
        
        // Act & Assert
        measure {
            for request in requests {
                let _ = selector.selectStrategy(for: request)
            }
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testStrategySelector_WithUnsupportedRequest_ShouldReturnFallbackStrategy() {
        // Arrange
        let selector = AIStrategySelector()
        
        // Create a mock unsupported request type
        let unsupportedRequest = GenerationRequest.story(
            prompt: "", // Empty prompt to trigger fallback
            parameters: StoryParameters(theme: "", childAge: 0)
        )
        
        // Act
        let strategy = selector.selectStrategy(for: unsupportedRequest)
        
        // Assert
        XCTAssertNotNil(strategy)
        // Should return a fallback strategy rather than crash
    }
}

// MARK: - Mock Classes

class MockURLSessionForStrategy: URLSessionProtocol {
    var mockImageData: Data?
    var shouldReturnError: Bool = false
    
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        if shouldReturnError {
            throw GenerationError.networkError(NSError(domain: "MockNetworkError", code: 0, userInfo: nil))
        }
        
        // Mock successful Gemini response for image generation
        let mockGeminiResponse = """
        {
            "candidates": [{
                "content": {
                    "parts": [{
                        "inlineData": {
                            "mimeType": "image/png",
                            "data": "\(mockImageData?.base64EncodedString() ?? "")"
                        }
                    }]
                }
            }]
        }
        """
        
        // Mock successful Imagen response  
        let mockImagenResponse = """
        {
            "predictions": [{
                "bytesBase64Encoded": "\(mockImageData?.base64EncodedString() ?? "")",
                "mimeType": "image/png"
            }]
        }
        """
        
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        
        // Use Gemini response format for Gemini endpoints, Imagen format for Imagen endpoints
        let responseData: Data
        if request.url?.absoluteString.contains("gemini") == true {
            responseData = mockGeminiResponse.data(using: .utf8) ?? Data()
        } else {
            responseData = mockImagenResponse.data(using: .utf8) ?? Data()
        }
        
        return (responseData, response)
    }
    
    func data(from url: URL) async throws -> (Data, URLResponse) {
        // Create a URLRequest from the URL and delegate to the existing method
        let request = URLRequest(url: url)
        return try await data(for: request)
    }
}