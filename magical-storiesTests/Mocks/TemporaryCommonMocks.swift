import Foundation
@testable import magical_stories

/// Response structure for Google AI Imagen API
struct ImagenPredictionResponse: Codable {
    let predictions: [ImagenPrediction]
}

struct ImagenPrediction: Codable {
    let bytesBase64Encoded: String
    let mimeType: String
}