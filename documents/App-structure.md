
### 🏗️ **Application Structure & Navigation Guidelines**

## **1️⃣ Navigation Structure**
The app uses SwiftUI's tab-based navigation structure with the following key components:

### **Main Navigation (`MainTabView`)**
- Uses SwiftUI's `TabView` for managing tab navigation
- Contains 3 main tabs:
  1. Home View
  2. Library (Stories)
  3. Settings & Parental Controls

### **Navigation Patterns**
```swift
// Example of proper tab and navigation implementation
struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house")
            }
            .tag(0)

            NavigationStack {
                StoriesView()
            }
            .tabItem {
                Label("Library", systemImage: "books.vertical")
            }
            .tag(1)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
            .tag(2)
        }
    }
}
```

## **2️⃣ View Structure**
Each main view follows this hierarchy:
```
MainTabView
├── HomeView
│   ├── StoryFormView (Sheet)
│   └── GrowthStoryFormView (Sheet)
├── StoriesView
│   └── StoryDetailView (Push)
└── SettingsView
    └── ParentalControlsView
```

## **3️⃣ State Management**
The app uses SwiftUI's native state management patterns:
- `@StateObject StoryService`: Manages story generation, collections, and storage
- `@StateObject SettingsService`: Handles app settings and preferences
- `@State` for local view state (forms, UI state)
- `@EnvironmentObject` for sharing services across views

## **4️⃣ Important Implementation Notes**

### **Navigation**
✅ **DO:**
- Use `NavigationStack` for consistent navigation within tabs
- Present modals using `.sheet` or `.fullScreenCover`
- Handle deep links using `NavigationPath`

❌ **DON'T:**
- Mix old `NavigationView` with `NavigationStack`
- Nest multiple `NavigationStack`s
- Assume navigation state persists across tab switches

### **Modal Forms**
For story generation forms, use `.sheet`:
```swift
struct HomeView: View {
    @State private var showingStoryForm = false
    
    var body: some View {
        Button("Create Story") {
            showingStoryForm = true
        }
        .sheet(isPresented: $showingStoryForm) {
            StoryFormView()
                .padding()
        }
    }
}
```

### **View Transitions**
For detail views, use `NavigationLink`:
```swift
struct StoriesView: View {
    var body: some View {
        List(stories) { story in
            NavigationLink(value: story) {
                StoryRowView(story: story)
            }
        }
        .navigationDestination(for: Story.self) { story in
            StoryDetailView(story: story)
        }
    }
}
```

## **5️⃣ Services Setup**
Initialize services at the app root:
```swift
@main
struct MagicalStoriesApp: App {
    @StateObject private var storyService = StoryService() // Manages stories
    @StateObject private var settingsService = SettingsService() // Manages app settings
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(storyService)
                .environmentObject(settingsService)
        }
    }
}
```

## **6️⃣ Navigation and Deep Linking**
Handle navigation paths programmatically:
```swift
struct StoriesView: View {
    @State private var path = NavigationPath()
    
    var body: some View {
        NavigationStack(path: $path) {
            List {
                // View content
            }
            .navigationDestination(for: Story.self) { story in
                StoryDetailView(story: story)
            }
        }
    }
}
```

## **7️⃣ Feature Components**

### **Single Story Generation**
- Uses `StoryFormView` for collecting story parameters
- Generates individual stories with custom themes
- Leverages `@State` for form data and `@EnvironmentObject StoryService` for generation

### **Growth Story Collections**
- Uses `GrowthStoryFormView` for collecting child development preferences
- Generates themed collections based on:
  - Age group (3-5, 6-8, 9-10)
  - Growth focus areas:
    1. Emotional Intelligence
    2. Cognitive Skills
    3. Confidence & Leadership
  - Child's interests and preferences

## **8️⃣ Error Handling**
Always implement proper error handling using Swift's native error handling:
```swift
enum StoryError: Error {
    case generationFailed
    case invalidParameters
    case persistenceFailed
}

// Example error handling in a view
struct StoryFormView: View {
    @State private var showError = false
    @State private var error: StoryError?
    
    func generateStory() async {
        do {
            try await storyService.generateStory(parameters)
        } catch {
            self.error = error as? StoryError ?? .generationFailed
            self.showError = true
        }
    }
    
    var body: some View {
        Form {
            // Form content
        }
        .alert("Error", isPresented: $showError, presenting: error) { error in
            Button("OK") {}
        } message: { error in
            Text(error.localizedDescription)
        }
    }
}
```

---

🔍 **Note:** This structure leverages SwiftUI's native patterns for state management and navigation while maintaining scalability and maintainability. When adding new features, follow these SwiftUI-specific patterns for consistency.
