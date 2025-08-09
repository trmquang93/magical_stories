//
//  magical_storiesTests.swift
//  magical-storiesTests
//
//  Created by Quang Tran Minh on 30/3/25.
//

import Testing
import Foundation
@testable import magical_stories

struct magical_storiesTests {

    @Test("Basic app functionality works")
    func testBasicAppFunctionality() async throws {
        // Test that the app module can be imported and basic types exist
        #expect(Bundle.main.bundleIdentifier != nil)
    }

    @Test("Basic models can be created")
    func testBasicModelCreation() async throws {
        let parameters = StoryParameters(
            theme: "Fantasy",
            childAge: 5,
            childName: "Test",
            storyLength: "medium"
        )
        
        #expect(parameters.childName == "Test")
        #expect(parameters.theme == "Fantasy")
    }

}
