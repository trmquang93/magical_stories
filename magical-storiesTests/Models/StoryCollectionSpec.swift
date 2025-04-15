import XCTest
@testable import magical_stories

final class StoryCollectionSpec: XCTestCase {
    func testInitialization() {
        let collection = StoryCollection(
            title: "Test Collection",
            descriptionText: "Test Description",
            category: "emotionalIntelligence",
            ageGroup: "elementary"
        )
        
        XCTAssertEqual(collection.title, "Test Collection")
        XCTAssertEqual(collection.descriptionText, "Test Description")
        XCTAssertEqual(collection.category, "emotionalIntelligence")
        XCTAssertEqual(collection.ageGroup, "elementary")
        XCTAssertEqual(collection.completionProgress, 0.0)
        XCTAssertNotNil(collection.id)
    }
}

extension StoryCollection {
    static func mock() -> StoryCollection {
        StoryCollection(
            title: "Mock Collection",
            descriptionText: "Mock Description",
            category: "emotionalIntelligence",
            ageGroup: "elementary"
        )
    }
}
