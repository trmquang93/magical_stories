import SwiftUI
import Foundation

// This function will map AppDestination cases to their corresponding views.
// Destination views (StoryDetailView, CollectionDetailView, ContentFiltersView)
// will need to be imported or accessible in this scope.
// They will also need to be adapted to potentially fetch their own data if initialized with IDs,
// or be prepared to receive necessary state/bindings.

@ViewBuilder
func view(for destination: AppDestination) -> some View {
    switch destination {
    case .storyDetail(let storyID):
        // Assuming StoryDetailView can be initialized with a storyID
        // and will fetch the Story object using StoryService from the environment.
        StoryDetailView(storyID: storyID)
    case .collectionDetail(let collectionID):
        // Assuming CollectionDetailView can be initialized with a collectionID
        // and will fetch the StoryCollection object using CollectionService from the environment.
        CollectionDetailView(collectionID: collectionID)
    case .contentFilters:
        // Create a view that initializes state and passes it to ContentFiltersView
        ContentFiltersViewWrapper()
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
