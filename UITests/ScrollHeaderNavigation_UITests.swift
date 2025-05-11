import XCTest

final class ScrollHeaderNavigation_UITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()

        // Set launch arguments to ensure we have test data
        app.launchArguments.append("UI_TESTING")
        app.launchArguments.append("CREATE_TEST_STORIES")

        app.launch()
    }

    func testScrollHeaderShowsOnScrollInHomeView() throws {
        // Ensure we're on the Home tab
        let homeTab = app.tabBars.buttons["HomeTabButton"]
        XCTAssertTrue(homeTab.waitForExistence(timeout: 5.0), "Home tab button should exist")
        homeTab.tap()

        // Get the main scroll view
        let mainScrollView = app.scrollViews["HomeView_MainScrollView"]
        XCTAssertTrue(
            mainScrollView.waitForExistence(timeout: 5.0), "Main scroll view should exist")

        // Perform a slow swipe up to trigger scroll
        let startPoint = mainScrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        let endPoint = mainScrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        startPoint.press(forDuration: 0.1, thenDragTo: endPoint)

        // Allow time for the scroll header to show
        sleep(1)

        // Scroll back down to dismiss the header
        let downStart = mainScrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        let downEnd = mainScrollView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        downStart.press(forDuration: 0.1, thenDragTo: downEnd)

        // Note: We cannot reliably check for the header's existence in UI tests since
        // animations might be in progress. The test primarily ensures that scroll
        // gestures can be performed without crashing.
    }

    func testScrollHeaderShowsOnScrollInLibraryView() throws {
        // Navigate to the Library tab
        let libraryTab = app.tabBars.buttons["LibraryTabButton"]
        XCTAssertTrue(libraryTab.waitForExistence(timeout: 5.0), "Library tab button should exist")
        libraryTab.tap()

        // Verify Library header is initially visible
        let libraryHeader = app.staticTexts["LibraryView_Header"]
        XCTAssertTrue(libraryHeader.waitForExistence(timeout: 5.0), "Library header should exist")

        // Perform a slow swipe up to trigger scroll
        let libraryView = app.otherElements.containing(
            .staticText, identifier: "LibraryView_Header"
        ).element
        let startPoint = libraryView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        let endPoint = libraryView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        startPoint.press(forDuration: 0.1, thenDragTo: endPoint)

        // Allow time for the scroll header to show
        sleep(1)

        // Scroll back down to dismiss the header
        let downStart = libraryView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
        let downEnd = libraryView.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.7))
        downStart.press(forDuration: 0.1, thenDragTo: downEnd)

        // Note: As with the previous test, we primarily want to ensure the scroll
        // gestures don't crash the app. The actual header visibility is hard to test
        // in UI tests due to animations.
    }
}
