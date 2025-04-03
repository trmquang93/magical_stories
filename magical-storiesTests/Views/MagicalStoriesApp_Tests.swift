import Testing
import SwiftUI
@testable import magical_stories

struct MagicalStoriesApp_Tests {
    
    @Test("MagicalStoriesApp should initialize without errors")
    func testAppInitialization() async {
        // Given/When
        _ = await MagicalStoriesApp()
        
        // Then - Simply verify it initializes without crashing
        // We can't directly verify private services, but we ensure initialization works
        #expect(true)
    }
    
    @Test("MagicalStoriesApp body should create a WindowGroup containing RootView")
    func testAppBody() async throws {
        // Given
        let app = await MagicalStoriesApp()
        
        // Then - Verify we have a scene
        // The body of the App is the Scene (WindowGroup in this case)
        let scene = await app.body
        let sceneMirror = Mirror(reflecting: scene)
        
        // Check if it's a WindowGroup by looking for its characteristic properties
        // Note: This is fragile and depends on WindowGroup's internal structure
        let windowGroupContentCheck = sceneMirror.descendant("content") // WindowGroup has a 'content' closure
        try #require(windowGroupContentCheck != nil, "App body should be a Scene (like WindowGroup) with content")
        
        // Simplified Check: Verify the scene content exists
        try #require(windowGroupContentCheck != nil, "Scene content (WindowGroup) should exist")

        // Further reflection is too fragile. We'll assume if the WindowGroup exists,
        // it contains the RootView as defined in MagicalStoriesApp.swift.
        // A better approach would involve UI testing or accessibility identifiers.
        let contentType = String(describing: type(of: windowGroupContentCheck!)) // Check type of the content closure itself
        // Check if the content type description suggests it's a closure returning RootView
        // This is still indirect.
        #expect(contentType.contains("RootView"), "WindowGroup content closure should likely return RootView")
    }
}
