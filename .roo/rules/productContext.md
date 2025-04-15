# Product Context: Magical Stories

## Why This Project Exists
Magical Stories aims to foster creativity, imagination, and positive development in children by providing personalized and engaging story content. It addresses the need for unique, age-appropriate stories that can be tailored to a child's interests and developmental needs, moving beyond static storybooks. The app also provides tools for parents to manage content and potentially track learning progress.

A key differentiator and Unique Selling Point (USP) is the **planned and designed (not yet started)** **"Growth Collections"** feature, offering guided, themed story collections focused on development, which is not commonly found in competing apps.

## How It Should Work

### Core User Flow (Single Story Generation)
1.  **Story Generation Input:** Users (likely parents) input parameters (theme, child's name, age, favorite character) into a form (`StoryFormView`).
2.  **AI Generation:** The app uses these parameters to generate a unique story via an AI service (Google Gemini).
3.  **Story Library:** Generated stories are saved locally using **SwiftData** as the primary persistence layer and displayed in a library view (`LibraryView` or `StoriesView`).
4.  **Story Reading:** Users can select a story from the library to read. The story is presented page by page (`PageView` within `StoryDetailView`).
5.  **Settings & Parental Controls:** Users can configure app settings and parental controls via `SettingsView`.

### Key Features

-   **Personalized Single Story Generation:** AI-driven creation based on user inputs via `StoryFormView`.
-   **Story Library:** Persistent storage and browsing of generated stories.
-   **Paginated Reading View:** Stories broken down into readable pages with illustrations.
-   **Parental Controls:** Content filtering by theme/age, screen time limits.
-   **App Settings:** Basic customization options.
-   **Illustration Generation:** AI-generated illustrations for story pages.
-   **StoreKit Monetization (Planned and designed, not yet started):** Integration with StoreKit 2 for premium features, subscriptions, or unlocking specific Growth Collections.

-   **📖 Growth Collections (Planned and designed, not yet started):**
    *   **Purpose:** Provide AI-personalized story collections focused on developing essential life skills, positive behaviors, and emotional intelligence.
    *   **How it Works:**
        1.  **Input:** Parents provide Child's Age Group, Developmental Focus, Interests, etc. (Specific form TBD, e.g., `CollectionFormView`).
        2.  **Generation:** AI creates a structured collection of stories tailored to the inputs (e.g., a "Kindness" collection).
        3.  **Tracking:** App tracks reading completion, offers achievements/badges, and shows progress within the collection.
    *   **Growth Themes:** Emotional Intelligence, Cognitive Development, Confidence, Social Responsibility, etc.
    *   **UI/UX:**
        *   Accessed potentially via `HomeView` or a dedicated Collections tab.
        *   Collections listed in the Library with progress indicators.
        *   Gamified elements like badges and animations.

### Future Enhancements (Beyond Core Features)
-   Enhanced accessibility features (beyond basic VoiceOver).
-   More sophisticated parental controls and reporting.
-   **Persistence:** The app now uses SwiftData as the primary storage solution for stories and user data.
