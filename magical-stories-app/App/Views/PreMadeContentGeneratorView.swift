import SwiftUI
import SwiftData

/// Development view for generating pre-made content using AI APIs
/// This view is intended for one-time use to create JSON files for bundling
@MainActor
struct PreMadeContentGeneratorView: View {
    @StateObject private var generator: PreMadeContentGenerator
    @StateObject private var loader: PreMadeContentLoader
    @Environment(\.dismiss) private var dismiss
    
    @State private var showingValidation = false
    @State private var validationResult: ValidationResult?
    
    init(
        storyService: StoryService,
        collectionService: CollectionService,
        illustrationService: SimpleIllustrationService,
        persistenceService: PersistenceService
    ) {
        self._generator = StateObject(wrappedValue: PreMadeContentGenerator(
            storyService: storyService,
            collectionService: collectionService,
            illustrationService: illustrationService,
            persistenceService: persistenceService
        ))
        
        self._loader = StateObject(wrappedValue: PreMadeContentLoader(
            persistenceService: persistenceService,
            collectionService: collectionService
        ))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    headerSection
                    
                    if generator.isGenerating {
                        generationProgressSection
                    } else {
                        generationControlsSection
                    }
                    
                    if !generator.generatedStories.isEmpty {
                        generatedContentSection
                    }
                    
                    jsonValidationSection
                    
                    loaderSection
                }
                .padding()
            }
            .navigationTitle("Pre-Made Content Generator")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "wand.and.stars")
                .font(.system(size: 40))
                .foregroundColor(.blue)
            
            Text("Pre-Made Content Generator")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Generate stories and illustrations using AI APIs, then export to JSON for bundling with the app.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var generationProgressSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text(generator.progress)
                .font(.headline)
                .multilineTextAlignment(.center)
            
            Text("This may take several minutes as we generate stories and illustrations...")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(Color(.systemBlue).opacity(0.1))
        .cornerRadius(12)
    }
    
    private var generationControlsSection: some View {
        VStack(spacing: 16) {
            Button(action: {
                Task {
                    await generator.generateAllPreMadeContent()
                }
            }) {
                HStack {
                    Image(systemName: "brain.head.profile")
                    Text("Generate All Content with AI")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            
            if !generator.progress.isEmpty {
                Text(generator.progress)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundColor(generator.progress.hasPrefix("❌") ? .red : .primary)
            }
        }
    }
    
    private var generatedContentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Generated Content")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Label("\(generator.generatedStories.count) Stories Generated", systemImage: "book.fill")
                Label("\(generator.generatedCollections.count) Collections Created", systemImage: "square.grid.2x2.fill")
                
                let totalPages = generator.generatedStories.reduce(0) { $0 + $1.pages.count }
                let illustratedPages = generator.generatedStories.flatMap { $0.pages }.filter { $0.illustrationStatus == .ready }.count
                
                Label("\(illustratedPages)/\(totalPages) Pages Illustrated", systemImage: "photo.fill")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            
            Button(action: {
                Task {
                    do {
                        try await generator.writeJSONFilesToDocuments()
                    } catch {
                        print("Failed to write JSON files: \(error)")
                        await MainActor.run {
                            generator.progress = "❌ Export failed: \(error.localizedDescription)"
                        }
                    }
                }
            }) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                    Text("Export to JSON Files")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var jsonValidationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("JSON File Validation")
                .font(.headline)
            
            Button(action: {
                Task {
                    validationResult = await loader.validateJSONContents()
                    showingValidation = true
                }
            }) {
                HStack {
                    Image(systemName: "checkmark.seal")
                    Text("Validate JSON Files")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            
            if let result = validationResult {
                Text(result.summary)
                    .font(.caption)
                    .foregroundColor(result.isValid ? .green : .red)
                    .padding(.top, 4)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .alert("JSON Validation", isPresented: $showingValidation) {
            Button("OK") { }
        } message: {
            if let result = validationResult {
                Text(result.summary)
            }
        }
    }
    
    private var loaderSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("JSON Loader Test")
                .font(.headline)
            
            Text("Test loading pre-made content from JSON files")
                .font(.caption)
                .foregroundColor(.secondary)
            
            if loader.isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(loader.loadProgress)
                        .font(.subheadline)
                }
            } else {
                Button(action: {
                    Task {
                        await loader.loadPreMadeContentIfNeeded()
                    }
                }) {
                    HStack {
                        Image(systemName: "tray.and.arrow.down")
                        Text("Test Load from JSON")
                    }
                    .font(.subheadline)
                    .foregroundColor(.orange)
                }
                
                if !loader.loadProgress.isEmpty {
                    Text(loader.loadProgress)
                        .font(.caption)
                        .foregroundColor(loader.loadProgress.hasPrefix("❌") ? .red : .green)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#if DEBUG
struct PreMadeContentGeneratorView_Previews: PreviewProvider {
    static var previews: some View {
        PreMadeContentGeneratorView(
            storyService: try! StoryService(
                apiKey: "test",
                context: ModelContext(try! ModelContainer(for: Story.self, StoryCollection.self))
            ),
            collectionService: CollectionService(
                repository: CollectionRepository(modelContext: ModelContext(try! ModelContainer(for: StoryCollection.self))),
                storyService: try! StoryService(
                    apiKey: "test",
                    context: ModelContext(try! ModelContainer(for: Story.self, StoryCollection.self))
                ),
                achievementRepository: AchievementRepository(modelContext: ModelContext(try! ModelContainer(for: AchievementModel.self)))
            ),
            illustrationService: try! SimpleIllustrationService(apiKey: "test"),
            persistenceService: PersistenceService(context: ModelContext(try! ModelContainer(for: Story.self, StoryCollection.self)))
        )
    }
}
#endif