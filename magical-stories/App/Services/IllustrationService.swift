// magical-stories/App/Services/IllustrationService.swift
import Foundation
// TODO: Potentially add import for GoogleCloudSwiftClient or another relevant library if used instead of direct REST.

/// Errors specific to the IllustrationService.
enum IllustrationError: Error, LocalizedError {
    case missingConfiguration(String)
    case invalidURL
    case networkError(Error)
    case apiError(statusCode: Int, message: String?)
    case invalidResponse(String)
    case tokenError(Error)
    case imageProcessingError(String)

    var errorDescription: String? {
        switch self {
        case .missingConfiguration(let detail):
            return "Configuration error: \(detail)"
        case .invalidURL:
            return "Failed to create a valid API endpoint URL."
        case .networkError(let underlyingError):
            return "Network request failed: \(underlyingError.localizedDescription)"
        case .apiError(let statusCode, let message):
            return "API request failed with status code \(statusCode). Message: \(message ?? "No details provided.")"
        case .invalidResponse(let reason):
            return "Failed to parse API response: \(reason)"
        case .tokenError(let underlyingError):
            return "Failed to obtain authentication token: \(underlyingError.localizedDescription)"
        case .imageProcessingError(let reason):
            return "Failed to process image data: \(reason)"
        }
    }
}

/// Service responsible for generating illustrations based on text prompts using Google Cloud Vertex AI Imagen.
public class IllustrationService: IllustrationServiceProtocol {

    // TODO: Replace "us-central1" with the appropriate Google Cloud region if different.
    private let region = "us-central1"
    private let modelId = "imagegeneration@006" // Example Imagen model ID, verify the latest/correct one.

    public init() {} // Default initializer

    /// Generates an illustration for the given prompt using Google Cloud Vertex AI Imagen.
    /// - Parameter prompt: The text prompt to use for image generation.
    /// - Returns: A URL pointing to the generated illustration (likely a signed GCS URL).
    public func generateIllustration(prompt: String) async throws -> URL? {
        print("IllustrationService: Generating illustration for prompt - \"\(prompt)\"")

        // 1. Get Configuration
        let projectID = AppConfig.googleCloudProjectID
        guard !projectID.isEmpty, projectID != "YOUR_PROJECT_ID_HERE" else {
            print("IllustrationService: Error - Google Cloud Project ID not configured in Config.plist. Check AppConfig setup.")
            throw IllustrationError.missingConfiguration("Google Cloud Project ID is not set.")
        }

        // 2. Authentication (OAuth 2.0 Token)
        // IMPORTANT: Assumes an OAuth 2.0 access token mechanism exists.
        // The actual implementation of getAccessToken() is needed elsewhere (e.g., in AppConfig.swift or a dedicated Auth service).
        let accessToken: String
        do {
            // This function needs to be implemented to handle the OAuth flow
            // accessToken = try await APIKeys.getAccessToken()
            // For now, using a placeholder. Replace with actual token fetching.
            print("IllustrationService: Warning - Using placeholder access token. Implement token fetching (consider AppConfig or dedicated Auth service).")
            accessToken = "PLACEHOLDER_ACCESS_TOKEN" // Replace with actual token fetching logic
            if accessToken == "PLACEHOLDER_ACCESS_TOKEN" {
                 // Throwing an error here makes it clear this needs implementation
                 throw IllustrationError.missingConfiguration("Access token generation not implemented.")
            }
        } catch {
            print("IllustrationService: Error getting access token - \(error.localizedDescription)")
            throw IllustrationError.tokenError(error)
        }


        // 3. Construct API Endpoint URL
        // Reference: https://cloud.google.com/vertex-ai/docs/generative-ai/image/generate-images#rest
        guard let url = URL(string: "https://\(region)-aiplatform.googleapis.com/v1/projects/\(projectID)/locations/\(region)/publishers/google/models/\(modelId):predict") else {
            print("IllustrationService: Error - Failed to create API endpoint URL.")
            throw IllustrationError.invalidURL
        }

        // 4. Prepare Request Body (Payload)
        // Customize parameters as needed (size, aspect ratio, negative prompts, etc.)
        // Refer to Vertex AI Imagen API documentation for available parameters.
        let parameters: [String: Any] = [
            "sampleCount": 1, // Number of images to generate
            "aspectRatio": "1:1", // Example aspect ratio
            "outputFormat": "png" // Example output format
            // "negativePrompt": "text, words, letters", // Example negative prompt
            // "guidanceScale": 7 // Example guidance scale
        ]
        let instances: [[String: Any]] = [
            ["prompt": prompt]
        ]
        let requestBodyDict: [String: Any] = [
            "instances": instances,
            "parameters": parameters
        ]

        let requestBodyData: Data
        do {
            requestBodyData = try JSONSerialization.data(withJSONObject: requestBodyDict)
        } catch {
            print("IllustrationService: Error - Failed to serialize request body: \(error)")
            throw IllustrationError.invalidResponse("Failed to create request JSON.")
        }

        // 5. Create URLRequest
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = requestBodyData

        // 6. Perform Network Request
        let data: Data
        let response: URLResponse
        do {
            print("IllustrationService: Sending request to Vertex AI Imagen...")
            (data, response) = try await URLSession.shared.data(for: request)
            print("IllustrationService: Received response from Vertex AI Imagen.")
        } catch {
            print("IllustrationService: Network error - \(error.localizedDescription)")
            throw IllustrationError.networkError(error)
        }

        // 7. Handle Response
        guard let httpResponse = response as? HTTPURLResponse else {
            print("IllustrationService: Error - Invalid response type received.")
            throw IllustrationError.invalidResponse("Did not receive HTTP response.")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let responseBodyString = String(data: data, encoding: .utf8) ?? "Could not decode error response body."
            print("IllustrationService: API Error - Status Code \(httpResponse.statusCode). Response: \(responseBodyString)")
            throw IllustrationError.apiError(statusCode: httpResponse.statusCode, message: responseBodyString)
        }

        // 8. Parse JSON Response
        // The exact structure depends on the Imagen API version and parameters.
        // Assuming it returns a structure like: { "predictions": [ { "bytesBase64Encoded": "...", "mimeType": "..." } ] }
        // OR potentially { "predictions": [ { "signedUri": "https://..." } ] } if it generates a GCS URL directly.
        // We need the URL as per the requirement. Let's assume 'signedUri' for now.
        do {
            guard let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let predictions = jsonResponse["predictions"] as? [[String: Any]],
                  let firstPrediction = predictions.first else {
                throw IllustrationError.invalidResponse("Missing 'predictions' array or first prediction object.")
            }

            // --- Attempt to find a signed URL ---
            if let signedUriString = firstPrediction["signedUri"] as? String,
               let generatedUrl = URL(string: signedUriString) {
                print("IllustrationService: Successfully extracted signed URL: \(generatedUrl.absoluteString)")
                return generatedUrl
            }

            // --- Fallback: Check for Base64 image data (if URL isn't provided) ---
            // This part is NOT the primary goal (which is returning a URL), but shows how to handle image data if needed.
            // If the API returns bytesBase64Encoded, you'd need to decode it, save it locally or to cloud storage,
            // and then return a URL to *that* location. This is more complex and likely out of scope for this step.
            /*
            else if let base64String = firstPrediction["bytesBase64Encoded"] as? String,
                    let mimeType = firstPrediction["mimeType"] as? String {
                print("IllustrationService: Received Base64 image data (mimeType: \(mimeType)). Needs processing to generate a URL.")
                // TODO: Implement logic to decode base64, save image (e.g., to temp dir or cloud storage), and return its URL.
                // This is a placeholder for that more complex flow.
                throw IllustrationError.imageProcessingError("Received image data instead of URL, processing not implemented.")
            }
            */

            // If neither URL nor expected image data is found
            else {
                 let responseString = String(data: data, encoding: .utf8) ?? "Could not decode response."
                 print("IllustrationService: Error - Could not find 'signedUri' or 'bytesBase64Encoded' in prediction. Response: \(responseString)")
                 throw IllustrationError.invalidResponse("Could not find expected image URL or data in the API response.")
            }

        } catch let error as IllustrationError {
            print("IllustrationService: Error parsing response - \(error.localizedDescription)")
            throw error // Re-throw specific illustration errors
        } catch {
            print("IllustrationService: Generic error parsing response - \(error.localizedDescription)")
            throw IllustrationError.invalidResponse("Failed to decode JSON: \(error.localizedDescription)")
        }
    }
}