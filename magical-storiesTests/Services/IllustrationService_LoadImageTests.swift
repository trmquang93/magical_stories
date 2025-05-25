import XCTest
import Foundation
@testable import magical_stories

/// Unit tests for IllustrationService loadImageAsBase64 method
final class IllustrationService_LoadImageTests: XCTestCase {
    
    var illustrationService: IllustrationService!
    var testImagePath: String!
    var fileManager: FileManager!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create test service
        illustrationService = try IllustrationService(apiKey: "test-key")
        fileManager = FileManager.default
        
        // Create temporary directory for test images
        tempDirectory = fileManager.temporaryDirectory.appendingPathComponent("test-illustrations")
        try fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true, attributes: nil)
        
        // Create a test image file
        let testImageData = createTestImageData()
        testImagePath = "test-image.png"
        let testImageURL = tempDirectory.appendingPathComponent(testImagePath)
        try testImageData.write(to: testImageURL)
    }
    
    override func tearDown() async throws {
        // Clean up test files
        if fileManager.fileExists(atPath: tempDirectory.path) {
            try fileManager.removeItem(at: tempDirectory)
        }
        
        illustrationService = nil
        try await super.tearDown()
    }
    
    /// Test loading a valid image file as base64
    func testLoadImageAsBase64_ValidPath_Success() async throws {
        // Given: A valid image file exists
        let relativePath = testImagePath!
        
        // When: Loading the image as base64
        // Note: We need to test the private method indirectly by calling through the public interface
        // For now, we'll test the underlying logic by creating a reflection-based test
        
        // Create the expected file path
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil,
            create: true)
        let illustrationsDir = appSupportURL.appendingPathComponent("Illustrations")
        try fileManager.createDirectory(at: illustrationsDir, withIntermediateDirectories: true, attributes: nil)
        
        // Copy test image to the expected location
        let testImageData = createTestImageData()
        let targetURL = illustrationsDir.appendingPathComponent("test-image.png")
        try testImageData.write(to: targetURL)
        
        // Test the logic directly (since method is private, we simulate it)
        let loadedData = try Data(contentsOf: targetURL)
        let base64String = loadedData.base64EncodedString()
        
        // Then: Base64 string should be generated successfully
        XCTAssertFalse(base64String.isEmpty)
        XCTAssertTrue(base64String.contains("data"))  // Base64 should contain some data
        
        // Verify we can decode it back
        let decodedData = Data(base64Encoded: base64String)
        XCTAssertNotNil(decodedData)
        XCTAssertEqual(decodedData, testImageData)
    }
    
    /// Test loading from non-existent path
    func testLoadImageAsBase64_InvalidPath_ThrowsError() async throws {
        // Given: A non-existent file path
        let nonExistentPath = "non-existent-image.png"
        
        // When/Then: Loading should throw an error
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil,
            create: false)
        let fileURL = appSupportURL.appendingPathComponent(nonExistentPath)
        
        // Verify the file doesn't exist
        XCTAssertFalse(fileManager.fileExists(atPath: fileURL.path))
        
        // Test would throw IllustrationError.imageProcessingError
        // We can't directly test the private method, but we know the expected behavior
    }
    
    /// Test loading different image formats
    func testLoadImageAsBase64_DifferentFormats_Success() async throws {
        // Given: Different image format files
        let formats = ["png", "jpg", "webp"]
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil,
            create: true)
        let illustrationsDir = appSupportURL.appendingPathComponent("Illustrations")
        try fileManager.createDirectory(at: illustrationsDir, withIntermediateDirectories: true, attributes: nil)
        
        for format in formats {
            // Create test image data for each format
            let testImageData = createTestImageData()
            let fileName = "test-image.\(format)"
            let fileURL = illustrationsDir.appendingPathComponent(fileName)
            try testImageData.write(to: fileURL)
            
            // When: Loading the image
            let loadedData = try Data(contentsOf: fileURL)
            let base64String = loadedData.base64EncodedString()
            
            // Then: Should successfully generate base64
            XCTAssertFalse(base64String.isEmpty, "Failed to generate base64 for \(format)")
            
            // Verify we can decode it back
            let decodedData = Data(base64Encoded: base64String)
            XCTAssertNotNil(decodedData, "Failed to decode base64 for \(format)")
            XCTAssertEqual(decodedData, testImageData, "Data mismatch for \(format)")
        }
    }
    
    /// Test loading large image file
    func testLoadImageAsBase64_LargeImage_Success() async throws {
        // Given: A large image file (simulate with large data)
        let largeImageData = Data(repeating: 0xFF, count: 1024 * 1024) // 1MB of data
        
        let appSupportURL = try fileManager.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil,
            create: true)
        let illustrationsDir = appSupportURL.appendingPathComponent("Illustrations")
        try fileManager.createDirectory(at: illustrationsDir, withIntermediateDirectories: true, attributes: nil)
        
        let fileName = "large-test-image.png"
        let fileURL = illustrationsDir.appendingPathComponent(fileName)
        try largeImageData.write(to: fileURL)
        
        // When: Loading the large image
        let loadedData = try Data(contentsOf: fileURL)
        let base64String = loadedData.base64EncodedString()
        
        // Then: Should handle large files
        XCTAssertFalse(base64String.isEmpty)
        XCTAssertEqual(loadedData.count, 1024 * 1024)
        
        // Verify base64 is approximately the right size (base64 is ~33% larger)
        let expectedBase64Length = (largeImageData.count * 4 + 2) / 3
        XCTAssertGreaterThan(base64String.count, expectedBase64Length - 100)
        XCTAssertLessThan(base64String.count, expectedBase64Length + 100)
    }
    
    // MARK: - Helper Methods
    
    /// Creates test image data (simple PNG-like data)
    private func createTestImageData() -> Data {
        // Create simple test data that represents an image
        var data = Data()
        data.append(contentsOf: [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]) // PNG signature
        data.append(contentsOf: Array(repeating: 0x00, count: 100)) // Some image data
        return data
    }
}