//
//  magical_storiesUITests.swift
//  magical-storiesUITests
//
//  Created by Quang Tran Minh on 30/3/25.
//

import XCTest

final class magical_storiesUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.

        // Clear potentially conflicting UserDefaults data before launching the app
        UserDefaults.standard.removeObject(forKey: "savedStories")
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
}
