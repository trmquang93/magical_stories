import Foundation
import SwiftData

/// Provides pre-made stories and collections that integrate seamlessly with the existing app architecture
/// Uses the same data models and structure as AI-generated content for consistency
@MainActor
class PreMadeContentProvider: ObservableObject {
    
    // MARK: - Pre-Made Stories
    
    /// Creates 5 pre-made stories following the same structure as AI-generated content
    static func createPreMadeStories() -> [Story] {
        let stories = [
            createLunasMoonbeamAdventure(),
            createKindnessGarden(),
            createBraveLittleBuilder(),
            createFriendshipForest(),
            createMiasArtStudio()
        ]
        
        // Set all stories as completed and ready for reading
        for story in stories {
            story.isCompleted = true
            for page in story.pages {
                page.illustrationStatus = .pending // Will be generated on-demand like regular stories
            }
        }
        
        return stories
    }
    
    // MARK: - Story 1: Luna's Moonbeam Adventure (Emotional Intelligence + Problem Solving)
    
    private static func createLunasMoonbeamAdventure() -> Story {
        let parameters = StoryParameters(
            theme: "Magical Adventure",
            childAge: 5,
            childName: "Luna",
            favoriteCharacter: "Moonbeam Cat",
            storyLength: "medium",
            developmentalFocus: [.emotionalIntelligence, .problemSolving],
            interactiveElements: true,
            emotionalThemes: ["courage", "empathy"],
            languageCode: "en"
        )
        
        let pages = [
            Page(
                content: "Luna loved her special cat, Moonbeam, who had silver fur that sparkled like stars. Every night, Moonbeam would glow softly and help Luna feel safe and happy before bed.",
                pageNumber: 1,
                imagePrompt: "A young girl with dark hair sitting with a magical silver cat that glows softly in a cozy bedroom with star decorations"
            ),
            Page(
                content: "One evening, Luna noticed that Moonbeam seemed sad. His usual glow was very dim, and he meowed softly as if something was wrong. Luna felt worried and wanted to help her special friend.",
                pageNumber: 2,
                imagePrompt: "Luna looking concerned at her silver cat Moonbeam who appears dim and sad, sitting by a window at sunset"
            ),
            Page(
                content: "\"What's wrong, Moonbeam?\" Luna asked gently. She petted him softly and listened carefully. Sometimes the best way to help a friend is to listen with your heart and show you care.",
                pageNumber: 3,
                imagePrompt: "Luna kneeling down to comfort Moonbeam, showing gentle care and attention in a warm, loving scene"
            ),
            Page(
                content: "Moonbeam led Luna to the window and looked up at the sky. Luna saw that the moon was hidden behind thick clouds. \"Oh! You miss the moon's light,\" Luna said, understanding her friend's feelings.",
                pageNumber: 4,
                imagePrompt: "Luna and Moonbeam at a window looking at a cloudy night sky where the moon is barely visible behind dark clouds"
            ),
            Page(
                content: "Luna thought carefully about how to solve this problem. She remembered that her grandmother had given her a special crystal that could catch and hold light. \"I have an idea!\" she said excitedly.",
                pageNumber: 5,
                imagePrompt: "Luna holding a beautiful glowing crystal, with Moonbeam looking interested and hopeful"
            ),
            Page(
                content: "Luna held the crystal up to her nightlight, and it began to glow with warm, gentle light just like the moon. When she showed it to Moonbeam, his silver fur began to sparkle again, and he purred happily.",
                pageNumber: 6,
                imagePrompt: "The crystal glowing brightly as Luna holds it near Moonbeam, whose silver fur is starting to sparkle and glow again"
            ),
            Page(
                content: "\"You solved the problem with kindness and creativity,\" Luna's mother said, watching from the doorway. \"When we care about someone, we can find ways to help them feel better.\" Luna hugged Moonbeam close, feeling proud and happy.",
                pageNumber: 7,
                imagePrompt: "Luna hugging a now-glowing Moonbeam while her mother watches proudly from the doorway, the room filled with warm, magical light"
            )
        ]
        
        let story = Story(
            title: "Luna's Moonbeam Adventure",
            pages: pages,
            parameters: parameters,
            categoryName: "Fantasy"
        )
        
        // Add visual guide for character consistency
        let visualGuide = VisualGuide(
            styleGuide: "Warm, dreamy illustration style with soft glowing effects. Use blues, silvers, and gentle purples. Create a magical, cozy atmosphere.",
            characterDefinitions: [
                "Luna": "A 5-year-old girl with shoulder-length dark brown hair and kind brown eyes. Wears comfortable pajamas with star patterns. Shows expressions of care and determination.",
                "Moonbeam": "A magical silver cat with fur that sparkles and glows. Medium-sized with bright green eyes. Can dim or brighten based on emotions.",
                "Luna's Mother": "A caring woman with gentle features and warm smile. Wears comfortable home clothes."
            ],
            settingDefinitions: [
                "Luna's Bedroom": "A cozy child's bedroom with star decorations, soft lighting, and magical elements. Window shows night sky.",
                "Night Sky": "Cloudy evening sky with hidden moon. Creates contrast between dim and bright scenes."
            ]
        )
        
        story.setVisualGuide(visualGuide)
        story.setCharacterNames(["Luna", "Moonbeam", "Luna's Mother"])
        
        return story
    }
    
    // MARK: - Story 2: The Kindness Garden (Kindness & Empathy + Social Skills)
    
    private static func createKindnessGarden() -> Story {
        let parameters = StoryParameters(
            theme: "Friendship and Kindness",
            childAge: 6,
            childName: "Maya",
            favoriteCharacter: "Gentle Rabbit",
            storyLength: "medium",
            developmentalFocus: [.kindnessEmpathy, .socialSkills],
            interactiveElements: true,
            emotionalThemes: ["kindness", "helping others"],
            languageCode: "en"
        )
        
        let pages = [
            Page(
                content: "Maya discovered a special garden where flowers only bloomed when someone did something kind. She met Benny the rabbit, who looked sad because his favorite flower had stopped blooming.",
                pageNumber: 1,
                imagePrompt: "A magical garden with some blooming and some wilted flowers, Maya meeting a sad brown rabbit near a drooping flower"
            ),
            Page(
                content: "\"Why is your flower so sad?\" Maya asked gently. Benny explained that he had been so worried about his flower that he forgot to help his friends. The flower could feel his forgotten kindness.",
                pageNumber: 2,
                imagePrompt: "Maya and Benny the rabbit talking near the wilted flower, with Benny looking regretful and explaining"
            ),
            Page(
                content: "Maya had an idea. \"Let's do kind things together!\" she suggested. They started by sharing Maya's lunch with a hungry squirrel. Immediately, a small bud appeared on Benny's flower.",
                pageNumber: 3,
                imagePrompt: "Maya and Benny sharing food with a happy squirrel, with a tiny flower bud beginning to appear"
            ),
            Page(
                content: "Next, they helped an elderly hedgehog carry heavy acorns to her home. \"Thank you so much!\" she said gratefully. Benny's flower grew a little taller and more colorful.",
                pageNumber: 4,
                imagePrompt: "Maya and Benny helping an elderly hedgehog carry acorns, with the flower noticeably taller and brighter"
            ),
            Page(
                content: "When they saw a baby bird who had fallen from its nest, Maya and Benny worked together to build a soft landing spot and gently help it back to safety. Their kindness made the flower bloom beautifully.",
                pageNumber: 5,
                imagePrompt: "Maya and Benny carefully helping a baby bird, with the flower now in full, radiant bloom"
            ),
            Page(
                content: "\"I learned that kindness grows when we share it,\" said Benny happily. Maya smiled, \"And when we help others together, we become even better friends!\" The garden sparkled with the magic of their friendship.",
                pageNumber: 6,
                imagePrompt: "Maya and Benny sitting together in the beautiful blooming garden, surrounded by colorful flowers and magical sparkles"
            )
        ]
        
        let story = Story(
            title: "The Kindness Garden",
            pages: pages,
            parameters: parameters,
            categoryName: "Fantasy"
        )
        
        let visualGuide = VisualGuide(
            styleGuide: "Bright, cheerful garden scenes with magical blooming effects. Use vibrant greens, colorful flower tones, and warm lighting. Show kindness through character expressions and actions.",
            characterDefinitions: [
                "Maya": "A 6-year-old girl with curly blonde hair and bright blue eyes. Wears a comfortable garden dress. Shows expressions of kindness and helpfulness.",
                "Benny": "A gentle brown rabbit with soft fur and expressive dark eyes. Medium-sized with long ears that show emotions.",
                "Squirrel": "A small, cheerful squirrel with bushy tail. Shows gratitude and happiness.",
                "Elderly Hedgehog": "A wise, older hedgehog with gray spines. Walks slowly but shows appreciation.",
                "Baby Bird": "A small, fluffy baby bird with tiny wings. Shows vulnerability and then joy."
            ],
            settingDefinitions: [
                "Kindness Garden": "A magical garden where flowers respond to acts of kindness. Some flowers bloom brilliantly while others wait for kindness to awaken them.",
                "Flower Spots": "Special places in the garden where kindness flowers grow, changing based on the kindness around them."
            ]
        )
        
        story.setVisualGuide(visualGuide)
        story.setCharacterNames(["Maya", "Benny", "Squirrel", "Elderly Hedgehog", "Baby Bird"])
        
        return story
    }
    
    // MARK: - Story 3: Brave Little Builder (Resilience & Grit + Creativity)
    
    private static func createBraveLittleBuilder() -> Story {
        let parameters = StoryParameters(
            theme: "Building and Creating",
            childAge: 7,
            childName: "Sam",
            favoriteCharacter: "Wise Owl",
            storyLength: "medium",
            developmentalFocus: [.resilienceGrit, .creativityImagination],
            interactiveElements: true,
            emotionalThemes: ["perseverance", "creativity"],
            languageCode: "en"
        )
        
        let pages = [
            Page(
                content: "Sam loved building with blocks more than anything else. When the annual Building Contest was announced, Sam decided to create the most amazing castle ever built. But building big dreams takes time and patience.",
                pageNumber: 1,
                imagePrompt: "Sam with building blocks and tools, looking determined while sketching plans for a castle, with contest poster in background"
            ),
            Page(
                content: "Sam worked hard all morning, but the castle kept falling down. Each time it tumbled, Sam felt frustrated. \"Maybe I'm not good at building,\" Sam said sadly, sitting among the scattered blocks.",
                pageNumber: 2,
                imagePrompt: "Sam looking disappointed surrounded by fallen blocks, with a partially built castle that has tumbled down"
            ),
            Page(
                content: "Olivia the wise owl landed nearby. \"I've been watching you build,\" she said kindly. \"Every great builder faces challenges. The secret is learning from each fall and trying again with new knowledge.\"",
                pageNumber: 3,
                imagePrompt: "A wise brown owl named Olivia perched near Sam, offering encouragement and guidance among the building blocks"
            ),
            Page(
                content: "\"What did you learn from your castle falling?\" Olivia asked. Sam thought carefully. \"The bottom needs to be stronger, and I should build slower,\" Sam realized. \"Those are excellent discoveries!\" Olivia hooted approvingly.",
                pageNumber: 4,
                imagePrompt: "Sam examining the fallen blocks thoughtfully while Olivia watches, both looking at the foundation pieces"
            ),
            Page(
                content: "Sam started again, this time building a wider, stronger base. When one wall wobbled, instead of giving up, Sam reinforced it with extra blocks. \"I'm learning to be a problem-solver!\" Sam said proudly.",
                pageNumber: 5,
                imagePrompt: "Sam carefully building a stronger foundation, adding support blocks, with Olivia watching proudly"
            ),
            Page(
                content: "After many tries and improvements, Sam's castle stood tall and strong. It had unique features that came from all the problem-solving: a wider base, reinforced walls, and creative towers that no one else had thought of.",
                pageNumber: 6,
                imagePrompt: "Sam standing proudly next to a magnificent, unique castle with special design features, Olivia perched nearby"
            ),
            Page(
                content: "At the contest, Sam didn't win first place, but received the \"Most Creative Problem-Solver\" award. \"You learned the most important building skill,\" said Olivia. \"When you don't give up, you grow stronger and more creative.\"",
                pageNumber: 7,
                imagePrompt: "Sam holding a special award at the building contest, surrounded by other children and their projects, with Olivia flying overhead"
            )
        ]
        
        let story = Story(
            title: "Brave Little Builder",
            pages: pages,
            parameters: parameters,
            categoryName: "Adventure"
        )
        
        let visualGuide = VisualGuide(
            styleGuide: "Bright, encouraging colors with focus on building materials and creativity. Use warm browns, blues, and colorful blocks. Show progress and determination through scenes.",
            characterDefinitions: [
                "Sam": "A 7-year-old child with short brown hair and determined green eyes. Wears practical clothes for building. Shows emotions from frustration to pride and determination.",
                "Olivia": "A wise brown owl with large, kind amber eyes. Has detailed feathers and an encouraging expression. Perches and flies gracefully."
            ],
            settingDefinitions: [
                "Building Area": "A creative space with blocks, tools, and building materials scattered around. Good lighting for detailed work.",
                "Contest Space": "A large area with many different building projects displayed, other children and families present."
            ]
        )
        
        story.setVisualGuide(visualGuide)
        story.setCharacterNames(["Sam", "Olivia"])
        
        return story
    }
    
    // MARK: - Story 4: The Friendship Forest (Social Skills + Emotional Intelligence)
    
    private static func createFriendshipForest() -> Story {
        let parameters = StoryParameters(
            theme: "Friendship",
            childAge: 5,
            childName: "Alex",
            favoriteCharacter: "Forest Friends",
            storyLength: "medium",
            developmentalFocus: [.socialSkills, .emotionalIntelligence],
            interactiveElements: true,
            emotionalThemes: ["friendship", "understanding differences"],
            languageCode: "en"
        )
        
        let pages = [
            Page(
                content: "Alex loved exploring the Friendship Forest, where animals of all kinds lived together happily. But today, Alex noticed that some friends were sitting apart from each other, looking sad.",
                pageNumber: 1,
                imagePrompt: "Alex walking through a beautiful forest with various animals visible, some grouped together happily while others sit alone looking sad"
            ),
            Page(
                content: "Benny the bear was sitting alone because he was much bigger than the other animals. \"They probably think I'm too loud and clumsy to play with,\" he said sadly to Alex.",
                pageNumber: 2,
                imagePrompt: "A large, gentle bear sitting alone looking sad while smaller animals play in the distance, Alex listening sympathetically"
            ),
            Page(
                content: "Meanwhile, Pip the mouse was hiding behind a tree. \"I'm too small,\" she whispered. \"When I try to talk, the bigger animals can't hear me, so I think they don't want to be my friend.\"",
                pageNumber: 3,
                imagePrompt: "A tiny mouse hiding behind a tree looking lonely, while Alex kneels down to listen to her quiet voice"
            ),
            Page(
                content: "Alex had an idea. \"What if being different is actually what makes friendship special?\" Alex suggested. \"Benny, your big voice could help Pip when she needs to be heard by everyone!\"",
                pageNumber: 4,
                imagePrompt: "Alex talking excitedly to both Benny the bear and Pip the mouse, gesturing as if explaining a wonderful idea"
            ),
            Page(
                content: "\"And Pip,\" Alex continued, \"you can fit into small spaces to help find things! Plus, you're a great listener.\" Benny and Pip looked at each other with new understanding and smiled.",
                pageNumber: 5,
                imagePrompt: "Benny and Pip looking at each other with growing friendship and understanding, Alex standing between them encouragingly"
            ),
            Page(
                content: "Soon, all the forest friends discovered how their differences made them a wonderful team. The big animals helped reach high places, the small animals found lost items, and everyone felt special and included.",
                pageNumber: 6,
                imagePrompt: "All the forest animals working and playing together happily, with big and small animals helping each other in various ways"
            ),
            Page(
                content: "\"I learned that good friends celebrate what makes each other special,\" said Alex. The Friendship Forest was filled with laughter and joy as everyone played together, appreciating their differences.",
                pageNumber: 7,
                imagePrompt: "Alex surrounded by all the happy forest animals playing together, showing a wonderful celebration of friendship and differences"
            )
        ]
        
        let story = Story(
            title: "The Friendship Forest",
            pages: pages,
            parameters: parameters,
            categoryName: "Animals"
        )
        
        let visualGuide = VisualGuide(
            styleGuide: "Warm, inviting forest scenes with diverse animal characters. Use rich greens, earthy browns, and bright accents. Show emotions clearly through character expressions and body language.",
            characterDefinitions: [
                "Alex": "A 5-year-old child with medium-length auburn hair and warm hazel eyes. Wears outdoor exploration clothes. Shows empathy and problem-solving expressions.",
                "Benny": "A large, gentle brown bear with kind dark eyes. Shows emotions from sadness to joy. Has soft, fluffy fur.",
                "Pip": "A very small gray mouse with bright black eyes and tiny pink ears. Shows shyness transforming to confidence.",
                "Forest Animals": "Various sized woodland animals including rabbits, squirrels, deer, and birds. Each unique but showing friendship."
            ],
            settingDefinitions: [
                "Friendship Forest": "A magical woodland with tall trees, dappled sunlight, and cozy spaces for animals of all sizes.",
                "Gathering Spaces": "Open clearings in the forest where animals naturally come together to play and interact."
            ]
        )
        
        story.setVisualGuide(visualGuide)
        story.setCharacterNames(["Alex", "Benny", "Pip", "Forest Animals"])
        
        return story
    }
    
    // MARK: - Story 5: Mia's Magical Art Studio (Creativity & Imagination + Cognitive Development)
    
    private static func createMiasArtStudio() -> Story {
        let parameters = StoryParameters(
            theme: "Art and Creativity",
            childAge: 6,
            childName: "Mia",
            favoriteCharacter: "Paint Brush Fairy",
            storyLength: "medium",
            developmentalFocus: [.creativityImagination, .cognitiveDevelopment],
            interactiveElements: true,
            emotionalThemes: ["creativity", "self-expression"],
            languageCode: "en"
        )
        
        let pages = [
            Page(
                content: "Mia loved to paint and draw, but sometimes she felt like her art wasn't good enough. One day, she discovered a magical art studio hidden behind a rainbow, where lived Sparkle, a tiny paintbrush fairy.",
                pageNumber: 1,
                imagePrompt: "Mia finding a magical art studio filled with floating paintbrushes and colorful paints, meeting a tiny glowing fairy with paintbrush wings"
            ),
            Page(
                content: "\"I can't paint like the grown-ups,\" Mia said sadly, showing Sparkle her artwork. Sparkle twirled around the painting and giggled. \"But you paint like Mia! That's the most magical way of all!\"",
                pageNumber: 2,
                imagePrompt: "Mia showing her artwork to Sparkle the fairy, who is examining it with wonder and joy, magical sparkles around the painting"
            ),
            Page(
                content: "Sparkle showed Mia the walls of the studio, covered with paintings by children from around the world. \"Every single one is different and special,\" Sparkle explained. \"Art is about sharing your heart, not copying others.\"",
                pageNumber: 3,
                imagePrompt: "Sparkle and Mia looking at walls covered with diverse, colorful children's artwork, each unique and beautiful in its own way"
            ),
            Page(
                content: "\"Let's try painting how you feel instead of what you think it should look like,\" suggested Sparkle. Mia picked up her brush and painted swirling blues for happiness and bright yellow for her excitement.",
                pageNumber: 4,
                imagePrompt: "Mia painting with magical brushes that leave glowing trails of blue and yellow, Sparkle flying nearby adding sparkles to the paint"
            ),
            Page(
                content: "As Mia painted her feelings, the colors began to dance and swirl on the canvas, creating something more beautiful than anything she had ever made. \"This is what happens when you paint with your heart!\" Sparkle cheered.",
                pageNumber: 5,
                imagePrompt: "Mia's painting coming alive with swirling, dancing colors that seem to move and glow, while she watches in amazement"
            ),
            Page(
                content: "Mia learned that art isn't about being perfect – it's about being yourself. She returned home with magical paintbrushes from Sparkle and a heart full of creative confidence.",
                pageNumber: 6,
                imagePrompt: "Mia back in her own room with glowing magical paintbrushes, creating confident, joyful artwork, Sparkle visible through the window waving goodbye"
            ),
            Page(
                content: "Now Mia paints every day, knowing that her unique way of seeing the world makes her art special. Sometimes she even sees Sparkle's twinkle in the sunlight on her paintings.",
                pageNumber: 7,
                imagePrompt: "Mia happily painting at home surrounded by her colorful artwork, with magical sparkles of light dancing across her paintings"
            )
        ]
        
        let story = Story(
            title: "Mia's Magical Art Studio",
            pages: pages,
            parameters: parameters,
            categoryName: "Fantasy"
        )
        
        let visualGuide = VisualGuide(
            styleGuide: "Vibrant, artistic scenes with magical paint effects and rainbow colors. Use rich art supplies colors, magical sparkles, and flowing paint effects. Show creativity and joy through visual elements.",
            characterDefinitions: [
                "Mia": "A 6-year-old girl with long black hair often in a ponytail and bright brown eyes. Wears art-friendly clothes with paint smudges. Shows emotions from doubt to confidence and joy.",
                "Sparkle": "A tiny fairy with iridescent wings shaped like paintbrushes. Glows with soft rainbow light. Has a mischievous but kind expression."
            ],
            settingDefinitions: [
                "Magical Art Studio": "A fantastical space with floating paintbrushes, rainbow-colored paint that glows, and walls covered in children's artwork.",
                "Mia's Room": "A regular child's bedroom with art supplies and Mia's artwork displayed, transformed by magic."
            ]
        )
        
        story.setVisualGuide(visualGuide)
        story.setCharacterNames(["Mia", "Sparkle"])
        
        return story
    }
    
    // MARK: - Pre-Made Collections
    
    /// Creates 2 pre-made growth path collections
    static func createPreMadeCollections(with stories: [Story]) -> [StoryCollection] {
        let collections = [
            createEmotionalHeroesCollection(with: stories),
            createCreativeProblemSolversCollection(with: stories)
        ]
        
        return collections
    }
    
    // MARK: - Collection 1: Emotional Heroes Journey
    
    private static func createEmotionalHeroesCollection(with stories: [Story]) -> StoryCollection {
        // Get relevant stories for this collection
        let relevantStories = stories.filter { story in
            guard let developmentalFocus = story.parameters.developmentalFocus else { return false }
            return developmentalFocus.contains(.emotionalIntelligence) || 
                   developmentalFocus.contains(.socialSkills)
        }
        
        let collection = StoryCollection(
            title: "Emotional Heroes Journey",
            descriptionText: "Stories that help children understand feelings, show empathy, and build strong friendships. These adventures teach emotional intelligence through caring characters and meaningful connections.",
            category: "Emotional Intelligence",
            ageGroup: "Ages 4-7",
            stories: relevantStories
        )
        
        // Create collection visual context for consistency
        let collectionContext = CollectionVisualContext(
            collectionId: collection.id,
            collectionTheme: "emotional growth and friendship",
            sharedCharacters: ["caring animal friends", "helpful magical creatures"],
            unifiedArtStyle: "warm, inviting illustration style with emphasis on emotional expressions and caring interactions",
            developmentalFocus: "emotional intelligence and social skills",
            ageGroup: "Ages 4-7",
            requiresCharacterConsistency: true,
            allowsStyleVariation: false,
            sharedProps: ["magical elements that respond to emotions", "cozy, safe environments"]
        )
        
        // Apply collection context to stories
        for story in relevantStories {
            story.setCollectionContext(collectionContext)
        }
        
        return collection
    }
    
    // MARK: - Collection 2: Creative Problem Solvers
    
    private static func createCreativeProblemSolversCollection(with stories: [Story]) -> StoryCollection {
        // Get relevant stories for this collection
        let relevantStories = stories.filter { story in
            guard let developmentalFocus = story.parameters.developmentalFocus else { return false }
            return developmentalFocus.contains(.creativityImagination) || 
                   developmentalFocus.contains(.problemSolving) ||
                   developmentalFocus.contains(.resilienceGrit)
        }
        
        let collection = StoryCollection(
            title: "Creative Problem Solvers",
            descriptionText: "Adventures that inspire creativity, persistence, and innovative thinking. These stories show children how to approach challenges with imagination and determination.",
            category: "Creativity & Problem Solving",
            ageGroup: "Ages 5-8",
            stories: relevantStories
        )
        
        // Create collection visual context for consistency
        let collectionContext = CollectionVisualContext(
            collectionId: collection.id,
            collectionTheme: "creativity and problem-solving adventures",
            sharedCharacters: ["wise mentors", "creative tools and materials"],
            unifiedArtStyle: "bright, inspiring illustration style showing creativity in action and problem-solving processes",
            developmentalFocus: "creativity, problem solving, and resilience",
            ageGroup: "Ages 5-8",
            requiresCharacterConsistency: true,
            allowsStyleVariation: true,
            sharedProps: ["building materials", "art supplies", "magical creation tools"]
        )
        
        // Apply collection context to stories
        for story in relevantStories {
            story.setCollectionContext(collectionContext)
        }
        
        return collection
    }
    
    // MARK: - Integration Methods
    
    /// Saves pre-made content to the persistence service
    static func savePremadeContent(
        persistenceService: any PersistenceServiceProtocol,
        collectionService: CollectionService? = nil
    ) async throws {
        let stories = createPreMadeStories()
        let collections = createPreMadeCollections(with: stories)
        
        // Save stories first
        for story in stories {
            try await persistenceService.saveStory(story)
        }
        
        // Save collections using CollectionService if available
        if let collectionService = collectionService {
            for collection in collections {
                try collectionService.createCollection(collection)
            }
        }
    }
    
    /// Checks if pre-made content already exists
    static func premadeContentExists(persistenceService: any PersistenceServiceProtocol) async -> Bool {
        do {
            let stories = try await persistenceService.loadStories()
            let premadeTitles = ["Luna's Moonbeam Adventure", "The Kindness Garden", "Brave Little Builder", "The Friendship Forest", "Mia's Magical Art Studio"]
            
            return premadeTitles.allSatisfy { title in
                stories.contains { $0.title == title }
            }
        } catch {
            return false
        }
    }
    
    /// Initializes pre-made content if it doesn't exist
    static func initializePremadeContentIfNeeded(
        persistenceService: any PersistenceServiceProtocol,
        collectionService: CollectionService? = nil
    ) async {
        let exists = await premadeContentExists(persistenceService: persistenceService)
        if !exists {
            do {
                try await savePremadeContent(
                    persistenceService: persistenceService,
                    collectionService: collectionService
                )
                print("[PreMadeContentProvider] Successfully initialized pre-made content")
            } catch {
                print("[PreMadeContentProvider] Failed to initialize pre-made content: \(error)")
            }
        }
    }
}