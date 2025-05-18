import Foundation

/// A service responsible for constructing AI prompts that generate age-appropriate, engaging stories
class PromptBuilder {

  // MARK: - Constants

  // Define the allowed categories
  private let allowedCategories: [String] = LibraryCategory.all.map { $0.name }

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
  func buildPrompt(parameters: StoryParameters, vocabularyBoostEnabled: Bool = false) -> String {
    let vocabularyLevel = VocabularyLevel.forAge(parameters.childAge)

    // Create a unique randomization seed based on current timestamp
    let uniqueSeed = "\(Date().timeIntervalSince1970)"

    var promptComponents = [
      basePrompt(parameters: parameters),
      "\nVocabulary Guidelines:",
      vocabularyBoostEnabled
        ? enhancedVocabularyGuidelines(forLevel: vocabularyLevel, childAge: parameters.childAge)
        : vocabularyLevel.vocabularyGuideline,
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

    // Add interactive elements if requested
    if let interactive = parameters.interactiveElements, interactive {
      promptComponents.append(interactiveElementsGuidelines())
    }

    // Add category selection instructions
    promptComponents.append(categorySelectionGuidelines())

    let prompt = promptComponents.joined(separator: "\n\n")
    return prompt
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
      
      IMPORTANT REQUIREMENTS:
      1. Maintain visual consistency with previous and upcoming illustrations
      2. Characters should look the same throughout the story
      3. DO NOT include any text, words, captions, speech bubbles, or written elements in the illustration
      4. The app will display the story text separately - the illustration must be completely text-free
      5. Create a 16:9 landscape aspect ratio illustration suitable for a children's story app
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
      6. DO NOT include any text, words, letters, captions, speech bubbles, or written elements in the illustrations
         - The app will display the story text separately below each illustration
         - Illustrations must be completely text-free

      For each page, include these specific details in your descriptions:
      - Character positions, expressions, and actions
      - Environmental elements with consistent details
      - Colors, lighting, and mood
      - Spatial relationships (foreground, background, relative positioning)
      - Any recurring objects or elements

      Return EXACTLY \(pages.count) descriptions in the same order as the pages, each separated by a line with only '---'.
      Ensure the described scene is suitable for a 16:9 landscape aspect ratio illustration.
      Do NOT use JSON format. Each description must be highly detailed for consistent visualization.
      CRITICAL: All illustrations must be TEXT-FREE - no words, captions, speech bubbles, or any written elements.
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
    let languageCode =
      parameters.languageCode?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    let targetLanguageCode = languageCode.isEmpty ? "en-US" : languageCode
    let targetLanguageName =
      Locale.current.localizedString(forIdentifier: targetLanguageCode) ?? "English"  // Attempt to get localized name

    var promptLines = [
      "Create an engaging children's story with the following requirements:",
      "- Age group: \(parameters.childAge) years old",
      "- Theme: \(parameters.theme)",
      "- Story length: \(parameters.storyLength ?? "medium (3-4 pages)")",
      "- Generate the story in \(targetLanguageName) (\(targetLanguageCode))."
    ]
    
    // Only include character name if provided
    if let childName = parameters.childName {
      promptLines.insert("- Main character name: \(childName)", at: 1)
    }
    
    // Only include favorite character if provided
    if let favoriteCharacter = parameters.favoriteCharacter {
      promptLines.insert("- Include this character: \(favoriteCharacter)", at: promptLines.count - 1)
    }
    
    promptLines.append("\nThe story should be educational, entertaining, and appropriate for the child's age.")
    
    return promptLines.joined(separator: "\n")
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
      Category Selection and Illustration Instructions:
      After writing the story, follow these steps:

      1. Analyze the story content and select the single most appropriate category from this list:
      [\(categoriesList)]

      2. Create a <visual_guide> section with comprehensive visual specifications:
         
         a. Create a <style_guide> that defines the overall artistic style (e.g., watercolor, cartoon, digital painting).
            * IMPORTANT: This must be a TEXT-FREE illustration style - no words, captions, or written elements
            * Create illustrations that communicate visually without any text elements
         
         b. For each key character, create a <character> entry with details:
            * Physical appearance (height, body type, age, facial features, hair)
            * Clothing with specific colors and styles
            * Distinctive accessories or items
         
         c. For each important setting, create a <setting> entry with:
            * Environment type and atmosphere
            * Key landmarks or features that should remain consistent
            * Color palette and lighting characteristics

      3. For each page of your story (marked by "---" separators), create a detailed illustration description:

         CRITICAL REQUIREMENTS FOR EACH ILLUSTRATION DESCRIPTION:
         - Each description must be COMPLETELY SELF-CONTAINED with all necessary visual information
         - Always reference the same character appearances defined in your visual guide
         - Include complete setting details, specific colors, lighting, and mood
         - Describe character positioning, expressions, and actions clearly
         - Use precise, detailed language focusing on visual elements (400-800 characters)
         - Design for a 16:9 landscape aspect ratio illustration
         - DO NOT include any text, words, letters, captions, speech bubbles, or written elements in the illustrations
         - The app will display the story text separately below each illustration

      Return your response as XML with the following structure:
      <title>Your Story Title</title>
      <visual_guide>
          <style_guide>Example: Colorful watercolor style with soft edges and warm lighting</style_guide>
          <character_definitions>
              <character name="Character1">Complete physical description including appearance, clothing, and accessories</character>
              <character name="Character2">Complete physical description including appearance, clothing, and accessories</character>
          </character_definitions>
          <setting_definitions>
              <setting name="Setting1">Complete setting description with atmosphere, landmarks, and color palette</setting>
              <setting name="Setting2">Complete setting description with atmosphere, landmarks, and color palette</setting>
          </setting_definitions>
      </visual_guide>
      <content>Full story text with title and "---" page breaks as instructed</content>
      <category>One category name from the provided list</category>
      <illustrations>
        <illustration page="1">Self-contained description for page 1 scene with character positioning and actions (NO TEXT or written elements)</illustration>
        <illustration page="2">Self-contained description for page 2 scene with character positioning and actions (NO TEXT or written elements)</illustration>
        <!-- Include one <illustration> tag for each page in your story, with NO text elements in any illustration -->
      </illustrations>

      IMPORTANT:
      - The <visual_guide> section ensures consistent visuals across all illustrations
      - Each <illustration> description should reference the elements defined in your visual guide
      - Descriptions should be detailed enough to create a consistent illustration without context from other pages
      - Maintain the same character appearances throughout all illustrations
      - DO NOT include any text, lettering, words, captions, speech bubbles, or written elements in ANY illustration
      - The app will display story text separately - illustrations should be text-free
      - Focus on creating vivid scene depictions without any embedded text elements
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

  // MARK: - Enhanced Vocabulary Methods

  /// Provides enhanced vocabulary guidelines when vocabulary boost is enabled
  private func enhancedVocabularyGuidelines(forLevel level: VocabularyLevel, childAge: Int)
    -> String
  {
    let baseGuideline = level.vocabularyGuideline
    var enhancedWords = ""
    var countGuidance = ""

    switch level {
    case .beginner:
      enhancedWords =
        "Include 2-3 new vocabulary words that are slightly above a \(childAge)-year-old's typical vocabulary, but explain them through context and repetition."
      countGuidance = "simple sentence structures"
    case .intermediate:
      enhancedWords =
        "Include 3-5 new vocabulary words that are moderately above a \(childAge)-year-old's typical vocabulary, with contextual explanations or visual descriptions that make their meaning clear."
      countGuidance = "varied sentence structures"
    case .advanced:
      enhancedWords =
        "Include 4-6 new vocabulary words that are appropriately challenging for a \(childAge)-year-old, enhancing their language development while ensuring comprehension through context, definition, or explanation."
      countGuidance = "complex sentence patterns"
    }

    return """
      \(baseGuideline)

      Include more advanced vocabulary words with these guidelines:
      - Use vocabulary appropriate for a \(childAge)-year-old as the foundation
      - \(enhancedWords)
      - Use \(countGuidance)
      - Each new vocabulary word should appear 2-3 times throughout the story for reinforcement
      - Prefer vivid, descriptive words that enhance imagery and emotional understanding
      """
  }

  /// Provides guidelines for interactive elements in stories
  private func interactiveElementsGuidelines() -> String {
    return """
      Interactive Elements:
      - Include 2-3 moments where the reader is prompted to participate
      - Examples: "Can you spot the [object]?", "What do you think happens next?", "Try making the sound a [animal] makes!"
      - Place interactive prompts at natural points in the narrative
      - Design prompts to reinforce the story's theme or moral
      - Ensure prompts are appropriate for the target age group
      """
  }
  
  /// Builds a prompt for generating a global reference image containing all key characters and elements
  /// - Parameters:
  ///   - visualGuide: The visual guide containing style, character and setting definitions
  ///   - storyTitle: The title of the story
  /// - Returns: A complete prompt for generating a global reference image
  func buildGlobalReferenceImagePrompt(visualGuide: VisualGuide, storyTitle: String) -> String {
    print("[PromptBuilder] Creating global reference image prompt for story '\(storyTitle)'")
    print("[PromptBuilder] Visual guide contains: \(visualGuide.characterDefinitions.count) characters, \(visualGuide.settingDefinitions.count) settings)")
    var promptComponents = [
      "Create a detailed reference sheet illustration for the children's story titled \"\(storyTitle)\".",
      "This reference image should show ALL main characters and key story elements in a single comprehensive illustration.",
      
      "Style Guide:",
      visualGuide.styleGuide
    ]
    
    // Add character definitions if available
    if !visualGuide.characterDefinitions.isEmpty {
      promptComponents.append("Characters to Include:")
      for (name, description) in visualGuide.characterDefinitions {
        promptComponents.append("- \(name): \(description)")
      }
    }
    
    // Add setting definitions if available
    if !visualGuide.settingDefinitions.isEmpty {
      promptComponents.append("Key Settings/Elements:")
      for (name, description) in visualGuide.settingDefinitions {
        promptComponents.append("- \(name): \(description)")
      }
    }
    
    // Add critical requirements
    promptComponents.append("""
      CRITICAL REQUIREMENTS:
      - Position all characters in a clear lineup or group arrangement
      - Show each character's full body with all details visible
      - Include key props, settings, or elements mentioned in the story
      - Maintain consistent style, proportions, and color palette
      - Label-free presentation (NO text or labels on the image)
      - Create a comprehensive visual reference that covers all story elements
      - Use a 16:9 landscape aspect ratio
      
      This image will serve as the master reference for all illustrations in the story.
      """)
    
    let finalPrompt = promptComponents.joined(separator: "\n\n")
    print("[PromptBuilder] Generated global reference image prompt (length: \(finalPrompt.count) characters)")
    return finalPrompt
  }
  
  /// Builds a prompt for a sequential page illustration that uses global reference and previous illustrations
  /// - Parameters:
  ///   - page: The page containing content to illustrate
  ///   - pageIndex: The position of the page in the story
  ///   - visualGuide: The visual guide containing style, character and setting information
  ///   - globalReferenceImageBase64: Optional base64-encoded global reference image
  ///   - previousIllustrationBase64: Optional base64-encoded previous page illustration
  /// - Returns: A complete prompt for generating a sequential illustration with references
  func buildSequentialIllustrationPrompt(
    page: Page,
    pageIndex: Int,
    visualGuide: VisualGuide,
    globalReferenceImageBase64: String? = nil,
    previousIllustrationBase64: String? = nil
  ) -> String {
    print("[PromptBuilder] Creating sequential illustration prompt for page \(pageIndex + 1)")
    print("[PromptBuilder] Has global reference: \(globalReferenceImageBase64 != nil)")
    print("[PromptBuilder] Has previous illustration: \(previousIllustrationBase64 != nil)")
    // Start with the base prompt for this page
    var promptComponents = [
      "Create a detailed illustration for page \(pageIndex + 1) showing this scene:",
      page.content
    ]
    
    // Add visual guide information
    promptComponents.append("VISUAL GUIDE SPECIFICATIONS:")
    promptComponents.append("Style Guide: \(visualGuide.styleGuide)")
    
    // Add character definitions
    if !visualGuide.characterDefinitions.isEmpty {
      promptComponents.append("Characters:")
      for (name, description) in visualGuide.characterDefinitions {
        promptComponents.append("- \(name): \(description)")
      }
    }
    
    // Add setting definitions
    if !visualGuide.settingDefinitions.isEmpty {
      promptComponents.append("Settings:")
      for (name, description) in visualGuide.settingDefinitions {
        promptComponents.append("- \(name): \(description)")
      }
    }
    
    // Add global reference image if available
    if let globalImage = globalReferenceImageBase64 {
      promptComponents.append("""
        GLOBAL REFERENCE IMAGE:
        The following image shows all characters and key elements from the story. Use it as your primary reference for:
        - Character appearances, proportions, and features
        - Artistic style and color palette
        - Overall consistency with the story world
        
        [Global reference: data:image/png;base64,\(globalImage)]
        """)
    }
    
    // Add previous illustration if available (usually for non-first pages)
    if let previousImage = previousIllustrationBase64 {
      promptComponents.append("""
        PREVIOUS PAGE ILLUSTRATION:
        The following is the illustration from the previous page. Maintain consistency with:
        - Character appearances and poses
        - Scene transitions and environments
        - Color palette and lighting
        - Overall style and visual elements
        
        [Previous illustration: data:image/png;base64,\(previousImage)]
        """)
    }
    
    // Add critical requirements
    promptComponents.append("""
      CRITICAL REQUIREMENTS:
      - Create a detailed, vibrant illustration matching this page's content
      - Maintain EXACT character appearances across all story illustrations
      - Use consistent artistic style, color palette, and proportions
      - Create a 16:9 landscape aspect ratio illustration
      - DO NOT include any text, words, captions, speech bubbles, or written elements
      - The app will display the story text separately - keep the illustration text-free
      - Character expressions and poses must match the emotional tone of the scene
      """)
    
    let finalPrompt = promptComponents.joined(separator: "\n\n")
    print("[PromptBuilder] Generated sequential illustration prompt (length: \(finalPrompt.count) characters)")
    return finalPrompt
  }
}
