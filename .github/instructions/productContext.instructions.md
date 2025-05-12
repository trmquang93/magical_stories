---
applyTo: '**'
---
# Product Context: Magical Stories

## Why This Project Exists
Magical Stories aims to foster creativity, imagination, and positive development in children by providing personalized and engaging story content. It addresses the need for unique, age-appropriate stories that can be tailored to a child's interests and developmental needs, moving beyond static storybooks. The app also provides tools for parents to manage content and potentially track learning progress.

A key differentiator and Unique Selling Point (USP) is the **"Growth Collections"** feature, which is currently being implemented. This feature offers guided, themed story collections focused on development, which is not commonly found in competing apps.

## How It Should Work

### Core User Flow (Single Story Generation)
1.  **Story Generation Input:** Users (likely parents) input parameters (theme, child's name, age, favorite character) into a form (`StoryFormView`).
2.  **AI Generation:** The app uses these parameters to generate a unique story via an AI service (Google Gemini).
3.  **Story Library:** Generated stories are saved locally using **SwiftData** as the primary persistence layer and displayed in a library view (`LibraryView`).
4.  **Story Reading:** Users can select a story from the library to read. The story is presented page by page (`PageView` within `StoryDetailView`).
5.  **Settings & Parental Controls:** Users can configure app settings and parental controls via `SettingsView`.

### Key Features

-   **Personalized Single Story Generation:** AI-driven creation based on user inputs via `StoryFormView`. The `StoryService` now incorporates optional parameters (`developmentalFocus`, `interactiveElements`, `emotionalThemes`) to generate stories that are not only personalized but also developmentally beneficial, fostering specific skills and emotional understanding through tailored prompts.
-   **Story Library:** Persistent storage and browsing of generated stories.
-   **Paginated Reading View:** Stories broken down into readable pages with illustrations.
-   **Parental Controls:** Content filtering by theme/age, screen time limits.
-   **App Settings:** Basic customization options.
-   **Illustration Generation:** AI-generated illustrations for story pages.
-   **StoreKit Monetization (Planned and designed, implementation pending):** Integration with StoreKit 2 for premium features, subscriptions, or unlocking specific Growth Collections.

-   **📖 Growth Collections (Implementation in progress):**
    *   **Purpose:** Provide AI-personalized story collections focused on developing essential life skills, positive behaviors, and emotional intelligence.
    *   **Current Status:** Core models (`StoryCollection`, `GrowthCategory`) and base service layer (`CollectionService`, `CollectionRepository`) implemented. Basic UI views (`CollectionsListView`, `CollectionCardView`, `CollectionDetailView`, `CollectionFormView`) exist. Integration and refinement ongoing.
    *   **How it Works:**
        1.  **Creation:** Parents initiate creation from `HomeView`, opening the `CollectionFormView` (sheet). They input Child's Age Group, Developmental Focus, Interests, etc.
        2.  **Generation:** Submitting the form triggers the `CollectionService` to create the collection structure and then generate a set of themed stories tailored to the inputs.
        3.  **Browsing:** Users access collections via a dedicated "Collections" tab, showing `CollectionsListView`. Each collection is displayed using `CollectionCardView`.
        4.  **Viewing:** Tapping a collection navigates to `CollectionDetailView`, listing the stories within that collection.
        5.  **Reading & Tracking:** Users read stories by navigating from `CollectionDetailView` to `StoryDetailView`. Completing a story updates its `readCount`. The `CollectionService` recalculates the collection's overall `completionProgress`, which is reflected in the UI (`CollectionCardView`, `CollectionDetailView`). Achievements/badges are planned based on progress.
    *   **Growth Themes:** Emotional Intelligence, Problem Solving, Creativity, Social Skills, Curiosity, Resilience, etc. (Defined in `DevelopmentalFocus` enum).
    *   **UI/UX:**
        *   Accessed via a dedicated "Collections" tab containing `CollectionsListView`.
        *   `CollectionsListView` displays `CollectionCardView`s with titles and progress indicators.
        *   `CollectionDetailView` shows collection details, story list, and overall progress.
        *   Creation flow initiated from `HomeView` using `CollectionFormView`.
        *   Gamified elements like badges and animations are planned.

### Future Enhancements (Beyond Core Features)
-   Enhanced accessibility features (beyond basic VoiceOver).
-   More sophisticated parental controls and reporting.
-   **Persistence:** The app now uses SwiftData as the primary storage solution for stories and user data.
