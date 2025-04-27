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
    @State private var isChildNameValid = true
    @State private var isInterestsValid = false
    @State private var isCharactersValid = true
    
    var body: some View {
        NavigationView { // Embed in NavigationView for title and potential toolbar items
            Form {
                Section(header: Text("Child Information").font(.headline)) {
                    ValidatedTextField(
                        text: $childName,
                        label: "Child's Name (Optional)",
                        validation: { _ in true },
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
                        validation: { _ in true },
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
                    .onChange(of: interests) { newValue in
                        isInterestsValid = !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    }
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
                    .disabled(isGenerating || !isInterestsValid) // Disable if generating or form invalid
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.vertical, 8)
                    .accessibilityIdentifier("generateButton")
                }
                .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            }
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
            // Overlay loading indicator for consistency with StoryFormView
            .overlay {
                if isGenerating {
                    // Enhanced loading overlay
                    ZStack {
                        Color.black.opacity(0.5).ignoresSafeArea()
                        VStack(spacing: 20) {
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                                    .frame(width: 80, height: 80)
                                
                                Circle()
                                    .trim(from: 0, to: 0.7)
                                    .stroke(Color.blue, lineWidth: 8)
                                    .frame(width: 80, height: 80)
                                    .rotationEffect(Angle(degrees: isGenerating ? 360 : 0))
                                    .animation(Animation.linear(duration: 1).repeatForever(autoreverses: false), value: isGenerating)
                            }
                            
                            Text("Creating Your Collection")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Please wait while we craft your personalized stories...")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.8))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            ProgressView()
                                .progressViewStyle(LinearProgressViewStyle())
                                .frame(width: 200)
                                .padding(.top, 8)
                        }
                        .padding(32)
                        .background(RoundedRectangle(cornerRadius: 20).fill(Color.gray.opacity(0.8)))
                        .shadow(radius: 15)
                    }
                    .accessibilityIdentifier("loadingOverlay")
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
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            showSuccessAnimation = false
                            dismiss()
                        }
                    }
                    .accessibilityIdentifier("successOverlay")
                }
            }
            // Present error as alert for consistency with StoryFormView
            .alert("Error Creating Collection", isPresented: .constant(errorMessage != nil), actions: {
                Button("Try Again", role: .none) {
                    // Keep form data and allow retry
                    errorMessage = nil
                }
                Button("Cancel", role: .cancel) {
                    errorMessage = nil
                    dismiss()
                }
            }, message: {
                if let error = errorMessage {
                    Text(error + "\n\nPlease check your inputs and try again. If the problem persists, try again later.")
                }
            })
            .onAppear {
                // Initialize validation state
                isInterestsValid = !interests.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            }
        }
    }
    
    // Function to handle collection generation
    private func generateCollection() async {
        guard isInterestsValid else {
            errorMessage = "Please enter the child's interests."
            return
        }
        
        isGenerating = true
        errorMessage = nil
        
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
