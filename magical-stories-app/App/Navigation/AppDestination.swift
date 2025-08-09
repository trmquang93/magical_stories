import Foundation // For UUID

// TabItem enum is defined in RootView.swift and assumed to be globally accessible
// or will be explicitly imported if needed.

enum AppDestination: Hashable, Codable {
    case storyDetail(storyID: UUID)
    case collectionDetail(collectionID: UUID)
    case contentFilters
}
