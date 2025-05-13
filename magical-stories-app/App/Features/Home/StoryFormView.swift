import SwiftData
import SwiftUI
import KeyboardAvoider

struct StoryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var storyService: StoryService

    // State Variables
    @State private var childName: String? = UserDefaults.standard.string(forKey: "childName")
    @State private var selectedAgeRange: String = "3-5"
    @State private var selectedTheme: StoryTheme = .friendship
    @State private var favoriteCharacter = ""
    @State private var storyLength: Double = 2
    @State private var selectedLanguage: String = "en"
    @State private var isGenerating = false
    @State private var error: Error?
    @State private var showError = false
    @State private var animateBackground = false
    @FocusState private var focusedField: FormField?

    // Enum for form field focus tracking
    enum FormField {
        case childName, favoriteCharacter
    }

    // Constants
    private let ageRanges = ["3-5", "6-8", "9-12"]
    private let storyThemes: [StoryTheme] = StoryTheme.allCases
    private let storyLengthLabels = ["Short", "Medium", "Long"]
    private let characterSuggestions = [
        "Dragon", "Unicorn", "Lion", "Panda", "Superhero", "Princess",
        "Wizard", "Fairy", "Robot", "Dinosaur", "Astronaut", "Pirate",
        "Knight", "Mermaid", "Detective",
    ]
    private let languages: [(String, String)] = StoryLanguages.languageOptions

    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [Color(hex: "#F3F7FF"), Color(hex: "#FFF3F7")],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    var body: some View {
        NavigationView {
            ZStack {
                backgroundView
                    .ignoresSafeArea(.container, edges: .bottom)
                formContentView
            }
            .navigationTitle("Create Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .overlay {
                if isGenerating {
                    LoadingOverlayView(
                        isLoading: isGenerating,
                        title: "Creating your magical story...",
                        subtitle: "Weaving enchantment and wonder just for \(childName ?? "")..."
                    )
                }
            }
            .alert("Story Creation Error", isPresented: $showError, presenting: error) { _ in
                errorAlertButtons
            } message: { error in
                Text(
                    "We couldn't create your story: \(error.localizedDescription)\n\nPlease try again later."
                )
            }
        }
        .accentColor(Color(hex: "#7B61FF"))
        .onAppear { withAnimation { animateBackground = true } }
    }

    // MARK: - View Components
    private var backgroundView: some View {
        Group {
            if colorScheme == .light {
                backgroundGradient
                    .hueRotation(Angle(degrees: animateBackground ? 10 : 0))
                    .animation(
                        Animation.easeInOut(duration: 5).repeatForever(autoreverses: true),
                        value: animateBackground
                    )
                    .onAppear { animateBackground = true }
            } else {
                Color(hex: "#121828")
            }
        }
    }

    private var formContentView: some View {
        KeyboardAvoider {
            VStack(alignment: .leading, spacing: UITheme.Spacing.lg) {
                FormHeader(animateBackground: $animateBackground)
                formFieldsView
            }
            .padding(.top, UITheme.Spacing.md)
        }
        .accessibilityIdentifier("formContentView")
    }

    private var formFieldsView: some View {
        VStack(spacing: UITheme.Spacing.lg) {
            ChildNameField(childName: $childName)
                .focused($focusedField, equals: .childName)
            CharacterField(
                favoriteCharacter: $favoriteCharacter,
                characterSuggestions: characterSuggestions,
                focusedField: $focusedField
            )
            .focused($focusedField, equals: .favoriteCharacter)
            AgeRangeField(selectedAgeRange: $selectedAgeRange, ageRanges: ageRanges)
            ThemeField(selectedTheme: $selectedTheme, storyThemes: storyThemes)
            StoryLengthField(storyLength: $storyLength, storyLengthLabels: storyLengthLabels)
            LanguageField(selectedLanguage: $selectedLanguage, languages: languages)
            GenerateButton(
                isGenerating: isGenerating,
                childName: childName,
                action: generateStory
            )
        }
    }

    private var toolbarContent: some ToolbarContent {
        Group {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    ZStack {
                        Circle()
                            .fill(
                                colorScheme == .light
                                    ? Color.white.opacity(0.8) : Color(hex: "#2D3748").opacity(0.8)
                            )
                            .frame(width: 36, height: 36)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                        Image(systemName: "arrow.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(
                                colorScheme == .light
                                    ? Color(hex: "#4A5568") : Color(hex: "#E2E8F0"))
                    }
                }
                .accessibilityLabel("Back")
            }

            ToolbarItem(placement: .principal) {
                Text("Magical Story Creator")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(
                        colorScheme == .light ? Color(hex: "#7B61FF") : Color(hex: "#a78bfa"))
            }
        }
    }

    private var errorAlertButtons: some View {
        VStack {
            Button {
                showError = false
            } label: {
                Text("Try Again").bold().foregroundColor(Color(hex: "#7B61FF"))
            }
            Button(role: .cancel) {
                showError = false
            } label: {
                Text("Cancel")
            }
        }
    }

    // MARK: - Helper Functions
    private func generateStory() {
        // Keyboard is automatically dismissed by KeyboardAvoider
        
        // Convert age range string to an approximate integer age
        let estimatedAge: Int
        let components = selectedAgeRange.split(separator: "-").compactMap { Int($0) }
        estimatedAge = components.count == 2 ? (components[0] + components[1]) / 2 : 6

        // Convert story length Double to a qualitative string
        let lengthString: String
        switch Int(storyLength) {
        case 1: lengthString = "Short"
        case 3: lengthString = "Long"
        default: lengthString = "Medium"
        }

        // Use provided favorite character or select a random one
        let character =
            !favoriteCharacter.isEmpty
            ? favoriteCharacter
            : characterSuggestions.randomElement() ?? "Lion"

        // Create emotional themes based on age (optional parameter)
        let emotionalThemes: [String]? =
            estimatedAge > 6 ? ["empathy", "courage", "curiosity"] : nil

        let parameters = StoryParameters(
            childName: childName,
            childAge: estimatedAge,
            theme: selectedTheme.rawValue,
            favoriteCharacter: character,
            storyLength: lengthString,
            developmentalFocus: [.emotionalIntelligence, .problemSolving],
            interactiveElements: true,
            emotionalThemes: emotionalThemes,
            languageCode: selectedLanguage
        )

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isGenerating = true
        }

        Task {
            do {
                _ = try await storyService.generateStory(parameters: parameters)
                await MainActor.run {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        self.isGenerating = false
                    }
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.showError = true
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        self.isGenerating = false
                    }
                    print("Error generating story: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Preview
struct StoryFormView_Previews: PreviewProvider {
    static var previews: some View {
        let mockModelContext = ModelContext(
            try! ModelContainer(
                for: Story.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ))
        StoryFormView()
            .environmentObject(MockStoryService(context: mockModelContext))
            .preferredColorScheme(.light)
    }
}
