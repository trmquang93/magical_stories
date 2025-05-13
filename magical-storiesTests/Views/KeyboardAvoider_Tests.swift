import SwiftUI
import SwiftData
import Testing
import ViewInspector
import KeyboardAvoider

@testable import magical_stories

@Suite
@MainActor
struct KeyboardAvoider_Tests {
    
    @Test("KeyboardAvoider is correctly added to StoryFormView")
    func testKeyboardAvoiderInStoryFormView() throws {
        // Check StoryFormView source code for KeyboardAvoider usage
        let storyFormCode = try String(contentsOfFile: "/Users/quang.tranminh/Projects/new-ios/magical_stories/magical-stories-app/App/Features/Home/StoryFormView.swift", encoding: .utf8)
        
        // Verify that KeyboardAvoider is imported
        #expect(storyFormCode.contains("import KeyboardAvoider"), "KeyboardAvoider is imported in StoryFormView")
        
        // Verify that KeyboardAvoider is used in the code
        #expect(storyFormCode.contains("KeyboardAvoider {"), "KeyboardAvoider is used in StoryFormView.formContentView")
        
        // Verify that the view contains an accessibility identifier for testing
        #expect(storyFormCode.contains(".accessibilityIdentifier(\"formContentView\")"), "formContentView has an accessibilityIdentifier set for testing")
    }
    
    @Test("KeyboardAvoider is correctly added to CollectionFormView")
    func testKeyboardAvoiderInCollectionFormView() throws {
        // Check CollectionFormView source code for KeyboardAvoider usage
        let collectionFormCode = try String(contentsOfFile: "/Users/quang.tranminh/Projects/new-ios/magical_stories/magical-stories-app/App/Features/Collections/CollectionFormView.swift", encoding: .utf8)
        
        // Verify that KeyboardAvoider is imported
        #expect(collectionFormCode.contains("import KeyboardAvoider"), "KeyboardAvoider is imported in CollectionFormView")
        
        // Verify that KeyboardAvoider is used in the code
        #expect(collectionFormCode.contains("KeyboardAvoider {"), "KeyboardAvoider is used in CollectionFormView")
    }
    
    @Test("KeyboardAvoider replaces ScrollView in StoryFormView")
    func testKeyboardAvoiderWrapsScrollViewInStoryForm() throws {
        // Check StoryFormView source code for ScrollView replacement
        let storyFormCode = try String(contentsOfFile: "/Users/quang.tranminh/Projects/new-ios/magical_stories/magical-stories-app/App/Features/Home/StoryFormView.swift", encoding: .utf8)
        
        // Verify KeyboardAvoider is used instead of ScrollView in formContentView
        let formContentViewCode = storyFormCode.components(separatedBy: "private var formContentView: some View {")[1]
            .components(separatedBy: "}")[0]
        
        // Verify the formContentView uses KeyboardAvoider instead of ScrollView
        #expect(formContentViewCode.contains("KeyboardAvoider {"), "KeyboardAvoider has replaced ScrollView in StoryFormView")
        #expect(!formContentViewCode.contains("ScrollView("), "ScrollView is not directly used in formContentView")
    }
    
    @Test("KeyboardAvoider replaces ScrollView in CollectionFormView")
    func testKeyboardAvoiderWrapsScrollViewInCollectionForm() throws {
        // Check CollectionFormView source code for ScrollView replacement
        let collectionFormCode = try String(contentsOfFile: "/Users/quang.tranminh/Projects/new-ios/magical_stories/magical-stories-app/App/Features/Collections/CollectionFormView.swift", encoding: .utf8)
        
        // Verify KeyboardAvoider is used in the body property
        let bodyCode = collectionFormCode.components(separatedBy: "var body: some View {")[1]
            .components(separatedBy: "// Loading overlay with animations")[0]
        
        // Verify the body contains KeyboardAvoider but not ScrollView
        #expect(bodyCode.contains("KeyboardAvoider {"), "KeyboardAvoider is used in CollectionFormView")
        
        // Check that there's not a direct ScrollView in the body at the same level as KeyboardAvoider
        let zstackCode = bodyCode.components(separatedBy: "ZStack {")[1]
            .components(separatedBy: "}")[0]
        let mainContent = zstackCode.components(separatedBy: "// Form content")[1]
            .components(separatedBy: "// Loading overlay")[0]
        
        #expect(!mainContent.contains("ScrollView("), "ScrollView is not used directly in the main content")
    }
    
    @Test("KeyboardAvoider dismisses keyboard on tap outside textfield")
    func testKeyboardAvoiderDismissesKeyboard() throws {
        // Check for keyboard dismissal documentation in both files
        let storyFormCode = try String(contentsOfFile: "/Users/quang.tranminh/Projects/new-ios/magical_stories/magical-stories-app/App/Features/Home/StoryFormView.swift", encoding: .utf8)
        let collectionFormCode = try String(contentsOfFile: "/Users/quang.tranminh/Projects/new-ios/magical_stories/magical-stories-app/App/Features/Collections/CollectionFormView.swift", encoding: .utf8)
        
        // Verify StoryFormView has a comment about automatic keyboard dismissal
        #expect(storyFormCode.contains("Keyboard is automatically dismissed by KeyboardAvoider"), 
               "StoryFormView comments document that KeyboardAvoider handles keyboard dismissal")
        
        // Verify similar documentation in CollectionFormView
        #expect(collectionFormCode.contains("Keyboard is automatically dismissed by KeyboardAvoider"), 
               "CollectionFormView comments document that KeyboardAvoider handles keyboard dismissal")
        
        // Verify that manual keyboard dismissal code is not present
        #expect(!storyFormCode.contains("UIApplication.shared.sendAction") && 
                !storyFormCode.contains(".endEditing") && 
                !storyFormCode.contains("resignFirstResponder"),
                "StoryFormView doesn't use manual keyboard dismissal methods")
        
        #expect(!collectionFormCode.contains("UIApplication.shared.sendAction") && 
                !collectionFormCode.contains(".endEditing") && 
                !collectionFormCode.contains("resignFirstResponder"),
                "CollectionFormView doesn't use manual keyboard dismissal methods")
    }
}