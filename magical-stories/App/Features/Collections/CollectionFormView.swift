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
    
    // Used to dismiss the sheet/view upon successful generation
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView { // Embed in NavigationView for title and potential toolbar items
            Form {
                Section(header: Text("Child Information")) {
                    TextField("Child's Name (Optional)", text: $childName)
                    
                    Picker("Age Group", selection: $childAgeGroup) {
                        ForEach(AgeGroup.allCases) { age in
                            Text(age.rawValue).tag(age)
                        }
                    }
                    
                    TextField("Favorite Characters (Optional, comma-separated)", text: $characters)
                }
                
                Section(header: Text("Collection Focus")) {
                    Picker("Developmental Focus", selection: $developmentalFocus) {
                        ForEach(DevelopmentalFocus.allCases) { focus in
                            Text(focus.rawValue).tag(focus)
                        }
                    }
                    
                    TextField("Interests (e.g., Dinosaurs, Space)", text: $interests)
                        .lineLimit(3...) // Allow multi-line input for interests
                }
                
                Section {
                    Button {
                        Task {
                            await generateCollection()
                        }
                    } label: {
                        // Show ProgressView inside the button when generating
                        if isGenerating {
                            ProgressView("Generating...")
                        } else {
                            Text("Generate Collection")
                        }
                    }
                    .disabled(isGenerating || !isFormValid) // Disable if generating or form invalid
                    .frame(maxWidth: .infinity, alignment: .center) // Center button
                }
                
                // Display error message
                if let error = errorMessage {
                    Section(header: Text("Error").foregroundColor(.red)) {
                        Text(error)
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .disabled(isGenerating)
                }
            }
            .disabled(isGenerating) // Disable the form while generating
        }
    }
    
    // Basic form validation (can be enhanced)
    private var isFormValid: Bool {
        // Pickers guarantee a value, only need to check text fields if they were required
        // Assuming interests is required for now.
        !interests.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Function to handle collection generation
    private func generateCollection() async {
        guard isFormValid else {
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
                title: "Untitled Collection", // Using a default title for now
                descriptionText: parameters.interests, // Using interests as description
                category: parameters.developmentalFocus, // Using focus as category
                ageGroup: parameters.childAgeGroup // Using age group from form
                // id, stories, createdAt, updatedAt will use default values
            )
            
            // Call the service with the StoryCollection object
            _ = try await collectionService.createCollection(newCollection)
            
            // Success!
            isGenerating = false
            dismiss() // Dismiss the form on success
        } catch {
            // Handle error
            isGenerating = false
            errorMessage = "Failed to generate collection: \(error.localizedDescription)"
            print("[CollectionFormView] Error generating collection: \(error)")
        }
    }
}
