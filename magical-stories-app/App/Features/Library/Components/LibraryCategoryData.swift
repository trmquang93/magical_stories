import SwiftUI

struct LibraryCategory: Identifiable {
    let id = UUID()
    let name: String
    let icon: String  // SF Symbol
    let color: Color
    let storyCount: Int

    static let all: [LibraryCategory] = [
        LibraryCategory(
            name: "Fantasy",
            icon: "sparkles",
            color: Color(red: 1.0, green: 0.38, blue: 0.48),
            storyCount: 0
        ),
        LibraryCategory(
            name: "Animals",
            icon: "pawprint",
            color: Color(red: 0.31, green: 0.55, blue: 1.0),
            storyCount: 0
        ),
        LibraryCategory(
            name: "Bedtime",
            icon: "moon.stars",
            color: Color(red: 0.48, green: 0.38, blue: 1.0),
            storyCount: 0
        ),
        LibraryCategory(
            name: "Adventure",
            icon: "map",
            color: Color(red: 0.0, green: 0.72, blue: 0.66),
            storyCount: 0
        ),
    ]
}
