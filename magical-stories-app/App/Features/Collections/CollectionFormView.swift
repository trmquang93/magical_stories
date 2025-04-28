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
    
    // State variables for form inputs
    @State private var childAgeGroup: AgeGroup = .preschool // Use Enum
    @State private var developmentalFocus: DevelopmentalFocus = .emotionalIntelligence // Use Enum
    @State private var interests: String = "" // Comma-separated or token field?
    @State private var childName: String = "" // Optional
    @State private var characters: String = "" // Optional, comma-separated
    
    // State for loading indicator
    @State private var isGenerating = false
    
    // State for potential error messages
    @State private var errorMessage: String? = nil
    
    // Success animation control
    @State private var showSuccessAnimation = false
    
    // Used to dismiss the sheet/view upon successful generation
    @Environment(\.dismiss) private var dismiss
    
    // State for validation
    // Validation state derived directly from input
    private var isInterestsValid: Bool {
        !interests.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // State for showing error alert
    @State private var showErrorAlert = false
    
    var body: some View {
        NavigationView {
            ZStack { // Keep ZStack for background and overlays
                CollectionFormBackgroundView(animateBackground: $isGenerating)
                
                Form { // Use Form for standard layout and styling
                    Section(header: Text("Child Details").font(.headline)) {
                        ValidatedTextField(
                            text: $childName,
                            label: "Child's Name (Optional)",
                            validation: { _ in true }, // No validation needed for optional field
                            errorMessage: ""
                        )
                        .accessibilityIdentifier("childNameField")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Age Group").font(.body)
                            Picker("Age Group", selection: $childAgeGroup) {
                                ForEach(AgeGroup.allCases) { age in
                                    Text(age.rawValue).tag(age)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .accessibilityIdentifier("ageGroupPicker")
                        }
                        .padding(.vertical, 4)
                        
                        ValidatedTextField(
                            text: $characters,
                            label: "Favorite Characters (Optional, comma-separated)",
                            validation: { _ in true }, // No validation needed for optional field
                            errorMessage: ""
                        )
                        .accessibilityIdentifier("charactersField")
                    }
                    
                    Section(header: Text("Collection Focus").font(.headline)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Developmental Focus").font(.body)
                            Picker("Developmental Focus", selection: $developmentalFocus) {
                                ForEach(DevelopmentalFocus.allCases) { focus in
                                    Text(focus.rawValue).tag(focus)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .accessibilityIdentifier("developmentalFocusPicker")
                        }
                        .padding(.vertical, 4)
                        
                        ValidatedTextField(
                            text: $interests,
                            label: "Interests (e.g., Dinosaurs, Space)",
                            validation: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty },
                            errorMessage: "Interests are required"
                        )
                        .lineLimit(3...) // Allow multi-line input for interests
                        .accessibilityIdentifier("interestsField")
                    }
                    
                    Section {
                        Button {
                            Task {
                                await generateCollection()
                            }
                        } label: {
                            HStack {
                                Spacer()
                                // Show ProgressView inside the button when generating
                                if isGenerating {
                                    ProgressView("Generating...")
                                } else {
                                    Text("Generate Collection")
                                        .fontWeight(.semibold)
                                }
                                Spacer()
                            }
                        }
                        .disabled(isGenerating || !isInterestsValid) // Disable if generating or interests invalid
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                        .padding(.vertical, 8)
                        .accessibilityIdentifier("generateButton")
                    }
                    // Apply listRowInsets to the Section for consistent padding
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
                } // End Form
                .disabled(isGenerating) // Disable the form while generating
            } // End ZStack
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isGenerating)
                        .accessibilityIdentifier("cancelButton")
                }
            }
            .disabled(isGenerating) // Disable the form while generating
            // Conditional overlay for loading OR success animation
            .overlay {
                if isGenerating {
                    CollectionLoadingOverlayView(isLoading: isGenerating)
                } else if showSuccessAnimation {
                    // Success animation overlay
                    ZStack {
                        Color.black.opacity(0.5).ignoresSafeArea()
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.circle.fill")
                                .resizable()
                                .frame(width: 80, height: 80)
                                .foregroundColor(.green)
                                .symbolEffect(.bounce, options: .repeating)
                            
                            Text("Collection Created!")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Your collection has been successfully created and is ready for reading.")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(32)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.gray.opacity(0.8)))
                        .shadow(radius: 15)
                    }
                    .transition(.opacity.animation(.easeInOut(duration: 0.5)))
                    // Removed redundant onAppear dismissal logic here
                    .accessibilityIdentifier("successOverlay")
                }
            }
            // Present error as alert using the boolean state
            .alert("Error Creating Collection", isPresented: $showErrorAlert, actions: {
                Button("Try Again", role: .none) {
                    // Keep form data and allow retry
                    errorMessage = nil // Clear message but keep alert state managed by showErrorAlert
                }
                Button("Cancel", role: .cancel) {
                    errorMessage = nil
                    dismiss() // Dismiss if user cancels the alert
                }
            }, message: {
                if let error = errorMessage {
                    Text(error + "\n\nPlease check your inputs and try again. If the problem persists, try again later.")
                } else {
                    Text("An unknown error occurred.") // Fallback message
                }
            })
            // No onAppear needed for validation initialization as it's a computed property now
        } // End NavigationView
    } // End body
    
    // Function to handle collection generation
    private func generateCollection() async {
        // Validation check remains the same
        guard isInterestsValid else {
            errorMessage = "Please enter the child's interests."
            showErrorAlert = true // Show the alert
            return
        }
        
        isGenerating = true
        errorMessage = nil // Clear previous errors
        showErrorAlert = false // Hide alert if it was previously shown
        
        let parameters = CollectionParameters(
            childAgeGroup: childAgeGroup.rawValue, // Pass rawValue
            developmentalFocus: developmentalFocus.rawValue, // Pass rawValue
            interests: interests,
            childName: childName.isEmpty ? nil : childName,
            characters: characters.isEmpty ? nil : characters.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        )
        
        do {
            print("[CollectionFormView] Generating collection with parameters: \(parameters)")
            
            // Create the StoryCollection object
            let newCollection = StoryCollection(
                title: "\(developmentalFocus.rawValue) Collection", // More descriptive title
                descriptionText: parameters.interests, // Using interests as description
                category: parameters.developmentalFocus, // Using focus as category
                ageGroup: parameters.childAgeGroup // Using age group from form
                // id, stories, createdAt, updatedAt will use default values
            )
            
            // Call the service to create collection
            try collectionService.createCollection(newCollection)
            
            // Generate stories for the collection asynchronously
            try await collectionService.generateStoriesForCollection(newCollection, parameters: parameters)
            
            // Success - show animation and haptic feedback
            isGenerating = false
            hapticSuccess()
            showSuccessAnimation = true
            
            // Wait a moment for animation to be visible
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            print("[CollectionFormView] Dismissing view")
            dismiss() // Dismiss the form on success
        } catch {
            // Handle error
            isGenerating = false
            errorMessage = "Failed to generate collection: \(error.localizedDescription)"
            showErrorAlert = true // Show the alert on error
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
