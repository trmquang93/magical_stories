# Visual Consistency Implementation Plan

## Overview
This document serves as the **single source of truth** for implementing a comprehensive visual consistency system across all story creation paths in the Magical Stories app. The system ensures perfect character and element consistency from story beginning to end, working seamlessly across single story creation and collection story creation.

## Current System Analysis

### Story Creation Entry Points
1. **Single Story Creation**: `HomeView` → `StoryFormView` → `StoryService.generateStory()`
2. **Collection Story Creation**: `CollectionFormView` → `CollectionService.generateStoriesForCollection()` → Multiple `StoryService.generateStory()` calls
3. **Future Entry Points**: Any new story creation workflows

### Current Visual Consistency Limitations
- ❌ Characters change appearance between pages
- ❌ No visual context sharing across collection stories
- ❌ Weak global reference image utilization
- ❌ Inconsistent prompt formatting between single and collection stories
- ❌ No unified art style enforcement across collections

## Target Architecture

### Core Principles
1. **Universal Visual Context**: All story creation uses enhanced visual consistency prompts
2. **Collection Awareness**: Stories within collections share visual themes and character consistency
3. **Backward Compatibility**: No breaking changes to existing APIs
4. **Cost Efficiency**: Enhanced prompts only, no additional API calls
5. **Seamless Integration**: Works transparently across all entry points

### Enhanced Data Models

#### CollectionVisualContext
```swift
struct CollectionVisualContext {
    let collectionId: UUID
    let collectionTheme: String
    let sharedCharacters: [String]
    let unifiedArtStyle: String
    let developmentalFocus: String
    let ageGroup: String
    let requiresCharacterConsistency: Bool
    let allowsStyleVariation: Bool
    let sharedProps: [String]
}
```

#### StoryVisualPlan
```swift
struct StoryVisualPlan {
    let pageNumber: Int
    let characters: [String]
    let settings: [String]
    let props: [String]
    let visualFocus: String
    let emotionalTone: String
}
```

#### EnhancedCharacterDefinition
```swift
struct EnhancedCharacterDefinition {
    let name: String
    let appearance: String
    let clothing: String
    let traits: [String]
    let keyFeatures: [String]
    let collectionRole: String?
}
```

## Implementation Plan

### Phase 1: Enhanced PromptBuilder Foundation

#### Step 1.1: Update PromptBuilder.swift
**File**: `/magical-stories-app/App/Services/PromptBuilder.swift`

**Action**: Enhance `formatGuidelines()` method to support collection context

**Implementation**:
```swift
// Replace existing formatGuidelines() method
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
```

#### Step 1.2: Add Visual Planning Guidelines
**Action**: Add new method `visualPlanningGuidelines()` to PromptBuilder

**Implementation**:
```swift
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
```

#### Step 1.3: Update buildPrompt Method
**Action**: Modify `buildPrompt` method to include visual planning guidelines

**Implementation**:
```swift
func buildPrompt(
    parameters: StoryParameters, 
    collectionContext: CollectionVisualContext? = nil,
    vocabularyBoostEnabled: Bool = false
) -> String {
    let vocabularyLevel = VocabularyLevel.forAge(parameters.childAge)
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

    // Add existing conditional components
    if let focus = parameters.developmentalFocus, !focus.isEmpty {
        promptComponents.append(developmentalGuidelines(categories: focus))
    }

    if let emotions = parameters.emotionalThemes, !emotions.isEmpty {
        promptComponents.append(emotionalGuidelines(themes: emotions))
    }

    if let interactive = parameters.interactiveElements, interactive {
        promptComponents.append(interactiveElementsGuidelines())
    }

    promptComponents.append(categorySelectionGuidelines())

    return promptComponents.joined(separator: "\n\n")
}
```

### Phase 2: Enhanced StoryService Integration

#### Step 2.1: Update StoryService.swift
**File**: `/magical-stories-app/App/Services/StoryService.swift`

**Action**: Add collection context support to story generation

**Implementation**:
```swift
// Add new generateStory method with collection context
func generateStory(
    parameters: StoryParameters,
    collectionContext: CollectionVisualContext? = nil
) async throws -> Story {
    print("[StoryService] generateStory START with collection context: \(collectionContext != nil)")

    isGenerating = true
    defer { isGenerating = false }

    // Generate the prompt using enhanced PromptBuilder with collection context
    let prompt = buildPromptWithContext(parameters: parameters, collectionContext: collectionContext)
    print(">>>Enhanced Prompt: \(prompt)")
    
    do {
        let response = try await model.generateContent(prompt)
        guard let text = response.text else {
            throw StoryServiceError.generationFailed("No content generated")
        }

        // Enhanced parsing to handle new XML structure
        let (extractedTitle, storyContent, category, illustrations, visualGuide, storyStructure) =
            try extractEnhancedTitleCategoryAndContent(from: text)

        let title = extractedTitle ?? "Magical Story"

        guard let content = storyContent, !content.isEmpty else {
            throw StoryServiceError.generationFailed("Could not extract story content from XML response")
        }

        // Process content with enhanced illustration descriptions
        let pages = try await storyProcessor.processIntoPages(
            content, 
            illustrations: illustrations ?? [],
            theme: parameters.theme,
            visualGuide: visualGuide,
            storyStructure: storyStructure
        )

        let story = Story(
            title: title,
            pages: pages,
            parameters: parameters,
            categoryName: category
        )
        
        // Enhanced visual guide handling
        if let visualGuide = visualGuide {
            story.setVisualGuide(visualGuide)
            print("[StoryService] Enhanced visual guide saved with \(visualGuide.characterDefinitions.count) characters")
            
            // Store collection context if provided
            if let context = collectionContext {
                story.setCollectionContext(context)
                print("[StoryService] Collection context saved: \(context.collectionTheme)")
            }
        }
        
        // Set all pages to pending for lazy illustration generation
        for page in story.pages {
            page.illustrationStatus = .pending
        }
        
        try await persistenceService.saveStory(story)
        
        if !stories.contains(where: { $0.id == story.id }) {
            stories.insert(story, at: 0)
        }
        await loadStories()
        return story
        
    } catch {
        print("[StoryService] Error generating story: \(error)")
        throw error
    }
}

// Keep existing method for backward compatibility
func generateStory(parameters: StoryParameters) async throws -> Story {
    return try await generateStory(parameters: parameters, collectionContext: nil)
}

// Add helper method for prompt building
private func buildPromptWithContext(
    parameters: StoryParameters, 
    collectionContext: CollectionVisualContext?
) -> String {
    let vocabularyBoostEnabled = settingsService?.isVocabularyBoostEnabled ?? false
    return promptBuilder.buildPrompt(
        parameters: parameters,
        collectionContext: collectionContext,
        vocabularyBoostEnabled: vocabularyBoostEnabled
    )
}
```

#### Step 2.2: Enhanced XML Parsing
**Action**: Update `extractTitleCategoryAndContent` method to handle new XML structure

**Implementation**:
```swift
private func extractEnhancedTitleCategoryAndContent(from response: String) throws -> (
    title: String?,
    content: String?,
    category: String?,
    illustrations: [IllustrationDescription]?,
    visualGuide: VisualGuide?,
    storyStructure: StoryStructure?
) {
    // Enhanced parsing logic to handle new XML structure including story_structure section
    let xmlString = response.trimmingCharacters(in: .whitespacesAndNewlines)
    
    // Extract title (existing logic)
    let title = extractTitle(from: xmlString)
    
    // Extract content (existing logic)
    let content = extractContent(from: xmlString)
    
    // Extract category (existing logic)
    let category = extractCategory(from: xmlString)
    
    // Enhanced visual guide extraction
    let visualGuide = extractEnhancedVisualGuide(from: xmlString)
    
    // NEW: Extract story structure
    let storyStructure = extractStoryStructure(from: xmlString)
    
    // Enhanced illustration descriptions
    let illustrations = extractEnhancedIllustrations(from: xmlString, storyStructure: storyStructure)
    
    return (title, content, category, illustrations, visualGuide, storyStructure)
}

// Add new extraction methods
private func extractStoryStructure(from xmlString: String) -> StoryStructure? {
    // Parse <story_structure> section
    // Implementation details for extracting page-level visual plans
    // Return StoryStructure with PageVisualPlan array
}

private func extractEnhancedVisualGuide(from xmlString: String) -> VisualGuide? {
    // Enhanced visual guide parsing with character appearance, clothing, traits, etc.
    // Parse collection_context if present
}

private func extractEnhancedIllustrations(
    from xmlString: String, 
    storyStructure: StoryStructure?
) -> [IllustrationDescription]? {
    // Parse enhanced illustration descriptions with scene_setup, character_positions, etc.
    // Use story structure context for better descriptions
}
```

### Phase 3: CollectionService Integration

#### Step 3.1: Update CollectionService.swift
**File**: `/magical-stories-app/App/Services/CollectionService.swift`

**Action**: Enhance `generateStoriesForCollection` to use unified visual context

**Implementation**:
```swift
func generateStoriesForCollection(
    _ collection: StoryCollection, 
    parameters: CollectionParameters
) async throws {
    
    DispatchQueue.main.async {
        self.isGenerating = true
        self.generationError = nil
    }

    defer {
        DispatchQueue.main.async {
            self.isGenerating = false
        }
    }

    do {
        let numberOfStories = 3
        
        // NEW: Create unified visual context for entire collection
        let visualContext = createCollectionVisualContext(
            collection: collection,
            parameters: parameters
        )
        
        print("[CollectionService] Created visual context: \(visualContext.collectionTheme)")
        print("[CollectionService] Shared characters: \(visualContext.sharedCharacters)")

        let storyThemes = createStoryThemes(
            developmentalFocus: parameters.developmentalFocus,
            interests: parameters.interests,
            count: numberOfStories
        )

        var generatedStories: [Story] = []

        for (index, theme) in storyThemes.enumerated() {
            let ageRange = parameters.childAgeGroup.components(
                separatedBy: CharacterSet.decimalDigits.inverted
            ).compactMap { Int($0) }

            let childAge = ageRange.count >= 2
                ? (ageRange[0] + ageRange[1]) / 2
                : (ageRange.first ?? 5)
            
            let characterName: String? = {
                if let availableCharacters = parameters.characters, !availableCharacters.isEmpty {
                    let characterIndex = index % availableCharacters.count
                    return availableCharacters[characterIndex]
                } else {
                    return nil
                }
            }()
            
            let storyParams = StoryParameters(
                theme: theme,
                childAge: childAge,
                childName: parameters.childName,
                favoriteCharacter: characterName,
                languageCode: parameters.languageCode
            )

            print("[CollectionService] Generating story \(index + 1)/\(numberOfStories) with collection context")

            // Use enhanced story generation with collection context
            let story = try await storyService.generateStory(
                parameters: storyParams,
                collectionContext: visualContext
            )

            if !story.collections.contains(where: { $0.id == collection.id }) {
                story.collections.append(collection)
            }

            generatedStories.append(story)

            if index < numberOfStories - 1 {
                try repository.saveCollection(collection)
            }
        }

        // Update collection with generated stories
        if collection.stories == nil {
            collection.stories = []
        }

        for story in generatedStories {
            if !(collection.stories?.contains(where: { $0.id == story.id }) ?? false) {
                collection.stories?.append(story)
            }
        }

        try repository.saveCollection(collection)
        loadCollections()

    } catch {
        print("[CollectionService] Failed to generate stories: \(error)")
        DispatchQueue.main.async {
            self.generationError = error
        }
        throw error
    }
}

// NEW: Create unified visual context for collection
private func createCollectionVisualContext(
    collection: StoryCollection,
    parameters: CollectionParameters
) -> CollectionVisualContext {
    
    // Extract shared characters from parameters
    let sharedCharacters = parameters.characters ?? []
    
    // Create unified art style based on age group and developmental focus
    let unifiedArtStyle = createUnifiedArtStyle(
        ageGroup: parameters.childAgeGroup,
        developmentalFocus: parameters.developmentalFocus
    )
    
    // Determine shared props based on interests and developmental focus
    let sharedProps = extractSharedProps(
        interests: parameters.interests,
        developmentalFocus: parameters.developmentalFocus
    )
    
    return CollectionVisualContext(
        collectionId: collection.id,
        collectionTheme: "\(parameters.developmentalFocus) through \(parameters.interests)",
        sharedCharacters: sharedCharacters,
        unifiedArtStyle: unifiedArtStyle,
        developmentalFocus: parameters.developmentalFocus,
        ageGroup: parameters.childAgeGroup,
        requiresCharacterConsistency: true,
        allowsStyleVariation: false,
        sharedProps: sharedProps
    )
}

private func createUnifiedArtStyle(ageGroup: String, developmentalFocus: String) -> String {
    let baseStyle = "Warm, engaging children's book illustration style with soft edges and vibrant colors"
    let ageSpecific = ageGroup.contains("3") || ageGroup.contains("4") ? 
        "Simple shapes and bold colors suitable for preschoolers" :
        "Detailed illustrations with rich visual storytelling"
    let focusSpecific = "Visual elements that support \(developmentalFocus) development"
    
    return "\(baseStyle). \(ageSpecific). \(focusSpecific)."
}

private func extractSharedProps(interests: String, developmentalFocus: String) -> [String] {
    var props: [String] = []
    
    // Extract props from interests
    let interestsList = interests.lowercased().components(separatedBy: ",")
        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    
    for interest in interestsList {
        switch interest {
        case let i where i.contains("animal"):
            props.append("friendly animals")
        case let i where i.contains("space"):
            props.append("stars and planets")
        case let i where i.contains("ocean"):
            props.append("seashells and waves")
        case let i where i.contains("forest"):
            props.append("trees and flowers")
        default:
            props.append(interest)
        }
    }
    
    // Add developmental focus props
    switch developmentalFocus.lowercased() {
    case let f where f.contains("emotional"):
        props.append("expressive faces")
    case let f where f.contains("problem"):
        props.append("puzzle elements")
    case let f where f.contains("social"):
        props.append("group activities")
    default:
        break
    }
    
    return props
}
```

### Phase 4: Enhanced Global Reference Generation

#### Step 4.1: Update PromptBuilder Global Reference Method
**Action**: Enhance `buildGlobalReferenceImagePrompt` in PromptBuilder.swift

**Implementation**:
```swift
func buildEnhancedGlobalReferencePrompt(
    visualGuide: VisualGuide,
    storyStructure: StoryStructure?,
    storyTitle: String,
    collectionContext: CollectionVisualContext? = nil
) -> String {
    print("[PromptBuilder] Creating enhanced global reference for '\(storyTitle)'")
    
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
    
    // Add character details
    if !visualGuide.characterDefinitions.isEmpty {
        promptComponents.append("")
        promptComponents.append("CHARACTER SPECIFICATIONS:")
        for (name, definition) in visualGuide.characterDefinitions {
            promptComponents.append("CHARACTER - \(name): \(definition)")
        }
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
    promptComponents.append(ConfigurablePromptTemplates.shared.textFreeEnforcement(level: .critical))
    
    let finalPrompt = promptComponents.joined(separator: "\n")
    print("[PromptBuilder] Generated enhanced global reference prompt (length: \(finalPrompt.count) characters)")
    return finalPrompt
}
```

#### Step 4.2: Update Sequential Illustration Prompts
**Action**: Enhance `buildSequentialIllustrationPrompt` in PromptBuilder.swift

**Implementation**:
```swift
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
    
    // Add consistency requirements
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
```

### Phase 5: Data Model Extensions

#### Step 5.1: Add CollectionVisualContext to Models
**File**: Create new file `/magical-stories-app/App/Models/CollectionVisualContext.swift`

**Implementation**:
```swift
import Foundation

/// Visual context shared across all stories in a collection for consistency
public struct CollectionVisualContext: Codable, Equatable {
    public let collectionId: UUID
    public let collectionTheme: String
    public let sharedCharacters: [String]
    public let unifiedArtStyle: String
    public let developmentalFocus: String
    public let ageGroup: String
    public let requiresCharacterConsistency: Bool
    public let allowsStyleVariation: Bool
    public let sharedProps: [String]
    
    public init(
        collectionId: UUID,
        collectionTheme: String,
        sharedCharacters: [String],
        unifiedArtStyle: String,
        developmentalFocus: String,
        ageGroup: String,
        requiresCharacterConsistency: Bool = true,
        allowsStyleVariation: Bool = false,
        sharedProps: [String] = []
    ) {
        self.collectionId = collectionId
        self.collectionTheme = collectionTheme
        self.sharedCharacters = sharedCharacters
        self.unifiedArtStyle = unifiedArtStyle
        self.developmentalFocus = developmentalFocus
        self.ageGroup = ageGroup
        self.requiresCharacterConsistency = requiresCharacterConsistency
        self.allowsStyleVariation = allowsStyleVariation
        self.sharedProps = sharedProps
    }
}
```

#### Step 5.2: Add StoryStructure to Models
**File**: Create new file `/magical-stories-app/App/Models/StoryStructure.swift`

**Implementation**:
```swift
import Foundation

/// Represents the visual planning structure for a complete story
public struct StoryStructure: Codable, Equatable {
    public let pages: [PageVisualPlan]
    
    public init(pages: [PageVisualPlan]) {
        self.pages = pages
    }
}

/// Visual planning information for a single story page
public struct PageVisualPlan: Codable, Equatable {
    public let pageNumber: Int
    public let characters: [String]
    public let settings: [String]
    public let props: [String]
    public let visualFocus: String
    public let emotionalTone: String
    
    public init(
        pageNumber: Int,
        characters: [String],
        settings: [String],
        props: [String],
        visualFocus: String,
        emotionalTone: String
    ) {
        self.pageNumber = pageNumber
        self.characters = characters
        self.settings = settings
        self.props = props
        self.visualFocus = visualFocus
        self.emotionalTone = emotionalTone
    }
}
```

#### Step 5.3: Extend Story Model
**Action**: Add collection context storage to Story model

**Implementation**: Add to existing Story model
```swift
// Add to Story.swift
private var _collectionContext: CollectionVisualContext?

func setCollectionContext(_ context: CollectionVisualContext) {
    self._collectionContext = context
}

var collectionContext: CollectionVisualContext? {
    return _collectionContext
}
```

### Phase 6: Testing Strategy

#### Step 6.1: Create Comprehensive Tests
**File**: Create `/magical-storiesTests/Services/VisualConsistencyTests.swift`

**Implementation**:
```swift
import XCTest
@testable import magical_stories

class VisualConsistencyTests: XCTestCase {
    
    var storyService: StoryService!
    var collectionService: CollectionService!
    var promptBuilder: PromptBuilder!
    
    override func setUp() async throws {
        // Setup test environment
        promptBuilder = PromptBuilder()
        // Initialize services with test configuration
    }
    
    // Test single story generation with enhanced prompts
    func testSingleStoryEnhancedPrompts() async throws {
        let parameters = StoryParameters(
            theme: "Magic Forest",
            childAge: 6,
            childName: "Alex"
        )
        
        let story = try await storyService.generateStory(parameters: parameters)
        
        XCTAssertNotNil(story.visualGuide)
        XCTAssertGreaterThan(story.pages.count, 0)
        // Add assertions for enhanced visual guide content
    }
    
    // Test collection story generation with shared visual context
    func testCollectionStoryConsistency() async throws {
        let collection = StoryCollection(/* test collection */)
        let parameters = CollectionParameters(
            childAgeGroup: "5-7",
            developmentalFocus: "Problem Solving",
            interests: "Animals, Forest"
        )
        
        try await collectionService.generateStoriesForCollection(collection, parameters: parameters)
        
        XCTAssertGreaterThan(collection.stories?.count ?? 0, 0)
        
        // Test visual consistency across collection stories
        let stories = collection.stories ?? []
        for story in stories {
            XCTAssertNotNil(story.collectionContext)
            XCTAssertEqual(story.collectionContext?.collectionTheme, "Problem Solving through Animals, Forest")
        }
    }
    
    // Test prompt building with collection context
    func testPromptBuildingWithCollectionContext() {
        let context = CollectionVisualContext(
            collectionId: UUID(),
            collectionTheme: "Test Collection",
            sharedCharacters: ["Alex", "Ruby"],
            unifiedArtStyle: "Test Style",
            developmentalFocus: "Test Focus",
            ageGroup: "5-7"
        )
        
        let parameters = StoryParameters(theme: "Test", childAge: 6)
        let prompt = promptBuilder.buildPrompt(parameters: parameters, collectionContext: context)
        
        XCTAssertTrue(prompt.contains("collection_context"))
        XCTAssertTrue(prompt.contains("Test Collection"))
        XCTAssertTrue(prompt.contains("Alex, Ruby"))
    }
    
    // Test backward compatibility
    func testBackwardCompatibility() async throws {
        let parameters = StoryParameters(theme: "Test", childAge: 6)
        
        // Test that existing generateStory method still works
        let story = try await storyService.generateStory(parameters: parameters)
        
        XCTAssertNotNil(story)
        XCTAssertNil(story.collectionContext) // Should be nil for single stories
    }
}
```

#### Step 6.2: Update Existing Tests
**Action**: Update existing test files to use enhanced methods

**Files to Update**:
- `StoryServiceTests.swift`
- `CollectionServiceTests.swift`
- `PromptBuilderTests.swift`

### Phase 7: Integration Verification

#### Step 7.1: Verify HomeView Integration
**Action**: Test single story creation flow

**Test Steps**:
1. Open HomeView
2. Tap "Create Story" button
3. Fill out StoryFormView
4. Generate story
5. Verify enhanced visual guide is created
6. Verify global reference image generation
7. Verify page illustrations use reference

#### Step 7.2: Verify CollectionFormView Integration
**Action**: Test collection story creation flow

**Test Steps**:
1. Open HomeView
2. Tap "Create Growth Collection" button
3. Fill out CollectionFormView
4. Generate collection
5. Verify all stories have shared visual context
6. Verify character consistency across stories
7. Verify unified art style

#### Step 7.3: Verify Backward Compatibility
**Action**: Test existing functionality still works

**Test Areas**:
- Existing single stories continue to work
- Existing collections continue to work
- No breaking changes to public APIs
- All existing tests pass

## Implementation Status (Updated: 2025-05-29)

### ✅ COMPLETED PHASES

#### Phase 1: Enhanced PromptBuilder Foundation (COMPLETED)
- ✅ **Step 1.1**: Updated `formatGuidelines()` method with collection context support
- ✅ **Step 1.2**: Added `visualPlanningGuidelines()` method for comprehensive visual consistency planning
- ✅ **Step 1.3**: Enhanced `buildPrompt()` method to include visual planning guidelines and collection context
- **Files Modified**: `/magical-stories-app/App/Services/PromptBuilder.swift`

#### Phase 2: Enhanced StoryService Integration (COMPLETED)
- ✅ **Step 2.1**: Enhanced `generateStory()` method with collection context support
- ✅ **Step 2.2**: Implemented enhanced XML parsing for new structure including `story_structure` section
- **Files Modified**: `/magical-stories-app/App/Services/StoryService.swift`

#### Phase 5: Data Model Extensions (COMPLETED)
- ✅ **Step 5.1**: Created `CollectionVisualContext` data model
- ✅ **Step 5.2**: Created `StoryStructure` and `PageVisualPlan` data models  
- ✅ **Step 5.3**: Extended Story model with collection context storage support
- **Files Created**: 
  - `/magical-stories-app/App/Models/CollectionVisualContext.swift`
  - `/magical-stories-app/App/Models/StoryStructure.swift`
- **Files Modified**: `/magical-stories-app/App/Models/StoryModels.swift`

#### Test Infrastructure (COMPLETED)
- ✅ Fixed failing tests due to StoryParameters constructor changes
- ✅ Updated MockURLSessionForStrategy protocol conformance
- ✅ Verified project builds successfully with all enhancements

### 🔄 PENDING PHASES

#### Phase 3: CollectionService Integration (HIGH PRIORITY - NEXT)
- ⏳ **Step 3.1**: Update CollectionService with unified visual context
- **Target File**: `/magical-stories-app/App/Services/CollectionService.swift`
- **Status**: Ready to implement

#### Phase 4: Enhanced Global Reference Generation (MEDIUM PRIORITY)
- ⏳ **Step 4.1**: Enhanced global reference generation
- ⏳ **Step 4.2**: Enhanced sequential illustration prompts  
- **Target Files**: PromptBuilder.swift illustration methods
- **Status**: Dependent on Phase 3 completion

#### Phase 6: Testing Strategy (MEDIUM PRIORITY)  
- ⏳ **Step 6.1**: Create comprehensive tests for visual consistency system
- **Target Files**: New test files for visual consistency features
- **Status**: Should follow implementation phases

#### Phase 7: Integration Verification (LOW PRIORITY)
- ⏳ **Step 7.1**: Integration verification across all entry points
- **Status**: Final verification phase

## Success Criteria

### Functional Requirements
1. ✅ Single story creation produces enhanced visual consistency
2. ✅ Collection stories share unified visual context
3. ✅ Characters maintain consistent appearance across pages
4. ✅ Global reference images are comprehensive and detailed
5. ✅ All existing functionality continues to work

### Quality Requirements
1. ✅ No performance degradation
2. ✅ No breaking changes to existing APIs
3. ✅ Comprehensive test coverage
4. ✅ Clear error handling and logging
5. ✅ Cost efficiency maintained (no additional API calls)

### Integration Requirements
1. ✅ HomeView story creation works seamlessly
2. ✅ CollectionFormView collection creation works seamlessly
3. ✅ All story creation entry points enhanced
4. ✅ Backward compatibility maintained
5. ✅ Future extensibility preserved

## Conclusion

This implementation plan provides a comprehensive, step-by-step approach to implementing visual consistency across all story creation paths in the Magical Stories app. The solution focuses on enhanced prompt engineering and data structure improvements rather than expensive additional API calls, ensuring cost efficiency while dramatically improving visual consistency.

The plan maintains strict backward compatibility while providing a foundation for future enhancements. All implementation steps are detailed and actionable, with clear testing criteria and success metrics.