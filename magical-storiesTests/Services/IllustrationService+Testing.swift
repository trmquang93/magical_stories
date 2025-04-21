// IllustrationService+Testing.swift
// Testing utilities for IllustrationService

import Foundation

@testable import magical_stories

// MARK: - Testing extensions

/// Creates a mock URLSession configured with MockURLProtocol
func createMockURLSession() -> URLSession {
    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: configuration)
}

// MARK: - Mock response helpers

/// Helper to create a successful mock response for the Imagen API
func createMockImagenSuccessResponse(base64EncodedImage: String, mimeType: String = "image/png")
    -> Data
{
    let responseJSON = """
        {
            "predictions": [
                {
                    "bytesBase64Encoded": "\(base64EncodedImage)",
                    "mimeType": "\(mimeType)"
                }
            ]
        }
        """
    return responseJSON.data(using: .utf8)!
}

/// Helper to create an error response from the Imagen API
func createMockImagenErrorResponse(errorMessage: String, statusCode: Int = 400) -> Data {
    let responseJSON = """
        {
            "error": {
                "code": \(statusCode),
                "message": "\(errorMessage)",
                "status": "INVALID_ARGUMENT"
            }
        }
        """
    return responseJSON.data(using: .utf8)!
}

/// Helper to register standard mock responses
func setupMockResponses(urlSession: URLSession, apiKey: String = "test_key") {
    // Extract the MockURLProtocol class from the session configuration
    guard let configuration = (urlSession as? URLSession)?.configuration,
        let protocolClasses = configuration.protocolClasses,
        protocolClasses.contains(where: { $0 == MockURLProtocol.self })
    else {
        fatalError("The provided URLSession is not configured with MockURLProtocol")
    }

    // Base API URL that contains our model name
    let baseURL =
        "https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict?key=\(apiKey)"

    // Reset any existing mock handlers
    MockURLProtocol.reset()

    // Register the URL to match our requests
    MockURLProtocol.registerMock(for: baseURL) { request in
        // Default to a successful response with a simple 1x1 transparent PNG
        let defaultBase64Image =
            "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII="
        let successData = createMockImagenSuccessResponse(base64EncodedImage: defaultBase64Image)
        let successResponse = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!

        return (successResponse, successData, nil)
    }
}

// MARK: - Test helper for saving mock image data

/// Helper function to save test image data to a temporary file
func saveMockImageToTempFile(data: Data, fileExtension: String = "png") throws -> URL {
    let tempDirectoryURL = FileManager.default.temporaryDirectory
    let fileName = "\(UUID().uuidString).\(fileExtension)"
    let fileURL = tempDirectoryURL.appendingPathComponent(fileName)

    try data.write(to: fileURL)
    return fileURL
}

// MARK: - TestableIllustrationService

/// A testable version of IllustrationService that allows injecting a URLSession
@MainActor
class TestableIllustrationService: IllustrationServiceProtocol {
    private let apiKey: String
    private let urlSession: URLSession
    private let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/"
    private let modelName = "imagen-3.0-generate-002"

    init(apiKey: String = "test_api_key", urlSession: URLSession) {
        self.apiKey = apiKey
        self.urlSession = urlSession
    }

    @MainActor
    func generateIllustration(for pageText: String, theme: String) async throws -> String? {
        let combinedPrompt =
            "Generate an illustration for a children's story page based on the following details. Theme: \(theme). Scene Description: \(pageText)."

        let urlString = "\(apiEndpoint)\(modelName):predict?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw IllustrationError.invalidURL
        }

        struct ImagenRequestBody: Codable {
            let instances: [ImagenInstance]
            let parameters: ImagenParameters
        }
        struct ImagenInstance: Codable {
            let prompt: String
        }
        struct ImagenParameters: Codable {
            let sampleCount: Int
            let aspectRatio: String
        }
        let requestBody = ImagenRequestBody(
            instances: [ImagenInstance(prompt: combinedPrompt)],
            parameters: ImagenParameters(sampleCount: 1, aspectRatio: "1:1")
        )
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw IllustrationError.invalidResponse(
                "Failed to encode request body: \(error.localizedDescription)")
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw IllustrationError.invalidResponse("Did not receive HTTP response.")
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorDetail = String(data: data, encoding: .utf8) ?? "No details available."
                throw IllustrationError.apiError(
                    NSError(
                        domain: "HTTPError", code: httpResponse.statusCode,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "API request failed with status \(httpResponse.statusCode). Detail: \(errorDetail)"
                        ])
                )
            }
            struct ImagenPredictionResponse: Codable {
                let predictions: [ImagenPrediction]
            }
            struct ImagenPrediction: Codable {
                let bytesBase64Encoded: String?
                let mimeType: String?
            }
            let predictionResponse = try JSONDecoder().decode(
                ImagenPredictionResponse.self, from: data)
            guard let firstPrediction = predictionResponse.predictions.first,
                let base64String = firstPrediction.bytesBase64Encoded
            else {
                throw IllustrationError.noImageDataFound
            }
            guard let imageData = Data(base64Encoded: base64String) else {
                throw IllustrationError.imageProcessingError("Failed to decode base64 image data.")
            }

            // Save to a fake persistent directory inside Application Support/Illustrations
            let appSupportURL = try FileManager.default.url(
                for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil,
                create: true)
            let illustrationsDir = appSupportURL.appendingPathComponent(
                "Illustrations", isDirectory: true)
            if !FileManager.default.fileExists(atPath: illustrationsDir.path) {
                try FileManager.default.createDirectory(
                    at: illustrationsDir, withIntermediateDirectories: true)
            }
            let uniqueID = UUID().uuidString
            let ext =
                (firstPrediction.mimeType ?? "image/png").split(separator: "/").last.map(
                    String.init) ?? "png"
            let fileName = "\(uniqueID).\(ext)"
            let fileURL = illustrationsDir.appendingPathComponent(fileName)
            try imageData.write(to: fileURL)
            return "Illustrations/\(fileName)"
        } catch let error as IllustrationError {
            throw error
        } catch let error as URLError {
            throw IllustrationError.networkError(error)
        } catch {
            throw IllustrationError.apiError(error)
        }
    }

    @MainActor
    func generateIllustration(for illustrationDescription: String, pageNumber: Int, totalPages: Int)
        async throws -> String?
    {
        // This implementation can be very similar to the other method, but with a different prompt construction
        let contextualPrompt =
            "Generate an illustration for a children's story page. This is page \(pageNumber) of \(totalPages). Scene Description: \(illustrationDescription)."

        let urlString = "\(apiEndpoint)\(modelName):predict?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw IllustrationError.invalidURL
        }

        struct ImagenRequestBody: Codable {
            let instances: [ImagenInstance]
            let parameters: ImagenParameters
        }
        struct ImagenInstance: Codable {
            let prompt: String
        }
        struct ImagenParameters: Codable {
            let sampleCount: Int
            let aspectRatio: String
        }
        let requestBody = ImagenRequestBody(
            instances: [ImagenInstance(prompt: contextualPrompt)],
            parameters: ImagenParameters(sampleCount: 1, aspectRatio: "1:1")
        )
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            request.httpBody = try JSONEncoder().encode(requestBody)
        } catch {
            throw IllustrationError.invalidResponse(
                "Failed to encode request body: \(error.localizedDescription)")
        }

        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw IllustrationError.invalidResponse("Did not receive HTTP response.")
            }
            guard (200...299).contains(httpResponse.statusCode) else {
                let errorDetail = String(data: data, encoding: .utf8) ?? "No details available."
                throw IllustrationError.apiError(
                    NSError(
                        domain: "HTTPError", code: httpResponse.statusCode,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "API request failed with status \(httpResponse.statusCode). Detail: \(errorDetail)"
                        ])
                )
            }
            struct ImagenPredictionResponse: Codable {
                let predictions: [ImagenPrediction]
            }
            struct ImagenPrediction: Codable {
                let bytesBase64Encoded: String?
                let mimeType: String?
            }
            let predictionResponse = try JSONDecoder().decode(
                ImagenPredictionResponse.self, from: data)
            guard let firstPrediction = predictionResponse.predictions.first,
                let base64String = firstPrediction.bytesBase64Encoded
            else {
                throw IllustrationError.noImageDataFound
            }
            guard let imageData = Data(base64Encoded: base64String) else {
                throw IllustrationError.imageProcessingError("Failed to decode base64 image data.")
            }

            // Save to a fake persistent directory inside Application Support/Illustrations
            let appSupportURL = try FileManager.default.url(
                for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil,
                create: true)
            let illustrationsDir = appSupportURL.appendingPathComponent(
                "Illustrations", isDirectory: true)
            if !FileManager.default.fileExists(atPath: illustrationsDir.path) {
                try FileManager.default.createDirectory(
                    at: illustrationsDir, withIntermediateDirectories: true)
            }
            let uniqueID = UUID().uuidString
            let ext =
                (firstPrediction.mimeType ?? "image/png").split(separator: "/").last.map(
                    String.init) ?? "png"
            let fileName = "\(uniqueID).\(ext)"
            let fileURL = illustrationsDir.appendingPathComponent(fileName)
            try imageData.write(to: fileURL)
            return "Illustrations/\(fileName)"
        } catch let error as IllustrationError {
            throw error
        } catch let error as URLError {
            throw IllustrationError.networkError(error)
        } catch {
            throw IllustrationError.apiError(error)
        }
    }
}
