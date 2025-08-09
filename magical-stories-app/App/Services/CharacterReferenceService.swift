import Foundation
import SwiftData
import CoreGraphics
#if os(iOS)
import UIKit
#endif


// MARK: - Master Reference Models

/// Information about a master reference image containing all visual elements
public struct MasterReferenceInfo: Codable, Sendable {
    let storyId: UUID
    let imageData: Data
    let visualElementNames: [String]
    let descriptiveMapping: [String]
    let generatedAt: Date
    
    public init(storyId: UUID, imageData: Data, visualElementNames: [String], descriptiveMapping: [String], generatedAt: Date = Date()) {
        self.storyId = storyId
        self.imageData = imageData
        self.visualElementNames = visualElementNames
        self.descriptiveMapping = descriptiveMapping
        self.generatedAt = generatedAt
    }
}

// MARK: - Character Reference Errors

public enum CharacterReferenceError: Error, LocalizedError, Sendable, Equatable {
    case invalidStoryData
    case noVisualElementsFound
    case masterReferenceGenerationFailed(String)
    case invalidImageData
    case cachingFailed(String)
    case visualElementNotFound(String)
    case unsupportedElementCount(Int)
    
    public var errorDescription: String? {
        switch self {
        case .invalidStoryData:
            return "Invalid story data provided"
        case .noVisualElementsFound:
            return "No visual elements found in the story"
        case .masterReferenceGenerationFailed(let reason):
            return "Master reference generation failed: \(reason)"
        case .invalidImageData:
            return "Invalid image data provided"
        case .cachingFailed(let reason):
            return "Failed to cache master reference: \(reason)"
        case .visualElementNotFound(let name):
            return "Visual element '\(name)' not found in reference"
        case .unsupportedElementCount(let count):
            return "Unsupported visual element count: \(count). Maximum supported is 10 elements."
        }
    }
}


// MARK: - Character Reference Service

/// Service for handling master reference generation for visual elements
@MainActor
public final class CharacterReferenceService: ObservableObject, @unchecked Sendable {
    
    // MARK: - Properties
    
    nonisolated private let illustrationService: any SimpleIllustrationServiceProtocol
    private let jsonPromptBuilder: JSONPromptBuilder
    private let cache: MasterReferenceCache
    
    @Published public var isGenerating = false
    
    // MARK: - Initialization
    
    init(
        illustrationService: any SimpleIllustrationServiceProtocol,
        jsonPromptBuilder: JSONPromptBuilder? = nil,
        cache: MasterReferenceCache? = nil
    ) {
        self.illustrationService = illustrationService
        self.jsonPromptBuilder = jsonPromptBuilder ?? JSONPromptBuilder()
        self.cache = cache ?? MasterReferenceCache()
    }
    
    // MARK: - Public Methods
    
    /// Generates a master reference image containing all visual elements in a grid layout
    /// - Parameter story: The story to generate master reference for
    /// - Returns: Master reference image data
    /// - Throws: CharacterReferenceError if generation fails
    func generateMasterReference(for story: Story) async throws -> Data {
        print("[CharacterReferenceService] Generating master reference for story: \(story.title)")
        
        guard let visualGuide = story.visualGuide else {
            throw CharacterReferenceError.invalidStoryData
        }
        
        // Use the story's ordered visual element names to maintain consistency
        guard let elementNames = story.characterNames, !elementNames.isEmpty else {
            throw CharacterReferenceError.noVisualElementsFound
        }
        
        print("[CharacterReferenceService] Using ordered visual element names: \(elementNames.joined(separator: ", "))")
        
        guard elementNames.count <= 10 else {
            throw CharacterReferenceError.unsupportedElementCount(elementNames.count)
        }
        
        isGenerating = true
        defer {
            isGenerating = false
        }
        
        do {
            // Create structured JSON master reference prompt
            let jsonPrompt = try jsonPromptBuilder.createMasterReferencePrompt(
                visualGuide: visualGuide,
                storyTitle: story.title,
                elementNames: elementNames
            )
            print("[CharacterReferenceService] 🎭 Generated structured JSON master reference prompt (\(jsonPrompt.count) characters)")
            print("[CharacterReferenceService] 🎯 Creating master reference for story: '\(story.title)' with \(elementNames.count) elements")
            
            // Generate master reference using illustration service
            let masterReferenceData = try await generateMasterReferenceImage(prompt: jsonPrompt)
            
            // Validate the generated image
            let isValid = validateMasterReferenceImage(masterReferenceData, expectedElementCount: elementNames.count)
            if !isValid {
                print("[CharacterReferenceService] ⚠️ Generated master reference may not meet specifications")
            }
            
            print("[CharacterReferenceService] Successfully generated master reference (\(masterReferenceData.count) bytes)")
            return masterReferenceData
            
        } catch {
            print("[CharacterReferenceService] Master reference generation failed: \(error.localizedDescription)")
            throw CharacterReferenceError.masterReferenceGenerationFailed(error.localizedDescription)
        }
    }
    
    /// Gets descriptive mapping for visual elements based on the story's visual guide
    /// - Parameter story: The story containing visual element definitions
    /// - Returns: Array of descriptive mapping strings
    func getDescriptiveMapping(for story: Story) -> [String] {
        guard let visualGuide = story.visualGuide,
              let elementNames = story.characterNames else {
            return []
        }
        
        return visualGuide.createDescriptiveMapping(orderedNames: elementNames)
    }
    
    /// Gets the master reference image for a story
    /// - Parameter story: The story to get master reference for
    /// - Returns: Master reference image data if available, nil otherwise
    func getMasterReference(for story: Story) -> Data? {
        // Check if master reference is stored in the story
        if let masterData = story.characterReferenceData {
            print("[CharacterReferenceService] Retrieved master reference from story cache")
            return masterData
        }
        
        print("[CharacterReferenceService] No master reference found for story")
        return nil
    }
    
    /// Caches master reference info for a story
    /// - Parameters:
    ///   - referenceInfo: Master reference information to cache
    ///   - story: Story to associate with the master reference
    /// - Throws: CharacterReferenceError if caching fails
    func cacheMasterReference(_ referenceInfo: MasterReferenceInfo, for story: Story) throws {
        do {
            // Store master reference data in the story
            story.characterReferenceData = referenceInfo.imageData
            
            // Update story with visual element names if needed
            if story.characterNames != referenceInfo.visualElementNames {
                story.characterNames = referenceInfo.visualElementNames
            }
            
            print("[CharacterReferenceService] Successfully cached master reference for story '\(story.title)'")
            
        } catch {
            print("[CharacterReferenceService] Failed to cache master reference: \(error.localizedDescription)")
            throw CharacterReferenceError.cachingFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Convenience Methods
    
    /// Generates complete master reference system for a story
    /// - Parameter story: Story to generate master reference for
    /// - Returns: Master reference information
    /// - Throws: CharacterReferenceError if generation fails
    func generateCompleteMasterReference(for story: Story) async throws -> MasterReferenceInfo {
        print("[CharacterReferenceService] Generating complete master reference for story: \(story.title)")
        
        // Generate master reference
        let masterReferenceData = try await generateMasterReference(for: story)
        
        // Store master reference in story
        story.characterReferenceData = masterReferenceData
        
        // Use the story's ordered visual element names to maintain consistency
        guard let elementNames = story.characterNames, !elementNames.isEmpty else {
            throw CharacterReferenceError.noVisualElementsFound
        }
        
        // Create descriptive mapping
        let descriptiveMapping = getDescriptiveMapping(for: story)
        
        let masterReferenceInfo = MasterReferenceInfo(
            storyId: story.id,
            imageData: masterReferenceData,
            visualElementNames: elementNames,
            descriptiveMapping: descriptiveMapping
        )
        
        // Cache the results
        try cacheMasterReference(masterReferenceInfo, for: story)
        
        print("[CharacterReferenceService] Successfully generated complete master reference system")
        return masterReferenceInfo
    }
    
    /// Checks if a story has a cached master reference
    /// - Parameter story: Story to check
    /// - Returns: True if master reference is available, false otherwise
    func hasCharacterReferences(for story: Story) -> Bool {
        return story.characterReferenceData != nil
    }
}

// MARK: - Private Implementation

private extension CharacterReferenceService {
    
    /// Sets the generating state on the main actor
    func setGeneratingState(_ generating: Bool) {
        self.isGenerating = generating
    }
    
    
    /// Generates the master reference image using the illustration service
    func generateMasterReferenceImage(prompt: String) async throws -> Data {
        print("[CharacterReferenceService] Generating master reference image with specialized prompt")
        print("[CharacterReferenceService] Bypassing story illustration wrapper to avoid confusion")
        
        // Use the raw illustration generation method to avoid story context wrapping
        // This prevents the AI from getting confused by story illustration prompts
        return try await illustrationService.generateRawIllustration(prompt: prompt, masterReferenceData: nil)
    }
    
    /// Validates the generated master reference image
    private func validateMasterReferenceImage(_ imageData: Data, expectedElementCount: Int) -> Bool {
        #if os(iOS)
        guard let image = UIImage(data: imageData) else {
            print("[CharacterReferenceService] ❌ Validation failed: Cannot create UIImage from data")
            return false
        }
        
        let imageSize = image.size
        let expectedAspectRatio: CGFloat = 16.0 / 9.0 // 16:9 aspect ratio
        let actualAspectRatio = imageSize.width / imageSize.height
        
        // Check if aspect ratio is approximately 16:9 (allow 5% tolerance)
        let aspectRatioTolerance: CGFloat = 0.05
        let aspectRatioMatch = abs(actualAspectRatio - expectedAspectRatio) <= (expectedAspectRatio * aspectRatioTolerance)
        
        // Check minimum size requirements
        let minWidth: CGFloat = 800
        let minHeight: CGFloat = 400
        let sizeMatch = imageSize.width >= minWidth && imageSize.height >= minHeight
        
        if !aspectRatioMatch {
            print("[CharacterReferenceService] ❌ Validation failed: Aspect ratio \(actualAspectRatio) doesn't match expected ~\(expectedAspectRatio)")
            return false
        }
        
        if !sizeMatch {
            print("[CharacterReferenceService] ❌ Validation failed: Image size \(imageSize) too small (min: \(minWidth)×\(minHeight))")
            return false
        }
        
        print("[CharacterReferenceService] ✅ Validation passed: Image size \(imageSize), aspect ratio \(String(format: "%.2f", actualAspectRatio))")
        return true
        #else
        // On non-iOS platforms, basic validation
        guard imageData.count > 1000 else {
            print("[CharacterReferenceService] ❌ Validation failed: Image data too small (\(imageData.count) bytes)")
            return false
        }
        
        print("[CharacterReferenceService] ✅ Basic validation passed: \(imageData.count) bytes")
        return true
        #endif
    }
    
}

// MARK: - Master Reference Cache

/// Simple cache for master references
class MasterReferenceCache {
    private var masterReferenceCache: [String: MasterReferenceInfo] = [:]
    private let cacheQueue = DispatchQueue(label: "com.magicalstories.master-reference-cache", attributes: .concurrent)
    
    func storeMasterReference(_ reference: MasterReferenceInfo, storyId: UUID) {
        let key = storyId.uuidString
        cacheQueue.async(flags: .barrier) {
            self.masterReferenceCache[key] = reference
        }
    }
    
    func getMasterReference(for storyId: UUID) -> MasterReferenceInfo? {
        let key = storyId.uuidString
        return cacheQueue.sync {
            return masterReferenceCache[key]
        }
    }
    
    func hasMasterReference(for storyId: UUID) -> Bool {
        let key = storyId.uuidString
        return cacheQueue.sync {
            return masterReferenceCache[key] != nil
        }
    }
    
    func clearCache(for storyId: UUID) {
        let key = storyId.uuidString
        cacheQueue.async(flags: .barrier) {
            self.masterReferenceCache.removeValue(forKey: key)
        }
    }
    
    func clearAllCache() {
        cacheQueue.async(flags: .barrier) {
            self.masterReferenceCache.removeAll()
        }
    }
}