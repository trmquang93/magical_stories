import Foundation

// MARK: - Generation Request Types

public enum GenerationRequest {
    case story(prompt: String, parameters: StoryParameters)
    case illustration(prompt: String, context: IllustrationContext)
    case globalReference(prompt: String, visualGuide: VisualGuide)
    case sequentialIllustration(prompt: String, context: IllustrationContext, previousImagePath: String?, globalReferencePath: String?)
}

public struct IllustrationContext {
    let pageNumber: Int
    let totalPages: Int
    let visualGuide: VisualGuide?
    
    public init(pageNumber: Int, totalPages: Int, visualGuide: VisualGuide? = nil) {
        self.pageNumber = pageNumber
        self.totalPages = totalPages
        self.visualGuide = visualGuide
    }
}

// MARK: - Generation Result Types

public enum GenerationResult {
    case text(String)
    case image(String) // File path
    case error(Error)
}

public enum GenerationError: Error, LocalizedError {
    case invalidRequest(String)
    case networkError(Error)
    case apiError(String)
    case processingError(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidRequest(let message):
            return "Invalid request: \(message)"
        case .networkError(let underlyingError):
            return "Network error: \(underlyingError.localizedDescription)"
        case .apiError(let message):
            return "API error: \(message)"
        case .processingError(let message):
            return "Processing error: \(message)"
        }
    }
}

// MARK: - Strategy Protocol

public protocol AIGenerationStrategy {
    func generate(request: GenerationRequest) async throws -> GenerationResult
}

// MARK: - Strategy Implementations

public class GeminiTextStrategy: AIGenerationStrategy {
    private let model: GenerativeModelProtocol
    
    public init(model: GenerativeModelProtocol) {
        self.model = model
    }
    
    public func generate(request: GenerationRequest) async throws -> GenerationResult {
        switch request {
        case .story(let prompt, _):
            do {
                let response = try await model.generateContent(prompt)
                guard let text = response.text else {
                    throw GenerationError.apiError("No text content in response")
                }
                return .text(text)
            } catch {
                throw GenerationError.networkError(error)
            }
        default:
            throw GenerationError.invalidRequest("GeminiTextStrategy only supports story requests")
        }
    }
}

public class GeminiImageStrategy: AIGenerationStrategy {
    private let urlSession: URLSessionProtocol
    private let apiKey: String
    private let modelName = "gemini-2.0-flash-exp-image-generation"
    
    public init(urlSession: URLSessionProtocol, apiKey: String) {
        self.urlSession = urlSession
        self.apiKey = apiKey
    }
    
    public func generate(request: GenerationRequest) async throws -> GenerationResult {
        let prompt: String
        let hasContextualImages: Bool
        
        switch request {
        case .illustration(let promptText, _):
            prompt = promptText
            hasContextualImages = false
        case .globalReference(let promptText, _):
            prompt = promptText
            hasContextualImages = false
        case .sequentialIllustration(let promptText, _, let previousPath, let globalPath):
            prompt = promptText
            hasContextualImages = previousPath != nil || globalPath != nil
        default:
            throw GenerationError.invalidRequest("GeminiImageStrategy only supports image requests")
        }
        
        do {
            let imagePath = try await generateImage(prompt: prompt, hasContextualImages: hasContextualImages)
            return .image(imagePath)
        } catch {
            throw GenerationError.networkError(error)
        }
    }
    
    private func generateImage(prompt: String, hasContextualImages: Bool) async throws -> String {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName):generateContent?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GenerationError.invalidRequest("Invalid API URL")
        }
        
        let parts: [GenerateContentRequest.Part] = [.text(prompt)]
        
        // Note: In a real implementation, we would load and add contextual images here
        // For now, we'll just create the text-only request
        
        let requestBody = GenerateContentRequest(
            contents: [GenerateContentRequest.Content(parts: parts)],
            generationConfig: GenerateContentRequest.GenerationConfig(responseModalities: ["TEXT", "IMAGE"])
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GenerationError.apiError("API request failed")
        }
        
        // Parse response and extract image data
        let generateContentResponse = try JSONDecoder().decode(GenerateContentResponse.self, from: data)
        
        guard let candidate = generateContentResponse.candidates?.first,
              let parts = candidate.content?.parts else {
            throw GenerationError.processingError("No content in response")
        }
        
        for part in parts {
            if case .inlineData(let mimeType, let base64String) = part,
               mimeType.starts(with: "image/") {
                guard let imageData = Data(base64Encoded: base64String) else {
                    continue
                }
                return try saveImageToFile(imageData: imageData, mimeType: mimeType)
            }
        }
        
        throw GenerationError.processingError("No image data found in response")
    }
    
    private func saveImageToFile(imageData: Data, mimeType: String) throws -> String {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let illustrationsDir = appSupportURL.appendingPathComponent("Illustrations", isDirectory: true)
        
        if !fileManager.fileExists(atPath: illustrationsDir.path) {
            try fileManager.createDirectory(at: illustrationsDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        let fileExtension: String
        switch mimeType.lowercased() {
        case "image/png": fileExtension = "png"
        case "image/jpeg", "image/jpg": fileExtension = "jpg"
        case "image/webp": fileExtension = "webp"
        default: fileExtension = "png"
        }
        
        let fileName = "\(UUID().uuidString).\(fileExtension)"
        let fileURL = illustrationsDir.appendingPathComponent(fileName)
        
        try imageData.write(to: fileURL)
        return "Illustrations/\(fileName)"
    }
}

public class ImagenStrategy: AIGenerationStrategy {
    private let urlSession: URLSessionProtocol
    private let apiKey: String
    private let modelName = "imagen-3.0-generate-002:predict"
    
    public init(urlSession: URLSessionProtocol, apiKey: String) {
        self.urlSession = urlSession
        self.apiKey = apiKey
    }
    
    public func generate(request: GenerationRequest) async throws -> GenerationResult {
        let prompt: String
        
        switch request {
        case .illustration(let promptText, _):
            prompt = promptText
        default:
            throw GenerationError.invalidRequest("ImagenStrategy only supports simple illustration requests")
        }
        
        do {
            let imagePath = try await generateWithImagen(prompt: prompt)
            return .image(imagePath)
        } catch {
            throw GenerationError.networkError(error)
        }
    }
    
    private func generateWithImagen(prompt: String) async throws -> String {
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(modelName)?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GenerationError.invalidRequest("Invalid API URL")
        }
        
        let requestBody = ImagenRequestBody(
            instances: [ImagenInstance(prompt: prompt)],
            parameters: ImagenParameters(sampleCount: 1, width: 1024, height: 1792)
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(requestBody)
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw GenerationError.apiError("Imagen API request failed")
        }
        
        let predictionResponse = try JSONDecoder().decode(ImagenPredictionResponse.self, from: data)
        
        guard let prediction = predictionResponse.predictions.first,
              let base64String = prediction.bytesBase64Encoded,
              let imageData = Data(base64Encoded: base64String) else {
            throw GenerationError.processingError("No image data in Imagen response")
        }
        
        let mimeType = prediction.mimeType ?? "image/png"
        return try saveImageToFile(imageData: imageData, mimeType: mimeType)
    }
    
    private func saveImageToFile(imageData: Data, mimeType: String) throws -> String {
        let fileManager = FileManager.default
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        let illustrationsDir = appSupportURL.appendingPathComponent("Illustrations", isDirectory: true)
        
        if !fileManager.fileExists(atPath: illustrationsDir.path) {
            try fileManager.createDirectory(at: illustrationsDir, withIntermediateDirectories: true, attributes: nil)
        }
        
        let fileExtension: String
        switch mimeType.lowercased() {
        case "image/png": fileExtension = "png"
        case "image/jpeg", "image/jpg": fileExtension = "jpg"
        default: fileExtension = "png"
        }
        
        let fileName = "\(UUID().uuidString).\(fileExtension)"
        let fileURL = illustrationsDir.appendingPathComponent(fileName)
        
        try imageData.write(to: fileURL)
        return "Illustrations/\(fileName)"
    }
}

// MARK: - Strategy Selector

public class AIStrategySelector {
    private let textModel: GenerativeModelProtocol?
    private let urlSession: URLSessionProtocol
    private let apiKey: String
    
    public init(textModel: GenerativeModelProtocol? = nil, urlSession: URLSessionProtocol = URLSession.shared, apiKey: String = AppConfig.geminiApiKey) {
        self.textModel = textModel
        self.urlSession = urlSession
        self.apiKey = apiKey
    }
    
    public func selectStrategy(for request: GenerationRequest) -> AIGenerationStrategy {
        switch request {
        case .story:
            if let model = textModel {
                return GeminiTextStrategy(model: model)
            } else {
                // Create default model if none provided
                let defaultModel = DefaultGenerativeModelWrapper(name: "gemini-2.5-flash-preview-04-17", apiKey: apiKey)
                return GeminiTextStrategy(model: defaultModel)
            }
            
        case .illustration:
            // Use Imagen for simple illustrations
            return ImagenStrategy(urlSession: urlSession, apiKey: apiKey)
            
        case .globalReference, .sequentialIllustration:
            // Use Gemini for complex image generation with context
            return GeminiImageStrategy(urlSession: urlSession, apiKey: apiKey)
        }
    }
}

// MARK: - AI Coordinator

public class AICoordinator {
    private let selector: AIStrategySelector
    
    public init(textModel: GenerativeModelProtocol? = nil, urlSession: URLSessionProtocol = URLSession.shared, apiKey: String = AppConfig.geminiApiKey) {
        self.selector = AIStrategySelector(textModel: textModel, urlSession: urlSession, apiKey: apiKey)
    }
    
    public func generate(request: GenerationRequest) async throws -> GenerationResult {
        let strategy = selector.selectStrategy(for: request)
        return try await strategy.generate(request: request)
    }
}

// MARK: - Default Model Wrapper

import GoogleGenerativeAI

class DefaultGenerativeModelWrapper: GenerativeModelProtocol {
    private let model: GenerativeModel
    
    init(name: String, apiKey: String) {
        self.model = GenerativeModel(name: name, apiKey: apiKey)
    }
    
    func generateContent(_ prompt: String) async throws -> StoryGenerationResponse {
        let response = try await model.generateContent(prompt)
        guard let text = response.text else {
            throw GenerationError.apiError("No text content in response")
        }
        return DefaultStoryGenerationResponse(text: text)
    }
}

struct DefaultStoryGenerationResponse: StoryGenerationResponse {
    let text: String?
    
    init(text: String?) {
        self.text = text
    }
}