import SwiftData
import SwiftUI

struct StoryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var storyService: StoryService

    // --- State Variables ---
    @State private var childName = ""
    @State private var selectedAgeRange: String = "3-5"  // Default to first option
    @State private var selectedTheme: StoryTheme = .friendship  // Default to first theme
    @State private var favoriteCharacter = ""  // Added favorite character field
    @State private var storyLength: Double = 2  // Default to Medium (1=Short, 2=Medium, 3=Long)
    @State private var selectedLanguage: String = "en"  // Default language code

    @State private var isGenerating = false
    @State private var error: Error?
    @State private var showError = false
    @State private var animateBackground = false

    // --- Constants based on HTML ---
    private let ageRanges = ["3-5", "6-8", "9-12"]  // Updated age ranges
    private let storyThemes: [StoryTheme] = StoryTheme.allCases
    private let languages = [  // Language codes and display names
        // Common European
        ("en", "English"),
        ("es", "Español"), // Spanish
        ("fr", "Français"), // French
        ("de", "Deutsch"), // German
        ("it", "Italiano"), // Italian
        ("pt", "Português"), // Portuguese
        ("ru", "Русский"), // Russian
        ("pl", "Polski"), // Polish
        ("nl", "Nederlands"), // Dutch
        ("sv", "Svenska"), // Swedish
        // Common Asian
        ("zh", "中文"), // Chinese (Simplified)
        ("ja", "日本語"), // Japanese
        ("ko", "한국어"), // Korean
        ("hi", "हिन्दी"), // Hindi
        ("vi", "Tiếng Việt"), // Vietnamese
        ("th", "ไทย"), // Thai
        ("id", "Bahasa Indonesia"), // Indonesian
        ("ms", "Bahasa Melayu"), // Malay
        ("fil", "Filipino"), // Filipino
        // Middle Eastern / Other
        ("ar", "العربية"), // Arabic
        ("tr", "Türkçe"), // Turkish
    ]
    private let storyLengthLabels = ["Short", "Medium", "Long"]

    // Sample favorite characters for suggestions
    private let characterSuggestions = [
        "Dragon", "Unicorn", "Lion", "Panda", "Superhero",
        "Princess", "Wizard", "Fairy", "Robot", "Dinosaur",
        "Astronaut", "Pirate", "Knight", "Mermaid", "Detective",
    ]

    // Gradient for buttons and accents
    private var primaryGradient: LinearGradient {
        Theme.Colors.primaryGradient
    }

    // Enhanced background gradient
    private var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(hex: "#F3F7FF"),
                Color(hex: "#FFF3F7"),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // --- Body ---
    var body: some View {
        NavigationView {
            ZStack {
                // Background extends to bottom, but respects top safe area
                backgroundView
                    .ignoresSafeArea(.container, edges: .bottom)
                formContentView
            }
            .navigationTitle("Create Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                toolbarContent
            }
            .overlay {
                if isGenerating {
                    loadingOverlay
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
        .onAppear {
            // Start animations when view appears
            withAnimation {
                animateBackground = true
            }
        }
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
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                headerView
                formFieldsView
            }
            .padding(.top, Theme.Spacing.md)
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Create Magic")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(
                        colorScheme == .light
                            ? Color(hex: "#7B61FF") : Color(hex: "#a78bfa"))

                Text("Personalize your magical story")
                    .font(.system(size: 16))
                    .foregroundColor(
                        Color(colorScheme == .light ? .black : .white).opacity(0.6))
            }

            Spacer()

            // Animated magic wand icon
            Image(systemName: "wand.and.stars")
                .font(.system(size: 32))
                .foregroundStyle(primaryGradient)
                .rotationEffect(Angle(degrees: animateBackground ? 5 : -5))
                .animation(
                    Animation.easeInOut(duration: 2).repeatForever(
                        autoreverses: true),
                    value: animateBackground
                )
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private var formFieldsView: some View {
        VStack(spacing: Theme.Spacing.lg) {
            childNameField
            characterField
            ageRangeField
            themeField
            storyLengthField
            languageField
            generateButton
        }
    }

    private var childNameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "person.fill")
                    .foregroundColor(Color(hex: "#7B61FF"))
                Text("Child's Name")
                    .font(.headline)
            }

            TextField(
                "Enter child's name",
                text: $childName
            )
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        colorScheme == .light
                            ? .white : Color(hex: "#1F2937"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#E2E8F0"), lineWidth: 1)
            )
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private var characterField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(Color(hex: "#7B61FF"))
                Text("Favorite Character")
                    .font(.headline)
            }

            TextField(
                "Enter a character (dragon, princess...)",
                text: $favoriteCharacter
            )
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        colorScheme == .light ? .white : Color(hex: "#1F2937"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#E2E8F0"), lineWidth: 1)
            )

            // Character suggestions
            charactersScrollView
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private var charactersScrollView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Theme.Spacing.sm) {
                ForEach(characterSuggestions, id: \.self) { character in
                    Button {
                        favoriteCharacter = character
                    } label: {
                        Text(character)
                            .font(.system(size: 14, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(
                                        favoriteCharacter == character
                                            ? AnyShapeStyle(Theme.Colors.primaryGradient)
                                            : AnyShapeStyle(
                                                colorScheme == .light
                                                    ? Color(hex: "#F0F4F8")
                                                    : Color(hex: "#2D3748")
                                            )
                                    )
                            )
                            .foregroundColor(
                                favoriteCharacter == character
                                    ? .white
                                    : (colorScheme == .light
                                        ? Color(hex: "#4A5568")
                                        : Color(hex: "#CBD5E0")))
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var ageRangeField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "person.2.fill")
                    .foregroundColor(Color(hex: "#7B61FF"))
                Text("Age Range")
                    .font(.headline)
            }

            // Simple segmented control
            Picker("Age Range", selection: $selectedAgeRange) {
                ForEach(ageRanges, id: \.self) { range in
                    Text(range).tag(range)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.vertical, 8)
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private var themeField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "book.fill")
                    .foregroundColor(Color(hex: "#7B61FF"))
                Text("Story Theme")
                    .font(.headline)
            }

            // Simple grid for themes
            themeGrid
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private var themeGrid: some View {
        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: Theme.Spacing.md
        ) {
            ForEach(storyThemes) { theme in
                Button {
                    selectedTheme = theme
                } label: {
                    themeGridItem(theme: theme)
                }
            }
        }
    }

    private func themeGridItem(theme: StoryTheme) -> some View {
        VStack {
            Image(systemName: getIconName(for: theme))
                .font(.system(size: 24))
                .foregroundColor(
                    colorScheme == .light ? .white : .white
                )
                .frame(width: 48, height: 48)
                .background(
                    Circle()
                        .fill(
                            selectedTheme == theme
                                ? AnyShapeStyle(Theme.Colors.primaryGradient)
                                : AnyShapeStyle(Color(hex: "#A3AED0")))
                )
            Text(theme.rawValue.capitalized)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(
                    selectedTheme == theme
                        ? Color(hex: "#7B61FF")
                        : (colorScheme == .light
                            ? Color(hex: "#4A5568")
                            : Color(hex: "#CBD5E0")))
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    colorScheme == .light
                        ? .white : Color(hex: "#1F2937")
                )
                .shadow(
                    color: Color.black.opacity(0.05), radius: 4,
                    x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    selectedTheme == theme
                        ? Color(hex: "#7B61FF") : .clear,
                    lineWidth: 2)
        )
    }

    private var storyLengthField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "text.book.closed.fill")
                    .foregroundColor(Color(hex: "#7B61FF"))
                Text("Story Length")
                    .font(.headline)
            }

            // Length slider
            storyLengthSlider
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private var storyLengthSlider: some View {
        VStack(spacing: 12) {
            Slider(value: $storyLength, in: 1...3, step: 1)
                .accentColor(Color(hex: "#7B61FF"))

            // Labels
            HStack {
                ForEach(0..<storyLengthLabels.count, id: \.self) { index in
                    Text(storyLengthLabels[index])
                        .font(
                            .system(
                                size: 14,
                                weight: Int(storyLength) == index + 1
                                    ? .semibold : .regular)
                        )
                        .foregroundColor(
                            Int(storyLength) == index + 1
                                ? Color(hex: "#7B61FF")
                                : (colorScheme == .light
                                    ? Color(hex: "#6B7280")
                                    : Color(hex: "#9CA3AF"))
                        )
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    colorScheme == .light ? .white : Color(hex: "#1F2937"))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(hex: "#E2E8F0"), lineWidth: 1)
        )
    }

    private var languageField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "globe")
                    .foregroundColor(Color(hex: "#7B61FF"))
                Text("Story Language")
                    .font(.headline)
            }

            // Simple language picker
            Picker("Language", selection: $selectedLanguage) {
                ForEach(languages, id: \.0) { code, name in
                    Text(name).tag(code)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        colorScheme == .light ? .white : Color(hex: "#1F2937"))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(hex: "#E2E8F0"), lineWidth: 1)
            )
        }
        .padding(.horizontal, Theme.Spacing.lg)
    }

    private var generateButton: some View {
        VStack(spacing: 12) {
            Button {
                generateStory()
            } label: {
                ZStack {
                    // Gradient background
                    RoundedRectangle(cornerRadius: 28)
                        .fill(primaryGradient)
                        .overlay(
                            RoundedRectangle(cornerRadius: 28)
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )

                    // Button content
                    HStack(spacing: 16) {
                        if isGenerating {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(0.8)
                        } else {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.15))
                                    .frame(width: 36, height: 36)

                                Image(systemName: "wand.and.stars.inverse")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        }

                        Text(
                            isGenerating
                                ? "Creating Magic..." : "Generate Magical Story"
                        )
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 64)
                .shadow(
                    color: Color(hex: "#7B61FF").opacity(0.4), radius: 15, x: 0,
                    y: 8)
            }
            .disabled(isGenerating || childName.isEmpty)
            .scaleEffect(childName.isEmpty ? 0.98 : 1.0)
            .animation(
                .spring(response: 0.3, dampingFraction: 0.7),
                value: childName.isEmpty)

            if childName.isEmpty {
                Text("Please enter the child's name to continue")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#FF617B"))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.lg)
                    .padding(.top, 4)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .padding(.top, Theme.Spacing.md)
        .padding(.bottom, Theme.Spacing.xxl)
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
                                    ? Color.white.opacity(0.8)
                                    : Color(hex: "#2D3748").opacity(0.8)
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
            }

            ToolbarItem(placement: .principal) {
                Text("Magical Story Creator")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(
                        colorScheme == .light ? Color(hex: "#7B61FF") : Color(hex: "#a78bfa"))
            }
        }
    }

    private var loadingOverlay: some View {
        ZStack {
            // Overlay background with blur
            Rectangle()
                .fill(
                    colorScheme == .light
                        ? Color.white.opacity(0.8) : Color.black.opacity(0.8)
                )
                .background(.ultraThinMaterial)
                .ignoresSafeArea(.container)

            VStack(spacing: Theme.Spacing.xl) {
                // Animated magic wand
                loadingWandAnimation

                // Loading text
                loadingText

                // Animated dots
                loadingDots
            }
            .padding(Theme.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(
                        colorScheme == .light
                            ? Color.white.opacity(0.8)
                            : Color(hex: "#1F2937").opacity(0.8)
                    )
                    .background(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.15), radius: 16, x: 0, y: 8)
        }
        .transition(.opacity)
        .zIndex(100)
    }

    private var loadingWandAnimation: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(primaryGradient)
                .frame(width: 100, height: 100)
                .blur(radius: 20)
                .opacity(0.7)

            // Spinner
            Circle()
                .trim(from: 0, to: 0.8)
                .stroke(
                    AngularGradient(
                        colors: [Color(hex: "#7B61FF"), Color(hex: "#FF617B")],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 80, height: 80)
                .rotationEffect(Angle(degrees: isGenerating ? 360 : 0))
                .animation(
                    Animation.linear(duration: 2).repeatForever(
                        autoreverses: false), value: isGenerating)

            // Inner circle
            Circle()
                .fill(colorScheme == .light ? .white : Color(hex: "#1F2937"))
                .frame(width: 60, height: 60)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

            // Magic wand icon
            Image(systemName: "wand.and.stars")
                .font(.system(size: 24))
                .foregroundStyle(primaryGradient)
        }
    }

    private var loadingText: some View {
        VStack(spacing: Theme.Spacing.md) {
            Text("Creating your magical story...")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(
                    colorScheme == .light
                        ? Color(hex: "#4A5568") : Color(hex: "#E2E8F0")
                )
                .multilineTextAlignment(.center)

            Text("Weaving enchantment and wonder just for \(childName)...")
                .font(.system(size: 16))
                .foregroundColor(
                    colorScheme == .light
                        ? Color(hex: "#6B7280") : Color(hex: "#9CA3AF")
                )
                .multilineTextAlignment(.center)
                .opacity(0.8)
        }
        .padding(.horizontal, Theme.Spacing.xl)
    }

    private var loadingDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(primaryGradient)
                    .frame(width: 10, height: 10)
                    .opacity(0.7)
                    .scaleEffect(isGenerating ? 1 : 0.5)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: isGenerating
                    )
            }
        }
    }

    private var errorAlertButtons: some View {
        VStack {
            Button {
                showError = false
            } label: {
                Text("Try Again")
                    .bold()
                    .foregroundColor(Color(hex: "#7B61FF"))
            }

            Button(role: .cancel) {
                showError = false
            } label: {
                Text("Cancel")
            }
        }
    }

    // MARK: - Helper Functions

    private func getIconName(for theme: StoryTheme) -> String {
        switch theme {
        case .friendship: return "heart.fill"
        case .adventure: return "map.fill"
        case .learning: return "book.fill"
        case .courage: return "shield.fill"
        // Add cases for other themes as needed
        default: return "star.fill"
        }
    }

    private func alignment(for index: Int, count: Int) -> Alignment {
        switch index {
        case 0: return .leading
        case count - 1: return .trailing
        default: return .center
        }
    }

    private func generateStory() {
        guard !childName.isEmpty else { return }

        // Convert age range string to an approximate integer age
        let estimatedAge: Int
        let components = selectedAgeRange.split(separator: "-").compactMap { Int($0) }
        if components.count == 2 {
            estimatedAge = (components[0] + components[1]) / 2
        } else {
            estimatedAge = 6  // Default age if parsing fails
        }

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
            ? favoriteCharacter : characterSuggestions.randomElement() ?? "Lion"

        // Create emotional themes based on age (optional parameter)
        var emotionalThemes: [String]? = nil
        if estimatedAge > 6 {
            emotionalThemes = ["empathy", "courage", "curiosity"]
        }

        // Prepare parameters
        let parameters = StoryParameters(
            childName: childName,
            childAge: estimatedAge,
            theme: selectedTheme.rawValue,
            favoriteCharacter: character,
            storyLength: lengthString,
            developmentalFocus: [.emotionalIntelligence, .problemSolving],  // Add developmental focus
            interactiveElements: true,  // Add interactive elements
            emotionalThemes: emotionalThemes  // Add emotional themes for older children
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
                for: StoryModel.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            ))

        let mockStoryService = MockStoryService(context: mockModelContext)

        StoryFormView()
            .environmentObject(mockStoryService)
            .preferredColorScheme(.light)
            .previewDisplayName("Light Mode")

        StoryFormView()
            .environmentObject(mockStoryService)
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
    }
}

// Mock StoryService for Previews
class MockStoryService: StoryService {
    init(context: ModelContext) {
        try! super.init(
            apiKey: "",
            context: context
        )
    }

    override func generateStory(parameters: StoryParameters) async throws -> Story {
        try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
        print("Mock generating story with params: \(parameters)") // Includes languageCode now

        return Story(
            id: UUID(),
            title: "Mock Story: \(parameters.childName)",
            pages: [],
            parameters: parameters,
            timestamp: Date()
        )
    }
}
