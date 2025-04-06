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
    private let modelName = "imagen-3.0-generate-002" // Keep model name for URL construction
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
    /// - Parameters:
    ///   - pageText: The text content of the story page.
    ///   - theme: The overall theme of the story.
    /// - Returns: A URL pointing to the generated illustration, or `nil` if generation fails gracefully.
    /// - Throws: `IllustrationError` for configuration, network, or API issues.
    public func generateIllustration(for pageText: String, theme: String) async throws -> URL? {
        let combinedPrompt =
            "Generate an illustration for a children's story page based on the following details. Theme: \(theme). Scene Description: \(pageText). Style: Whimsical, colorful, suitable for young children. IMPORTANT: Visualize the scene and characters based on the description, but DO NOT depict animals performing human-like actions (like talking or wearing clothes) even if mentioned in the description. Focus on the environment and the animals' natural appearance."
        print(
            "--- IllustrationService: Generating illustration via REST API for prompt - \"\(combinedPrompt.prefix(80))...\" ---"
        )

        // 1. Construct URL
        let urlString = "\(apiEndpoint)\(modelName):predict?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw IllustrationError.invalidURL
        }

        // 2. Prepare Request Body
        let requestBody = ImagenRequestBody(
            instances: [ImagenInstance(prompt: combinedPrompt)],
            parameters: ImagenParameters(sampleCount: 1, aspectRatio: "1:1") // Request 1 image, 1:1 ratio
        )

        // 3. Prepare URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            print("--- IllustrationService: Failed to encode request body - \(error.localizedDescription) ---")
            throw IllustrationError.invalidResponse("Failed to encode request body: \(error.localizedDescription)")
        }

        // 4. Perform Network Request
        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            // Check HTTP response status
            guard let httpResponse = response as? HTTPURLResponse else {
                throw IllustrationError.invalidResponse("Did not receive HTTP response.")
            }

            print("--- IllustrationService: Received HTTP status code: \(httpResponse.statusCode) ---")

            guard (200...299).contains(httpResponse.statusCode) else {
                // Attempt to decode error message from response body if available
                let errorDetail = String(data: data, encoding: .utf8) ?? "No details available."
                print("--- IllustrationService: API Error Response Body: \(errorDetail) ---")
                throw IllustrationError.apiError(
                    NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "API request failed with status \(httpResponse.statusCode). Detail: \(errorDetail)"])
                )
            }

            // 5. Decode Successful Response
            let predictionResponse: ImagenPredictionResponse
            do {
                predictionResponse = try JSONDecoder().decode(ImagenPredictionResponse.self, from: data)
            } catch {
                print("--- IllustrationService: Failed to decode successful response - \(error.localizedDescription) ---")
                print("--- IllustrationService: Raw Response Data: \(String(data: data, encoding: .utf8) ?? "Unable to decode data") ---")
                throw IllustrationError.invalidResponse("Failed to decode API response: \(error.localizedDescription)")
            }


            // 6. Extract and Decode Image Data
            guard let firstPrediction = predictionResponse.predictions.first,
                  let base64String = firstPrediction.bytesBase64Encoded else {
                print("--- IllustrationService: No image data found in predictions array. Response: \(predictionResponse) ---")
                throw IllustrationError.noImageDataFound
            }

            guard let imageData = Data(base64Encoded: base64String) else {
                print("--- IllustrationService: Failed to decode base64 image string. ---")
                throw IllustrationError.imageProcessingError("Failed to decode base64 image data.")
            }

            // 7. Save Image Data
            print(
                "--- IllustrationService: Found and decoded image data (\(imageData.count) bytes). Saving to temporary file. ---"
            )
            // Assume PNG if mimeType is not provided in the response, or use a default.
            let mimeType = firstPrediction.mimeType ?? "image/png"
            let fileURL = try saveImageDataToTemporaryFile(imageData: imageData, mimeType: mimeType)
            print(
                "--- IllustrationService: Successfully saved image to temporary file: \(fileURL.absoluteString) ---"
            )
            return fileURL

        } catch let error as IllustrationError {
             // Re-throw known IllustrationErrors
             print("--- IllustrationService: Caught known IllustrationError - \(error.localizedDescription) ---")
             throw error
        } catch let error as URLError {
            // Handle URLSession specific errors
            print("--- IllustrationService: Network Error (URLError) - \(error.localizedDescription) ---")
            throw IllustrationError.networkError(error)
        } catch {
            // Handle other unexpected errors during the process
            print("--- IllustrationService: Unexpected error during REST API call - \(error.localizedDescription) ---")
            // Map to a general API error or a more specific one if identifiable
            throw IllustrationError.apiError(error)
        }
    } // End of generateIllustration method

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
            throw IllustrationError.imageProcessingError(
                "Failed to save image data to temporary file: \(error.localizedDescription)")
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
    let mimeType: String? // Include if the API provides it
    // Include other potential fields like safetyAttributes if needed
}
