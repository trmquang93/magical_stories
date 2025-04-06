# Product Context: Magical Stories

## Why This Project Exists
Magical Stories aims to foster creativity and imagination in children by providing personalized and engaging story content. It addresses the need for unique, age-appropriate stories that can be tailored to a child's interests, moving beyond static storybooks. The app also provides tools for parents to manage content and screen time.

## How It Should Work

### Core User Flow
1.  **Story Generation:** Users (likely parents) input parameters (theme, child's name, age, favorite character) into a form. The app uses these parameters to generate a unique story via an AI service (Google Gemini).
2.  **Story Library:** Generated stories are saved locally (using SwiftData) and displayed in a library view.
3.  **Story Reading:** Users can select a story from the library to read. The story is presented page by page.
4.  **Settings & Parental Controls:** Users can configure app settings (like font size, dark mode) and parental controls (content filtering, usage limits).

### Key Features
-   **Personalized Story Generation:** AI-driven creation based on user inputs.
-   **Story Library:** Persistent storage and browsing of generated stories.
-   **Paginated Reading View:** Stories broken down into readable pages.
-   **Parental Controls:** Content filtering by theme/age, screen time limits.
-   **App Settings:** Basic customization options.

### Future Enhancements (Potential)
-   Illustration generation for story pages.
-   Growth Story Collections based on developmental themes.
-   Integration with StoreKit for potential premium features.
-   Enhanced accessibility features.
