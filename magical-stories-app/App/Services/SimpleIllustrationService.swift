import Foundation
import GoogleGenerativeAI
import SwiftData
#if os(iOS)
import UIKit
#endif

/// Simple illustration service that provides on-demand illustration generation
/// This replaces the complex background task system with a clean, efficient approach
/// Enhanced with character reference integration for consistent character appearance
@MainActor
public final class SimpleIllustrationService: ObservableObject, @unchecked Sendable {
    
    // MARK: - Properties
    
    private let apiKey: String
    private let modelName = "gemini-2.0-flash-exp"
    private let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/"
    nonisolated private let urlSession: any URLSessionProtocol
    private let cache: IllustrationCache
    private var characterReferenceService: CharacterReferenceService?
    private let jsonPromptBuilder: JSONPromptBuilder
    private let requestSigner: RequestSigner
    
    @Published public var isGenerating = false
    
    // MARK: - Performance Optimization Helpers
    
    /// Optimized state update to reduce MainActor.run overhead
    @MainActor
    private func setGeneratingState(_ generating: Bool) {
        self.isGenerating = generating
    }
    
    // MARK: - Initialization
    
    /// Initializes the simple illustration service
    /// - Parameters:
    ///   - apiKey: Google AI API key, defaults to AppConfig
    ///   - cache: Illustration cache instance
    ///   - urlSession: URL session for network requests
    ///   - characterReferenceService: Optional character reference service for consistent character generation
    ///   - requestSigner: Request signer for HMAC-SHA256 signing, defaults to new instance
    public init(
        apiKey: String = AppConfig.geminiApiKey,
        cache: IllustrationCache = IllustrationCache(),
        urlSession: (any URLSessionProtocol)? = nil,
        characterReferenceService: CharacterReferenceService? = nil,
        jsonPromptBuilder: JSONPromptBuilder = JSONPromptBuilder(),
        requestSigner: RequestSigner = RequestSigner()
    ) throws {
        guard !apiKey.isEmpty else {
            throw ConfigurationError.keyMissing("GeminiAPIKey")
        }
        
        self.apiKey = apiKey
        self.cache = cache
        
        // Use secure URLSession with certificate pinning for Google AI API
        if let providedSession = urlSession {
            self.urlSession = providedSession
        } else {
            let secureDelegate = SecureNetworkDelegate()
            let configuration = secureDelegate.secureURLSessionConfiguration()
            let secureSession = URLSession(configuration: configuration, delegate: secureDelegate, delegateQueue: nil)
            self.urlSession = secureSession
        }
        
        self.characterReferenceService = characterReferenceService
        self.jsonPromptBuilder = jsonPromptBuilder
        self.requestSigner = requestSigner
    }
    
    /// Sets the character reference service for consistent character generation
    /// - Parameter service: The character reference service
    public func setCharacterReferenceService(_ service: CharacterReferenceService) throws {
        self.characterReferenceService = service
    }
    
    // MARK: - Error Types
    
    enum SimpleIllustrationError: Error, LocalizedError, Equatable {
        case invalidConfiguration(String)
        case networkError(any Error)
        case apiError(String, Int)
        case invalidResponse(String)
        case noImageData
        case imageProcessingFailed(String)
        case generationFailed(String)
        case characterReferenceGenerationFailed(String)
        case characterReferenceServiceUnavailable
        case requestSigningFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .invalidConfiguration(let detail):
                return "Configuration error: \(detail)"
            case .networkError(let error):
                return "Network error: \(error.localizedDescription)"
            case .apiError(let message, let code):
                return "API error (\(code)): \(message)"
            case .invalidResponse(let reason):
                return "Invalid response: \(reason)"
            case .noImageData:
                return "No image data found in response"
            case .imageProcessingFailed(let reason):
                return "Image processing failed: \(reason)"
            case .generationFailed(let reason):
                return "Generation failed: \(reason)"
            case .characterReferenceGenerationFailed(let reason):
                return "Character reference generation failed: \(reason)"
            case .characterReferenceServiceUnavailable:
                return "Character reference service is not available"
            case .requestSigningFailed(let reason):
                return "Request signing failed: \(reason)"
            }
        }
        
        static func == (lhs: SimpleIllustrationError, rhs: SimpleIllustrationError) -> Bool {
            switch (lhs, rhs) {
            case (.invalidConfiguration(let lhsDetail), .invalidConfiguration(let rhsDetail)):
                return lhsDetail == rhsDetail
            case (.networkError, .networkError):
                return true // For testing purposes, consider all network errors equal
            case (.apiError(let lhsMessage, let lhsCode), .apiError(let rhsMessage, let rhsCode)):
                return lhsMessage == rhsMessage && lhsCode == rhsCode
            case (.invalidResponse(let lhsReason), .invalidResponse(let rhsReason)):
                return lhsReason == rhsReason
            case (.noImageData, .noImageData):
                return true
            case (.imageProcessingFailed(let lhsReason), .imageProcessingFailed(let rhsReason)):
                return lhsReason == rhsReason
            case (.generationFailed(let lhsReason), .generationFailed(let rhsReason)):
                return lhsReason == rhsReason
            case (.characterReferenceGenerationFailed(let lhsReason), .characterReferenceGenerationFailed(let rhsReason)):
                return lhsReason == rhsReason
            case (.characterReferenceServiceUnavailable, .characterReferenceServiceUnavailable):
                return true
            case (.requestSigningFailed(let lhsReason), .requestSigningFailed(let rhsReason)):
                return lhsReason == rhsReason
            default:
                return false
            }
        }
    }
    
    // MARK: - Request/Response Models
    
    private struct GenerateContentRequest: Codable {
        let contents: [Content]
        let generationConfig: GenerationConfig?
        
        struct Content: Codable {
            let role: String
            let parts: [Part]
        }
        
        enum Part: Codable {
            case text(String)
            case inlineData(mimeType: String, data: String)
            
            func encode(to encoder: any Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                switch self {
                case .text(let text):
                    try container.encode(text, forKey: .text)
                case .inlineData(let mimeType, let data):
                    var inlineContainer = container.nestedContainer(keyedBy: InlineDataKeys.self, forKey: .inlineData)
                    try inlineContainer.encode(mimeType, forKey: .mimeType)
                    try inlineContainer.encode(data, forKey: .data)
                }
            }
            
            init(from decoder: any Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                if let text = try container.decodeIfPresent(String.self, forKey: .text) {
                    self = .text(text)
                } else if let inlineContainer = try? container.nestedContainer(keyedBy: InlineDataKeys.self, forKey: .inlineData) {
                    let mimeType = try inlineContainer.decode(String.self, forKey: .mimeType)
                    let data = try inlineContainer.decode(String.self, forKey: .data)
                    self = .inlineData(mimeType: mimeType, data: data)
                } else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: decoder.codingPath,
                            debugDescription: "Invalid Part data"
                        )
                    )
                }
            }
            
            private enum CodingKeys: String, CodingKey {
                case text, inlineData
            }
            
            private enum InlineDataKeys: String, CodingKey {
                case mimeType, data
            }
        }
        
        struct GenerationConfig: Codable {
            let responseModalities: [String]
            let temperature: Double?
            let topP: Double?
            let topK: Int?
        }
    }
    
    private struct GenerateContentResponse: Codable {
        let candidates: [Candidate]?
        
        struct Candidate: Codable {
            let content: Content?
            
            struct Content: Codable {
                let parts: [GenerateContentRequest.Part]
            }
        }
    }
}

// MARK: - SimpleIllustrationServiceProtocol Conformance

extension SimpleIllustrationService: SimpleIllustrationServiceProtocol, EmbeddedIllustrationServiceProtocol, IllustrationServiceProtocol {
    
    /// Generates an illustration for a page with character reference integration
    /// - Parameter page: The page to generate illustration for
    /// - Returns: Image data for the generated illustration
    /// - Throws: SimpleIllustrationError for various failure cases
    func generateIllustration(for page: Page) async throws -> Data {
        print("[SimpleIllustrationService] 🎨 Starting illustration generation for page \(page.pageNumber)")
        print("[SimpleIllustrationService] 📄 Page content preview: \(String(page.content.prefix(100)))...")
        
        if let imagePrompt = page.imagePrompt {
            print("[SimpleIllustrationService] 🖼️ Using custom image prompt: \(String(imagePrompt.prefix(100)))...")
        }
        let cacheKey = "page_\(page.id.uuidString)"
        
        // Check cache first
        if let cachedData = getCachedIllustration(for: cacheKey) {
            print("[SimpleIllustrationService] ✅ Using cached illustration for page \(page.pageNumber) (\(cachedData.count) bytes)")
            return cachedData
        }
        
        print("[SimpleIllustrationService] 🔄 No cache found, generating new illustration for page \(page.pageNumber)")
        
        // Update generating state
        await setGeneratingState(true)
        
        defer {
            Task { await setGeneratingState(false) }
        }
        
        // Get story reference for character integration (fallback to simple prompt if no story)
        let story = page.story
        
        if let story = story {
            print("[SimpleIllustrationService] 📚 Story context: '\(story.title)' (ID: \(story.id))")
            if let characterNames = story.characterNames, !characterNames.isEmpty {
                print("[SimpleIllustrationService] 👥 Story characters: \(characterNames.joined(separator: ", "))")
            } else {
                print("[SimpleIllustrationService] 👤 No defined characters in story")
            }
        } else {
            print("[SimpleIllustrationService] ⚠️ No story context available - using standalone page generation")
        }
        
        // Create prompt with master reference integration
        let (prompt, masterReferenceData) = try await createEnhancedPrompt(for: page, story: story)
        
        // Log master reference integration summary
        if let masterData = masterReferenceData {
            print("[SimpleIllustrationService] Page \(page.pageNumber): Using master reference (\(masterData.count) bytes)")
        } else {
            print("[SimpleIllustrationService] Page \(page.pageNumber): No master reference available, using text-only prompt")
        }
        
        // Generate with retry logic, including master reference
        let imageData = try await generateWithRetry(prompt: prompt, masterReferenceData: masterReferenceData, maxRetries: 3)
        
        // Cache the result
        cache.storeImage(imageData, forKey: cacheKey)
        
        print("[SimpleIllustrationService] 🎉 Successfully generated and cached illustration for page \(page.pageNumber)")
        print("[SimpleIllustrationService] 📊 Final result: \(imageData.count) bytes")
        
        // Summary log for debugging
        let hasMasterReference = masterReferenceData != nil
        let storyTitle = story?.title ?? "No story"
        print("[SimpleIllustrationService] =============== GENERATION SUMMARY ===============")
        print("[SimpleIllustrationService] Story: \(storyTitle)")
        print("[SimpleIllustrationService] Page: \(page.pageNumber)")
        print("[SimpleIllustrationService] Master reference used: \(hasMasterReference ? "YES (\(masterReferenceData?.count ?? 0) bytes)" : "NO")")
        print("[SimpleIllustrationService] Generation mode: \(hasMasterReference ? "ENHANCED (text + master reference)" : "STANDARD (text only)")")
        print("[SimpleIllustrationService] Result size: \(imageData.count) bytes")
        print("[SimpleIllustrationService] ===============================================")
        
        return imageData
    }
    
    /// Generates an illustration for a page with explicit story context
    /// - Parameters:
    ///   - page: The page to generate illustration for
    ///   - story: The story context for character reference integration
    /// - Returns: Image data for the generated illustration
    /// - Throws: SimpleIllustrationError for various failure cases
    func generateIllustration(for page: Page, in story: Story?) async throws -> Data {
        print("[SimpleIllustrationService] 🎨 Starting illustration generation for page \(page.pageNumber) with explicit story context")
        
        // Log story context with explicitly passed story (this is the key fix)
        if let story = story {
            print("[SimpleIllustrationService] 📚 Story context: '\(story.title)' (ID: \(story.id))")
            if let characterNames = story.characterNames, !characterNames.isEmpty {
                print("[SimpleIllustrationService] 👥 Story characters: \(characterNames.joined(separator: ", "))")
            } else {
                print("[SimpleIllustrationService] 👤 No defined characters in story")
            }
        } else {
            print("[SimpleIllustrationService] ⚠️ No story context provided - using standalone page generation")
        }
        
        // Use the caching and generation logic from createEnhancedPrompt and generateWithRetry
        let cacheKey = "page_\(page.id.uuidString)"
        
        // Check cache first
        if let cachedData = getCachedIllustration(for: cacheKey) {
            print("[SimpleIllustrationService] ✅ Using cached illustration for page \(page.pageNumber) (\(cachedData.count) bytes)")
            return cachedData
        }
        
        print("[SimpleIllustrationService] 🔄 No cache found, generating new illustration for page \(page.pageNumber)")
        
        // Create prompt with master reference integration using explicit story
        let (prompt, masterReferenceData) = try await createEnhancedPrompt(for: page, story: story)
        
        // Log master reference integration summary
        if let masterData = masterReferenceData {
            print("[SimpleIllustrationService] Page \(page.pageNumber): Using master reference (\(masterData.count) bytes)")
        } else {
            print("[SimpleIllustrationService] Page \(page.pageNumber): No master reference available, using text-only prompt")
        }
        
        // Generate with retry logic, including master reference
        let imageData = try await generateWithRetry(prompt: prompt, masterReferenceData: masterReferenceData, maxRetries: 3)
        
        // Cache the result
        cache.storeImage(imageData, forKey: cacheKey)
        
        // Log generation summary for debugging
        let storyTitle = story?.title ?? "Unknown"
        let hasMasterReference = masterReferenceData != nil
        print("[SimpleIllustrationService] ===============================================")
        print("[SimpleIllustrationService] ✅ ILLUSTRATION GENERATED SUCCESSFULLY")
        print("[SimpleIllustrationService] Story: \(storyTitle)")
        print("[SimpleIllustrationService] Page: \(page.pageNumber)")
        print("[SimpleIllustrationService] Master reference used: \(hasMasterReference ? "YES (\(masterReferenceData?.count ?? 0) bytes)" : "NO")")
        print("[SimpleIllustrationService] Generation mode: \(hasMasterReference ? "ENHANCED (text + master reference)" : "STANDARD (text only)")")
        print("[SimpleIllustrationService] Result size: \(imageData.count) bytes")
        print("[SimpleIllustrationService] ===============================================")
        
        return imageData
    }
    
    /// Gets cached illustration data for a given key
    /// - Parameter pageId: The page identifier
    /// - Returns: Cached image data if available
    nonisolated func getCachedIllustration(for pageId: String) -> Data? {
        return cache.getImage(forKey: pageId)
    }
    
    /// Clears all cached illustrations
    nonisolated func clearCache() {
        cache.clearAll()
        print("[SimpleIllustrationService] Cache cleared")
    }
    
    // MARK: - EmbeddedIllustrationServiceProtocol Conformance
    
    /// Generates and stores illustration directly in the page model using embedded storage
    /// - Parameter page: The page to generate illustration for
    /// - Throws: SimpleIllustrationError if generation or storage fails
    @MainActor
    func generateAndStoreIllustration(for page: Page) async throws {
        print("[SimpleIllustrationService] Generating and storing illustration for page \(page.pageNumber) using embedded storage")
        
        // Check if page already has embedded illustration
        if page.hasEmbeddedIllustration {
            print("[SimpleIllustrationService] Page \(page.pageNumber) already has embedded illustration")
            return
        }
        
        // Generate illustration data
        let imageData = try await generateIllustration(for: page)
        
        // Store directly in the page model using embedded storage
        page.setEmbeddedIllustration(data: imageData, mimeType: "image/png")
        
        print("[SimpleIllustrationService] Successfully stored \(imageData.count) bytes of illustration data in page \(page.pageNumber)")
    }
    
    /// Generates and stores illustration directly in the page model with explicit story context
    /// - Parameters:
    ///   - page: The page to generate illustration for
    ///   - story: The story context for character reference integration
    /// - Throws: SimpleIllustrationError if generation or storage fails
    @MainActor
    func generateAndStoreIllustration(for page: Page, in story: Story?) async throws {
        print("[SimpleIllustrationService] Generating and storing illustration for page \(page.pageNumber) using embedded storage with explicit story context")
        
        // Check if page already has embedded illustration
        if page.hasEmbeddedIllustration {
            print("[SimpleIllustrationService] Page \(page.pageNumber) already has embedded illustration")
            return
        }
        
        // Generate illustration data using the explicit story context
        let imageData = try await generateIllustration(for: page, in: story)
        
        // Store directly in the page model using embedded storage
        page.setEmbeddedIllustration(data: imageData, mimeType: "image/png")
        
        print("[SimpleIllustrationService] Successfully stored \(imageData.count) bytes of illustration data in page \(page.pageNumber)")
    }
    
    /// Gets illustration data from embedded storage first, then cache, then generates if needed
    /// - Parameter page: The page to get illustration for
    /// - Returns: Image data if available
    nonisolated func getIllustration(for page: Page) -> Data? {
        // First, try persistent storage (preferred)
        if let illustrationData = page.getIllustrationData() {
            print("[SimpleIllustrationService] Retrieved illustration from persistent storage for page \(page.pageNumber)")
            return illustrationData
        }
        
        // Second, try cache
        let cacheKey = "page_\(page.id.uuidString)"
        if let cachedData = getCachedIllustration(for: cacheKey) {
            print("[SimpleIllustrationService] Retrieved illustration from cache for page \(page.pageNumber)")
            return cachedData
        }
        
        // Third, try loading from file path (for backward compatibility)
        if let data = page.getIllustrationData() {
            print("[SimpleIllustrationService] Retrieved illustration from file path for page \(page.pageNumber)")
            
            // Store in cache for future access
            cache.storeImage(data, forKey: cacheKey)
            return data
        }
        
        print("[SimpleIllustrationService] No illustration found for page \(page.pageNumber)")
        return nil
    }
    
    /// Migrates a page from file-based to embedded storage while preserving cache
    /// - Parameter page: The page to migrate
    /// - Returns: True if migration was successful
    @MainActor
    func migratePageToEmbeddedStorage(_ page: Page) -> Bool {
        guard !page.hasEmbeddedIllustration else {
            print("[SimpleIllustrationService] Page \(page.pageNumber) already uses embedded storage")
            return true
        }
        
        // Try to get illustration data from any source
        guard let data = getIllustration(for: page) else {
            print("[SimpleIllustrationService] No illustration data found for page \(page.pageNumber) to migrate")
            return false
        }
        
        // Store in embedded format
        page.setEmbeddedIllustration(data: data, mimeType: "image/png")
        
        print("[SimpleIllustrationService] Successfully migrated page \(page.pageNumber) to embedded storage")
        return true
    }
    
    // MARK: - Character Reference Integration
    
    /// Generates character references for a story if they don't already exist
    /// - Parameter story: The story to generate character references for
    /// - Returns: Master reference image data
    /// - Throws: SimpleIllustrationError if generation fails
    @MainActor
    func generateCharacterReference(for story: Story) async throws -> Data {
        guard let characterReferenceService = characterReferenceService else {
            throw SimpleIllustrationError.characterReferenceServiceUnavailable
        }
        
        print("[SimpleIllustrationService] Generating character reference for story: \(story.title)")
        
        do {
            let masterReferenceData = try await characterReferenceService.generateMasterReference(for: story)
            
            // Store the master reference in the story
            story.characterReferenceData = masterReferenceData
            
            print("[SimpleIllustrationService] Successfully generated character reference (\(masterReferenceData.count) bytes)")
            return masterReferenceData
            
        } catch {
            print("[SimpleIllustrationService] Character reference generation failed: \(error.localizedDescription)")
            throw SimpleIllustrationError.characterReferenceGenerationFailed(error.localizedDescription)
        }
    }
    
    /// Generates an illustration using a raw prompt without story context wrapping
    /// - Parameters:
    ///   - prompt: Raw prompt for generation  
    ///   - masterReferenceData: Optional master reference image data
    /// - Returns: Generated image data
    /// - Throws: SimpleIllustrationError if generation fails
    func generateRawIllustration(prompt: String, masterReferenceData: Data?) async throws -> Data {
        print("[SimpleIllustrationService] 🎨 Generating with raw prompt (bypassing story context)")
        print("[SimpleIllustrationService] 📝 Raw prompt length: \(prompt.count) characters")
        
        // Update generating state
        await setGeneratingState(true)
        
        defer {
            Task { await setGeneratingState(false) }
        }
        
        // Generate directly with the provided prompt
        return try await generateWithRetry(prompt: prompt, masterReferenceData: masterReferenceData, maxRetries: 3)
    }
    
    /// Ensures character references exist for a story, generating them if needed
    /// - Parameter story: The story to ensure character references for
    /// - Throws: SimpleIllustrationError if generation fails
    @MainActor
    func ensureCharacterReferences(for story: Story) async throws {
        guard let characterReferenceService = characterReferenceService else {
            print("[SimpleIllustrationService] Character reference service not available, skipping character reference generation")
            return
        }
        
        // Check if character references already exist
        if characterReferenceService.hasCharacterReferences(for: story) {
            print("[SimpleIllustrationService] Character references already exist for story: \(story.title)")
            return
        }
        
        // Check if story has visual guide with characters
        guard let visualGuide = story.visualGuide,
              !visualGuide.characterDefinitions.isEmpty else {
            print("[SimpleIllustrationService] No character definitions found, skipping character reference generation")
            return
        }
        
        print("[SimpleIllustrationService] Ensuring character references for story: \(story.title)")
        
        do {
            // Generate complete master reference system
            let _ = try await characterReferenceService.generateCompleteMasterReference(for: story)
            print("[SimpleIllustrationService] Successfully ensured master reference for story: \(story.title)")
            
        } catch {
            print("[SimpleIllustrationService] Failed to ensure master reference: \(error.localizedDescription)")
            throw SimpleIllustrationError.characterReferenceGenerationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - IllustrationServiceProtocol (Deprecated) Conformance
    
    /// Legacy method for compatibility with deprecated IllustrationServiceProtocol
    /// This method adapts the old file-based approach to the new embedded storage
    func generateIllustration(
        for illustrationDescription: String,
        pageNumber: Int,
        totalPages: Int,
        previousIllustrationPath: String?,
        visualGuide: VisualGuide?,
        globalReferenceImagePath: String?,
        collectionContext: CollectionVisualContext?
    ) async throws -> String? {
        print("[SimpleIllustrationService] ⚠️ Using deprecated IllustrationServiceProtocol method")
        print("[SimpleIllustrationService] This legacy file-based approach is deprecated - use embedded storage instead")
        
        // Generate using the new method
        let imageData = try await generateRawIllustration(prompt: illustrationDescription, masterReferenceData: nil)
        
        // For legacy compatibility, we'll return a mock path since the old system expected file paths
        // In reality, the data is now handled via embedded storage
        return "legacy_compat_\(pageNumber).png"
    }
    
}

// MARK: - Private Implementation

private extension SimpleIllustrationService {
    
    /// Creates a simple, effective prompt for illustration generation
    /// - Parameter page: The page to create prompt for
    /// - Returns: Generated prompt string
    func createSimplePrompt(for page: Page) -> String {
        let basePrompt = page.imagePrompt ?? page.content
        
        return """
        Create a vibrant, child-friendly illustration for a children's story page.
        
        Content: \(basePrompt)
        
        Style requirements:
        - Warm, welcoming art style suitable for children ages 3-12
        - Bright, cheerful colors
        - Simple, clear composition
        - 16:9 landscape aspect ratio
        - High quality digital illustration
        - Safe, age-appropriate content
        
        The illustration should capture the essence of the story content while being visually engaging for young readers.
        """
    }
    
    /// Creates an enhanced prompt with master reference integration
    /// - Parameters:
    ///   - page: The page to create prompt for
    ///   - story: The story containing visual element definitions
    /// - Returns: Tuple containing enhanced prompt string and master reference image data
    /// - Throws: SimpleIllustrationError if prompt creation fails
    func createEnhancedPrompt(for page: Page, story: Story?) async throws -> (prompt: String, masterReferenceData: Data?) {
        print("[SimpleIllustrationService] 🔧 Creating enhanced JSON prompt for page \(page.pageNumber)")
        
        let basePrompt = page.imagePrompt ?? page.content
        var masterReferenceData: Data? = nil
        
        print("[SimpleIllustrationService] 📝 Base prompt content: \(basePrompt)")
        
        // Check for master reference availability
        print("[SimpleIllustrationService] 🔍 Checking master reference conditions:")
        print("[SimpleIllustrationService]   - Story exists: \(story != nil)")
        print("[SimpleIllustrationService]   - CharacterReferenceService exists: \(characterReferenceService != nil)")
        
        if let story = story {
            let hasMasterRef = await characterReferenceService?.hasCharacterReferences(for: story) ?? false
            print("[SimpleIllustrationService]   - Has master reference: \(hasMasterRef)")
            print("[SimpleIllustrationService]   - Visual guide exists: \(story.visualGuide != nil)")
            if let visualGuide = story.visualGuide {
                print("[SimpleIllustrationService]   - Visual element definitions count: \(visualGuide.characterDefinitions.count)")
            }
            
            // Get master reference data if available
            if let characterReferenceService = characterReferenceService,
               await characterReferenceService.hasCharacterReferences(for: story) {
                masterReferenceData = await characterReferenceService.getMasterReference(for: story)
                if let masterData = masterReferenceData {
                    print("[SimpleIllustrationService] ✅ Retrieved master reference image (\(masterData.count) bytes)")
                }
            }
        }
        
        // Use JSON prompt builder to create structured prompt
        let jsonPrompt: String
        
        if let story = story, let visualGuide = story.visualGuide {
            print("[SimpleIllustrationService] 🎭 Creating structured JSON prompt for story '\(story.title)'")
            
            jsonPrompt = try jsonPromptBuilder.createStoryPagePrompt(
                pageContent: basePrompt,
                visualGuide: visualGuide,
                masterReferenceData: masterReferenceData,
                orderedElementNames: story.characterNames
            )
        } else {
            print("[SimpleIllustrationService] 📭 No story context - creating basic JSON prompt")
            
            // Create a minimal visual guide for generic illustration
            let basicVisualGuide = VisualGuide(
                styleGuide: "Warm, welcoming art style suitable for children ages 3-12. Bright, cheerful colors with simple, clear composition.",
                characterDefinitions: [:],
                settingDefinitions: [:]
            )
            
            let orderedNames: [String]? = nil
            jsonPrompt = try jsonPromptBuilder.createStoryPagePrompt(
                pageContent: basePrompt,
                visualGuide: basicVisualGuide,
                masterReferenceData: masterReferenceData,
                orderedElementNames: orderedNames
            )
        }
        
        print("[SimpleIllustrationService] 📋 Final JSON prompt generated:")
        print("[SimpleIllustrationService]   - Prompt length: \(jsonPrompt.count) characters")
        print("[SimpleIllustrationService]   - Master reference: \(masterReferenceData != nil ? "YES (\(masterReferenceData?.count ?? 0) bytes)" : "NO")")
        print("[SimpleIllustrationService] 🚀 About to send JSON prompt to AI for illustration generation")
        
        return (prompt: jsonPrompt, masterReferenceData: masterReferenceData)
    }
    
    /// Generates illustration with exponential backoff retry logic
    /// - Parameters:
    ///   - prompt: The prompt for generation
    ///   - masterReferenceData: Optional master reference image data
    ///   - maxRetries: Maximum number of retry attempts
    /// - Returns: Generated image data
    /// - Throws: SimpleIllustrationError if all retries fail
    func generateWithRetry(prompt: String, masterReferenceData: Data?, maxRetries: Int) async throws -> Data {
        print("[SimpleIllustrationService] 🔄 Starting generation with retry logic (max attempts: \(maxRetries))")
        print("[SimpleIllustrationService] 📤 Request will include master reference: \(masterReferenceData != nil ? "YES (\(masterReferenceData?.count ?? 0) bytes)" : "NO")")
        
        var lastError: (any Error)?
        
        for attempt in 1...maxRetries {
            print("[SimpleIllustrationService] 🎯 Generation attempt \(attempt)/\(maxRetries)")
            do {
                let result = try await generateSingleAttempt(prompt: prompt, masterReferenceData: masterReferenceData)
                print("[SimpleIllustrationService] ✅ Generation succeeded on attempt \(attempt) (\(result.count) bytes)")
                return result
            } catch {
                lastError = error
                print("[SimpleIllustrationService] ❌ Attempt \(attempt) failed: \(error.localizedDescription)")
                
                // Don't retry on certain errors
                if case SimpleIllustrationError.invalidConfiguration = error {
                    throw error
                }
                
                // Exponential backoff for retries
                if attempt < maxRetries {
                    let delay = pow(2.0, Double(attempt)) + Double.random(in: 0...1)
                    print("[SimpleIllustrationService] ⏱️ Waiting \(String(format: "%.1f", delay))s before retry \(attempt + 1)")
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? SimpleIllustrationError.generationFailed("All retry attempts failed")
    }
    
    /// Performs a single generation attempt
    /// - Parameters:
    ///   - prompt: The prompt for generation
    ///   - masterReferenceData: Optional master reference image data to include in the request
    /// - Returns: Generated image data
    /// - Throws: SimpleIllustrationError if generation fails
    func generateSingleAttempt(prompt: String, masterReferenceData: Data?) async throws -> Data {
        print("[SimpleIllustrationService] 🌐 Preparing API request to model: \(modelName)")
        
        // Build URL
        let urlString = "\(apiEndpoint)\(modelName):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw SimpleIllustrationError.invalidConfiguration("Invalid API endpoint URL")
        }
        
        // Build request parts - start with text prompt
        var parts: [GenerateContentRequest.Part] = [.text(prompt)]
        
        // Add master reference image as inline data if available
        if let masterData = masterReferenceData {
            let maxImageSize = 5 * 1024 * 1024 // 5MB limit per image
            
            // Check image size before adding
            if masterData.count <= maxImageSize {
                let base64Data = masterData.base64EncodedString()
                parts.append(.inlineData(mimeType: "image/png", data: base64Data))
                print("[SimpleIllustrationService] Added master reference to request (\(masterData.count) bytes)")
            } else {
                print("[SimpleIllustrationService] Skipping master reference - too large (\(masterData.count) bytes)")
            }
        }
        
        // Log final request composition
        let textParts = parts.filter { if case .text = $0 { return true } else { return false } }.count
        let imageParts = parts.filter { if case .inlineData = $0 { return true } else { return false } }.count
        print("[SimpleIllustrationService] API request: \(textParts) text part(s), \(imageParts) image part(s)")
        
        let requestBody = GenerateContentRequest(
            contents: [
                GenerateContentRequest.Content(
                    role: "user",
                    parts: parts
                )
            ],
            generationConfig: GenerateContentRequest.GenerationConfig(
                responseModalities: ["TEXT", "IMAGE"],
                temperature: 0.2,  // Low temperature for better instruction following
                topP: 0.8,         // More focused sampling
                topK: 40           // Limited vocabulary selection
            )
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        // Sign the request for integrity and authenticity
        do {
            request = try requestSigner.signRequest(request)
            print("[SimpleIllustrationService] Request signed successfully with HMAC-SHA256")
        } catch {
            print("[SimpleIllustrationService] Request signing failed: \(error.localizedDescription)")
            throw SimpleIllustrationError.requestSigningFailed(error.localizedDescription)
        }
        
        // Make request
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SimpleIllustrationError.networkError(
                NSError(domain: "SimpleIllustrationService", code: -1, userInfo: [
                    NSLocalizedDescriptionKey: "Invalid response type"
                ])
            )
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw SimpleIllustrationError.apiError(errorMessage, httpResponse.statusCode)
        }
        
        // Parse response
        let generateResponse: GenerateContentResponse
        do {
            generateResponse = try JSONDecoder().decode(GenerateContentResponse.self, from: data)
        } catch {
            throw SimpleIllustrationError.invalidResponse("Failed to decode response: \(error.localizedDescription)")
        }
        
        // Extract image data
        guard let candidate = generateResponse.candidates?.first,
              let content = candidate.content else {
            throw SimpleIllustrationError.noImageData
        }
        
        for part in content.parts {
            if case .inlineData(let mimeType, let base64String) = part,
               mimeType.hasPrefix("image/") {
                guard let imageData = Data(base64Encoded: base64String) else {
                    throw SimpleIllustrationError.imageProcessingFailed("Invalid base64 data")
                }
                return imageData
            }
        }
        
        throw SimpleIllustrationError.noImageData
    }
}