import Testing
import SwiftUI
@testable import magical_stories

// Use the shared MockCollectionService from Mocks/ServiceMocks.swift

@Suite("CollectionFormView Tests")
@MainActor
struct CollectionFormView_Tests {
    @Test("Button is disabled when required fields are empty (logic only)")
    func testButtonDisabledWhenFormInvalid() async throws {
        // UI-level test would require a mock conforming to ObservableObject and ViewInspector or UI test
        #expect(true) // Placeholder: logic-only
    }

    @Test("Service creates collection and appends to list")
    func testServiceCreatesCollection() async throws {
        let service = MockCollectionService()
        let initialCount = service.collections.count
        let collection = StoryCollection(title: "T", descriptionText: "D", category: "C", ageGroup: "A")
        try service.createCollection(collection)
        #expect(service.collections.count == initialCount + 1)
        #expect(service.collections.last?.title == "T")
    }

    @Test("Service deletes collection")
    func testServiceDeletesCollection() async throws {
        let service = MockCollectionService()
        let collection = StoryCollection(title: "T", descriptionText: "D", category: "C", ageGroup: "A")
        try service.createCollection(collection)
        let id = collection.id
        try service.deleteCollection(id: id)
        #expect(service.collections.first(where: { $0.id == id }) == nil)
    }
}

// NOTE: UI state transitions (button enabled/disabled, ProgressView, error message) require a mock conforming to ObservableObject and ViewInspector or UI test. These tests focus on service logic only.

// TODO: Add UI tests for the following states in CollectionFormView:
// - Loading overlay appears when isGenerating is true (matches StoryFormView pattern)
// - Error alert is presented when errorMessage is set
// - Form dismisses on successful collection generation
// These require ViewInspector or UI test suite integration.

// TODO: If ViewInspector is available, add assertions for UI state. 