import Foundation
import GoogleGenerativeAI  // Adding this import for text generation
import SwiftUI

// Removed ImageReference struct as it's replaced by direct URL/prompt storage
// in Page for now.

// MARK: - Story Processor

@MainActor
class StoryProcessor {
    // Configuration constants
    static let maxPageContentLength =
        500  // Approximate character limit per page
    static let paragraphBreakPattern = "\n\n"  // How paragraphs are delimited
    static let maxParagraphsPerPage =
        2  // Maximum paragraphs allowed on a single page (Adjusted from 3)
    static let defaultPageBreakDelimiter =
        "---"  // Default delimiter for explicit page breaks

    private let formatter =
        StoryTextFormatter()  // For potential future text formatting
    nonisolated let illustrationService: any IllustrationServiceProtocol  // Injected via
    // initializer
    nonisolated private let generativeModel: (any GenerativeModelProtocol)?  // For generating
    // illustration descriptions

    init(
        illustrationService: any IllustrationServiceProtocol,
        generativeModel: (any GenerativeModelProtocol)? = nil
    ) {
        self.illustrationService = illustrationService
        self.generativeModel = generativeModel
    }

    // MARK: - Segmentation

    /// Process raw story content into structured Page objects and generate
    /// illustrations.
    /// This method first checks for explicit page break delimiters and falls
    /// back to paragraph-based pagination if needed.
    func processIntoPages(
        _ content: String,
        illustrations: [IllustrationDescription] = [],
        theme: String,
        visualGuide: VisualGuide? = nil,
        storyStructure: StoryStructure? = nil,
        collectionContext: CollectionVisualContext? = nil
    ) async throws -> [Page] {
        print("[StoryProcessor] Processing story into pages")
        print("[StoryProcessor] Has visual guide: \(visualGuide != nil)")
        print("[StoryProcessor] Has story structure: \(storyStructure != nil)")
        print("[StoryProcessor] Has collection context: \(collectionContext != nil)")
        if let context = collectionContext {
            print("[StoryProcessor] Collection theme: \(context.collectionTheme)")
            print("[StoryProcessor] Collection art style: \(context.unifiedArtStyle)")
        }
        
        // First attempt to paginate using the delimiter-based approach
        var pages = paginateStory(content)

        // Apply illustration descriptions to pages if provided
        if !illustrations.isEmpty {
            pages = applyIllustrationDescriptions(to: pages, illustrations: illustrations)
        }

        // The image prompts will be set later in StoryService if they are provided in the AI response
        // No need to preprocess descriptions here anymore

        // No longer generate illustrations here; it'll be handled by IllustrationTaskManager
        // await generateIllustrationsForPages(&pages, theme: theme)
        return pages
    }

    // Helper method to apply illustration descriptions to pages
    private func applyIllustrationDescriptions(
        to pages: [Page], illustrations: [IllustrationDescription]
    ) -> [Page] {
        let updatedPages = pages
        for illustration in illustrations {
            // Find the matching page by page number
            if illustration.pageNumber > 0 && illustration.pageNumber <= pages.count {
                // Page numbers in our array are 0-indexed, but illustrations use 1-indexed
                let pageIndex = illustration.pageNumber - 1
                // Set the illustration description as the image prompt
                updatedPages[pageIndex].imagePrompt = illustration.description
            }
        }

        print(
            "[StoryService] Applied \(illustrations.count) illustration descriptions to \(pages.count) pages"
        )

        return updatedPages
    }

    /// Paginates story content using explicit delimiters, with fallback to
    /// paragraph-based pagination.
    /// - Parameters:
    ///   - content: The raw story content to paginate
    ///   - delimiter: The delimiter string to use for page breaks (default:
    /// "---")
    /// - Returns: An array of Page objects representing the paginated story
    @MainActor
    func paginateStory(
        _ content: String,
        delimiter: String = "---"
    ) -> [Page] {
        let trimmedContent =
            content
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            return []  // Return empty if content is just whitespace
        }

        // Check if the content contains the delimiter
        if trimmedContent.contains(delimiter) {
            // Split content by delimiter
            var pageNumber = 1
            var pages = [Page]()

            // Split by delimiter and process each segment
            let segments = trimmedContent.components(separatedBy: delimiter)
            for segment in segments {
                let trimmedSegment =
                    segment
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedSegment.isEmpty {
                    pages.append(
                        Page(
                            content: trimmedSegment,
                            pageNumber: pageNumber
                        )
                    )
                    pageNumber += 1
                }
            }

            return pages
        } else {
            // Fallback to the existing paragraph-based pagination logic
            if trimmedContent.count <= Self.maxPageContentLength,
                trimmedContent
                    .components(separatedBy: Self.paragraphBreakPattern).count
                    <= Self.maxParagraphsPerPage
            {
                // If the entire story is short and fits within limits, return
                // as a single page
                return [Page(content: trimmedContent, pageNumber: 1)]
            } else {
                // Otherwise, build pages paragraph by paragraph using existing
                // logic
                let paragraphs =
                    trimmedContent
                    .components(separatedBy: Self.paragraphBreakPattern)
                    .map {
                        $0.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    .filter { !$0.isEmpty }  // Remove empty paragraphs

                return buildPagesFromParagraphs(paragraphs)
            }
        }
    }

    /// Process raw story content into structured Page objects.
    /// Process raw story content into structured Page objects and generate
    /// illustrations.
    /// This is the original method that's now updated to use the new
    /// paginateStory method.
    @available(
        *, deprecated,
        message:
            "Use processIntoPages(_:theme:) instead which uses delimiter-based pagination with fallback"
    )
    func processIntoPagesLegacy(
        _ content: String,
        theme: String
    ) async throws -> [Page] {
        let trimmedContent =
            content
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            return []  // Return empty if content is just whitespace
        }

        // Split the content into paragraphs based on double newlines
        let paragraphs =
            trimmedContent
            .components(separatedBy: Self.paragraphBreakPattern)
            .map {
                $0.trimmingCharacters(in: .whitespacesAndNewlines)
            }  // Trim each paragraph
            .filter { !$0.isEmpty }  // Remove empty paragraphs

        // If the entire story is short and fits within limits, return as a
        // single page
        if trimmedContent.count <= Self.maxPageContentLength,
            paragraphs.count <= Self.maxParagraphsPerPage
        {
            var pages = [Page(content: trimmedContent, pageNumber: 1)]
            // Generate illustrations even for single-page stories
            await generateIllustrationsForPages(&pages, theme: theme)
            return pages
        }

        // Otherwise, build pages paragraph by paragraph
        var pages = buildPagesFromParagraphs(paragraphs)
        // Generate illustrations for multi-page stories
        await generateIllustrationsForPages(&pages, theme: theme)
        return pages
    }

    /// Build pages from an array of paragraphs, respecting length and paragraph
    /// count limits.
    private func buildPagesFromParagraphs(_ paragraphs: [String]) -> [Page] {
        var pages = [Page]()
        var currentPageContent = ""
        var currentParagraphCount = 0
        var currentPageNumber = 1

        for paragraph in paragraphs {
            // Handle very long paragraphs by splitting them first
            if paragraph.count > Self.maxPageContentLength {
                // If the current page has content, finalize it before adding
                // split pages
                if !currentPageContent.isEmpty {
                    pages.append(
                        Page(
                            content: currentPageContent,  // Already trimmed
                            pageNumber: currentPageNumber
                        )
                    )
                    currentPageNumber += 1
                    currentPageContent = ""
                    currentParagraphCount = 0
                }

                // Split the long paragraph and add its pages
                let splitPages = splitLongParagraph(
                    paragraph, startingPageNumber: currentPageNumber
                )
                if !splitPages.isEmpty {
                    pages.append(contentsOf: splitPages)
                    currentPageNumber +=
                        splitPages
                        .count  // Update page number based on how many pages
                    // were added
                }
                continue  // Move to the next paragraph
            }

            // Check if adding this paragraph would exceed page limits
            let potentialContent =
                currentPageContent.isEmpty
                ? paragraph
                : currentPageContent
                    + Self
                    .paragraphBreakPattern + paragraph

            // Start a new page if:
            // 1. The current page is not empty AND
            // 2. Adding the new paragraph exceeds max length OR the current
            // page already has max paragraphs
            if !currentPageContent.isEmpty,
                potentialContent.count > Self.maxPageContentLength
                    || currentParagraphCount >= Self.maxParagraphsPerPage
            {
                // Finalize the current page
                pages.append(
                    Page(
                        content: currentPageContent,  // Already trimmed
                        pageNumber: currentPageNumber
                    )
                )

                // Start a new page with the current paragraph
                currentPageNumber += 1
                currentPageContent = paragraph
                currentParagraphCount = 1
            } else {
                // Add the paragraph to the current page
                if currentPageContent.isEmpty {
                    currentPageContent = paragraph
                } else {
                    currentPageContent += Self.paragraphBreakPattern + paragraph
                }
                currentParagraphCount += 1
            }
        }

        // Add the final page if there's any remaining content
        if !currentPageContent.isEmpty {
            pages.append(
                Page(
                    content: currentPageContent,  // Already trimmed
                    pageNumber: currentPageNumber
                )
            )
        }

        return pages
    }

    /// Split a very long paragraph into multiple pages based on
    /// maxPageContentLength.
    /// Tries to split at sentence endings or word boundaries.
    private func splitLongParagraph(
        _ paragraph: String,
        startingPageNumber: Int
    ) -> [Page] {
        var pages = [Page]()
        var remainingContent =
            paragraph
            .trimmingCharacters(in: .whitespacesAndNewlines)
        var pageNumber = startingPageNumber

        while !remainingContent.isEmpty {
            var splitIndex = remainingContent.endIndex
            var pageContent = ""

            // If remaining content is within limit, use it all for the last
            // page
            if remainingContent.count <= Self.maxPageContentLength {
                pageContent = remainingContent
                remainingContent = ""  // No more content left
            } else {
                // Find a suitable split point within the limit
                let potentialSplitEndIndex = remainingContent.index(
                    remainingContent.startIndex,
                    offsetBy: Self.maxPageContentLength
                )
                let potentialSplitRange =
                    remainingContent
                    .startIndex..<potentialSplitEndIndex

                // Prefer splitting at the last sentence end (".", "!", "?")
                // within the range
                if let sentenceEndIndex = remainingContent.rangeOfCharacter(
                    from: CharacterSet(charactersIn: ".!?"),
                    options: .backwards,
                    range: potentialSplitRange
                )?.upperBound {
                    splitIndex = sentenceEndIndex
                }
                // Otherwise, split at the last word boundary (space or newline)
                // within the range
                else if let wordEndIndex = remainingContent.rangeOfCharacter(
                    from: .whitespacesAndNewlines, options: .backwards,
                    range: potentialSplitRange
                )?
                .lowerBound {
                    // Ensure we don't create an empty page if the split is at
                    // the very beginning
                    if remainingContent.distance(
                        from: remainingContent.startIndex, to: wordEndIndex
                    ) > 0 {
                        splitIndex = wordEndIndex
                    } else {
                        // If the first word is already too long or no space
                        // found, force split at max length
                        splitIndex = potentialSplitEndIndex
                    }
                }
                // If no sentence or word boundary found (very long word), force
                // split at max length
                else {
                    splitIndex = potentialSplitEndIndex
                }

                pageContent = String(remainingContent[..<splitIndex])
                remainingContent = String(remainingContent[splitIndex...])
            }

            // Add the created page (trimming just in case)
            let trimmedPageContent =
                pageContent
                .trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedPageContent.isEmpty {
                pages.append(
                    Page(
                        content: trimmedPageContent,
                        pageNumber: pageNumber
                    )
                )
                pageNumber += 1
            }
            // Trim remaining content for the next iteration
            remainingContent =
                remainingContent
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Note: Illustrations for split long paragraphs are handled by the main
        // call
        // in processIntoPages after buildPagesFromParagraphs returns.
        return pages
    }

    // MARK: - Illustration Description Preprocessing

    /// Analyzes the full story and generates context-rich illustration
    /// descriptions for each page
    /// - Parameters:
    ///   - pages: The paginated story pages
    ///   - theme: The overall theme of the story
    /// - Returns: Array of detailed illustration descriptions, one for each
    /// page
    private func preprocessIllustrationDescriptions(
        pages: [Page],
        theme: String
    ) async -> [String] {
        guard !pages.isEmpty, let generativeModel = generativeModel else {
            return []
        }
        do {
            let storyContextPrompt = PromptBuilder.buildIllustrationDescriptionsPrompt(
                theme: theme, pages: pages)
            let response = try await generativeModel.generateContent(storyContextPrompt)
            if let text = response.text {
                // Split the response by lines with only '---' (allowing whitespace)
                let regex = try? NSRegularExpression(
                    pattern: "^\\s*---\\s*$", options: [.anchorsMatchLines])
                let nsText = text as NSString
                var lastIndex = 0
                var descriptions: [String] = []
                let matches =
                    regex?.matches(
                        in: text, options: [], range: NSRange(location: 0, length: nsText.length))
                    ?? []
                for match in matches {
                    let range = NSRange(
                        location: lastIndex, length: match.range.location - lastIndex)
                    let part = nsText.substring(with: range).trimmingCharacters(
                        in: .whitespacesAndNewlines)
                    if !part.isEmpty { descriptions.append(part) }
                    lastIndex = match.range.location + match.range.length
                }
                // Add the last segment
                let lastPart = nsText.substring(from: lastIndex).trimmingCharacters(
                    in: .whitespacesAndNewlines)
                if !lastPart.isEmpty { descriptions.append(lastPart) }
                if descriptions.count == pages.count {
                    return descriptions
                }
            }
        } catch {
            AIErrorManager.logError(
                error, source: "StoryProcessor",
                additionalInfo: "Failed to generate AI-based illustration descriptions")
        }
        return generateFallbackDescriptions(pages: pages, theme: theme)
    }

    /// Generates fallback illustration descriptions when AI-based generation
    /// fails
    /// - Parameters:
    ///   - pages: The paginated story pages
    ///   - theme: The overall theme of the story
    /// - Returns: Array of contextual descriptions, one for each page
    private func generateFallbackDescriptions(
        pages: [Page],
        theme: String
    ) -> [String] {
        return pages.enumerated().map { index, page in
            PromptBuilder.buildFallbackIllustrationPrompt(
                page: page, pageIndex: index, pages: pages, theme: theme)
        }
    }

    // MARK: - Illustration Generation

    /// Iterates through pages and calls the illustration service. Handles
    /// errors with graceful fallbacks.
    /// This method no longer throws errors but handles them internally with
    /// fallbacks.
    private func generateIllustrationsForPages(
        _ pages: inout [Page],
        theme: String,
        usePreprocessedDescriptions: Bool = false,
        visualGuide: VisualGuide? = nil,
        collectionContext: CollectionVisualContext? = nil
    ) async {
        AIErrorManager.logError(
            NSError(
                domain: "StoryProcessor", code: 0,
                userInfo: [
                    NSLocalizedDescriptionKey:
                        "Informational: Starting illustration generation for \(pages.count) pages"
                ]
            ),
            source: "StoryProcessor",
            additionalInfo: "Starting illustration generation"
        )

        // First, prepare all the prompts to ensure we have consistent descriptions
        for i in pages.indices {
            if pages[i].imagePrompt == nil {
                // If no image prompt is set from illustrations XML, generate a description
                // from the page content
                pages[i].imagePrompt = pages[i].content
            } else {
                // Add page context to the existing prompt to ensure it includes all relevant information
                let enhancedPrompt = enhanceIllustrationPrompt(
                    existingPrompt: pages[i].imagePrompt!,
                    pageIndex: i,
                    totalPages: pages.count,
                    theme: theme
                )
                pages[i].imagePrompt = enhancedPrompt
            }
        }

        // Now generate the illustrations using the prepared prompts
        for i in pages.indices {
            if i > 0 {
                do {
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                } catch {
                    AIErrorManager.logError(
                        error, source: "StoryProcessor",
                        additionalInfo: "Task.sleep failed"
                    )
                }
            }

            do {
                let imagePrompt = pages[i].imagePrompt!
                print(
                    "[StoryProcessor] Generating illustration for page \(i+1) with prompt: \(imagePrompt.prefix(100))..."
                )

                // Note: Legacy illustration path approach - this service uses older file-based storage
                
                // Generate illustration using the enhanced prompt with proper references
                // Legacy illustration generation - StoryProcessor uses older file-based service
                // TODO: Update to use SimpleIllustrationService with embedded storage
                let relativePath = try await illustrationService.generateIllustration(
                    for: imagePrompt,
                    pageNumber: i + 1,
                    totalPages: pages.count,
                    previousIllustrationPath: nil, // Removed legacy parameter
                    visualGuide: visualGuide,
                    globalReferenceImagePath: nil,  // Global reference not used during initial story creation
                    collectionContext: collectionContext
                )

                if let relativePath = relativePath {
                    // Note: This legacy approach stores file paths - app now uses embedded storage
                    pages[i].illustrationStatus = .ready
                } else {
                    AIErrorManager.logError(
                        NSError(
                            domain: "StoryProcessor", code: 1,
                            userInfo: [
                                NSLocalizedDescriptionKey: "Illustration service returned nil"
                            ]
                        ),
                        source: "StoryProcessor",
                        additionalInfo: "Marking as failed for page \(pages[i].pageNumber)"
                    )
                    pages[i].illustrationStatus = .failed
                }
            } catch {
                AIErrorManager.logError(
                    error, source: "StoryProcessor",
                    additionalInfo:
                        "Failed to generate illustration for page \(pages[i].pageNumber)"
                )
                // Legacy path storage removed - now using embedded storage
                pages[i].illustrationStatus = .failed
            }
        }
    }

    /// Enhances an illustration prompt with context if needed
    private func enhanceIllustrationPrompt(
        existingPrompt: String,
        pageIndex: Int,
        totalPages: Int,
        theme: String
    ) -> String {
        // If the prompt is already detailed (more than 150 characters), assume it's good
        if existingPrompt.count > 150 {
            return existingPrompt
        }

        // Otherwise, add context for this specific illustration
        return """
            🚫 ABSOLUTELY NO TEXT ALLOWED IN ILLUSTRATION 🚫
            ‼️ CRITICAL: This illustration must be COMPLETELY TEXT-FREE ‼️
            
            Create a detailed illustration for page \(pageIndex + 1) of \(totalPages):

            \(existingPrompt)

            Theme: \(theme)

            IMPORTANT REQUIREMENTS:
            - Follow the description exactly with all specified details
            - Create a vibrant, colorful illustration suitable for a children's book
            - Include rich backgrounds and clear character details as described
            - The illustration should be in landscape (16:9) orientation
            
            🚫 FORBIDDEN ELEMENTS - NEVER INCLUDE:
            ❌ NO text of any kind
            ❌ NO words or letters
            ❌ NO captions or labels
            ❌ NO speech bubbles or dialogue
            ❌ NO written signs or text elements
            ❌ NO story text overlay
            
            ✅ The app displays story text separately below the image
            ✅ Focus ONLY on visual storytelling without ANY written words
            ✅ Create pure visual scenes that communicate through imagery alone
            
            REMINDER: If you include ANY text, the illustration will be rejected!
            """
    }

    // MARK: - Reading Progress

    /// Calculate reading progress as a value between 0.0 and 1.0.
    static func calculateReadingProgress(
        currentPage: Int,
        totalPages: Int
    ) -> Double {  // Make static
        guard totalPages > 0, currentPage > 0 else { return 0.0 }
        // Ensure currentPage doesn't exceed totalPages for calculation
        let validCurrentPage = min(currentPage, totalPages)
        return Double(validCurrentPage) / Double(totalPages)
    }
}

// MARK: - Story Text Formatter (Placeholder)

private class StoryTextFormatter {
    // This class can be expanded to handle additional formatting requirements
    // such as applying styling to specific words, handling quotations, etc.

    func formatText(_ text: String) -> String {
        // Apply any text formatting rules (currently none)
        return text
    }
}
