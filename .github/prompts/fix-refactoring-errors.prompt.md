---
mode: 'agent'
---
I have refactored the navigation logic according to our plan by:
1. Creating `AppDestination.swift` to define type-safe navigation destinations.
2. Creating `AppRouter.swift` to centralize navigation logic and manage `NavigationPath`s for each tab.
3. Creating `ViewFactory.swift` to map `AppDestination` cases to their corresponding views.
4. Modifying `MagicalStoriesApp.swift` to initialize and inject the `AppRouter`.
5. Modifying `MainTabView.swift` to use the `AppRouter` for its `NavigationStack` paths and to use the `ViewFactory` for centralized navigation destination handling.
6. Modifying feature views (`HomeView`, `LibraryView`, `CollectionsListView`, `SettingsView`, `ParentalControlsCard`, `CollectionDetailView`) to remove their local `NavigationStack`s and use the `AppRouter` and `AppDestination` for navigation.
7. Adapting `StoryDetailView.swift` to be initialized with a `storyID` and fetch its own data. A similar adaptation is outlined for `CollectionDetailView.swift`.

This refactor provides a centralized and more maintainable navigation system for your application.
--- 

Please fix the issues: 
${input:errors}