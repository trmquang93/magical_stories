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
  func buildPrompt(
    parameters: StoryParameters, 
    collectionContext: CollectionVisualContext? = nil,
    vocabularyBoostEnabled: Bool = false
  ) -> String {
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
      visualPlanningGuidelines(collectionContext: collectionContext),
      formatGuidelines(collectionContext: collectionContext),
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

  /// Builds a complete prompt for story generation based on the provided parameters (backward compatibility)
  func buildPrompt(parameters: StoryParameters, vocabularyBoostEnabled: Bool = false) -> String {
    return buildPrompt(parameters: parameters, collectionContext: nil, vocabularyBoostEnabled: vocabularyBoostEnabled)
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
      
      🚫 ABSOLUTELY NO TEXT IN ILLUSTRATION 🚫
      
      CRITICAL REQUIREMENTS:
      1. Maintain visual consistency with previous and upcoming illustrations
      2. Characters should look the same throughout the story
      3. 🚫 FORBIDDEN: NO text, words, captions, speech bubbles, or written elements
      4. ❌ NO story text overlay - the app displays text separately
      5. Create a 16:9 landscape aspect ratio illustration suitable for a children's story app
      
      ‼️ TEXT-FREE ILLUSTRATION ONLY - ANY TEXT WILL BE REJECTED ‼️
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

  private func formatGuidelines(collectionContext: CollectionVisualContext? = nil) -> String {
    let baseFormat = """
    FORMAT REQUIREMENTS:
    Return your response in this EXACT XML structure:
    
    <visual_guide>
        <style_guide>Detailed art style description with color palette, lighting, mood</style_guide>
        <character_definitions>
            <character name="CharacterName">
                <appearance>Detailed physical description: height, build, facial features, hair, skin</appearance>
                <clothing>Complete outfit description with colors, style, accessories</clothing>
                <traits>Personality traits that affect visual presentation</traits>
                <key_features>Distinctive visual elements for easy recognition</key_features>
                \(collectionContext != nil ? "<collection_role>Role and consistency requirements across collection</collection_role>" : "")
            </character>
        </character_definitions>
        <setting_definitions>
            <setting name="SettingName">
                <description>Complete environment description</description>
                <mood>Atmosphere and lighting</mood>
                <key_elements>Important props, landmarks, objects</key_elements>
            </setting>
        </setting_definitions>
        <key_props>
            <prop name="PropName">Visual description and story importance</prop>
        </key_props>
        \(collectionContext != nil ? getCollectionVisualSection(collectionContext!) : "")
    </visual_guide>
    
    <story_structure>
        <page page="1">
            <characters>List of characters appearing on this page</characters>
            <settings>Primary setting for this page</settings>
            <props>Key props/objects needed for this page</props>
            <visual_focus>Main visual elements to emphasize</visual_focus>
            <emotional_tone>Emotional atmosphere for this page</emotional_tone>
        </page>
        <!-- Repeat for each page -->
    </story_structure>
    
    <content>Story text with clear page breaks marked by "---"</content>
    <category>Category name from provided list</category>
    
    <illustrations>
        <illustration page="1">
            <scene_setup>Overall scene composition and layout</scene_setup>
            <character_positions>Where each character is positioned and what they're doing</character_positions>
            <key_elements>Important visual elements from the visual guide to include</key_elements>
            <mood_lighting>Lighting and atmospheric details</mood_lighting>
            <reference_usage>Specific elements from global reference to emphasize</reference_usage>
        </illustration>
        <!-- Repeat for each page -->
    </illustrations>
    """
    
    return baseFormat
  }

  // Add new method for collection visual context
  private func getCollectionVisualSection(_ context: CollectionVisualContext) -> String {
    return """
    <collection_context>
        <collection_theme>\(context.collectionTheme)</collection_theme>
        <shared_characters>\(context.sharedCharacters.joined(separator: ", "))</shared_characters>
        <unified_art_style>\(context.unifiedArtStyle)</unified_art_style>
        <developmental_focus>\(context.developmentalFocus)</developmental_focus>
        <consistency_requirements>Characters must maintain identical appearance across all collection stories</consistency_requirements>
        <shared_props>\(context.sharedProps.joined(separator: ", "))</shared_props>
    </collection_context>
    """
  }

  // Add visual planning guidelines method
  private func visualPlanningGuidelines(collectionContext: CollectionVisualContext? = nil) -> String {
    let baseGuidelines = """
    VISUAL CONSISTENCY PLANNING:
    
    1. CHARACTER DESIGN REQUIREMENTS:
       - Each character must have CONSISTENT visual identity throughout story
       - Provide detailed physical descriptions: facial features, hair, clothing, proportions
       - Include distinctive visual markers for easy recognition
       - Specify character's emotional range and expressions
    
    2. STORY VISUAL MAPPING:
       - Plan which characters appear on each page
       - Identify key visual elements needed per page
       - Ensure logical visual progression throughout story
       - Map emotional beats to visual presentation
    
    3. GLOBAL REFERENCE PREPARATION:
       - Design characters that work well in a reference lineup
       - Include key props and settings that will be reused
       - Create consistent style guide for entire story
       - Plan for both close-up and full-body character representations
    
    4. PAGE-LEVEL VISUAL PLANNING:
       - Specify exact characters and elements for each page
       - Plan character positions, actions, and interactions
       - Identify which elements from global reference to emphasize
       - Design scenes that flow visually from page to page
    """
    
    if let context = collectionContext {
        return baseGuidelines + """
        
        5. COLLECTION CONSISTENCY REQUIREMENTS:
           - All stories must use unified art style: \(context.unifiedArtStyle)
           - Shared characters must appear identical across stories: \(context.sharedCharacters.joined(separator: ", "))
           - Maintain developmental focus visual elements: \(context.developmentalFocus)
           - Support age group complexity: \(context.ageGroup)
           - Include collection theme elements: \(context.collectionTheme)
        """
    } else {
        return baseGuidelines
    }
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

         🚫 ABSOLUTELY NO TEXT IN ANY ILLUSTRATION 🚫
         
         CRITICAL REQUIREMENTS FOR EACH ILLUSTRATION DESCRIPTION:
         - Each description must be COMPLETELY SELF-CONTAINED with all necessary visual information
         - Always reference the same character appearances defined in your visual guide
         - Include complete setting details, specific colors, lighting, and mood
         - Describe character positioning, expressions, and actions clearly
         - Use precise, detailed language focusing on visual elements (400-800 characters)
         - Design for a 16:9 landscape aspect ratio illustration
         
         🚫 FORBIDDEN IN ALL ILLUSTRATIONS:
         ❌ NO text, words, letters, or written content
         ❌ NO captions, speech bubbles, or dialogue
         ❌ NO story text overlay or embedded text
         ❌ NO signs with writing or textual elements
         
         ✅ The app displays story text separately below each illustration
         ✅ Focus ONLY on visual storytelling without ANY written words

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

      🚫 FINAL REMINDER - NO TEXT IN ILLUSTRATIONS 🚫
      
      IMPORTANT:
      - The <visual_guide> section ensures consistent visuals across all illustrations
      - Each <illustration> description should reference the elements defined in your visual guide
      - Descriptions should be detailed enough to create a consistent illustration without context from other pages
      - Maintain the same character appearances throughout all illustrations
      
      ‼️ ABSOLUTELY FORBIDDEN ‼️
      🚫 NO text, lettering, words, captions, speech bubbles, or written elements in ANY illustration
      🚫 NO story text overlay - the app displays text separately below the image
      🚫 NO written signs, labels, or textual content of any kind
      
      ✅ Focus ONLY on visual storytelling without ANY embedded text elements
      ✅ Create pure visual scenes that communicate through imagery alone
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
  
  /// Enhanced global reference generation with collection context and story structure support
  /// - Parameters:
  ///   - visualGuide: The visual guide containing style, character and setting definitions
  ///   - storyTitle: The title of the story
  ///   - storyStructure: Optional story structure with page-level visual plans
  ///   - collectionContext: Optional collection context for unified visual consistency
  /// - Returns: A complete prompt for generating an enhanced global reference image
  func buildEnhancedGlobalReferencePrompt(
    visualGuide: VisualGuide,
    storyStructure: StoryStructure?,
    storyTitle: String,
    collectionContext: CollectionVisualContext? = nil
  ) -> String {
    print("[PromptBuilder] Creating enhanced global reference for '\(storyTitle)'")
    print("[PromptBuilder] Collection context: \(collectionContext != nil)")
    print("[PromptBuilder] Story structure: \(storyStructure != nil)")
    
    var promptComponents = [
      "Create a COMPREHENSIVE CHARACTER REFERENCE SHEET for \"\(storyTitle)\"",
      "",
      "LAYOUT REQUIREMENTS:",
      "TOP SECTION - CHARACTER LINEUP:",
      "- Show ALL main characters in a clear lineup format",
      "- Each character shown in: front view, side profile, and back view",
      "- Include full body proportions, facial details, clothing, and accessories",
      "- Characters should be clearly separated and easily distinguishable",
      "",
      "MIDDLE SECTION - KEY EXPRESSIONS:",
      "- Show each main character with 4-5 key facial expressions",
      "- Include: happy, sad, surprised, excited, and story-specific emotion",
      "- Maintain character consistency across all expressions",
      "",
      "BOTTOM SECTION - KEY PROPS AND SETTINGS:",
      "- Important objects, tools, or magical items from the story",
      "- Sample setting elements or backgrounds",
      "- Color palette reference swatches",
      "- Scale reference for object sizes relative to characters"
    ]
    
    // Add style guide
    promptComponents.append("")
    promptComponents.append("ARTISTIC STYLE:")
    promptComponents.append(visualGuide.styleGuide)
    
    // Add character details with enhanced descriptions
    if !visualGuide.characterDefinitions.isEmpty {
      promptComponents.append("")
      promptComponents.append("CHARACTER SPECIFICATIONS:")
      for (name, definition) in visualGuide.characterDefinitions {
        promptComponents.append("CHARACTER - \(name): \(definition)")
      }
    }
    
    // Add setting definitions if available
    if !visualGuide.settingDefinitions.isEmpty {
      promptComponents.append("")
      promptComponents.append("KEY SETTINGS/ELEMENTS:")
      for (name, description) in visualGuide.settingDefinitions {
        promptComponents.append("- \(name): \(description)")
      }
    }
    
    // Add story structure context if available
    if let structure = storyStructure {
      promptComponents.append("")
      promptComponents.append("STORY VISUAL REQUIREMENTS:")
      
      // Extract all unique characters across all pages
      let allCharacters = Set(structure.pages.flatMap { $0.characters })
      if !allCharacters.isEmpty {
        promptComponents.append("- All story characters: \(allCharacters.joined(separator: ", "))")
      }
      
      // Extract all unique props across all pages
      let allProps = Set(structure.pages.flatMap { $0.props })
      if !allProps.isEmpty {
        promptComponents.append("- Key props needed: \(allProps.joined(separator: ", "))")
      }
      
      // Extract emotional range
      let emotionalTones = Set(structure.pages.map { $0.emotionalTone })
      promptComponents.append("- Emotional range: \(emotionalTones.joined(separator: ", "))")
    }
    
    // Add collection context if available
    if let context = collectionContext {
      promptComponents.append("")
      promptComponents.append("COLLECTION CONSISTENCY REQUIREMENTS:")
      promptComponents.append("- This reference will be used across multiple stories in the collection")
      promptComponents.append("- Art style must be: \(context.unifiedArtStyle)")
      promptComponents.append("- Collection theme: \(context.collectionTheme)")
      promptComponents.append("- Target age group: \(context.ageGroup)")
      promptComponents.append("- Shared elements: \(context.sharedProps.joined(separator: ", "))")
      if !context.sharedCharacters.isEmpty {
        promptComponents.append("- Shared characters (maintain identical across collection): \(context.sharedCharacters.joined(separator: ", "))")
      }
    }
    
    // Add critical requirements
    promptComponents.append("")
    promptComponents.append("CRITICAL REQUIREMENTS:")
    promptComponents.append("🚫 NO TEXT OR LABELS in the image itself")
    promptComponents.append("✅ Visual reference only - characters identifiable by appearance alone")
    promptComponents.append("✅ High detail level for facial features, clothing, and distinctive elements")
    promptComponents.append("✅ Consistent artistic style throughout the reference sheet")
    promptComponents.append("✅ Professional character reference sheet suitable for animation/illustration")
    promptComponents.append("✅ Each character must be visually distinct and memorable")
    
    // Add text-free enforcement
    promptComponents.append("")
    promptComponents.append("⛔️ CRITICAL: NO TEXT, LETTERS, OR WRITTEN ELEMENTS ALLOWED IN IMAGE ⛔️")
    
    let finalPrompt = promptComponents.joined(separator: "\n")
    print("[PromptBuilder] Generated enhanced global reference prompt (length: \(finalPrompt.count) characters)")
    return finalPrompt
  }
  
  /// Legacy method for backward compatibility
  func buildGlobalReferenceImagePrompt(visualGuide: VisualGuide, storyTitle: String) -> String {
    return buildEnhancedGlobalReferencePrompt(
      visualGuide: visualGuide,
      storyStructure: nil,
      storyTitle: storyTitle,
      collectionContext: nil
    )
  }
  
  /// Enhanced sequential illustration prompts with story structure and collection context support
  /// - Parameters:
  ///   - page: The page containing content to illustrate
  ///   - pageIndex: The position of the page in the story
  ///   - storyStructure: Optional story structure with page-level visual plans
  ///   - visualGuide: The visual guide containing style, character and setting information
  ///   - globalReferenceImageBase64: Optional base64-encoded global reference image
  ///   - previousIllustrationBase64: Optional base64-encoded previous page illustration
  ///   - collectionContext: Optional collection context for unified visual consistency
  /// - Returns: A complete prompt for generating an enhanced sequential illustration with references
  func buildEnhancedSequentialIllustrationPrompt(
    page: Page,
    pageIndex: Int,
    storyStructure: StoryStructure?,
    visualGuide: VisualGuide,
    globalReferenceImageBase64: String? = nil,
    previousIllustrationBase64: String? = nil,
    collectionContext: CollectionVisualContext? = nil
  ) -> String {
    print("[PromptBuilder] Creating enhanced sequential illustration for page \(pageIndex + 1)")
    print("[PromptBuilder] Story structure: \(storyStructure != nil)")
    print("[PromptBuilder] Collection context: \(collectionContext != nil)")
    
    let pageVisualPlan = storyStructure?.pages.first { $0.pageNumber == pageIndex + 1 }
    
    var promptComponents = [
      "Generate illustration for page \(pageIndex + 1):",
      "Page content: \(page.content)",
      ""
    ]
    
    // Add global reference usage
    if globalReferenceImageBase64 != nil {
      promptComponents.append("GLOBAL REFERENCE USAGE:")
      promptComponents.append("- A comprehensive character reference sheet is attached")
      promptComponents.append("- Use EXACT character appearances from the reference sheet")
      if let visualPlan = pageVisualPlan {
        promptComponents.append("- Characters to include: \(visualPlan.characters.joined(separator: ", "))")
        promptComponents.append("- Key props to include: \(visualPlan.props.joined(separator: ", "))")
        promptComponents.append("- Visual focus: \(visualPlan.visualFocus)")
        promptComponents.append("- Emotional tone: \(visualPlan.emotionalTone)")
      }
      promptComponents.append("")
    }
    
    // Add scene requirements
    promptComponents.append("SCENE REQUIREMENTS:")
    if let visualPlan = pageVisualPlan {
      promptComponents.append("- Setting: \(visualPlan.settings.joined(separator: ", "))")
      promptComponents.append("- Character actions: [derived from page content]")
      promptComponents.append("- Props needed: \(visualPlan.props.joined(separator: ", "))")
      promptComponents.append("- Emotional atmosphere: \(visualPlan.emotionalTone)")
    }
    promptComponents.append("")
    
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
    
    // Add consistency requirements
    promptComponents.append("")
    promptComponents.append("CONSISTENCY REQUIREMENTS:")
    promptComponents.append("- Match character faces, proportions, and clothing EXACTLY to reference sheet")
    promptComponents.append("- Use the same art style and color palette as reference")
    promptComponents.append("- Maintain character personalities through body language and expressions")
    promptComponents.append("- Include specified props in positions that make sense for the scene")
    promptComponents.append("")
    
    // Add collection context if available
    if let context = collectionContext {
      promptComponents.append("COLLECTION CONSISTENCY:")
      promptComponents.append("- This illustration is part of a story collection: \(context.collectionTheme)")
      promptComponents.append("- Maintain unified art style: \(context.unifiedArtStyle)")
      promptComponents.append("- Support developmental focus: \(context.developmentalFocus)")
      promptComponents.append("- Age-appropriate complexity: \(context.ageGroup)")
      promptComponents.append("")
    }
    
    // Add reference sheet guidance
    promptComponents.append("REFERENCE SHEET GUIDANCE:")
    promptComponents.append("- Study the character lineup section for accurate character appearance")
    promptComponents.append("- Use the expression examples for appropriate facial expressions")
    promptComponents.append("- Reference the color palette for consistent coloring")
    promptComponents.append("- Maintain the same level of detail and artistic style")
    promptComponents.append("")
    
    // Add previous illustration context
    if previousIllustrationBase64 != nil {
      promptComponents.append("PREVIOUS ILLUSTRATION CONTEXT:")
      promptComponents.append("- A previous page illustration is attached for visual continuity")
      promptComponents.append("- Maintain consistent character appearance and style")
      promptComponents.append("- Ensure logical visual progression from previous scene")
      promptComponents.append("")
    }
    
    // Add text-free requirements
    promptComponents.append("🚫 NO TEXT in illustration - story text displays separately")
    promptComponents.append("✅ Focus on accurate character representation and visual storytelling")
    promptComponents.append("✅ Create engaging, age-appropriate visual narrative")
    
    return promptComponents.joined(separator: "\n")
  }
  
  /// Legacy method for backward compatibility
  func buildSequentialIllustrationPrompt(
    page: Page,
    pageIndex: Int,
    visualGuide: VisualGuide,
    globalReferenceImageBase64: String? = nil,
    previousIllustrationBase64: String? = nil
  ) -> String {
    return buildEnhancedSequentialIllustrationPrompt(
      page: page,
      pageIndex: pageIndex,
      storyStructure: nil,
      visualGuide: visualGuide,
      globalReferenceImageBase64: globalReferenceImageBase64,
      previousIllustrationBase64: previousIllustrationBase64,
      collectionContext: nil
    )
  }
}
