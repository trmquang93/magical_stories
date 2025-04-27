import Foundation

/// A service responsible for constructing AI prompts that generate age-appropriate, engaging stories
class PromptBuilder {

  // MARK: - Constants

  // Define the allowed categories
  private let allowedCategories = ["Fantasy", "Animals", "Bedtime", "Adventure", "Friendship"]

  private enum VocabularyLevel {
    case beginner  // Ages 3-4
    case intermediate  // Ages 5-7
    case advanced  // Ages 8+

    static func forAge(_ age: Int) -> VocabularyLevel {
      switch age {
      case ..<5: return .beginner
      case 5...7: return .intermediate
      default: return .advanced
      }
    }

    var vocabularyGuideline: String {
      switch self {
      case .beginner:
        return
          "Use simple, concrete words and short sentences. Repeat key words. Avoid complex tenses."
      case .intermediate:
        return
          "Use a mix of familiar and new vocabulary. Include some compound sentences. Introduce metaphors sparingly."
      case .advanced:
        return
          "Use rich vocabulary including some challenging words (with context clues). Vary sentence structure. Include figurative language."
      }
    }

    var narrativeGuideline: String {
      switch self {
      case .beginner:
        return
          "Create a linear story with clear cause-and-effect. Use repetitive patterns. Include simple emotional reactions."
      case .intermediate:
        return
          "Include minor subplots. Show character motivations. Include problem-solving sequences. Balance action and reflection."
      case .advanced:
        return
          "Develop multiple story layers. Include character growth. Explore complex emotions. Use foreshadowing."
      }
    }
  }

  // MARK: - Public Methods

  /// Builds a complete prompt for story generation based on the provided parameters
  func buildPrompt(parameters: StoryParameters) -> String {
    let vocabularyLevel = VocabularyLevel.forAge(parameters.childAge)

    // Create a unique randomization seed based on current timestamp
    let uniqueSeed = "\(Date().timeIntervalSince1970)"

    var promptComponents = [
      basePrompt(parameters: parameters),
      "\nVocabulary Guidelines:",
      vocabularyLevel.vocabularyGuideline,
      "\nNarrative Guidelines:",
      vocabularyLevel.narrativeGuideline,
      storyStructureGuidelines(),
      formatGuidelines(),
      variabilityGuidelines(seed: uniqueSeed),
    ]

    // Add developmental focus if specified
    if let focus = parameters.developmentalFocus, !focus.isEmpty {
      promptComponents.append(developmentalGuidelines(categories: focus))
    }

    // Add emotional themes if specified
    if let emotions = parameters.emotionalThemes, !emotions.isEmpty {
      promptComponents.append(emotionalGuidelines(themes: emotions))
    }

    // Add category selection instructions
    promptComponents.append(categorySelectionGuidelines())

    return promptComponents.joined(separator: "\n\n")
  }

  /// Builds a fallback prompt for generating illustration descriptions for a single page, with context.
  static func buildFallbackIllustrationPrompt(
    page: Page, pageIndex: Int, pages: [Page], theme: String
  ) -> String {
    let pageNumber = pageIndex + 1
    let totalPages = pages.count
    let previousPages = pages.prefix(pageIndex)
    let nextPages = pages.suffix(from: min(pageIndex + 1, pages.count))
    let previousSummary =
      previousPages.isEmpty
      ? "This is the beginning of the story."
      : "Previous pages include: "
        + previousPages.map { String($0.content.prefix(40)) + "..." }.joined(
          separator: "; ")
    let nextSummary =
      nextPages.isEmpty
      ? "This is the end of the story."
      : "Upcoming pages include: "
        + nextPages.map { String($0.content.prefix(40)) + "..." }.joined(separator: "; ")
    return """
      Create a detailed illustration for page \(pageNumber) of \(totalPages) showing this scene:
      \(page.content)

      Story context:
      \(previousSummary)
      \(nextSummary)

      Theme: \(theme)
      Important: Maintain visual consistency with previous and upcoming illustrations. Characters should look the same throughout the story.
      """
  }

  /// Builds an enhanced prompt for the AI to generate illustration descriptions with improved visual consistency.
  static func buildIllustrationDescriptionsPrompt(theme: String, pages: [Page]) -> String {
    let fullStoryText = pages.map { $0.content }.joined(separator: "\n---\n")

    // Extract potential character names from the story for consistency
    let potentialCharacters = extractPotentialCharacters(from: pages)
    let characterSection =
      potentialCharacters.isEmpty
      ? ""
      : """

      KEY CHARACTERS (maintain consistent appearance for these across ALL illustrations):
      \(potentialCharacters.enumerated().map { index, name in "- \(name)" }.joined(separator: "\n"))
      """

    return """
      Create detailed, visually consistent illustration descriptions for a children's story.

      THEME: \(theme)
      TOTAL PAGES: \(pages.count)\(characterSection)

      FULL STORY CONTENT (each page is separated by '---'):
      \(fullStoryText)

      IMPORTANT VISUAL CONSISTENCY REQUIREMENTS:
      1. Create a STYLE GUIDE first in your mind - decide on character appearances, color palette, and art style
      2. For EACH character, maintain EXACTLY the same:
         - Physical appearance (height, build, features)
         - Clothing/accessories
         - Color scheme
         - Relative size compared to other characters
      3. For settings/locations, maintain:
         - Consistent geography and spatial relationships
         - Matching color schemes and architectural elements
         - Consistent scale and perspective
      4. Ensure smooth visual transitions between pages
      5. Think of these illustrations as frames from the same animated film

      For each page, include these specific details in your descriptions:
      - Character positions, expressions, and actions
      - Environmental elements with consistent details
      - Colors, lighting, and mood
      - Spatial relationships (foreground, background, relative positioning)
      - Any recurring objects or elements

      Return EXACTLY \(pages.count) descriptions in the same order as the pages, each separated by a line with only '---'.
      Ensure the described scene is suitable for a 9:16 portrait aspect ratio illustration.
      Do NOT use JSON format. Each description must be highly detailed for consistent visualization.
      """
      }

  /// Extract potential character names from story pages.
  private static func extractPotentialCharacters(from pages: [Page]) -> [String] {
    let fullText = pages.map { $0.content }.joined(separator: " ")

    // Common naming pattern: capital letter followed by lowercase letters
    let possibleNames = fullText.split { !$0.isLetter }
      .filter { word in
        guard let first = word.first else { return false }
        return first.isUppercase && word.count > 1
          && word.dropFirst().allSatisfy { $0.isLowercase }
      }
      .map { String($0) }

    // Filter out common words that might be capitalized
    let commonWords = ["The", "And", "But", "For", "With", "When", "Then", "They", "She", "He"]
    let filteredNames = possibleNames.filter { !commonWords.contains($0) }

    // Return unique names, preserving order of first appearance
    var uniqueNames: [String] = []
    for name in filteredNames {
      if !uniqueNames.contains(name) {
        uniqueNames.append(name)
      }
    }

    // Limit to most likely character names (up to 5)
    return Array(uniqueNames.prefix(5))
  }

  // MARK: - Private Methods

  private func basePrompt(parameters: StoryParameters) -> String {
    // Determine language and code, defaulting to English if not provided or empty
    let languageCode = parameters.languageCode?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let targetLanguageCode = languageCode.isEmpty ? "en-US" : languageCode
    let targetLanguageName = Locale.current.localizedString(forIdentifier: targetLanguageCode) ?? "English" // Attempt to get localized name

    return """
      Create an engaging children's story with the following requirements:
      - Main character name: \(parameters.childName)
      - Age group: \(parameters.childAge) years old
      - Theme: \(parameters.theme)
      - Include this character: \(parameters.favoriteCharacter)
      - Story length: \(parameters.storyLength ?? "medium (3-4 pages)")
      - Generate the story in \(targetLanguageName) (\(targetLanguageCode)).

      The story should be educational, entertaining, and appropriate for the child's age.
      """
  }

  private func storyStructureGuidelines() -> String {
    return """
      Story Structure Requirements:
      - Start with "Title: [Your Story Title]" on the first line
      - Follow with the story content
      - Divide the story into clear, logical segments that represent pages
      - IMPORTANT: Insert "---" (three hyphens) on a separate line between segments to indicate page breaks
      - Each page should be 2-3 paragraphs in length and flow naturally
      - Include page breaks at natural points where illustrations could enhance the story
      - Aim for 3-6 pages total, depending on the requested story length
      - End with a clear resolution that reinforces the story's theme
      """
  }

  private func formatGuidelines() -> String {
    return """
      Format Requirements:
      - Use clear paragraph breaks
      - Keep paragraphs concise (2-4 sentences)
      - Include dialogue when appropriate
      - Use descriptive language that creates vivid mental images
      - Maintain consistent tense throughout
      - VERY IMPORTANT: Use "---" (three hyphens) on a separate line to indicate where a new page should begin
      - Make sure each page (separated by "---") has a coherent chunk of the story
      """
  }

  private func categorySelectionGuidelines() -> String {
      let categoriesList = allowedCategories.joined(separator: ", ")

      return """
      Category Selection Instructions:
      After writing the story, analyze its content and select the single most appropriate category from this list:
      [\(categoriesList)]

      Return your response as XML with the following tags:
      <title>Your Story Title</title>
      <content>Full story text with page breaks as before</content>
      <category>Selected category name from the list above</category>

      The <content> tag should contain the complete story text with title and page breaks as instructed earlier.
      The <category> tag should be exactly one of the category names listed above, based on your analysis of the story content.
      """
  }

  private func developmentalGuidelines(categories: [GrowthCategory]) -> String {
    let categoryDescriptions = categories.map {
      "- \($0.rawValue): Include elements that promote this skill"
    }
    return """
      Developmental Focus:
      Incorporate opportunities for learning and growth in these areas:
      \(categoryDescriptions.joined(separator: "\n"))
      """
  }

  private func emotionalGuidelines(themes: [String]) -> String {
    return """
      Emotional Elements:
      Include appropriate exploration of these emotions/themes:
      \(themes.map { "- \($0)" }.joined(separator: "\n"))
      """
  }

  private func variabilityGuidelines(seed: String) -> String {
    return """
      Variability Requirements:
      - Make this story unique, creative, and different from other stories you've generated
      - Avoid formulaic storytelling - surprise the reader with unexpected twists
      - Create fresh characters and scenarios that stand out
      - Use this unique seed to ensure variability: \(seed)
      """
  }
}
