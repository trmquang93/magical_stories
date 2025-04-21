import SwiftUI
import SwiftData

struct StoryFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var storyService: StoryService
    
    // --- State Variables ---
    @State private var childName = ""
    @State private var selectedAgeRange: String = "3-5" // Default to first option
    @State private var selectedTheme: StoryTheme = .friendship // Default to first theme
    @State private var favoriteCharacter = "" // Added favorite character field
    @State private var storyLength: Double = 2 // Default to Medium (1=Short, 2=Medium, 3=Long)
    @State private var selectedLanguage: String = "en" // Default language code
    
    @State private var isGenerating = false
    @State private var error: Error?
    @State private var showError = false
    
    // --- Constants based on HTML ---
    private let ageRanges = ["3-5", "6-8", "9-12"] // Updated age ranges
    private let storyThemes: [StoryTheme] = StoryTheme.allCases
    private let languages = [ // Language codes and display names
        ("en", "English"),
        ("es", "Español"),
        ("fr", "Français"),
        ("de", "Deutsch"),
        ("it", "Italiano"),
        ("pt", "Português"),
        ("ru", "Русский"),
        ("zh", "中文"),
        ("ja", "日本語"),
        ("ko", "한국어"),
        ("hi", "हिन्दी"),
        ("ar", "العربية")
    ]
    private let storyLengthLabels = ["Short", "Medium", "Long"]
    
    // Sample favorite characters for suggestions
    private let characterSuggestions = [
        "Dragon", "Unicorn", "Lion", "Panda", "Superhero", 
        "Princess", "Wizard", "Fairy", "Robot", "Dinosaur",
        "Astronaut", "Pirate", "Knight", "Mermaid", "Detective"
    ]
    
    // Gradient for buttons and accents
    private var primaryGradient: LinearGradient {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(red: 123/255, green: 97/255, blue: 255/255), // #7B61FF
                Color(red: 255/255, green: 97/255, blue: 123/255)  // #FF617B
            ]),
            startPoint: .leading,
            endPoint: .trailing
        )
    }
    
    // --- Body ---
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: UITheme.Spacing.lg) {
                    // --- Form Fields ---
                    Group {
                        // Child's Name
                        FormField(title: "Child's Name") {
                            TextField("Enter child's name", text: $childName)
                                .inputFieldStyle()
                        }
                        
                        // Age Range
                        FormField(title: "Age Range") {
                            HStack(spacing: UITheme.Spacing.sm) {
                                ForEach(ageRanges, id: \.self) { range in
                                    Button(range + " years") {
                                        selectedAgeRange = range
                                    }
                                    .buttonStyle(SegmentedButtonStyle(isSelected: selectedAgeRange == range))
                                }
                            }
                        }
                        
                        // Favorite Character
                        FormField(title: "Favorite Character") {
                            VStack(spacing: UITheme.Spacing.xs) {
                                TextField("Enter favorite character", text: $favoriteCharacter)
                                    .inputFieldStyle()
                                
                                // Character suggestions
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: UITheme.Spacing.xs) {
                                        ForEach(characterSuggestions, id: \.self) { character in
                                            Button(character) {
                                                favoriteCharacter = character
                                            }
                                            .padding(.horizontal, UITheme.Spacing.sm)
                                            .padding(.vertical, UITheme.Spacing.xs)
                                            .background(UITheme.Colors.surfaceSecondary)
                                            .cornerRadius(UITheme.Layout.cornerRadiusSmall)
                                            .foregroundColor(UITheme.Colors.textSecondary)
                                        }
                                    }
                                    .padding(.vertical, UITheme.Spacing.xs)
                                }
                            }
                        }
                        
                        // Story Theme
                        FormField(title: "Story Theme") {
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: UITheme.Spacing.sm) {
                                ForEach(storyThemes) { theme in
                                    ThemeCard(theme: theme, isSelected: selectedTheme == theme) {
                                        selectedTheme = theme
                                    }
                                }
                            }
                        }
                        
                        // Story Length
                        FormField(title: "Story Length") {
                            VStack(spacing: UITheme.Spacing.xs) {
                                Slider(value: $storyLength, in: 1...3, step: 1)
                                    .tint(UITheme.Colors.primary)
                                HStack {
                                    ForEach(0..<storyLengthLabels.count, id: \.self) { index in
                                        Text(storyLengthLabels[index])
                                            .font(UITheme.Typography.bodySmall)
                                            .foregroundColor(UITheme.Colors.textSecondary)
                                            .frame(maxWidth: .infinity, alignment: alignment(for: index, count: storyLengthLabels.count))
                                    }
                                }
                            }
                            .padding(UITheme.Spacing.md)
                            .background(UITheme.Colors.surfacePrimary)
                            .cornerRadius(UITheme.Layout.cornerRadiusMedium)
                            .overlay(
                                RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusMedium)
                                    .stroke(UITheme.Colors.textSecondary.opacity(0.2), lineWidth: 1)
                            )
                        }
                        
                        // Story Language
                        FormField(title: "Story Language") {
                            LanguagePicker(languages: languages, selection: $selectedLanguage)
                        }
                    }
                    .padding(.horizontal, UITheme.Spacing.md)
                    
                    // Generate Button with gradient
                    Button {
                        generateStory()
                    } label: {
                        ZStack {
                            // Gradient background
                            primaryGradient
                            
                            // Shine effect (optional)
                            if !isGenerating {
                                ShineEffect()
                            }
                            
                            // Button content
                            HStack(spacing: UITheme.Spacing.sm) {
                                if isGenerating {
                                    ProgressView()
                                        .tint(.white)
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "wand.and.stars")
                                        .font(.system(size: 16))
                                }
                                
                                Text(isGenerating ? "Creating Magic..." : "Generate Magical Story")
                                    .font(UITheme.Typography.headingSmall)
                                    .foregroundColor(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .cornerRadius(UITheme.Layout.cornerRadiusMedium)
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.15), radius: 8, x: 0, y: 4)
                    }
                    .disabled(isGenerating || childName.isEmpty)
                    .padding(.horizontal, UITheme.Spacing.md)
                    .padding(.top, UITheme.Spacing.sm)
                    .padding(.bottom, UITheme.Spacing.lg)
                }
                .padding(.top, UITheme.Spacing.md)
            }
            .background(UITheme.Colors.background.edgesIgnoringSafeArea(.all))
            .navigationTitle("Create Story")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "arrow.left")
                            .foregroundColor(UITheme.Colors.textPrimary)
                    }
                }
            }
            .overlay {
                if isGenerating {
                    ZStack {
                        Color.black.opacity(0.7)
                            .edgesIgnoringSafeArea(.all)
                        
                        VStack(spacing: UITheme.Spacing.md) {
                            ProgressView()
                                .tint(.white)
                                .scaleEffect(1.5)
                            
                            Text("Creating your magical story...")
                                .font(UITheme.Typography.bodyLarge)
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text("This may take a moment...")
                                .font(UITheme.Typography.bodySmall)
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(UITheme.Spacing.lg)
                        .background(UITheme.Colors.surfacePrimary.opacity(0.2))
                        .cornerRadius(UITheme.Layout.cornerRadiusMedium)
                        .shadow(radius: 10)
                    }
                }
            }
            .alert("Error Generating Story", isPresented: $showError, presenting: error) { _ in
                Button("OK", role: .cancel) {}
            } message: { error in
                Text(error.localizedDescription)
            }
        }
        .accentColor(UITheme.Colors.primary)
    }
    
    // --- Helper Functions ---
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
            estimatedAge = 6 // Default age if parsing fails
        }
        
        // Convert story length Double to a qualitative string
        let lengthString: String
        switch Int(storyLength) {
        case 1: lengthString = "Short"
        case 3: lengthString = "Long"
        default: lengthString = "Medium"
        }
        
        // Use provided favorite character or select a random one
        let character = !favoriteCharacter.isEmpty ? favoriteCharacter : characterSuggestions.randomElement() ?? "Lion"
        
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
            developmentalFocus: [.emotionalIntelligence, .problemSolving], // Add developmental focus
            interactiveElements: true, // Add interactive elements
            emotionalThemes: emotionalThemes // Add emotional themes for older children
        )
        
        isGenerating = true
        Task {
            do {
                _ = try await storyService.generateStory(parameters: parameters)
                await MainActor.run {
                    self.isGenerating = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    self.error = error
                    self.showError = true
                    self.isGenerating = false
                    print("Error generating story: \(error.localizedDescription)")
                }
            }
        }
    }
}

// MARK: - Shine Effect
struct ShineEffect: View {
    @State private var shineOffset: CGFloat = -200
    
    var body: some View {
        GeometryReader { geometry in
            Color.white.opacity(0.2)
                .mask(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(stops: [
                                    .init(color: .clear, location: 0),
                                    .init(color: .white, location: 0.45),
                                    .init(color: .white, location: 0.55),
                                    .init(color: .clear, location: 1)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .rotationEffect(.degrees(-30))
                        .offset(x: shineOffset)
                        .frame(width: geometry.size.width * 2)
                )
        }
        .onAppear {
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                shineOffset = 400
            }
        }
    }
}

// MARK: - Helper Views and Styles

// Reusable Form Field Wrapper
struct FormField<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: UITheme.Spacing.xs) {
            Text(title)
                .font(UITheme.Typography.bodyMedium)
                .foregroundColor(UITheme.Colors.textPrimary)
            content
        }
        .padding(.vertical, UITheme.Spacing.xs)
    }
}

// Style for TextFields
struct InputFieldStyle: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var isFocused: Bool
    
    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .padding(UITheme.Spacing.md)
            .font(UITheme.Typography.bodyLarge)
            .foregroundColor(UITheme.Colors.textPrimary)
            .background(UITheme.Colors.surfacePrimary)
            .cornerRadius(UITheme.Layout.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusMedium)
                    .stroke(isFocused ? UITheme.Colors.primary : UITheme.Colors.textSecondary.opacity(0.2), lineWidth: isFocused ? 1.5 : 1)
            )
    }
}

extension View {
    func inputFieldStyle() -> some View {
        modifier(InputFieldStyle())
    }
}

// Button Style for Segmented Controls
struct SegmentedButtonStyle: ButtonStyle {
    let isSelected: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(UITheme.Typography.bodyMedium)
            .padding(.vertical, UITheme.Spacing.md)
            .frame(maxWidth: .infinity)
            .background(isSelected ? UITheme.Colors.primary : UITheme.Colors.surfacePrimary)
            .foregroundColor(isSelected ? .white : UITheme.Colors.textSecondary)
            .cornerRadius(UITheme.Layout.cornerRadiusMedium)
            .overlay(
                RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusMedium)
                    .stroke(isSelected ? UITheme.Colors.primary : UITheme.Colors.textSecondary.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

// Theme Card View
struct ThemeCard: View {
    let theme: StoryTheme
    let isSelected: Bool
    let action: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    private var iconName: String {
        switch theme {
        case .adventure: return "map"
        case .friendship: return "heart"
        case .learning: return "book"
        case .courage: return "star"
        case .kindness: return "hand.wave"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: iconName)
                    .font(.system(size: 24))
                    .foregroundColor(isSelected ? UITheme.Colors.primary : UITheme.Colors.textSecondary)
                    .padding(.bottom, UITheme.Spacing.xxs)
                
                Text(theme.title)
                    .font(UITheme.Typography.bodyMedium)
                    .foregroundColor(isSelected ? UITheme.Colors.textPrimary : UITheme.Colors.textSecondary)
            }
            .padding(UITheme.Spacing.md)
            .frame(maxWidth: .infinity, minHeight: 100)
            .background(UITheme.Colors.surfacePrimary)
            .cornerRadius(UITheme.Layout.cornerRadiusMedium)
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusMedium)
                        .stroke(isSelected ? UITheme.Colors.primary : UITheme.Colors.textSecondary.opacity(0.2), lineWidth: isSelected ? 1.5 : 1)
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(UITheme.Colors.primary)
                            .font(.system(size: 16))
                            .padding(UITheme.Spacing.xs)
                            .background(UITheme.Colors.surfacePrimary.opacity(0.8))
                            .clipShape(Circle())
                            .position(x: UITheme.Layout.cornerRadiusMedium + UITheme.Spacing.xs, y: UITheme.Layout.cornerRadiusMedium + UITheme.Spacing.xs)
                    }
                }
            )
        }
        .buttonStyle(.plain)
    }
}

// Language Picker View
struct LanguagePicker: View {
    let languages: [(String, String)]
    @Binding var selection: String
    
    var body: some View {
        HStack {
            Picker("Story Language", selection: $selection) {
                ForEach(languages, id: \.0) { language in
                    Text(language.1).tag(language.0)
                }
            }
            .pickerStyle(.menu)
            .tint(UITheme.Colors.textPrimary)
            Spacer()
            Image(systemName: "chevron.down")
                .foregroundColor(UITheme.Colors.textSecondary)
        }
        .padding(.horizontal, UITheme.Spacing.md)
        .padding(.vertical, UITheme.Spacing.md)
        .background(UITheme.Colors.surfacePrimary)
        .cornerRadius(UITheme.Layout.cornerRadiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: UITheme.Layout.cornerRadiusMedium)
                .stroke(UITheme.Colors.textSecondary.opacity(0.2), lineWidth: 1)
        )
    }
}

// MARK: - Preview
struct StoryFormView_Previews: PreviewProvider {
    static var previews: some View {
        let mockModelContext = ModelContext(try! ModelContainer(for: StoryModel.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))
        
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
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        print("Mock generating story with params: \(parameters)")
        
        return Story(
            id: UUID(),
            title: "Mock Story: \(parameters.childName)",
            pages: [],
            parameters: parameters,
            timestamp: Date()
        )
    }
}
