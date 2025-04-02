import SwiftUI

struct StoryDetailView: View {
    let story: Story
    
    @EnvironmentObject private var textToSpeechService: TextToSpeechService
    @State private var isPlaying = false
    @State private var highlightedRange: NSRange?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // Story Title
                Text(story.title)
                    .font(Theme.Typography.displaySmall)
                    .padding(.top, Theme.Spacing.lg)
                
                // Story Content
                Text(story.content)
                    .font(Theme.Typography.bodyLarge)
                    .lineSpacing(8)
                    .padding(.bottom, Theme.Spacing.lg)
                    .highlightText(story.content, range: highlightedRange, color: Theme.Colors.accent)
                
                // Story Metadata
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    HStack {
                        Label("Theme", systemImage: story.theme.iconName)
                        Text(story.theme.title)
                    }
                    .font(Theme.Typography.bodyMedium)
                    
                    HStack {
                        Label("Created for", systemImage: "person")
                        Text(story.childName)
                    }
                    .font(Theme.Typography.bodyMedium)
                    
                    HStack {
                        Label("Age group", systemImage: "number")
                        Text("\(story.ageGroup)")
                    }
                    .font(Theme.Typography.bodyMedium)
                }
                .foregroundColor(Theme.Colors.textSecondary)
                .padding(.vertical, Theme.Spacing.md)
            }
            .padding(.horizontal, Theme.Spacing.lg)
            .padding(.bottom, 100) // Add padding for the bottom controls
        }
        .navigationTitle("Story")
        .navigationBarTitleDisplayMode(.inline)
        .overlay(alignment: .bottom) {
            audioControls
                .padding(.bottom, Theme.Spacing.md)
        }
        .onAppear {
            highlightedRange = textToSpeechService.currentWordRange
        }
        .onReceive(textToSpeechService.$currentWordRange) { range in
            highlightedRange = range
        }
        .onReceive(textToSpeechService.$isPlaying) { playing in
            isPlaying = playing
        }
    }
    
    private var audioControls: some View {
        HStack(spacing: Theme.Spacing.lg) {
            Button {
                if isPlaying {
                    textToSpeechService.pauseSpeaking()
                } else {
                    if textToSpeechService.isPlaying {
                        textToSpeechService.continueSpeaking()
                    } else {
                        textToSpeechService.speak(story.content)
                    }
                }
            } label: {
                Label(isPlaying ? "Pause" : "Play", systemImage: isPlaying ? "pause.fill" : "play.fill")
                    .font(Theme.Typography.bodyLarge)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Theme.Colors.primary)
                    .cornerRadius(Theme.Layout.cornerRadiusMedium)
            }
            
            Button {
                textToSpeechService.stopSpeaking()
            } label: {
                Label("Stop", systemImage: "stop.fill")
                    .font(Theme.Typography.bodyLarge)
                    .foregroundColor(.white)
                    .frame(width: 80, height: 50)
                    .background(Theme.Colors.secondary)
                    .cornerRadius(Theme.Layout.cornerRadiusMedium)
            }
        }
        .padding(.horizontal, Theme.Spacing.lg)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.bottom)
        )
    }
}

#Preview {
    NavigationStack {
        StoryDetailView(
            story: Story(
                title: "The Brave Lion",
                content: "Once upon a time, there was a brave lion named Leo who lived in the savanna. Leo was known for his courage and kindness to all animals. One day, a terrible storm came to the savanna, and all the animals were afraid. But Leo stood tall and helped everyone find shelter. Thanks to Leo's bravery, all the animals were safe.",
                theme: .courage,
                childName: "Alex",
                ageGroup: 6,
                favoriteCharacter: "🦁"
            )
        )
    }
    .environmentObject(TextToSpeechService(settingsService: SettingsService()))
}