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
    let configuration = urlSession.configuration
    guard let protocolClasses = configuration.protocolClasses,
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

// TestableIllustrationService removed as IllustrationService now supports URLSession injection via internal initializer.
