# App Structure (Updated 2025-04-16)

## Main Navigation (TabView)

- **Home**: HomeView (NavigationStack)
- **Library**: LibraryView (NavigationStack)
- **Collections**: CollectionsListView (NavigationStack) ← **NEW**
- **Settings**: SettingsView (NavigationStack)

All tabs are managed by MainTabView, which receives a Binding<TabItem> for selection. Each tab is wrapped in a NavigationStack. CollectionsListView is now a first-class tab, enabling direct access to Growth Collections. All environment objects (StoryService, SettingsService, CollectionService) are injected at the app root and available throughout the hierarchy.

## View Hierarchy (Simplified)

MagicalStoriesApp
└── RootView
    └── MainTabView
        ├── HomeView
        ├── LibraryView
        ├── CollectionsListView ← **NEW TAB**
        └── SettingsView

## Notes
- CollectionsListView is no longer only accessible from HomeView; it is now a dedicated tab.
- This change enables direct UI testing and incremental development of Growth Collections features. 