import SwiftUI
import Testing

@testable import magical_stories

struct HomeView_Tests {

    @Test("HomeView displays welcome message")
    func testWelcomeMessage() async throws {
        let view = await HomeView()

        // Basic structural test to start
        await #expect(Mirror(reflecting: view.body).descendant("title") != nil)
    }
}
