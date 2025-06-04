// magical-stories/App/Services/IllustrationService.swift
import Foundation
import GoogleGenerativeAI  // Import the Google AI SDK
import SwiftData  // Import SwiftData for ModelContext
#if os(iOS)
import UIKit  // Import UIKit for image processing on iOS
#endif

/// Errors specific to the IllustrationService.
enum IllustrationError: Error, LocalizedError {
    case missingConfiguration(String)
    case invalidURL
    case networkError(Error)
    case apiError(Error)  // General API error from the SDK
    case invalidResponse(String)
    // case tokenError(Error) // SDK likely handles auth internally with API key
    case noImageDataFound  // Added case for when the response lacks image data
    case imageProcessingError(String)
    case generationFailed(String)  // Specific failure like content filtering
    case unsupportedModel

    var errorDescription: String? {
        switch self {
        case .missingConfiguration(let detail):
            return "Configuration error: \(detail)"
        case .invalidURL:
            // This might still be relevant if constructing URLs from responses
            return "Invalid URL encountered."
        case .networkError(let underlyingError):
            // SDK might wrap network errors, map to apiError or keep specific
            return "Network request failed: \(underlyingError.localizedDescription)"
        case .apiError(let underlyingError):
            // Provide more context from the underlying SDK error if possible
            return "Google AI API request failed: \(underlyingError.localizedDescription)"
        case .invalidResponse(let reason):
            return "Failed to parse or understand API response: \(reason)"
        case .noImageDataFound:
            return "No image data found in the API response."
        case .imageProcessingError(let reason):
            return "Failed to process image data: \(reason)"
        case .generationFailed(let reason):
            return "Image generation failed: \(reason)"
        case .unsupportedModel:
            return "The configured generative model does not support image generation."
        }
    }

    // Helper to check if an IllustrationError is related to decoding
    var isDecodingError: Bool {
        switch self {
        case .invalidResponse, .noImageDataFound, .imageProcessingError:
            return true
        default:
            return false
        }
    }
}

/// Service responsible for generating illustrations based on text prompts using the Google AI SDK.
public class IllustrationService: IllustrationServiceProtocol, ObservableObject {
    @Published var isGenerating = false

    private let apiKey: String
    // Update to the correct model that supports image generation
    private let modelName = "gemini-2.0-flash-exp-image-generation"
    private let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/"
    private let urlSession: URLSessionProtocol  // Use the protocol instead of concrete class

    // Removed generativeModel property as we are using REST API directly

    /// Initializes the service, potentially fetching the API key from configuration.
    /// - Parameter apiKey: The Google AI API key. Defaults to loading from `AppConfig`.
    /// - Throws: `ConfigurationError` if the API key is missing.
    /// Public designated initializer. Creates the real GenerativeModel.
    public init(apiKey: String = AppConfig.geminiApiKey) throws {
        guard !apiKey.isEmpty else {
            // Use the specific error type defined in AppConfig or a general one
            throw ConfigurationError.keyMissing("GeminiAPIKey")
        }
        self.apiKey = apiKey
        self.urlSession = URLSession.shared  // Initialize default session
        // No longer need to initialize generativeModel here
    }

    /// Public initializer for testing purposes. (Should ideally be internal, but trying public for visibility)
    public init(apiKey: String, urlSession: URLSessionProtocol) throws {
        guard !apiKey.isEmpty else {
            throw ConfigurationError.keyMissing("GeminiAPIKey")
        }
        self.apiKey = apiKey
        self.urlSession = urlSession
    }


    /// Generates an illustration using a context-rich description and the previous page's illustration.
    /// - Parameters:
    ///   - illustrationDescription: The detailed, preprocessed description for the illustration.
    ///   - pageNumber: The current page number.
    ///   - totalPages: The total number of pages in the story.
    ///   - previousIllustrationPath: The relative path to the previous page's illustration, if available.
    /// - Returns: A relative path string pointing to the generated illustration, or `nil` if generation fails gracefully.
    /// - Throws: `IllustrationError` for configuration, network, or API issues.
    public func generateIllustration(
        for illustrationDescription: String,
        pageNumber: Int,
        totalPages: Int,
        previousIllustrationPath: String? = nil,
        visualGuide: VisualGuide? = nil,
        globalReferenceImagePath: String? = nil,
        collectionContext: CollectionVisualContext? = nil
    ) async throws -> String? {
        // Log the generation start with task type info
        let taskType = pageNumber == 0 ? "GLOBAL REFERENCE" : "PAGE ILLUSTRATION"
        print("[IllustrationService] Starting generation of \(taskType) (page \(pageNumber) of \(totalPages))")
        print("[IllustrationService] Has visual guide: \(visualGuide != nil)")
        print("[IllustrationService] Has previous illustration reference: \(previousIllustrationPath != nil)")
        print("[IllustrationService] Has global reference: \(globalReferenceImagePath != nil)")
        print("[IllustrationService] Has collection context: \(collectionContext != nil)")
        
        // Use PromptBuilder to generate appropriate prompt based on page type
        let promptBuilder = PromptBuilder()
        let enhancedPrompt: String
        
        if pageNumber == 0 {
            // Global Reference Generation (Page 0)
            guard let visualGuide = visualGuide else {
                throw IllustrationError.invalidResponse("Visual guide is required for global reference generation")
            }
            let storyTitle = "Story Title" // TODO: Pass actual story title
            enhancedPrompt = promptBuilder.buildEnhancedGlobalReferencePrompt(
                visualGuide: visualGuide,
                storyStructure: nil, // TODO: Pass story structure if available
                storyTitle: storyTitle,
                collectionContext: collectionContext
            )
            print("[IllustrationService] Generated enhanced global reference prompt with collection context")
        } else {
            // Page Illustration Generation (Page > 0)
            guard let visualGuide = visualGuide else {
                throw IllustrationError.invalidResponse("Visual guide is required for page illustration generation")
            }
            
            // Create a temporary Page object for the prompt builder
            let tempPage = Page(
                content: illustrationDescription,
                pageNumber: pageNumber
            )
            
            enhancedPrompt = promptBuilder.buildEnhancedSequentialIllustrationPrompt(
                page: tempPage,
                pageIndex: pageNumber - 1, // Convert to 0-based index
                storyStructure: nil, // TODO: Pass story structure if available
                visualGuide: visualGuide,
                globalReferenceImageBase64: globalReferenceImagePath != nil ? "available" : nil,
                previousIllustrationBase64: previousIllustrationPath != nil ? "available" : nil,
                collectionContext: collectionContext
            )
            print("[IllustrationService] Generated enhanced sequential page prompt with visual references and collection context")
        }

        print(
            "[IllustrationService] Generating illustration for page \(pageNumber) with description length: \(illustrationDescription.count) characters"
        )
        print("[IllustrationService] Enhanced prompt length: \(enhancedPrompt.count) characters (should be small without embedded images)")

        var lastError: Error?

        for attempt in 1...5 {
            do {
                // 1. Construct URL
                let urlString = "\(apiEndpoint)\(modelName):generateContent?key=\(apiKey)"
                guard let url = URL(string: urlString) else {
                    throw IllustrationError.invalidURL
                }

                // 2. Prepare Request Body (Gemini generateContent structure)
                var parts: [GenerateContentRequest.Part] = []

                // Add the text part with explicit dimension requirements
                let dimensionPrompt = enhancedPrompt + "\n\nIMAGE SPECIFICATIONS:\n- Generate image in 16:9 landscape aspect ratio\n- Dimensions should be wider than tall (landscape orientation)\n- Compose the scene for horizontal/landscape viewing"
                parts.append(.text(dimensionPrompt))
                
                // Add global reference image as separate part if available (for page illustrations)
                if pageNumber > 0, let globalPath = globalReferenceImagePath {
                    do {
                        let globalImageData = try await loadImageAsBase64(from: globalPath)
                        parts.append(.inlineData(mimeType: "image/png", data: globalImageData))
                        print("[IllustrationService] Added global reference image as separate API part")
                    } catch {
                        print("[IllustrationService] Warning: Could not load global reference for API: \(error.localizedDescription)")
                    }
                }
                
                // Add previous illustration as separate part if available (for page illustrations)
                if pageNumber > 0, let previousPath = previousIllustrationPath {
                    do {
                        let previousImageData = try await loadImageAsBase64(from: previousPath)
                        parts.append(.inlineData(mimeType: "image/png", data: previousImageData))
                        print("[IllustrationService] Added previous illustration as separate API part")
                    } catch {
                        print("[IllustrationService] Warning: Could not load previous illustration for API: \(error.localizedDescription)")
                    }
                }

                let requestBody = GenerateContentRequest(
                    contents: [GenerateContentRequest.Content(parts: parts)],
                    generationConfig: GenerateContentRequest.GenerationConfig(responseModalities: [
                        "TEXT", "IMAGE",
                    ])
                )

                // For debugging
                print("--- IllustrationService: Using model: \(modelName) ---")

                // 3. Prepare URLRequest
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                request.httpBody = try JSONEncoder().encode(requestBody)
                // Avoid logging full body if sensitive or large
                // print("--- IllustrationService: Sending request to \(url) with body: \(String(data: request.httpBody ?? Data(), encoding: .utf8) ?? \"Invalid Body\") ---")

                // 4. Perform Network Request
                let (data, response) = try await self.urlSession.data(for: request)  // Use injected session

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw IllustrationError.invalidResponse("Did not receive HTTP response.")
                }

                print(
                    "--- IllustrationService: Received HTTP status code: \(httpResponse.statusCode) ---"
                )
                let responseBodyString =
                    String(data: data, encoding: .utf8) ?? "Could not decode response body"
                // Log response body only on error or debug builds if needed
                // print("--- IllustrationService: Response Body: \(responseBodyString) ---")

                guard (200...299).contains(httpResponse.statusCode) else {
                    print(
                        "--- IllustrationService: API Error Response Body: \(responseBodyString) ---"
                    )  // Log error body
                    throw IllustrationError.apiError(
                        NSError(
                            domain: "HTTPError", code: httpResponse.statusCode,
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    "API request failed with status \(httpResponse.statusCode). Detail: \(responseBodyString)"
                            ])
                    )
                }

                // 5. Decode Successful Response (Gemini generateContent structure)
                let generateContentResponse: GenerateContentResponse
                do {
                    generateContentResponse = try JSONDecoder().decode(
                        GenerateContentResponse.self, from: data)
                } catch let decodeError {
                    print(
                        "--- IllustrationService: Failed to decode Gemini response: \(decodeError). Body was: \(responseBodyString) ---"
                    )
                    throw IllustrationError.invalidResponse(
                        "Failed to decode Gemini API response: \(decodeError.localizedDescription)"
                    )
                }

                // When extracting image data from response, look for "data" field in inline_data
                guard let firstCandidate = generateContentResponse.candidates?.first,
                    let candidateParts = firstCandidate.content?.parts,
                    !candidateParts.isEmpty
                else {
                    print("--- IllustrationService: No candidates or parts in response ---")
                    throw IllustrationError.noImageDataFound
                }

                // Look for inline_data with an image
                var foundImageData: Data? = nil
                var foundMimeType: String? = nil

                for part in candidateParts {
                    if case .inlineData(let mimeType, let base64String) = part {
                        if mimeType.starts(with: "image/") {
                            guard let imageData = Data(base64Encoded: base64String) else {
                                continue
                            }
                            foundImageData = imageData
                            foundMimeType = mimeType
                            break
                        }
                    }
                }

                guard let imageData = foundImageData, let mimeType = foundMimeType else {
                    print("--- IllustrationService: No image data found in response parts ---")
                    throw IllustrationError.noImageDataFound
                }

                let relativePath = try saveImageDataToPersistentDirectory(
                    imageData: imageData, mimeType: mimeType)
                // Log successful generation with more details
                let taskType = pageNumber == 0 ? "GLOBAL REFERENCE" : "PAGE ILLUSTRATION"
                print("[IllustrationService] SUCCESS: Generated \(taskType) for page \(pageNumber) of \(totalPages)")
                print("[IllustrationService] Saved at path: \(relativePath)")
                print("[IllustrationService] Used visual guide: \(visualGuide != nil)")
                print("[IllustrationService] Used previous illustration: \(previousIllustrationPath != nil)")
                return relativePath

            } catch let error as IllustrationError {
                lastError = error
                print(
                    "--- IllustrationService: Attempt \(attempt) failed with IllustrationError: \(error.localizedDescription) ---"
                )
            } catch {
                lastError = error
                print(
                    "--- IllustrationService: Attempt \(attempt) failed with generic error: \(error.localizedDescription) ---"
                )
            }

            if let currentError = lastError as? IllustrationError,
                case .generationFailed = currentError
            {
                print("--- IllustrationService: Generation failed, not retrying. ---")
                break
            }

            if attempt < 5 {
                try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...3_000_000_000))
            }
        }

        if let error = lastError {
            AIErrorManager.logError(
                error, source: "IllustrationService",
                additionalInfo:
                    "All retries failed for contextual illustration page \(pageNumber)/\(totalPages)"
            )
            // Re-throw the last encountered error after exhausting retries
            throw error
        }

        // Should not be reached if retries failed, as the error is re-thrown above.
        // Return nil only if the loop somehow completes without success or error (unlikely).
        print(
            "--- IllustrationService: Warning - Reached end of contextual generation function unexpectedly after retries without success or throwing an error. ---"
        )
        return nil
    }

    /// Saves image data to a temporary file and returns its URL.
    private func saveImageDataToTemporaryFile(imageData: Data, mimeType: String) throws -> URL {
        let fileManager = FileManager.default
        let tempDirectoryURL = fileManager.temporaryDirectory
        let uniqueID = UUID().uuidString
        // Determine file extension based on MIME type
        let fileExtension: String
        switch mimeType.lowercased() {
        case "image/png": fileExtension = "png"
        case "image/jpeg", "image/jpg": fileExtension = "jpg"
        case "image/webp": fileExtension = "webp"
        // Add other supported types if needed
        default: fileExtension = "tmp"  // Default extension if type is unknown
        }
        let fileName = "\(uniqueID).\(fileExtension)"
        let fileURL = tempDirectoryURL.appendingPathComponent(fileName)

        do {
            try imageData.write(to: fileURL)
            return fileURL
        } catch {
            let processingError = IllustrationError.imageProcessingError(
                "Failed to save image data to temporary file: \(error.localizedDescription)")
            AIErrorManager.logError(
                processingError, source: "IllustrationService", additionalInfo: "File write failed")
            throw processingError
        }
    }
    /// Saves image data to persistent app directory and returns relative path string.
    private func saveImageDataToPersistentDirectory(imageData: Data, mimeType: String) throws
        -> String
    {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil,
            create: true)
        let illustrationsDir = appSupportURL.appendingPathComponent(
            "Illustrations", isDirectory: true)

        // Create Illustrations directory if it doesn't exist
        if !fileManager.fileExists(atPath: illustrationsDir.path) {
            try fileManager.createDirectory(
                at: illustrationsDir, withIntermediateDirectories: true, attributes: nil)
        }

        let uniqueID = UUID().uuidString
        let fileExtension: String
        switch mimeType.lowercased() {
        case "image/png": fileExtension = "png"
        case "image/jpeg", "image/jpg": fileExtension = "jpg"
        case "image/webp": fileExtension = "webp"
        default: fileExtension = "tmp"
        }
        let fileName = "\(uniqueID).\(fileExtension)"
        let fileURL = illustrationsDir.appendingPathComponent(fileName)

        do {
            try imageData.write(to: fileURL)
            // Return relative path from Application Support directory
            let relativePath = "Illustrations/\(fileName)"
            return relativePath
        } catch {
            let processingError = IllustrationError.imageProcessingError(
                "Failed to save image data to persistent directory: \(error.localizedDescription)")
            AIErrorManager.logError(
                processingError, source: "IllustrationService", additionalInfo: "File write failed")
            throw processingError
        }
    }

    /// Loads image data and determines MIME type from persistent app directory.
    private func loadImageDataFromPersistentDirectory(relativePath: String) throws -> (
        data: Data, mimeType: String
    ) {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil,
            create: false)  // Don't create if it doesn't exist when loading

        let fileURL = appSupportURL.appendingPathComponent(relativePath)

        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw IllustrationError.imageProcessingError(
                "Previous illustration file not found at path: \(relativePath)")
        }

        do {
            let imageData = try Data(contentsOf: fileURL)
            let mimeType = mimeType(for: fileURL)
            return (imageData, mimeType)
        } catch {
            throw IllustrationError.imageProcessingError(
                "Failed to load previous illustration data from path \(relativePath): \(error.localizedDescription)"
            )
        }
    }

    /// Determines the MIME type based on the file extension.
    private func mimeType(for fileURL: URL) -> String {
        let fileExtension = fileURL.pathExtension.lowercased()
        switch fileExtension {
        case "png": return "image/png"
        case "jpeg", "jpg": return "image/jpeg"
        case "webp": return "image/webp"
        // Add heic/heif if needed and supported by API
        // case "heic": return "image/heic"
        // case "heif": return "image/heif"
        default: return "application/octet-stream"  // Default or best guess
        }
    }

    /// Loads an image from persistent storage and converts it to base64 string for prompt inclusion
    /// - Parameter relativePath: The relative path to the image file in persistent storage
    /// - Returns: Base64 encoded string of the image data
    /// - Throws: IllustrationError if the image cannot be loaded or encoded
    private func loadImageAsBase64(from relativePath: String) async throws -> String {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil,
            create: false)
        
        let fileURL = appSupportURL.appendingPathComponent(relativePath)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            throw IllustrationError.imageProcessingError(
                "Image file not found at path: \(relativePath)")
        }
        
        do {
            let originalImageData = try Data(contentsOf: fileURL)
            print("[IllustrationService] Original image size: \(originalImageData.count) bytes")
            
            // Compress image to reduce API payload size
            let compressedImageData = try compressImageForAPI(originalImageData)
            let base64String = compressedImageData.base64EncodedString()
            print("[IllustrationService] Compressed image from \(originalImageData.count) to \(compressedImageData.count) bytes (\(String(format: "%.1f", Double(compressedImageData.count) / Double(originalImageData.count) * 100))% of original)")
            return base64String
        } catch {
            throw IllustrationError.imageProcessingError(
                "Failed to load image data from path \(relativePath): \(error.localizedDescription)")
        }
    }
    
    /// Compresses image data to reduce API payload size while maintaining quality for reference
    /// - Parameter imageData: Original image data
    /// - Returns: Compressed image data
    /// - Throws: IllustrationError if compression fails
    private func compressImageForAPI(_ imageData: Data) throws -> Data {
        #if os(iOS)
        // Convert to UIImage
        guard let image = UIImage(data: imageData) else {
            throw IllustrationError.imageProcessingError("Failed to create UIImage from data")
        }
        
        // Resize to maximum 512x512 for API efficiency (maintains aspect ratio)
        let maxSize: CGFloat = 512
        let resizedImage: UIImage
        
        if max(image.size.width, image.size.height) > maxSize {
            let aspectRatio = image.size.width / image.size.height
            let newSize: CGSize
            
            if image.size.width > image.size.height {
                newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
            } else {
                newSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
            }
            
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            resizedImage = image
        }
        
        // Compress with medium quality JPEG (good balance of size vs quality)
        guard let compressedData = resizedImage.jpegData(compressionQuality: 0.6) else {
            throw IllustrationError.imageProcessingError("Failed to compress image as JPEG")
        }
        
        return compressedData
        #else
        // For non-iOS platforms, return original data
        return imageData
        #endif
    }

    /// Generates an illustration for a specific Page model, updating its status during the process.
    /// This method updates the illustration status to reflect the generation progress.
    /// - Parameters:
    ///   - page: The page for which to generate an illustration.
    ///   - context: The ModelContext to use for updating the page.
    /// - Returns: Nothing, but updates the page's illustrationStatus and illustrationPath.
    /// - Throws: IllustrationError if the generation fails.
    func generateIllustration(for page: Page, context: ModelContext) async throws {
        print("--- IllustrationService: Starting generation for page \(page.id) ---")

        // Update service state for UI observation
        await MainActor.run {
            self.isGenerating = true
        }

        // Ensure ModelContext operations happen on the main actor to avoid concurrency issues
        try await MainActor.run {
            // Update status to generating
            page.illustrationStatus = .generating
            try context.save()
        }

        // Use the page content directly as the illustration description
        let illustrationDescription = page.imagePrompt ?? createDefaultPrompt(from: page.content)

        do {
            // Call the main generation method with proper parameters
            if let relativePath = try await generateIllustration(
                for: illustrationDescription,
                pageNumber: page.pageNumber,
                totalPages: 1, // Default to 1 if not available in context
                previousIllustrationPath: nil,
                visualGuide: nil, // Could be enhanced to use a default visual guide
                globalReferenceImagePath: nil
            ) {
                // Update the page with the result path and set status to ready
                try await MainActor.run {
                    page.illustrationPath = relativePath
                    page.illustrationStatus = .ready
                    try context.save()
                }

                print(
                    "--- IllustrationService: Successfully generated illustration for page \(page.id) ---"
                )
            } else {
                // If no path was returned but no error was thrown, set to failed
                try await MainActor.run {
                    page.illustrationStatus = .failed
                    try context.save()
                }

                print(
                    "--- IllustrationService: No illustration path returned for page \(page.id) ---"
                )
                throw IllustrationError.noImageDataFound
            }
        } catch {
            // Update status to failed
            try await MainActor.run {
                page.illustrationStatus = .failed
                try context.save()
            }

            // Log the error
            AIErrorManager.logError(
                error, source: "IllustrationService",
                additionalInfo: "Failed to generate illustration for page \(page.id)"
            )

            print(
                "--- IllustrationService: Failed to generate illustration for page \(page.id): \(error.localizedDescription) ---"
            )

            // Re-throw the error
            throw error
        }

        // Update service state for UI observation after completion (whether successful or not)
        await MainActor.run {
            self.isGenerating = false
        }
    }


    /// Creates a default prompt from the page content if none is provided
    private func createDefaultPrompt(from content: String) -> String {
        // Simply return the content, or a shortened version if it's too long
        if content.count > 300 {
            return String(content.prefix(300)) + "..."
        }
        return content
    }

    /// Updates all pages in a story to have the new illustration status
    /// This is a migration helper method to support existing data
    func migrateIllustrationStatus(for pages: [Page], context: ModelContext) throws {
        for page in pages {
            // If the page has an illustration path but status is pending, update to ready
            if page.illustrationStatus == .pending && page.illustrationPath != nil {
                page.illustrationStatus = .ready
            }
        }
        try context.save()
    }

    /// Generates illustrations for all pages in the story asynchronously
    /// Returns immediately after setting up the generation tasks
    func generateIllustrationsForStory(_ story: Story, context: ModelContext) {
        for page in story.pages {
            // Skip pages that already have illustrations or are in progress
            if page.illustrationStatus == .ready || page.illustrationStatus == .generating {
                continue
            }

            // Start a background task for each page
            Task {
                do {
                    try await generateIllustration(for: page, context: context)
                } catch {
                    print(
                        "--- IllustrationService: Background generation failed for page \(page.id): \(error.localizedDescription) ---"
                    )
                    // Error is already logged in generateIllustration method
                }
            }
        }
    }
}

// Internal protocol and extension definitions removed.

// MARK: - Imagen API Structs (Still used by AIGenerationStrategy)

struct ImagenRequestBody: Codable {
    let instances: [ImagenInstance]
    let parameters: ImagenParameters
}

struct ImagenInstance: Codable {
    let prompt: String
}

struct ImagenParameters: Codable {
    let sampleCount: Int
    let width: Int?
    let height: Int?

    init(sampleCount: Int, width: Int? = nil, height: Int? = nil) {
        self.sampleCount = sampleCount
        self.width = width
        self.height = height
    }
}

struct ImagenPredictionResponse: Codable {
    let predictions: [ImagenPrediction]
}

struct ImagenPrediction: Codable {
    let bytesBase64Encoded: String?
    let mimeType: String?
}

// MARK: - Internal Helper Structs for Gemini generateContent REST API (Made internal for testing)

struct GenerateContentRequest: Codable {
    let contents: [Content]
    var generationConfig: GenerationConfig? = nil  // Make optional if not always needed

    struct Content: Codable {
        // Assuming 'user' role for requests containing prompts/images
        var role: String? = "user"
        let parts: [Part]
    }

    // Enum to represent different part types
    enum Part: Codable {
        case text(String)
        case inlineData(mimeType: String, data: String)

        // Custom Codable implementation
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .text(let textValue):
                try container.encode(textValue, forKey: .text)
            case .inlineData(let mimeTypeValue, let dataValue):
                var inlineDataContainer = container.nestedContainer(
                    keyedBy: InlineDataKeys.self, forKey: .inlineData)
                try inlineDataContainer.encode(mimeTypeValue, forKey: .mimeType)
                try inlineDataContainer.encode(dataValue, forKey: .data)
            }
        }

        // Need init(from decoder:) if you ever need to decode this enum (e.g., for model responses in same format)
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let textValue = try container.decodeIfPresent(String.self, forKey: .text) {
                self = .text(textValue)
            } else if let inlineDataContainer = try? container.nestedContainer(
                keyedBy: InlineDataKeys.self, forKey: .inlineData)
            {
                let mimeType = try inlineDataContainer.decode(String.self, forKey: .mimeType)
                let data = try inlineDataContainer.decode(String.self, forKey: .data)
                self = .inlineData(mimeType: mimeType, data: data)
            } else {
                throw DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: decoder.codingPath, debugDescription: "Invalid Part data"))
            }
        }

        // Keep CodingKeys private as they are implementation details
        private enum CodingKeys: String, CodingKey {
            case text
            case inlineData
        }

        private enum InlineDataKeys: String, CodingKey {
            case mimeType
            case data
        }
    }

    struct GenerationConfig: Codable {
        // Specifies the desired modality for the response.
        let responseModalities: [String]?

        // Custom initializer
        init(responseModalities: [String]?) {
            self.responseModalities = responseModalities
        }
    }
}

struct GenerateContentResponse: Codable {
    let candidates: [Candidate]?
    let promptFeedback: PromptFeedback?

    struct Candidate: Codable {
        let content: Content?
        let finishReason: String?
        let safetyRatings: [SafetyRating]?
    }

    struct Content: Codable {
        let parts: [GenerateContentRequest.Part]  // Use the same Part enum
        let role: String?  // e.g., "model"
    }

    struct SafetyRating: Codable {
        let category: String  // Non-optional based on observed responses
        let probability: String  // Non-optional based on observed responses
    }

    struct PromptFeedback: Codable {
        let blockReason: String?  // Optional as it only appears when blocked
        let safetyRatings: [SafetyRating]?
    }
}
