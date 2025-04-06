import Foundation
import SwiftUI


// Removed ImageReference struct as it's replaced by direct URL/prompt storage in Page for now.
// MARK: - Story Processor
@MainActor
class StoryProcessor {
    // Configuration constants
    static let maxPageContentLength = 500 // Approximate character limit per page
    static let paragraphBreakPattern = "\n\n" // How paragraphs are delimited
    static let maxParagraphsPerPage = 2 // Maximum paragraphs allowed on a single page (Adjusted from 3)

    private let formatter = StoryTextFormatter() // For potential future text formatting
    let illustrationService: IllustrationServiceProtocol // Injected via initializer

    init(illustrationService: IllustrationServiceProtocol) {
        self.illustrationService = illustrationService
    }

    // MARK: - Segmentation

    /// Process raw story content into structured Page objects.
    /// Process raw story content into structured Page objects and generate illustrations.
    func processIntoPages(_ content: String, theme: String) async throws -> [Page] {
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedContent.isEmpty else {
            return [] // Return empty if content is just whitespace
        }

        // Split the content into paragraphs based on double newlines
        let paragraphs = trimmedContent.components(separatedBy: Self.paragraphBreakPattern)
                                      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) } // Trim each paragraph
                                      .filter { !$0.isEmpty } // Remove empty paragraphs

        // If the entire story is short and fits within limits, return as a single page
        if trimmedContent.count <= Self.maxPageContentLength && paragraphs.count <= Self.maxParagraphsPerPage {
             var pages = [Page(content: trimmedContent, pageNumber: 1)]
             // Generate illustrations even for single-page stories
             try await generateIllustrationsForPages(&pages, theme: theme)
             return pages
        }

        // Otherwise, build pages paragraph by paragraph
        var pages = buildPagesFromParagraphs(paragraphs)
        // Generate illustrations for multi-page stories
        try await generateIllustrationsForPages(&pages, theme: theme)
        return pages
    }

    /// Build pages from an array of paragraphs, respecting length and paragraph count limits.
    private func buildPagesFromParagraphs(_ paragraphs: [String]) -> [Page] {
        var pages = [Page]()
        var currentPageContent = ""
        var currentParagraphCount = 0
        var currentPageNumber = 1

        for paragraph in paragraphs {
            // Handle very long paragraphs by splitting them first
            if paragraph.count > Self.maxPageContentLength {
                // If the current page has content, finalize it before adding split pages
                if !currentPageContent.isEmpty {
                    pages.append(Page(
                        content: currentPageContent, // Already trimmed
                        pageNumber: currentPageNumber
                    ))
                    currentPageNumber += 1
                    currentPageContent = ""
                    currentParagraphCount = 0
                }

                // Split the long paragraph and add its pages
                let splitPages = splitLongParagraph(paragraph, startingPageNumber: currentPageNumber)
                if !splitPages.isEmpty {
                    pages.append(contentsOf: splitPages)
                    currentPageNumber += splitPages.count // Update page number based on how many pages were added
                }
                continue // Move to the next paragraph
            }

            // Check if adding this paragraph would exceed page limits
            let potentialContent = currentPageContent.isEmpty
                ? paragraph
                : currentPageContent + Self.paragraphBreakPattern + paragraph

            // Start a new page if:
            // 1. The current page is not empty AND
            // 2. Adding the new paragraph exceeds max length OR the current page already has max paragraphs
            if !currentPageContent.isEmpty &&
               (potentialContent.count > Self.maxPageContentLength || currentParagraphCount >= Self.maxParagraphsPerPage) {
                // Finalize the current page
                pages.append(Page(
                    content: currentPageContent, // Already trimmed
                    pageNumber: currentPageNumber
                ))

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
            pages.append(Page(
                content: currentPageContent, // Already trimmed
                pageNumber: currentPageNumber
            ))
        }

        return pages
    }

    /// Split a very long paragraph into multiple pages based on maxPageContentLength.
    /// Tries to split at sentence endings or word boundaries.
    private func splitLongParagraph(_ paragraph: String, startingPageNumber: Int) -> [Page] {
        var pages = [Page]()
        var remainingContent = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
        var pageNumber = startingPageNumber

        while !remainingContent.isEmpty {
            var splitIndex = remainingContent.endIndex
            var pageContent = ""

            // If remaining content is within limit, use it all for the last page
            if remainingContent.count <= Self.maxPageContentLength {
                pageContent = remainingContent
                remainingContent = "" // No more content left
            } else {
                // Find a suitable split point within the limit
                let potentialSplitEndIndex = remainingContent.index(remainingContent.startIndex, offsetBy: Self.maxPageContentLength)
                let potentialSplitRange = remainingContent.startIndex..<potentialSplitEndIndex

                // Prefer splitting at the last sentence end (".", "!", "?") within the range
                if let sentenceEndIndex = remainingContent.rangeOfCharacter(from: CharacterSet(charactersIn: ".!?"), options: .backwards, range: potentialSplitRange)?.upperBound {
                    splitIndex = sentenceEndIndex
                }
                // Otherwise, split at the last word boundary (space or newline) within the range
                else if let wordEndIndex = remainingContent.rangeOfCharacter(from: .whitespacesAndNewlines, options: .backwards, range: potentialSplitRange)?.lowerBound {
                     // Ensure we don't create an empty page if the split is at the very beginning
                    if remainingContent.distance(from: remainingContent.startIndex, to: wordEndIndex) > 0 {
                         splitIndex = wordEndIndex
                    } else {
                        // If the first word is already too long or no space found, force split at max length
                        splitIndex = potentialSplitEndIndex
                    }
                }
                // If no sentence or word boundary found (very long word), force split at max length
                else {
                    splitIndex = potentialSplitEndIndex
                }

                pageContent = String(remainingContent[..<splitIndex])
                remainingContent = String(remainingContent[splitIndex...])
            }

            // Add the created page (trimming just in case)
            let trimmedPageContent = pageContent.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedPageContent.isEmpty {
                 pages.append(Page(
                    content: trimmedPageContent,
                    pageNumber: pageNumber
                 ))
                 pageNumber += 1
            }
            // Trim remaining content for the next iteration
            remainingContent = remainingContent.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Note: Illustrations for split long paragraphs are handled by the main call
        // in processIntoPages after buildPagesFromParagraphs returns.
        return pages
    }

    // MARK: - Illustration Generation

    /// Iterates through pages and calls the illustration service.
    private func generateIllustrationsForPages(_ pages: inout [Page], theme: String) async throws {
        // No need for guard let anymore, illustrationService is non-optional

        print("StoryProcessor: Starting illustration generation for \(pages.count) pages...")

        for i in pages.indices {
            // let pageContent = pages[i].content // This was unused after refactor
            // Combine page content and theme for the prompt
            // Use page content directly, pass theme separately
            let pageText = pages[i].content
            pages[i].imagePrompt = pageText // Store the page text used for the prompt

            // Introduce a delay before the API call, especially after the first page
            if i > 0 { // Only delay after the first call
                do {
                    // Delay for 1 second (1_000_000_000 nanoseconds)
                    try await Task.sleep(nanoseconds: 1_000_000_000)
                    print("--- StoryProcessor: Added 1-second delay before generating illustration for page \(pages[i].pageNumber) ---")
                } catch {
                    // Handle potential cancellation or other errors during sleep
                    print("--- StoryProcessor: Task.sleep failed: \(error.localizedDescription). Proceeding without delay. ---")
                }
            }

            print("StoryProcessor: Generating illustration for page \(pages[i].pageNumber) with theme: \(theme), content: \"\(pageText.prefix(80))...\"")

            do {
                // Use the updated service method signature
                let url = try await illustrationService.generateIllustration(for: pageText, theme: theme)
                pages[i].illustrationURL = url
                if let url = url {
                    print("StoryProcessor: Successfully generated illustration for page \(pages[i].pageNumber): \(url.absoluteString)")
                } else {
                    print("StoryProcessor: Illustration generation returned nil for page \(pages[i].pageNumber).")
                }
            } catch {
                print("StoryProcessor: Error generating illustration for page \(pages[i].pageNumber): \(error)")
                // Decide how to handle errors - store nil, retry, etc.
                // Storing nil for now.
                pages[i].illustrationURL = nil
            }
        }
        print("StoryProcessor: Finished illustration generation.")
    }

    // MARK: - Reading Progress

    /// Calculate reading progress as a value between 0.0 and 1.0.
    static func calculateReadingProgress(currentPage: Int, totalPages: Int) -> Double { // Make static
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

