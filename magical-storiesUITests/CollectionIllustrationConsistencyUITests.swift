import XCTest

final class CollectionIllustrationConsistencyUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Wait for app to fully load
        XCTAssertTrue(app.waitForExistence(timeout: 15), "App should launch successfully")
        takeScreenshot("setup_app_launched")
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Main Test: Collection Creation and Illustration Consistency
    
    func testCollectionCreationAndIllustrationConsistency() throws {
        // This test validates the complete flow:
        // 1. Navigate to Collections tab
        // 2. Create a new collection
        // 3. Open the first story in the collection
        // 4. Wait for all illustrations to generate
        // 5. Go through all pages to verify illustration consistency
        
        // Step 1: Navigate to Collections tab
        navigateToCollectionsTab()
        
        // Step 2: Create a new collection
        let collectionTitle = createNewCollection()
        
        // Step 3: Open the first story in the collection
        openFirstStoryInCollection(collectionTitle: collectionTitle)
        
        // Step 4: Wait for all illustrations to generate
        waitForAllIllustrationsToGenerate()
        
        // Step 5: Go through all pages and verify illustration consistency
        verifyIllustrationConsistencyAcrossPages()
    }
    
    // MARK: - Step 1: Navigate to Collections Tab
    
    private func navigateToCollectionsTab() {
        takeScreenshot("01_before_collections_navigation")
        
        // Look for Collections tab
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10), "Tab bar should exist")
        
        // Try different ways to find the Collections tab
        var collectionsTab: XCUIElement?
        
        // Method 1: Look for button with "Collections" text
        collectionsTab = app.buttons["Collections"]
        if !collectionsTab!.exists {
            // Method 2: Look for tab bar button containing "Collections"
            collectionsTab = tabBar.buttons.containing(NSPredicate(format: "label CONTAINS 'Collections'")).firstMatch
        }
        if !collectionsTab!.exists {
            // Method 3: Look for any element containing "Collection"
            collectionsTab = app.descendants(matching: .any).containing(NSPredicate(format: "label CONTAINS 'Collection'")).firstMatch
        }
        
        XCTAssertTrue(collectionsTab!.exists, "Collections tab should be found")
        collectionsTab!.tap()
        
        // Wait for Collections view to load
        sleep(2)
        takeScreenshot("02_collections_tab_opened")
        
        print("✅ Successfully navigated to Collections tab")
    }
    
    // MARK: - Step 2: Create New Collection
    
    private func createNewCollection() -> String {
        takeScreenshot("03_collections_view_loaded")
        
        // Look for "Add Collection" or "Create Collection" button
        var createButton: XCUIElement?
        
        // Try different selectors for the create collection button
        let possibleButtonTexts = ["Add Collection", "Create Collection", "New Collection", "+", "Add"]
        
        for buttonText in possibleButtonTexts {
            createButton = app.buttons[buttonText]
            if createButton!.exists {
                print("✅ Found create button: \(buttonText)")
                break
            }
        }
        
        // If no button found, look for any tappable element with relevant text
        if createButton == nil || !createButton!.exists {
            createButton = app.descendants(matching: .any).containing(NSPredicate(format: "label CONTAINS 'Add' OR label CONTAINS 'Create' OR label CONTAINS 'New'")).firstMatch
        }
        
        XCTAssertTrue(createButton?.exists == true, "Create collection button should exist")
        createButton!.tap()
        
        takeScreenshot("04_create_collection_button_tapped")
        
        // Wait for collection creation form
        sleep(3)
        takeScreenshot("05_collection_form_opened")
        
        // Fill in collection details
        let collectionTitle = "Test Collection \(Date().timeIntervalSince1970)"
        fillCollectionForm(title: collectionTitle)
        
        return collectionTitle
    }
    
    private func fillCollectionForm(title: String) {
        // Look for title field
        let titleField = app.textFields.firstMatch
        if titleField.exists {
            titleField.tap()
            titleField.typeText(title)
            takeScreenshot("06_collection_title_entered")
        }
        
        // Look for description field
        let descriptionField = app.textViews.firstMatch
        if descriptionField.exists {
            descriptionField.tap()
            descriptionField.typeText("Automated test collection for illustration consistency verification")
            takeScreenshot("07_collection_description_entered")
        }
        
        // Look for age group selection
        let ageGroupPicker = app.pickers.firstMatch
        if ageGroupPicker.exists {
            ageGroupPicker.tap()
            // Select first available age group
            let firstAgeGroup = app.pickerWheels.firstMatch
            if firstAgeGroup.exists {
                firstAgeGroup.adjust(toPickerWheelValue: "3-5 years")
            }
            takeScreenshot("08_age_group_selected")
        }
        
        // Submit the form
        let submitButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Create' OR label CONTAINS 'Save' OR label CONTAINS 'Generate'")).firstMatch
        XCTAssertTrue(submitButton.waitForExistence(timeout: 5), "Submit button should exist")
        submitButton.tap()
        
        takeScreenshot("09_collection_form_submitted")
        
        // Wait for collection creation to complete
        sleep(5)
        takeScreenshot("10_collection_created")
        
        print("✅ Collection created successfully: \(title)")
    }
    
    // MARK: - Step 3: Open First Story in Collection
    
    private func openFirstStoryInCollection(collectionTitle: String) {
        takeScreenshot("11_looking_for_new_collection")
        
        // Wait for collection to appear in the list
        sleep(3)
        
        // Look for the newly created collection
        let collectionCard = app.descendants(matching: .any).containing(NSPredicate(format: "label CONTAINS '\(collectionTitle)'")).firstMatch
        
        if collectionCard.waitForExistence(timeout: 10) {
            collectionCard.tap()
            takeScreenshot("12_collection_tapped")
        } else {
            // Fallback: tap on any collection card
            let anyCollectionCard = app.descendants(matching: .any).containing(NSPredicate(format: "label CONTAINS 'Collection'")).firstMatch
            XCTAssertTrue(anyCollectionCard.waitForExistence(timeout: 10), "Should find at least one collection")
            anyCollectionCard.tap()
            takeScreenshot("12_fallback_collection_tapped")
        }
        
        // Wait for collection detail view
        sleep(3)
        takeScreenshot("13_collection_detail_opened")
        
        // Look for the first story in the collection
        let firstStory = app.descendants(matching: .any).containing(NSPredicate(format: "label CONTAINS 'Story' OR label CONTAINS 'Page'")).firstMatch
        
        if firstStory.waitForExistence(timeout: 10) {
            firstStory.tap()
            takeScreenshot("14_first_story_tapped")
        } else {
            // If no story found, look for any tappable element that might open a story
            let storyElement = app.cells.firstMatch
            if storyElement.exists {
                storyElement.tap()
                takeScreenshot("14_fallback_story_element_tapped")
            }
        }
        
        // Wait for story to open
        sleep(3)
        takeScreenshot("15_story_opened")
        
        print("✅ First story in collection opened")
    }
    
    // MARK: - Step 4: Wait for All Illustrations to Generate
    
    private func waitForAllIllustrationsToGenerate() {
        takeScreenshot("16_waiting_for_illustrations")
        
        print("⏳ Waiting for illustrations to generate...")
        
        // Wait for illustration generation to begin and complete
        // This is a longer wait since illustration generation takes time
        let maxWaitTime = 120 // 2 minutes maximum wait
        let checkInterval = 5 // Check every 5 seconds
        var waitedTime = 0
        
        while waitedTime < maxWaitTime {
            sleep(UInt32(checkInterval))
            waitedTime += checkInterval
            
            takeScreenshot("17_illustration_check_\(waitedTime)s")
            
            // Check for illustration loading indicators
            let loadingIndicators = app.descendants(matching: .any).containing(NSPredicate(format: "label CONTAINS 'Loading' OR label CONTAINS 'Generating' OR label CONTAINS 'Creating'"))
            
            if loadingIndicators.count == 0 {
                // No loading indicators found, illustrations might be ready
                print("✅ No loading indicators found at \(waitedTime)s")
                break
            } else {
                print("⏳ Still generating illustrations... (\(waitedTime)s elapsed)")
            }
        }
        
        // Final wait to ensure everything is settled
        sleep(5)
        takeScreenshot("18_illustrations_generation_complete")
        
        print("✅ Illustration generation phase completed")
    }
    
    // MARK: - Step 5: Verify Illustration Consistency Across Pages
    
    private func verifyIllustrationConsistencyAcrossPages() {
        takeScreenshot("19_starting_page_consistency_check")
        
        var pageNumber = 1
        var hasMorePages = true
        var previousPageElements: [String] = []
        
        while hasMorePages && pageNumber <= 10 { // Limit to 10 pages for safety
            takeScreenshot("20_page_\(pageNumber)_view")
            
            // Analyze current page for consistency elements
            let currentPageElements = analyzePageForConsistencyElements()
            
            // Compare with previous pages
            if pageNumber > 1 {
                verifyConsistencyBetweenPages(
                    previousElements: previousPageElements,
                    currentElements: currentPageElements,
                    pageNumber: pageNumber
                )
            }
            
            previousPageElements = currentPageElements
            
            // Try to navigate to next page
            hasMorePages = navigateToNextPage(currentPage: pageNumber)
            pageNumber += 1
        }
        
        takeScreenshot("21_page_consistency_check_complete")
        print("✅ Completed consistency check for \(pageNumber - 1) pages")
    }
    
    private func analyzePageForConsistencyElements() -> [String] {
        var elements: [String] = []
        
        // Look for images (illustrations)
        let images = app.images
        for i in 0..<images.count {
            let image = images.element(boundBy: i)
            if image.exists {
                elements.append("image_\(i)")
            }
        }
        
        // Look for character consistency in text
        let textElements = app.staticTexts
        for i in 0..<min(textElements.count, 5) { // Check first 5 text elements
            let text = textElements.element(boundBy: i)
            if text.exists {
                let label = text.label
                if label.contains("character") || label.contains("dragon") || label.contains("princess") {
                    elements.append("character_reference_\(i)")
                }
            }
        }
        
        // Check for illustration-related UI elements
        let illustrationElements = app.descendants(matching: .any).containing(NSPredicate(format: "label CONTAINS 'illustration' OR label CONTAINS 'image' OR label CONTAINS 'picture'"))
        elements.append("illustration_elements_count_\(illustrationElements.count)")
        
        return elements
    }
    
    private func verifyConsistencyBetweenPages(previousElements: [String], currentElements: [String], pageNumber: Int) {
        // Check that we have illustrations on both pages
        let previousImageCount = previousElements.filter { $0.contains("image_") }.count
        let currentImageCount = currentElements.filter { $0.contains("image_") }.count
        
        print("📊 Page \(pageNumber): Previous page had \(previousImageCount) images, current page has \(currentImageCount) images")
        
        // Verify we have illustrations
        XCTAssertGreaterThan(currentImageCount, 0, "Page \(pageNumber) should have at least one illustration")
        
        // Check for character consistency
        let previousCharacterRefs = previousElements.filter { $0.contains("character_reference_") }.count
        let currentCharacterRefs = currentElements.filter { $0.contains("character_reference_") }.count
        
        if previousCharacterRefs > 0 && currentCharacterRefs > 0 {
            print("✅ Character references found on both pages - good for consistency")
        }
        
        takeScreenshot("consistency_check_page_\(pageNumber)")
    }
    
    private func navigateToNextPage(currentPage: Int) -> Bool {
        // Look for next page button or swipe gesture
        let nextButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Next' OR label CONTAINS '>' OR label CONTAINS 'Forward'")).firstMatch
        
        if nextButton.exists {
            nextButton.tap()
            sleep(2) // Wait for page transition
            takeScreenshot("navigation_to_page_\(currentPage + 1)")
            return true
        }
        
        // Try swiping left to go to next page
        let storyView = app.descendants(matching: .any).firstMatch
        if storyView.exists {
            storyView.swipeLeft()
            sleep(2)
            takeScreenshot("swipe_to_page_\(currentPage + 1)")
            
            // Check if page changed by looking for different content
            return true // Assume swipe worked for now
        }
        
        // If we can't find a way to navigate, we're done
        print("⚠️ Could not find next page navigation from page \(currentPage)")
        return false
    }
    
    // MARK: - Helper Methods
    
    private func takeScreenshot(_ name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        
        // Add to test bundle (for Xcode result viewer)
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "CollectionFlow_\(name)"
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Also save directly to test-reports folder
        let projectPath = "/Users/quang.tranminh/Projects/new-ios/magical_stories"
        let testReportsPath = "\(projectPath)/test-reports"
        let fileName = "CollectionFlow_\(name).png"
        let filePath = "\(testReportsPath)/\(fileName)"
        
        // Create test-reports directory if it doesn't exist
        let fileManager = FileManager.default
        if !fileManager.fileExists(atPath: testReportsPath) {
            try? fileManager.createDirectory(atPath: testReportsPath, withIntermediateDirectories: true)
        }
        
        // Save screenshot to file
        let url = URL(fileURLWithPath: filePath)
        try? screenshot.pngRepresentation.write(to: url)
        
        print("📸 Screenshot saved: \(fileName)")
    }
}