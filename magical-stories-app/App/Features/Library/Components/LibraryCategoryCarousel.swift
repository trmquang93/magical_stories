import SwiftUI

struct LibraryCategoryCarousel: View {
    let categories: [LibraryCategory]
    let selectedCategoryName: String?
    let onSelect: (String?) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: UITheme.Spacing.md) {
                ForEach(categories) { category in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if selectedCategoryName == category.name {
                                onSelect(nil)
                            } else {
                                onSelect(category.name)
                            }
                        }
                    }) {
                        CategoryCarouselCard(
                            category: category,
                            isSelected: category.name == selectedCategoryName
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .accessibilityIdentifier(
                        "LibraryView_CategoryCard_\(category.name)"
                    )
                    .accessibilityLabel(
                        "Category: \(category.name), \(category.storyCount) stories"
                    )
                }
            }
            .padding(.horizontal, UITheme.Spacing.lg)
            .padding(.vertical, UITheme.Spacing.sm)
        }
    }
}
