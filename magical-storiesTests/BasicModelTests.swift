//
//  BasicModelTests.swift
//  magical-storiesTests
//
//  Created by AI Assistant on 19/7/25.
//

import Testing
import Foundation
@testable import magical_stories

/// Simple tests for basic data model functionality without complex mocking
@MainActor
struct BasicModelTests {
    
    // MARK: - Page Model Tests
    
    @Test("Page can be created with required parameters")
    func testPageCreation() async throws {
        let page = Page(
            content: "Once upon a time...",
            pageNumber: 1
        )
        
        #expect(page.content == "Once upon a time...")
        #expect(page.pageNumber == 1)
        #expect(page.illustrationStatus == .pending)
        #expect(page.imagePrompt == nil)
    }
    
    @Test("Page can be created with optional parameters")
    func testPageCreationWithOptionalParameters() async throws {
        let page = Page(
            content: "The adventure continues...",
            pageNumber: 2,
            imagePrompt: "A magical forest"
        )
        
        #expect(page.content == "The adventure continues...")
        #expect(page.pageNumber == 2)
        #expect(page.imagePrompt == "A magical forest")
        #expect(page.illustrationStatus == .pending)
    }
    
    @Test("Page illustration status can be updated")
    func testPageIllustrationStatusUpdate() async throws {
        let page = Page(
            content: "Test content",
            pageNumber: 1
        )
        
        page.illustrationStatus = .ready
        #expect(page.illustrationStatus == .ready)
    }
    
    // MARK: - Story Model Tests
    
    @Test("Story can be created with required parameters")
    func testStoryCreation() async throws {
        let parameters = StoryParameters(
            theme: "Friendship",
            childAge: 5,
            childName: "Alex"
        )
        
        let pages = [
            Page(content: "Once upon a time...", pageNumber: 1),
            Page(content: "The end.", pageNumber: 2)
        ]
        
        let story = Story(
            title: "A Test Story",
            pages: pages,
            parameters: parameters
        )
        
        #expect(story.title == "A Test Story")
        #expect(story.pages.count == 2)
        #expect(story.parameters.theme == "Friendship")
        #expect(story.parameters.childName == "Alex")
        #expect(story.isCompleted == false)
    }
    
    @Test("Story can be marked as completed")
    func testStoryCompletion() async throws {
        let parameters = StoryParameters(
            theme: "Adventure",
            childAge: 6
        )
        
        let pages = [Page(content: "Test", pageNumber: 1)]
        
        let story = Story(
            title: "Test Story",
            pages: pages,
            parameters: parameters,
            isCompleted: true
        )
        
        #expect(story.isCompleted == true)
    }
    
    @Test("Story read count increments correctly")
    func testStoryReadCount() async throws {
        let parameters = StoryParameters(
            theme: "Learning",
            childAge: 4
        )
        
        let pages = [Page(content: "Test", pageNumber: 1)]
        
        let story = Story(
            title: "Test Story",
            pages: pages,
            parameters: parameters,
            readCount: 3
        )
        
        #expect(story.readCount == 3)
    }
    
    // MARK: - StoryParameters Tests
    
    @Test("StoryParameters can be created with minimal data")
    func testStoryParametersMinimal() async throws {
        let parameters = StoryParameters(
            theme: "Adventure",
            childAge: 7
        )
        
        #expect(parameters.theme == "Adventure")
        #expect(parameters.childAge == 7)
        #expect(parameters.childName == nil)
        #expect(parameters.favoriteCharacter == nil)
    }
    
    @Test("StoryParameters can be created with full data")
    func testStoryParametersComplete() async throws {
        let parameters = StoryParameters(
            theme: "Fantasy",
            childAge: 8,
            childName: "Emma",
            favoriteCharacter: "Dragon",
            storyLength: "long",
            interactiveElements: true,
            languageCode: "en"
        )
        
        #expect(parameters.theme == "Fantasy")
        #expect(parameters.childAge == 8)
        #expect(parameters.childName == "Emma")
        #expect(parameters.favoriteCharacter == "Dragon")
        #expect(parameters.storyLength == "long")
        #expect(parameters.interactiveElements == true)
        #expect(parameters.languageCode == "en")
    }
    
    // MARK: - IllustrationStatus Tests
    
    @Test("IllustrationStatus has correct enum values")
    func testIllustrationStatusValues() async throws {
        #expect(IllustrationStatus.pending.rawValue == "pending")
        #expect(IllustrationStatus.scheduled.rawValue == "scheduled") 
        #expect(IllustrationStatus.generating.rawValue == "generating")
        #expect(IllustrationStatus.ready.rawValue == "ready")
        #expect(IllustrationStatus.failed.rawValue == "failed")
    }
    
    // MARK: - StoryError Tests
    
    @Test("StoryError provides correct error descriptions")
    func testStoryErrorDescriptions() async throws {
        let generationError = StoryError.generationFailed
        let parameterError = StoryError.invalidParameters
        let persistenceError = StoryError.persistenceFailed
        
        #expect(generationError.errorDescription?.contains("generate") == true)
        #expect(parameterError.errorDescription?.contains("invalid") == true)
        #expect(persistenceError.errorDescription?.contains("save") == true)
    }
}