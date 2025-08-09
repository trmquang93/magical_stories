#!/usr/bin/env swift

// MARK: - IllustrationServiceTester.swift
// Simple command-line tool for testing IllustrationService against the real API
// Created as part of the end-to-end integration testing for step 35 in progress.md
//
// Usage:
//   swift IllustrationServiceTester.swift --prompt "Story prompt" --theme "Story theme" [--api-key YOUR_API_KEY]
//
// If no API key is provided, it will attempt to use the one from Config.plist
//
// Examples:
//   1. Using with custom API key:
//      swift IllustrationServiceTester.swift --prompt "A happy elephant playing in water" --theme "Animal Adventures" --api-key "YOUR_API_KEY"
//
//   2. Using with Config.plist API key:
//      swift IllustrationServiceTester.swift --prompt "A magical forest with glowing trees" --theme "Fantasy World"
//
// How to run:
//   1. Navigate to the Tools directory:
//      cd magical-stories/Tools
//
//   2. Run the script directly:
//      swift IllustrationServiceTester.swift --prompt "..." --theme "..." [--api-key "..."]

import Foundation

// Include necessary files from the main project
// We need to include these directly since we're running as a standalone script
// In a real package-based command-line tool, we would import the main module instead

// MARK: - ConfigurationError
enum ConfigurationError: Error, LocalizedError {
    case plistNotFound(String)
    case keyMissing(String)
    case invalidValue(String)
    
    var errorDescription: String? {
        switch self {
        case .plistNotFound(let fileName):
            return "Configuration file '\(fileName)' not found."
        case .keyMissing(let key):
            return "Required configuration key '\(key)' is missing."
        case .invalidValue(let key):
            return "Invalid value type for configuration key '\(key)'."
        }
    }
}

// MARK: - IllustrationError
enum IllustrationError: Error, LocalizedError {
    case missingConfiguration(String)
    case invalidURL
    case networkError(Error)
    case apiError(Error)
    case invalidResponse(String)
    case noImageDataFound
    case imageProcessingError(String)
    case generationFailed(String)
    case unsupportedModel
    
    var errorDescription: String? {
        switch self {
        case .missingConfiguration(let detail):
            return "Configuration error: \(detail)"
        case .invalidURL:
            return "Invalid URL encountered."
        case .networkError(let underlyingError):
            return "Network request failed: \(underlyingError.localizedDescription)"
        case .apiError(let underlyingError):
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

// MARK: - JSON Request/Response Structures
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

struct ImagenPredictionResponse: Codable {
    let predictions: [ImagenPrediction]
}

struct ImagenPrediction: Codable {
    let bytesBase64Encoded: String?
    let mimeType: String?
}

// MARK: - IllustrationService
class IllustrationService {
    private let apiKey: String
    private let modelName = "imagen-3.0-generate-002" 
    private let apiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/"
    
    init(apiKey: String) throws {
        guard !apiKey.isEmpty else {
            throw ConfigurationError.keyMissing("API Key")
        }
        self.apiKey = apiKey
    }
    
    func generateIllustration(for pageText: String, theme: String) async throws -> URL? {
        let combinedPrompt =
            "Generate an illustration for a children's story page based on the following details. Theme: \(theme). Scene Description: \(pageText). Style: Whimsical, colorful, suitable for young children. IMPORTANT: Visualize the scene and characters based on the description, but DO NOT depict animals performing human-like actions (like talking or wearing clothes) even if mentioned in the description. Focus on the environment and the animals' natural appearance."
        print("\n--- IllustrationService: Generating illustration via REST API for prompt ---")
        print("Prompt: \"\(combinedPrompt)\"")
        
        // 1. Construct URL
        let urlString = "\(apiEndpoint)\(modelName):predict?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw IllustrationError.invalidURL
        }
        
        // 2. Prepare Request Body
        let requestBody = ImagenRequestBody(
            instances: [ImagenInstance(prompt: combinedPrompt)],
            parameters: ImagenParameters(sampleCount: 1, aspectRatio: "1:1")
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
            print("--- IllustrationService: Sending request to \(urlString) ---")
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
                print("--- IllustrationService: No image data found in predictions array. ---")
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
            print("--- IllustrationService: Caught known IllustrationError - \(error.localizedDescription) ---")
            throw error
        } catch let error as URLError {
            print("--- IllustrationService: Network Error (URLError) - \(error.localizedDescription) ---")
            throw IllustrationError.networkError(error)
        } catch {
            print("--- IllustrationService: Unexpected error during REST API call - \(error.localizedDescription) ---")
            throw IllustrationError.apiError(error)
        }
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
}

// MARK: - Command Line Argument Parsing
struct CommandLineArguments {
    var prompt: String?
    var theme: String?
    var apiKey: String?
    var helpRequested: Bool = false
    
    init(arguments: [String]) {
        var skipNext = false
        for (index, arg) in arguments.enumerated() {
            if skipNext {
                skipNext = false
                continue
            }
            
            switch arg {
            case "--prompt":
                if index + 1 < arguments.count {
                    prompt = arguments[index + 1]
                    skipNext = true
                }
            case "--theme":
                if index + 1 < arguments.count {
                    theme = arguments[index + 1]
                    skipNext = true
                }
            case "--api-key":
                if index + 1 < arguments.count {
                    apiKey = arguments[index + 1]
                    skipNext = true
                }
            case "--help", "-h":
                helpRequested = true
            default:
                if arg.hasPrefix("--") && index + 1 < arguments.count {
                    skipNext = true
                }
            }
        }
    }
    
    func isValid() -> Bool {
        return prompt != nil && theme != nil
    }
}

// MARK: - Helper Functions
func printUsage() {
    print("""
    
    IllustrationServiceTester - Test tool for the Magical Stories IllustrationService
    
    Usage:
      swift IllustrationServiceTester.swift --prompt "Story prompt" --theme "Story theme" [--api-key YOUR_API_KEY]
    
    Required Arguments:
      --prompt TEXT     The text prompt for the illustration
      --theme TEXT      The theme for the illustration
    
    Optional Arguments:
      --api-key KEY     API key for Google AI services (if not provided, will try to use Config.plist)
      --help, -h        Show this help message and exit
    
    Example:
      swift IllustrationServiceTester.swift --prompt "A happy elephant playing in water" --theme "Animal Adventures"
    
    """)
}

func loadAPIKeyFromConfigPlist() -> String? {
    let fileManager = FileManager.default
    
    // Attempt to find the Config.plist in the magical-stories directory
    let possiblePaths = [
        "magical-stories/Config.plist",
        "Config.plist",
        "../magical-stories/Config.plist",
        "../../magical-stories/Config.plist"
    ]
    
    for path in possiblePaths {
        if fileManager.fileExists(atPath: path) {
            guard let plistData = fileManager.contents(atPath: path) else {
                print("Error: Could not read Config.plist data at \(path)")
                continue
            }
            
            do {
                guard let plistDict = try PropertyListSerialization.propertyList(from: plistData, options: [], format: nil) as? [String: Any] else {
                    print("Error: Could not deserialize Config.plist at \(path)")
                    continue
                }
                
                if let apiKey = plistDict["GeminiAPIKey"] as? String, !apiKey.isEmpty {
                    print("Found API key in Config.plist at \(path)")
                    return apiKey
                } else {
                    print("Error: GeminiAPIKey not found or empty in Config.plist at \(path)")
                }
            } catch {
                print("Error reading Config.plist at \(path): \(error.localizedDescription)")
            }
        }
    }
    
    return nil
}

// MARK: - Main Function

// Execute the main function immediately
// Create a semaphore to wait for the task to complete
let semaphore = DispatchSemaphore(value: 0)

Task {
    defer {
        semaphore.signal() // Signal completion when task is done
    }
    // Parse command line arguments
    let args = CommandLineArguments(arguments: CommandLine.arguments)
    
    // Show help if requested or if required arguments are missing
    if args.helpRequested || !args.isValid() {
        printUsage()
        if !args.isValid() {
            print("\nError: Missing required arguments (prompt and theme)")
        }
        exit(1)
    }
    
    // Get API key either from command line or from Config.plist
    let apiKey: String
    if let providedApiKey = args.apiKey, !providedApiKey.isEmpty {
        print("Using provided API key from command line arguments")
        apiKey = providedApiKey
    } else if let configApiKey = loadAPIKeyFromConfigPlist() {
        print("Using API key from Config.plist")
        apiKey = configApiKey
    } else {
        print("\nError: No API key provided and couldn't find a valid API key in Config.plist")
        print("Please provide an API key using --api-key or ensure Config.plist contains a valid GeminiAPIKey")
        exit(1)
    }
    
    // Create IllustrationService and generate illustration
    do {
        print("\n--- Creating IllustrationService ---")
        let illustrationService = try IllustrationService(apiKey: apiKey)
        
        print("\n--- Generating Illustration ---")
        print("Prompt: \(args.prompt!)")
        print("Theme: \(args.theme!)")
        
        let startTime = Date()
        let imageURL = try await illustrationService.generateIllustration(
            for: args.prompt!,
            theme: args.theme!
        )
        let duration = Date().timeIntervalSince(startTime)
        
        print("\n--- Results ---")
        print("Generation Duration: \(String(format: "%.2f", duration)) seconds")
        
        if let url = imageURL {
            print("Success! Image saved at: \(url.path)")
            print("You can view it with: open \"\(url.path)\"")
        } else {
            print("Generation completed but no image URL was returned.")
        }
        
    } catch {
        print("\nError: \(error.localizedDescription)")
        exit(1)
    }
}

// Wait for the task to complete
_ = semaphore.wait(timeout: .distantFuture)