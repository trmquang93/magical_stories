import SwiftUI
import SwiftData

struct StoryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var storyService: StoryService

    @State private var childName = ""
    @State private var ageGroup = 6  // Default to middle age group (6-8)
    @State private var favoriteCharacter = "🦁"  // Default to lion
    @State private var theme: StoryTheme = .adventure  // Default theme

    @State private var selectedLanguage: String = "English"  // Default language
    private let languages = ["English", "Spanish", "French", "German", "Chinese", "Vietnamese"]
    @State private var isGenerating = false
    @State private var error: Error?
    @State private var showError = false
    // Available age groups
    private let ageGroups = [(3, "3-5"), (6, "6-8"), (9, "9-10")]

    // Available character options
    private let characterOptions = [
        ("🦁", "Lion"),
        ("🐯", "Tiger"),
        ("🐼", "Panda"),
        ("🐰", "Rabbit"),
        ("🦊", "Fox"),
        ("🐶", "Dog"),
        ("🐱", "Cat"),
        ("🐵", "Monkey"),
        ("🦄", "Unicorn"),
        ("🐉", "Dragon"),
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Form Title
                    Text("Create a Magical Story")
                        .font(Theme.Typography.displayMedium)
                        .multilineTextAlignment(.center)
                        .padding(.top, Theme.Spacing.lg)

                    // Form Fields
                    VStack(spacing: Theme.Spacing.md) {
                        // Child's Name
                        MagicalTextField(
                            title: "Child's Name",
                            placeholder: "Enter name",
                            text: $childName
                        )

                        // Age Group
                        MagicalSegmentedPicker(
                            title: "Age Group",
                            options: ageGroups,
                            selection: $ageGroup
                        )

                        // Favorite Character
                        MagicalEmojiPicker(
                            title: "Favorite Character",
                            selection: $favoriteCharacter,
                            emojis: characterOptions
                        )

                        // Story Theme
                        MagicalThemePicker(
                            title: "Story Theme",
                            selection: $theme,
                            themes: StoryTheme.allCases
                        )

                        // Language Selection
                        MagicalSegmentedPicker(
                            title: "Story Language",
                            options: languages.map { ($0, $0) },
                            selection: $selectedLanguage
                        )
                    }
                    .padding(.horizontal, Theme.Spacing.md)

                    // Generate Button
                    PrimaryButton(title: isGenerating ? "Generating..." : "Generate Story") {
                        generateStory()
                    }
                    .disabled(isGenerating || childName.isEmpty)
                    .padding(.horizontal, Theme.Spacing.md)
                    .padding(.top, Theme.Spacing.md)
                }
                .padding(.bottom, Theme.Spacing.xl)
            }
            .navigationTitle("New Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .overlay {
                if isGenerating {
                    MagicalLoadingView(message: "Creating your magical story...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.7))
                        .edgesIgnoringSafeArea(.all)
                }
            }
            .alert("Error", isPresented: $showError, presenting: error) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.localizedDescription)
            }
        }
    }

    private func generateStory() {
        guard !childName.isEmpty else { return }

        // Prepare parameters
        let parameters = StoryParameters(
            childName: childName,
            childAge: ageGroup, // Corrected parameter name
            theme: theme.rawValue, // Corrected type to String using rawValue
            favoriteCharacter: favoriteCharacter
        )

        // Start generation
        isGenerating = true

        // Generate story using StoryService
        Task {
            do {
                _ = try await storyService.generateStory(parameters: parameters) // Assign to _ as story is unused
                await MainActor.run {
                    // On success, dismiss the sheet
                    self.isGenerating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.showError = true
                    self.isGenerating = false
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer()
    StoryFormView()
        .environment(\.modelContext, container.mainContext)
        .environmentObject(try! StoryService(context: container.mainContext))
}
