import Foundation
import Testing
@testable import magical_stories

@Suite
struct IllustrationTaskExtensionTests {
    
    @Test("illustrationTaskShouldSupportTaskTypePropertyWithGlobalReferenceAndPageIllustrationTypes")
    func testTaskTypeProperty() {
        // Arrange & Act
        let globalTask = IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .high,
            taskType: .globalReference
        )
        
        let pageTask = IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .medium,
            taskType: .pageIllustration
        )
        
        // Assert
        #expect(globalTask.taskType == .globalReference)
        #expect(pageTask.taskType == .pageIllustration)
        
        // Default value should be pageIllustration
        let defaultTask = IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .low
        )
        
        #expect(defaultTask.taskType == .pageIllustration)
    }
    
    @Test("illustrationTaskShouldSupportPageIndexProperty")
    func testPageIndexProperty() {
        // Arrange & Act
        let task = IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .medium,
            pageIndex: 2
        )
        
        // Assert
        #expect(task.pageIndex == 2)
        
        // Page index should be nil by default for backwards compatibility
        let defaultTask = IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .low
        )
        
        #expect(defaultTask.pageIndex == nil)
    }
    
    @Test("illustrationTaskShouldSupportPreviousPageIllustrationURLProperty")
    func testPreviousIllustrationURLProperty() {
        // Arrange
        let previousURL = URL(string: "file:///path/to/previous/illustration.png")!
        
        // Act
        let task = IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .medium,
            previousIllustrationURL: previousURL
        )
        
        // Assert
        #expect(task.previousIllustrationURL == previousURL)
        
        // Previous illustration URL should be nil by default
        let defaultTask = IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .low
        )
        
        #expect(defaultTask.previousIllustrationURL == nil)
    }
    
    @Test("illustrationTaskShouldSupportGlobalReferenceURLProperty")
    func testGlobalReferenceURLProperty() {
        // Arrange
        let globalURL = URL(string: "file:///path/to/global/reference.png")!
        
        // Act
        let task = IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .medium,
            globalReferenceURL: globalURL
        )
        
        // Assert
        #expect(task.globalReferenceURL == globalURL)
        
        // Global reference URL should be nil by default
        let defaultTask = IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .low
        )
        
        #expect(defaultTask.globalReferenceURL == nil)
    }
    
    @Test("illustrationTaskShouldSupportDependenciesProperty")
    func testDependenciesProperty() {
        // Arrange
        let dependency1 = UUID()
        let dependency2 = UUID()
        
        // Act
        let task = IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .medium,
            dependencies: [dependency1, dependency2]
        )
        
        // Assert
        #expect(task.dependencies != nil)
        #expect(task.dependencies?.count == 2)
        #expect(task.dependencies?.contains(dependency1) == true)
        #expect(task.dependencies?.contains(dependency2) == true)
        
        // Dependencies should be nil by default
        let defaultTask = IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .low
        )
        
        #expect(defaultTask.dependencies == nil)
    }
    
    @Test("illustrationTaskShouldSupportAddDependencyMethod")
    func testAddDependencyMethod() {
        // Arrange
        let dependency1 = UUID()
        let dependency2 = UUID()
        var task = IllustrationTask(
            pageId: UUID(),
            storyId: UUID(),
            priority: .medium
        )
        
        // Act
        task.addDependency(dependency1)
        
        // Assert
        #expect(task.dependencies?.count == 1)
        #expect(task.dependencies?.contains(dependency1) == true)
        
        // Add another dependency
        task.addDependency(dependency2)
        
        // Assert
        #expect(task.dependencies?.count == 2)
        #expect(task.dependencies?.contains(dependency1) == true)
        #expect(task.dependencies?.contains(dependency2) == true)
        
        // Adding the same dependency again should not duplicate it
        task.addDependency(dependency1)
        
        // Assert
        #expect(task.dependencies?.count == 2)
    }
    
    @Test("illustrationTaskWithDependenciesShouldBeEncodableAndDecodable")
    func testCoding() throws {
        // Arrange
        let dependency1 = UUID()
        let dependency2 = UUID()
        let pageId = UUID()
        let storyId = UUID()
        let globalReferenceURL = URL(string: "file:///path/to/global/reference.png")!
        let previousIllustrationURL = URL(string: "file:///path/to/previous/illustration.png")!
        
        let originalTask = IllustrationTask(
            id: UUID(),
            pageId: pageId,
            storyId: storyId,
            priority: .high,
            status: .pending,
            taskType: .pageIllustration,
            pageIndex: 3,
            previousIllustrationURL: previousIllustrationURL,
            globalReferenceURL: globalReferenceURL,
            dependencies: [dependency1, dependency2]
        )
        
        // Act
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalTask)
        
        let decoder = JSONDecoder()
        let decodedTask = try decoder.decode(IllustrationTask.self, from: data)
        
        // Assert
        #expect(decodedTask.id == originalTask.id)
        #expect(decodedTask.pageId == originalTask.pageId)
        #expect(decodedTask.storyId == originalTask.storyId)
        #expect(decodedTask.priority == originalTask.priority)
        #expect(decodedTask.status == originalTask.status)
        #expect(decodedTask.taskType == originalTask.taskType)
        #expect(decodedTask.pageIndex == originalTask.pageIndex)
        #expect(decodedTask.previousIllustrationURL == originalTask.previousIllustrationURL)
        #expect(decodedTask.globalReferenceURL == originalTask.globalReferenceURL)
        #expect(decodedTask.dependencies?.count == originalTask.dependencies?.count)
        #expect(decodedTask.dependencies?.contains(dependency1) == true)
        #expect(decodedTask.dependencies?.contains(dependency2) == true)
    }
}