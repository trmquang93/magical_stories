import Foundation
@testable import magical_stories

// MARK: - Shared Mock Illustration Service
// This mock is shared across multiple test files to avoid duplication
// and resolve compilation issues in disabled test files.

@MainActor
class SharedMockIllustrationService: IllustrationServiceProtocol {
    var generateIllustrationCallCount = 0
    // Store the parameters received by the last call
    var lastCallParameters: (pageText: String, theme: String)?
    var generateIllustrationPrompts: [(pageText: String, theme: String)] = []  // Store all parameters received
    var generateIllustrationShouldReturnURL: URL? = URL(string: "https://mock.url/image.png")  // Default success URL
    var generateIllustrationShouldThrowError: Error? = nil  // Default no error
    var urlToReturn: URL? = URL(string: "https://mock.url/image.png")  // Control return value

    // For the enhanced method
    var generateContextualIllustrationCallCount = 0
    var lastContextualCallParameters:
        (description: String, pageNumber: Int, totalPages: Int, previousPath: String?)?
    var contextualIllustrationPrompts:
        [(description: String, pageNumber: Int, totalPages: Int, previousPath: String?)] = []

    // Update signature to match protocol
    @MainActor
    func generateIllustration(for pageText: String, theme: String) async throws -> String? {
        generateIllustrationCallCount += 1
        lastCallParameters = (pageText, theme)
        generateIllustrationPrompts.append((pageText, theme))

        if let error = generateIllustrationShouldThrowError {
            print(
                "--- SharedMockIllustrationService: Throwing error for pageText: \(pageText.prefix(50))..., theme: \(theme) ---"
            )
            throw error
        }
        let relativePath = urlToReturn?.path.replacingOccurrences(
            of: "/private/var/mobile/Containers/Data/Application/UUID/Application Support/",
            with: "")
        print(
            "--- SharedMockIllustrationService: Returning relative path \(relativePath ?? "nil") for pageText: \(pageText.prefix(50))..., theme: \(theme) ---"
        )
        return relativePath
    }

    // Implement the new method required by the protocol
    @MainActor
    func generateIllustration(
        for illustrationDescription: String,
        pageNumber: Int,
        totalPages: Int,
        previousIllustrationPath: String?,
        visualGuide: VisualGuide?,
        globalReferenceImagePath: String?,
        collectionContext: CollectionVisualContext?
    ) async throws -> String? {
        generateContextualIllustrationCallCount += 1
        lastContextualCallParameters = (
            illustrationDescription, pageNumber, totalPages, previousIllustrationPath
        )
        contextualIllustrationPrompts.append(
            (illustrationDescription, pageNumber, totalPages, previousIllustrationPath))

        if let error = generateIllustrationShouldThrowError {
            print(
                "--- SharedMockIllustrationService: Throwing error for contextual description: \(illustrationDescription.prefix(50))..., page \(pageNumber)/\(totalPages) ---"
            )
            throw error
        }

        let relativePath = urlToReturn?.path.replacingOccurrences(
            of: "/private/var/mobile/Containers/Data/Application/UUID/Application Support/",
            with: "")
        print(
            "--- SharedMockIllustrationService: Returning relative path \(relativePath ?? "nil") for contextual description: \(illustrationDescription.prefix(50))..., page \(pageNumber)/\(totalPages) ---"
        )
        return relativePath
    }

    func reset() {
        generateIllustrationCallCount = 0
        lastCallParameters = nil
        generateIllustrationPrompts = []
        generateContextualIllustrationCallCount = 0
        lastContextualCallParameters = nil
        contextualIllustrationPrompts = []
        generateIllustrationShouldThrowError = nil
        urlToReturn = URL(string: "https://mock.url/image.png")
    }
}