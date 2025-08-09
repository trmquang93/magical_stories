import SwiftUI
import SwiftData

/// Developer tools card for settings (DEBUG builds only)
struct DeveloperCard: View {
    @EnvironmentObject private var storyService: StoryService
    @EnvironmentObject private var collectionService: CollectionService
    @EnvironmentObject private var persistenceService: PersistenceService
    @EnvironmentObject private var ratingService: RatingService
    
    @State private var showingGenerator = false
    @State private var showingRatingDebug = false
    
    var body: some View {
        #if DEBUG
        SettingsCard(title: "Developer Tools", icon: "wrench.and.screwdriver.fill") {
            VStack(spacing: UITheme.Spacing.lg) {
                Button(action: {
                    showingGenerator = true
                }) {
                    HStack {
                        Image(systemName: "wand.and.stars")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Pre-Made Content Generator")
                                .font(UITheme.Typography.bodyMedium)
                                .foregroundColor(UITheme.Colors.textPrimary)
                            
                            Text("Generate stories with AI and export to JSON")
                                .font(UITheme.Typography.bodySmall)
                                .foregroundColor(UITheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(UITheme.Colors.textSecondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                
                Button(action: {
                    showingRatingDebug = true
                }) {
                    HStack {
                        Image(systemName: "star.circle.fill")
                            .foregroundColor(.purple)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rating System Debug")
                                .font(UITheme.Typography.bodyMedium)
                                .foregroundColor(UITheme.Colors.textPrimary)
                            
                            Text("Test rating prompts and view analytics")
                                .font(UITheme.Typography.bodySmall)
                                .foregroundColor(UITheme.Colors.textSecondary)
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(UITheme.Colors.textSecondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                
                HStack {
                    Text("Environment")
                        .font(UITheme.Typography.bodyMedium)
                        .foregroundColor(UITheme.Colors.textPrimary)
                    
                    Spacer()
                    
                    Text("DEBUG")
                        .font(UITheme.Typography.bodySmall)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(4)
                }
            }
        }
        .sheet(isPresented: $showingGenerator) {
            PreMadeContentGeneratorView(
                storyService: storyService,
                collectionService: collectionService,
                illustrationService: try! SimpleIllustrationService(),
                persistenceService: persistenceService
            )
        }
        .sheet(isPresented: $showingRatingDebug) {
            RatingDebugView()
                .environmentObject(ratingService)
        }
        #endif
    }
}

#if DEBUG
struct DeveloperCard_Previews: PreviewProvider {
    static var previews: some View {
        DeveloperCard()
            .environmentObject(try! StoryService(
                apiKey: "test",
                context: ModelContext(try! ModelContainer(for: Story.self, StoryCollection.self))
            ))
            .environmentObject(CollectionService(
                repository: CollectionRepository(modelContext: ModelContext(try! ModelContainer(for: StoryCollection.self))),
                storyService: try! StoryService(
                    apiKey: "test",
                    context: ModelContext(try! ModelContainer(for: Story.self, StoryCollection.self))
                ),
                achievementRepository: AchievementRepository(modelContext: ModelContext(try! ModelContainer(for: AchievementModel.self)))
            ))
            .environmentObject(PersistenceService(context: ModelContext(try! ModelContainer(for: Story.self, StoryCollection.self))))
            .padding()
    }
}
#endif