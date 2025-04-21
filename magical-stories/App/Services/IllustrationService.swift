// magical-stories/App/Services/IllustrationService.swift
import Foundation
import GoogleGenerativeAI  // Import the Google AI SDK

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
}

/// Service responsible for generating illustrations based on text prompts using the Google AI SDK.
public class IllustrationService: IllustrationServiceProtocol {

    private let apiKey: String
    // Update to the correct model that supports image generation
    private let modelName = "gemini-2.0-flash-exp-image-generation"
    private let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/"

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
        // No longer need to initialize generativeModel here
    }

    // Internal initializer removed.

    /// Generates an illustration URL for the given page text and theme using the Google AI SDK.
    /// This method remains unchanged for now, but might need updating or deprecation later
    /// depending on how illustration generation is triggered.
    public func generateIllustration(for pageText: String, theme: String) async throws -> String? {
        // ... existing code for the first generateIllustration method ...
        // NOTE: This method currently uses the old Imagen API structure.
        // Consider refactoring or removing if the contextual method becomes standard.
        let combinedPrompt =
            "Generate an illustration for a children's story page based on the following details. Theme: \(theme). Scene Description: \(pageText). Style: Whimsical, colorful, suitable for young children. IMPORTANT: Visualize the scene and characters based on the description, but DO NOT depict animals performing human-like actions (like talking or wearing clothes) even if mentioned in the description. Focus on the environment and the animals' natural appearance."

        var lastError: Error?

        // Using the old Imagen endpoint/request structure for this specific method for now.
        let imagenModelName = "imagen-3.0-generate-002:predict"  // Keep original model for this method
        let imagenEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/"  // Keep original endpoint

        for attempt in 1...5 {
            do {
                print(
                    "--- IllustrationService (Legacy): Attempt \(attempt) to generate illustration ---"
                )

                // 1. Construct URL
                let urlString = "\(imagenEndpoint)\(imagenModelName)?key=\(apiKey)"
                guard let url = URL(string: urlString) else {
                    throw IllustrationError.invalidURL
                }

                // 2. Prepare Request Body (Imagen structure)
                let requestBody = ImagenRequestBody(
                    instances: [ImagenInstance(prompt: combinedPrompt)],
                    parameters: ImagenParameters(sampleCount: 1, aspectRatio: "1:1")
                )

                // 3. Prepare URLRequest
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                request.httpBody = try JSONEncoder().encode(requestBody)

                // 4. Perform Network Request
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw IllustrationError.invalidResponse("Did not receive HTTP response.")
                }

                print(
                    "--- IllustrationService (Legacy): Received HTTP status code: \(httpResponse.statusCode) ---"
                )

                guard (200...299).contains(httpResponse.statusCode) else {
                    let errorDetail = String(data: data, encoding: .utf8) ?? "No details available."
                    print(
                        "--- IllustrationService (Legacy): API Error Response Body: \(errorDetail) ---"
                    )
                    throw IllustrationError.apiError(
                        NSError(
                            domain: "HTTPError", code: httpResponse.statusCode,
                            userInfo: [
                                NSLocalizedDescriptionKey:
                                    "API request failed with status \(httpResponse.statusCode). Detail: \(errorDetail)"
                            ])
                    )
                }

                // 5. Decode Successful Response (Imagen structure)
                let predictionResponse = try JSONDecoder().decode(
                    ImagenPredictionResponse.self, from: data)

                guard let firstPrediction = predictionResponse.predictions.first,
                    let base64String = firstPrediction.bytesBase64Encoded
                else {
                    print(
                        "--- IllustrationService (Legacy): No image data found in predictions array. Response: \(predictionResponse) ---"
                    )
                    throw IllustrationError.noImageDataFound
                }

                guard let imageData = Data(base64Encoded: base64String) else {
                    print(
                        "--- IllustrationService (Legacy): Failed to decode base64 image string. ---"
                    )
                    throw IllustrationError.imageProcessingError(
                        "Failed to decode base64 image data.")
                }

                let mimeType = firstPrediction.mimeType ?? "image/png"
                let relativePath = try saveImageDataToPersistentDirectory(
                    imageData: imageData, mimeType: mimeType)
                print(
                    "--- IllustrationService (Legacy): Successfully saved image at relative path: \(relativePath) ---"
                )
                return relativePath

            } catch {
                if let decodingError = error as? DecodingError {
                    lastError = IllustrationError.invalidResponse(
                        "Failed to decode API response: \(decodingError.localizedDescription)")
                } else {
                    lastError = error
                }
                print(
                    "--- IllustrationService (Legacy): Attempt \(attempt) failed with error: \(error.localizedDescription) ---"
                )
                if attempt < 5 {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second delay
                }
            }
        }

        if let lastError = lastError {
            AIErrorManager.logError(
                lastError, source: "IllustrationService (Legacy)",
                additionalInfo: "All retries failed")
        }
        return nil
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
        previousIllustrationPath: String?  // Added parameter
    ) async throws -> String? {

        // Load previous image data if path is provided and it's not the first page
        var previousImageData: Data? = nil
        var previousImageMimeType: String? = nil

        if pageNumber > 1, let path = previousIllustrationPath {
            do {
                let loadedData = try loadImageDataFromPersistentDirectory(relativePath: path)
                previousImageData = loadedData.data
                previousImageMimeType = loadedData.mimeType
                print(
                    "--- IllustrationService: Successfully loaded previous illustration: \(path)")
            } catch {
                print(
                    "--- IllustrationService: Warning - Failed to load previous illustration at path \(path): \(error.localizedDescription). Proceeding without image context. ---"
                )
                // Log this error but continue without the image context
                AIErrorManager.logError(
                    error, source: "IllustrationService",
                    additionalInfo: "Failed to load previous illustration for context")
                previousImageData = nil  // Ensure it's nil if loading failed
            }
        }

        // Construct the prompt, indicating if a reference image is provided
        let promptText: String
        if previousImageData != nil {
            promptText =
                "Generate an illustration for page \(pageNumber) of \(totalPages) in a children's story. **Use the provided image as a reference for visual consistency** (style, characters, setting). Adapt the scene based on the following description: \(illustrationDescription). Style: Whimsical, colorful, suitable for young children. IMPORTANT: Maintain visual consistency with the reference image and setting. DO NOT depict animals performing human-like actions (like talking or wearing clothes)."
        } else {
            // Prompt for the first page or if loading previous image failed
            promptText =
                "Generate an illustration for page \(pageNumber) of \(totalPages) in a children's story based *only* on the following description: \(illustrationDescription). Style: Whimsical, colorful, suitable for young children. IMPORTANT: Establish the initial visual style. DO NOT depict animals performing human-like actions (like talking or wearing clothes)."
        }

        var lastError: Error?

        for attempt in 1...5 {
            do {
                print(
                    "--- IllustrationService: Attempt \(attempt) to generate contextual illustration for page \(pageNumber)/\(totalPages) \(previousImageData != nil ? "with" : "without") previous image context ---"
                )

                let urlString = "\(apiEndpoint)\(modelName):generateContent?key=\(apiKey)"
                guard let url = URL(string: urlString) else {
                    throw IllustrationError.invalidURL
                }

                // 2. Prepare Request Body (Gemini generateContent structure)
                var parts: [GenerateContentRequest.Part] = []

                // Add the text part first
                parts.append(.text(promptText))

                // Add the image part if available
                if let imageData = previousImageData, let mimeType = previousImageMimeType {
                    let base64Image = imageData.base64EncodedString()
                    parts.append(.inlineData(mimeType: mimeType, data: base64Image))
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
                let (data, response) = try await URLSession.shared.data(for: request)

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
                print(
                    "--- IllustrationService: Successfully saved contextual illustration at relative path: \(relativePath) ---"
                )
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
}  // End of IllustrationService class

// Internal protocol and extension definitions removed.

// MARK: - Codable Structs for REST API

private struct ImagenRequestBody: Codable {
    let instances: [ImagenInstance]
    let parameters: ImagenParameters
}

private struct ImagenInstance: Codable {
    let prompt: String
}

private struct ImagenParameters: Codable {
    let sampleCount: Int
    let aspectRatio: String
    // Add other parameters here if needed, matching the API documentation (e.g., negativePrompt, seed)
}

private struct ImagenPredictionResponse: Codable {
    let predictions: [ImagenPrediction]
}

private struct ImagenPrediction: Codable {
    // Assuming the key for base64 image data is 'bytesBase64Encoded' based on common Google API patterns
    let bytesBase64Encoded: String?
    let mimeType: String?  // Include if the API provides it
    // Include other potential fields like safetyAttributes if needed
}

// MARK: - Codable Structs for Gemini generateContent REST API

private struct GenerateContentRequest: Codable {
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

        // Add other generation config parameters if needed (e.g., temperature, topP, maxOutputTokens)
        // Ensure they match the API documentation for the chosen model.

        // Custom initializer if needed for default values or specific logic
        init(responseModalities: [String]?) {
            self.responseModalities = responseModalities
            // Initialize other parameters here if added
        }
    }
}

private struct GenerateContentResponse: Codable {
    let candidates: [Candidate]?
    let promptFeedback: PromptFeedback?

    struct Candidate: Codable {
        let content: Content?
        let finishReason: String?
        let safetyRatings: [SafetyRating]?
    }

    struct Content: Codable {
        let parts: [GenerateContentRequest.Part]
        let role: String?
    }

    struct SafetyRating: Codable {
        let category: String
        let probability: String
    }

    struct PromptFeedback: Codable {
        let blockReason: String?
        let safetyRatings: [SafetyRating]?
    }
}
