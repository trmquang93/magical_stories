import SwiftData
import SwiftUI
import KeyboardAvoider

enum DevelopmentalFocus: String, CaseIterable, Identifiable {
    case emotionalIntelligence = "Emotional Intelligence"
    case problemSolving = "Problem Solving"
    case creativity = "Creativity"
    case socialSkills = "Social Skills (Sharing, Cooperation)"
    case curiosity = "Curiosity & Exploration"
    case resilience = "Resilience & Coping"

    var id: String { self.rawValue }
}

struct CollectionFormView: View {
    // Access the CollectionService to trigger generation
    @EnvironmentObject private var collectionService: CollectionService
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    // State variables for form inputs
    @State private var childAgeGroup: AgeGroup = .preschool
    @State private var developmentalFocus: DevelopmentalFocus = .emotionalIntelligence
    @State internal var interests: String = ""
    @State private var childName: String = UserDefaults.standard.string(forKey: "childName") ?? ""
    @State private var characters: String = ""
    @State private var selectedLanguage: String = "en"

    // Focus state for form fields
    @FocusState private var focusedField: CollectionFormField?

    // Enum for form field focus tracking
    enum CollectionFormField {
        case interests, childName, characters
    }

    // Language options from StoryLanguages
    private let languages: [(String, String)] = StoryLanguages.languageOptions

    // State for loading indicator
    @State internal var isGenerating = false
    @State private var animateBackground = false

    // State for potential error messages
    @State internal var errorMessage: String? = nil

    // Success animation control
    @State private var showSuccessAnimation = false

    // State for validation
    private var isInterestsValid: Bool {
        !interests.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // State for showing error alert
    @State private var showErrorAlert = false

    var body: some View {
        ZStack {
            // Background with subtle animation
            CollectionFormBackgroundView(animateBackground: $animateBackground)
                .ignoresSafeArea()

            // Form content
            KeyboardAvoider {
                VStack(alignment: .leading, spacing: UITheme.Spacing.lg) {
                    CollectionFormHeader(
                        title: "Create Growth Collection",
                        subtitle: "Personalized stories for development"
                    )
                    .padding(.top, UITheme.Spacing.md)

                    // Form fields with staggered animations
                    AgeGroupField(
                        selectedAgeGroup: $childAgeGroup,
                        ageGroups: AgeGroup.allCases
                    )

                    ChildNameInputField(childName: $childName)
                        .focused($focusedField, equals: .childName)

                    CharactersInputField(characters: $characters)
                        .focused($focusedField, equals: .characters)

                    DevelopmentalFocusField(
                        selectedFocus: $developmentalFocus,
                        focuses: DevelopmentalFocus.allCases
                    )

                    InterestsInputField(interests: $interests)
                        .focused($focusedField, equals: .interests)

                    LanguageField(
                        selectedLanguage: $selectedLanguage, languages: languages)

                    GenerateCollectionButton(
                        isGenerating: isGenerating,
                        action: {
                            Task {
                                await generateCollection()
                            }
                        }
                    )
                    .padding(.top, UITheme.Spacing.lg)
                    .padding(.bottom, UITheme.Spacing.xxl * 2) // Added extra bottom padding to prevent collapse
                }
                .padding(.horizontal, UITheme.Spacing.md)
            }
            .ignoresSafeArea(.keyboard, edges: .bottom) // Ignoring bottom safe area for better keyboard handling

            // Loading overlay with animations
            CollectionLoadingOverlayView(isVisible: $isGenerating)
                .accessibilityIdentifier("CollectionLoadingOverlay")
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        dismiss()
                    }
                }) {
                    ZStack {
                        Circle()
                            .fill(
                                colorScheme == .light
                                    ? Color.white.opacity(0.8)
                                    : Color(hex: "#2D3748").opacity(0.8)
                            )
                            .frame(width: 36, height: 36)
                            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)

                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(
                                colorScheme == .light
                                    ? Color(hex: "#4A5568")
                                    : Color(hex: "#E2E8F0"))
                    }
                }
                .accessibilityIdentifier("CollectionForm_CancelButton")
            }

            ToolbarItem(placement: .principal) {
                Text("Growth Collections")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(
                        colorScheme == .light
                            ? Color(hex: "#7B61FF")
                            : Color(hex: "#a78bfa"))
            }
        }
        .alert(
            "Error Creating Collection", isPresented: $showErrorAlert,
            actions: {
                Button("Try Again", role: .none) {
                    errorMessage = nil
                }
                Button("Cancel", role: .cancel) {
                    errorMessage = nil
                    dismiss()
                }
            },
            message: {
                if let error = errorMessage {
                    Text(
                        error
                            + "\n\nPlease check your inputs and try again. If the problem persists, try again later."
                    )
                } else {
                    Text("An unknown error occurred.")
                }
            }
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 1)) {
                animateBackground = true
            }
        }
    }

    // Function to handle collection generation
    private func generateCollection() async {
        // Keyboard is automatically dismissed by KeyboardAvoider
        
        // Validation check remains the same
        guard isInterestsValid else {
            errorMessage = "Please enter the child's interests."
            showErrorAlert = true  // Show the alert
            hapticError()
            return
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            isGenerating = true
        }

        errorMessage = nil  // Clear previous errors
        showErrorAlert = false  // Hide alert if it was previously shown

        let parameters = CollectionParameters(
            childAgeGroup: childAgeGroup.rawValue,
            developmentalFocus: developmentalFocus.rawValue,
            interests: interests,
            childName: childName.isEmpty ? nil : childName,
            characters: characters.isEmpty
                ? nil
                : characters.components(separatedBy: ",").map {
                    $0.trimmingCharacters(in: .whitespaces)
                },
            languageCode: selectedLanguage
        )

        do {
            print("[CollectionFormView] Generating collection with parameters: \(parameters)")

            // Create the StoryCollection object
            let newCollection = StoryCollection(
                title: "\(developmentalFocus.rawValue) Collection",
                descriptionText: parameters.interests,
                category: parameters.developmentalFocus,
                ageGroup: parameters.childAgeGroup
            )

            // Call the service to create collection
            try collectionService.createCollection(newCollection)

            // Generate stories for the collection asynchronously
            try await collectionService.generateStoriesForCollection(
                newCollection, parameters: parameters)

            // Success - show animation and haptic feedback
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isGenerating = false
                showSuccessAnimation = true
            }

            hapticSuccess()

            // Wait a moment for animation to be visible
            try? await Task.sleep(nanoseconds: 1_500_000_000)  // 1.5 seconds

            print("[CollectionFormView] Dismissing view")
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                dismiss()  // Dismiss the form on success
            }
        } catch {
            // Handle error
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                isGenerating = false
            }

            errorMessage = "Failed to generate collection: \(error.localizedDescription)"
            showErrorAlert = true  // Show the alert on error
            hapticError()
            print("[CollectionFormView] Error generating collection: \(error)")
        }
    }

    // Haptic feedback functions
    private func hapticSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    private func hapticError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
}

// MARK: - Form Fields for CollectionFormView

struct ChildNameInputField: View {
    @Binding var childName: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        FormFieldContainer {
            HStack {
                Image(systemName: "person.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#7B61FF"))
                Text("Child's Name (Optional)")
                    .font(.system(size: 16, weight: .semibold))
            }

            HStack {
                TextField("Enter child's name", text: $childName)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .light ? .white : Color(hex: "#1F2937"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#E2E8F0"), lineWidth: 1)
                    )
                    .submitLabel(.next)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("childNameTextField")

                if !childName.isEmpty {
                    Button(action: {
                        childName = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .transition(.opacity)
                    .accessibilityLabel("Clear child name")
                }
            }
        }
    }
}

struct CharactersInputField: View {
    @Binding var characters: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        FormFieldContainer {
            HStack {
                Image(systemName: "heart.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#7B61FF"))
                Text("Characters (Optional)")
                    .font(.system(size: 16, weight: .semibold))
            }

            HStack {
                TextField("Dragon, unicorn, wizard...", text: $characters)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .light ? .white : Color(hex: "#1F2937"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#E2E8F0"), lineWidth: 1)
                    )
                    .submitLabel(.next)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("charactersTextField")

                if !characters.isEmpty {
                    Button(action: {
                        characters = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .transition(.opacity)
                    .accessibilityLabel("Clear characters")
                }
            }

            Text("Separate multiple characters with commas")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 4)
        }
    }
}

struct InterestsInputField: View {
    @Binding var interests: String
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        FormFieldContainer {
            HStack {
                Image(systemName: "star.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: "#7B61FF"))
                Text("Child's Interests (Required)")
                    .font(.system(size: 16, weight: .semibold))
            }

            HStack {
                TextField("Space, dinosaurs, ballet...", text: $interests)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(colorScheme == .light ? .white : Color(hex: "#1F2937"))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(hex: "#E2E8F0"), lineWidth: 1)
                    )
                    .submitLabel(.done)
                    .autocorrectionDisabled()
                    .accessibilityIdentifier("interestsTextField")

                if !interests.isEmpty {
                    Button(action: {
                        interests = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                    .transition(.opacity)
                    .accessibilityLabel("Clear interests")
                }
            }
        }
    }
}

// MARK: - Preview
struct CollectionFormView_Previews: PreviewProvider {
    static var previews: some View {
        // Register the achievement model to ensure it's available for container creation
        let schemas = Schema([
            StoryCollection.self,
            Story.self,
            AchievementModel.self,
        ])

        // Create the container with all necessary models
        let configuration = ModelConfiguration(schema: schemas, isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: schemas, configurations: configuration)
        let context = ModelContext(container)

        // Create all required repositories with proper context
        let collectionRepo = CollectionRepository(modelContext: context)
        let storyService = MockStoryService(context: context)
        let achievementRepo = AchievementRepository(modelContext: context)

        // Create the collection service
        let service = CollectionService(
            repository: collectionRepo,
            storyService: storyService,
            achievementRepository: achievementRepo
        )

        // Return the view with properly configured service
        return CollectionFormView()
            .environmentObject(service)
            .preferredColorScheme(.light)
    }
}
