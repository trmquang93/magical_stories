// magical-stories/App/Services/IllustrationService.swift
import Foundation
import GoogleGenerativeAI  // Import the Google AI SDK
import SwiftData  // Import SwiftData for ModelContext

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
                    // Specify exact dimensions instead of aspect ratio
                    parameters: ImagenParameters(sampleCount: 1, width: 1024, height: 1792)
                )

                // 3. Prepare URLRequest
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                // Add explicit do-catch for encoding
                do {
                    request.httpBody = try JSONEncoder().encode(requestBody)
                    // DEBUG: Check if httpBody is set before network call
                    print(
                        "--- IllustrationService (Legacy): DEBUG - Request body size after encoding: \(request.httpBody?.count ?? -1) bytes ---"
                    )
                } catch {
                    print(
                        "--- IllustrationService (Legacy): ERROR - Failed to encode request body: \(error.localizedDescription) ---"
                    )
                    // Propagate encoding error as an invalidResponse or a new specific error type
                    throw IllustrationError.invalidResponse(
                        "Failed to encode request body: \(error.localizedDescription)")
                }

                // 4. Perform Network Request
                let (data, response) = try await self.urlSession.data(for: request)  // Use injected session

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

            } catch let error as URLError {
                // Specific handling for network errors
                lastError = IllustrationError.networkError(error)
                print(
                    "--- IllustrationService (Legacy): Attempt \(attempt) failed with network error: \(error.localizedDescription) ---"
                )
                // Optional: Decide if retrying makes sense for network errors
                // if attempt < 5 { try? await Task.sleep(nanoseconds: 1_000_000_000) }
            } catch let error as DecodingError {
                // Specific handling for JSON decoding errors after successful network request
                lastError = IllustrationError.invalidResponse(
                    "Failed to decode API response: \(error.localizedDescription)")
                print(
                    "--- IllustrationService (Legacy): Attempt \(attempt) failed with decoding error: \(error.localizedDescription) ---"
                )
                // Probably don't retry on decoding errors
                break  // Exit retry loop for decoding errors
            } catch let error as IllustrationError {
                // Catch errors already wrapped by internal logic (e.g., apiError, noImageDataFound)
                lastError = error
                print(
                    "--- IllustrationService (Legacy): Attempt \(attempt) failed with IllustrationError: \(error.localizedDescription) ---"
                )
                // Decide on retry logic based on the specific IllustrationError type if needed
            } catch {
                // Catch any other unexpected errors during the process
                lastError = error  // Store the generic error
                print(
                    "--- IllustrationService (Legacy): Attempt \(attempt) failed with unexpected error: \(error.localizedDescription) ---"
                )
                // Optional: Retry for generic errors or break
                // if attempt < 5 { try? await Task.sleep(nanoseconds: 1_000_000_000) }
            }

            // Common retry delay logic (if retrying is enabled for the caught error type)
            // This example assumes we retry for network and generic errors, but not decoding errors.
            if !(lastError is IllustrationError
                && (lastError as! IllustrationError).isDecodingError) && attempt < 5
            {
                try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...2_000_000_000))  // Exponential backoff might be better
            }
        }

        // After loop, check the last error and handle/log
        if let finalError = lastError {
            AIErrorManager.logError(
                finalError, source: "IllustrationService (Legacy)",
                additionalInfo: "All retries failed for pageText: \(pageText)")
            // Re-throw the last error encountered after all retries
            throw finalError
        }

        // Should only be reached if successful within the loop
        // The original return nil is now effectively unreachable if an error occurred
        print(
            "--- IllustrationService (Legacy): Warning - Reached end of function unexpectedly after retries without success or throwing an error. ---"
        )
        return nil  // Should ideally not happen if error handling is correct
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
        previousIllustrationPath: String? = nil
    ) async throws -> String? {
        // Create an enhanced prompt that focuses on the specific illustration
        let enhancedPrompt = """
            Generate a high-quality illustration for page \(pageNumber) of \(totalPages) of a children's story.

            ILLUSTRATION CONTENT:
            \(illustrationDescription)

            REQUIREMENTS:
            - Create a 9:16 landscape-orientation illustration in a vibrant, whimsical children's book style
            - Follow the description EXACTLY, including all specified character details, colors, and elements
            - Create high-quality art with good composition, color balance, and visual appeal
            - Ensure all described characters and elements are clearly visible
            - Pay close attention to character appearances exactly as described
            - Render backgrounds and settings with appropriate detail
            - Use lighting and color to create the mood described
            - Ensure appropriate scaling and proportions between characters and environment

            The illustration should be high quality, child-friendly, and look like it belongs in a professional children's picture book.
            """

        print(
            "[IllustrationService] Generating illustration for page \(pageNumber) with description length: \(illustrationDescription.count) characters"
        )

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

                // Add the text part first
                parts.append(.text(enhancedPrompt))

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
        DispatchQueue.main.async {
            self.isGenerating = true
        }

        // Update status to generating
        page.illustrationStatus = .generating
        try context.save()

        // Construct the prompt from the page
        let imagePrompt = page.imagePrompt ?? createDefaultPrompt(from: page.content)

        do {
            // Call our existing method to generate the illustration
            if let relativePath = try await generateIllustrationWithPrompt(imagePrompt) {
                // Update the page with the result path and set status to ready
                page.illustrationPath = relativePath
                page.illustrationStatus = .ready
                try context.save()

                print(
                    "--- IllustrationService: Successfully generated illustration for page \(page.id) ---"
                )
            } else {
                // If no path was returned but no error was thrown, set to failed
                page.illustrationStatus = .failed
                try context.save()

                print(
                    "--- IllustrationService: No illustration path returned for page \(page.id) ---"
                )
                throw IllustrationError.noImageDataFound
            }
        } catch {
            // Update status to failed
            page.illustrationStatus = .failed
            try context.save()

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
        DispatchQueue.main.async {
            self.isGenerating = false
        }
    }

    /// Internal method to generate an illustration using a prompt
    /// This refactors the existing code to be more reusable
    private func generateIllustrationWithPrompt(_ prompt: String) async throws -> String? {
        let combinedPrompt =
            "Generate an illustration for a children's story page based on the following details. Scene Description: \(prompt). Style: Whimsical, colorful, suitable for young children. IMPORTANT: Visualize the scene and characters based on the description, but DO NOT depict animals performing human-like actions (like talking or wearing clothes) even if mentioned in the description. Focus on the environment and the animals' natural appearance."

        var lastError: Error?

        // Use the Imagen 3.0 endpoint
        let imagenModelName = "imagen-3.0-generate-002:predict"
        let imagenEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/"

        for attempt in 1...5 {
            do {
                print(
                    "--- IllustrationService: Attempt \(attempt) to generate illustration ---"
                )

                // 1. Construct URL
                let urlString = "\(imagenEndpoint)\(imagenModelName)?key=\(apiKey)"
                guard let url = URL(string: urlString) else {
                    throw IllustrationError.invalidURL
                }

                // 2. Prepare Request Body (Imagen structure)
                let requestBody = ImagenRequestBody(
                    instances: [ImagenInstance(prompt: combinedPrompt)],
                    // Specify exact dimensions instead of aspect ratio
                    parameters: ImagenParameters(sampleCount: 1, width: 1024, height: 1792)
                )

                // 3. Prepare URLRequest
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")

                do {
                    request.httpBody = try JSONEncoder().encode(requestBody)
                    print(
                        "--- IllustrationService: DEBUG - Request body size after encoding: \(request.httpBody?.count ?? -1) bytes ---"
                    )
                } catch {
                    print(
                        "--- IllustrationService: ERROR - Failed to encode request body: \(error.localizedDescription) ---"
                    )
                    throw IllustrationError.invalidResponse(
                        "Failed to encode request body: \(error.localizedDescription)")
                }

                // 4. Perform Network Request
                let (data, response) = try await self.urlSession.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw IllustrationError.invalidResponse("Did not receive HTTP response.")
                }

                print(
                    "--- IllustrationService: Received HTTP status code: \(httpResponse.statusCode) ---"
                )

                guard (200...299).contains(httpResponse.statusCode) else {
                    let errorDetail = String(data: data, encoding: .utf8) ?? "No details available."
                    print(
                        "--- IllustrationService: API Error Response Body: \(errorDetail) ---"
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
                        "--- IllustrationService: No image data found in predictions array. Response: \(predictionResponse) ---"
                    )
                    throw IllustrationError.noImageDataFound
                }

                guard let imageData = Data(base64Encoded: base64String) else {
                    print(
                        "--- IllustrationService: Failed to decode base64 image string. ---"
                    )
                    throw IllustrationError.imageProcessingError(
                        "Failed to decode base64 image data.")
                }

                let mimeType = firstPrediction.mimeType ?? "image/png"
                let relativePath = try saveImageDataToPersistentDirectory(
                    imageData: imageData, mimeType: mimeType)
                print(
                    "--- IllustrationService: Successfully saved image at relative path: \(relativePath) ---"
                )
                return relativePath

            } catch let error as URLError {
                // Specific handling for network errors
                lastError = IllustrationError.networkError(error)
                print(
                    "--- IllustrationService: Attempt \(attempt) failed with network error: \(error.localizedDescription) ---"
                )
            } catch let error as DecodingError {
                // Specific handling for JSON decoding errors after successful network request
                lastError = IllustrationError.invalidResponse(
                    "Failed to decode API response: \(error.localizedDescription)")
                print(
                    "--- IllustrationService: Attempt \(attempt) failed with decoding error: \(error.localizedDescription) ---"
                )
                // Probably don't retry on decoding errors
                break  // Exit retry loop for decoding errors
            } catch let error as IllustrationError {
                // Catch errors already wrapped by internal logic (e.g., apiError, noImageDataFound)
                lastError = error
                print(
                    "--- IllustrationService: Attempt \(attempt) failed with IllustrationError: \(error.localizedDescription) ---"
                )
                // Decide on retry logic based on the specific IllustrationError type if needed
            } catch {
                // Catch any other unexpected errors during the process
                lastError = error  // Store the generic error
                print(
                    "--- IllustrationService: Attempt \(attempt) failed with unexpected error: \(error.localizedDescription) ---"
                )
            }

            // Common retry delay logic (if retrying is enabled for the caught error type)
            if !(lastError is IllustrationError
                && (lastError as! IllustrationError).isDecodingError) && attempt < 5
            {
                try? await Task.sleep(nanoseconds: UInt64.random(in: 1_000_000_000...2_000_000_000))
            }
        }

        // After loop, check the last error and handle/log
        if let finalError = lastError {
            AIErrorManager.logError(
                finalError, source: "IllustrationService",
                additionalInfo: "All retries failed for prompt: \(prompt)")
            // Re-throw the last error encountered after all retries
            throw finalError
        }

        // Should only be reached if all attempts fail without throwing an error (unlikely)
        print(
            "--- IllustrationService: Warning - Reached end of function unexpectedly after retries without success or throwing an error. ---"
        )
        return nil
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

// MARK: - Internal Helper Structs for REST API (Made internal for testing)

struct ImagenRequestBody: Codable {
    let instances: [ImagenInstance]
    let parameters: ImagenParameters
}

struct ImagenInstance: Codable {
    let prompt: String
}

struct ImagenParameters: Codable {
    let sampleCount: Int
    let aspectRatio: String?  // Keep optional for flexibility, though we'll prioritize width/height
    let width: Int?  // Desired output width in pixels
    let height: Int?  // Desired output height in pixels

    // Provide a convenience initializer if needed, though default memberwise should work
    init(sampleCount: Int, aspectRatio: String? = nil, width: Int? = nil, height: Int? = nil) {
        self.sampleCount = sampleCount
        self.aspectRatio = aspectRatio  // Store it even if not used in primary call
        self.width = width
        self.height = height
    }
    // Note: Removed the comment about adding other parameters as we are adding width/height now.
}

struct ImagenPredictionResponse: Codable {
    let predictions: [ImagenPrediction]
}

struct ImagenPrediction: Codable {
    // Assuming the key for base64 image data is 'bytesBase64Encoded' based on common Google API patterns
    let bytesBase64Encoded: String?
    let mimeType: String?  // Include if the API provides it
    // Include other potential fields like safetyAttributes if needed
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

        // Add other generation config parameters if needed (e.g., temperature, topP, maxOutputTokens)
        // Ensure they match the API documentation for the chosen model.

        // Custom initializer if needed for default values or specific logic
        init(responseModalities: [String]?) {
            self.responseModalities = responseModalities
            // Initialize other parameters here if added
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
