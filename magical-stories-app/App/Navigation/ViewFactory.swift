import SwiftUI
import Foundation

// This function will map AppDestination cases to their corresponding views.
// Destination views (StoryDetailView, CollectionDetailView, ContentFiltersView)
// will need to be imported or accessible in this scope.
// They will also need to be adapted to potentially fetch their own data if initialized with IDs,
// or be prepared to receive necessary state/bindings.

@MainActor
@ViewBuilder
func view(for destination: AppDestination) -> some View {
    // Fix iPad memory corruption by using AnyView to prevent SwiftUI conditional content issues
    switch destination {
    case .storyDetail(let storyID):
        // Wrap in AnyView to prevent conditional content memory corruption on iPad
        AnyView(
            StoryDetailView(storyID: storyID)
                .id("story-\(storyID.uuidString)") // Explicit ID for memory stability
        )
    case .collectionDetail(let collectionID):
        // Wrap in AnyView to prevent conditional content memory corruption on iPad
        AnyView(
            CollectionDetailView(collectionID: collectionID)
                .id("collection-\(collectionID.uuidString)") // Explicit ID for memory stability
        )
    case .contentFilters:
        // Wrap in AnyView for consistency and memory stability
        AnyView(
            ContentFiltersViewWrapper()
                .id("content-filters") // Stable ID for view
        )
    }
}

// A wrapper view that provides the necessary binding for ContentFiltersView
struct ContentFiltersViewWrapper: View {
    @EnvironmentObject private var settingsService: SettingsService
    
    var body: some View {
        ContentFiltersViewContainer()
            .environmentObject(settingsService)
    }
}

// Container view that handles bindings for ContentFiltersView
struct ContentFiltersViewContainer: View {
    @EnvironmentObject private var settingsService: SettingsService
    
    // Using @State to create bindings that can be passed to ContentFiltersView
    @State private var selectedThemes = Set<StoryTheme>()
    @State private var minimumAge = 3
    @State private var maximumAge = 12
    
    var body: some View {
        // Initialize a ContentFiltersView with the necessary bindings
        ContentFiltersView(
            selectedThemes: $selectedThemes,
            minimumAge: $minimumAge,
            maximumAge: $maximumAge
        )
        .onAppear {
            // Initialize our state with values from the settingsService
            selectedThemes = settingsService.parentalControls.allowedThemes
            minimumAge = settingsService.parentalControls.minimumAge
            maximumAge = settingsService.parentalControls.maximumAge
        }
        .onChange(of: selectedThemes) { oldValue, newValue in
            var controls = settingsService.parentalControls
            controls.allowedThemes = newValue
            settingsService.updateParentalControls(controls)
        }
        .onChange(of: minimumAge) { oldValue, newValue in
            var controls = settingsService.parentalControls
            controls.minimumAge = newValue
            settingsService.updateParentalControls(controls)
        }
        .onChange(of: maximumAge) { oldValue, newValue in
            var controls = settingsService.parentalControls
            controls.maximumAge = newValue
            settingsService.updateParentalControls(controls)
        }
    }
}
