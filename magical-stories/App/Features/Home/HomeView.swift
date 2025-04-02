import SwiftUI

struct HomeView: View {
    @State private var showingStoryForm = false
    @State private var showingGrowthStoryForm = false
    @EnvironmentObject private var storyService: StoryService
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    // Header
                    Text("Create a Magical Story")
                        .font(Theme.Typography.displayLarge)
                        .padding(.top, Theme.Spacing.xl)
                    
                    Text("Let's create a unique bedtime story for your child")
                        .font(Theme.Typography.bodyLarge)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, Theme.Spacing.lg)
                    
                    // Story Creation Card
                    MagicalCard {
                        VStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.Colors.primary)
                            
                            Text("Single Story")
                                .font(Theme.Typography.headingMedium)
                            
                            Text("Create a custom bedtime story with your child as the main character")
                                .font(Theme.Typography.bodyMedium)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                            
                            PrimaryButton(title: "Create Story") {
                                showingStoryForm = true
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    
                    // Growth Path Stories Card
                    MagicalCard {
                        VStack(spacing: Theme.Spacing.md) {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 40))
                                .foregroundColor(Theme.Colors.accent)
                            
                            Text("Growth Path Stories")
                                .font(Theme.Typography.headingMedium)
                            
                            Text("Create a personalized collection of stories focused on specific developmental skills")
                                .font(Theme.Typography.bodyMedium)
                                .foregroundColor(Theme.Colors.textSecondary)
                                .multilineTextAlignment(.center)
                            
                            PrimaryButton(title: "Create Collection") {
                                showingGrowthStoryForm = true
                            }
                        }
                        .padding()
                    }
                    .padding(.horizontal, Theme.Spacing.lg)
                    
                    Spacer()
                }
                .padding(.bottom, Theme.Spacing.xxl)
            }
            .navigationTitle("Home")
            .sheet(isPresented: $showingStoryForm) {
                StoryFormView()
            }
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(StoryService())
}
