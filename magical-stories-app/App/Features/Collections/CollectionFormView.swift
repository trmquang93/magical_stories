import SwiftUI

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
    @State private var childName: String = ""
    @State private var characters: String = ""

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
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                    CollectionFormHeader(
                        title: "Create Growth Collection",
                        subtitle: "Personalized stories for development"
                    )
                    .padding(.top, Theme.Spacing.md)

                    // Form fields with staggered animations
                    AgeGroupField(
                        selectedAgeGroup: $childAgeGroup,
                        ageGroups: AgeGroup.allCases
                    )

                    CharactersField(characters: $characters)

                    DevelopmentalFocusField(
                        selectedFocus: $developmentalFocus,
                        focuses: DevelopmentalFocus.allCases
                    )

                    InterestsField(interests: $interests)

                    GenerateCollectionButton(
                        isGenerating: isGenerating,
                        action: {
                            Task {
                                await generateCollection()
                            }
                        }
                    )
                    .padding(.top, Theme.Spacing.lg)
                    .padding(.bottom, Theme.Spacing.xxl)
                }
                .padding(.horizontal, Theme.Spacing.md)
            }

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
                }
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
