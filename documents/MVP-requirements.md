---
description: MVP Goals and Scope
---

**Primary Objectives:**  
- Validate that parents and children enjoy personalized, AI‑generated bedtime stories.
- Establish a core revenue model (freemium/subscription or select in‑app purchases) using StoreKit 2.
- Keep development lean and focused on the core storytelling functionality.

**Core MVP Features:**
- **User Input:**  
  - SwiftUI forms with `TextField` and `Picker` components for parents to enter:
    - Child's name
    - Age (using a segmented picker)
    - Favorite animal/character (with emoji support)
    - Story theme/moral (using a custom picker with illustrations)
- **Story Generation:**  
  - Construct prompt from user inputs using a dedicated `PromptBuilder` service
  - Call Google AI API (Gemini Pro) using async/await pattern
  - Handle API errors gracefully with user-friendly alerts
- **Story Display:**  
  - Clean, child‑friendly SwiftUI interface using SF Pro Rounded font
  - Support for Dynamic Type and accessibility
  - Custom animations for page turns and transitions
- **Basic Personalization:**  
  - Support system-wide Dark Mode using `.preferredColorScheme`
  - Dynamic Type support for adjustable font sizes
  - Native iOS text-to-speech using AVSpeechSynthesizer
  - Store preferences using @AppStorage
- **Story Library (Optional for MVP):**  
  - Save stories using SwiftData for persistence
  - Alternatively, use UserDefaults for simple storage in MVP
  - List view with preview cards and search functionality
- **Parental Controls:**  
  - Basic content filtering through prompt engineering
  - Simple toggles in Settings using SwiftUI `Form` views
  - Optional Screen Time integration

**Technical Implementation Notes:**
- Use SwiftUI and target iOS 16.0+
- Implement async/await for all network operations
- Handle all errors with appropriate user feedback
- Support iPhone and iPad (basic Universal app)
- Use SF Symbols for consistent iconography
- Follow Apple Human Interface Guidelines
- Implement basic VoiceOver support

*This focused feature set ensures you're building the "must-have" without extra bells and whistles while leveraging native iOS capabilities.*
