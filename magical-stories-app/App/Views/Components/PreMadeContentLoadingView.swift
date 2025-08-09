import SwiftUI

/// A view that shows progress while pre-made content is being loaded
@MainActor
struct PreMadeContentLoadingView: View {
    @ObservedObject var loader: PreMadeContentLoader
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Title
            Text("Loading Magical Stories")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            // Progress Circle
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 8)
                    .frame(width: 100, height: 100)
                
                Circle()
                    .trim(from: 0, to: loader.progressPercentage)
                    .stroke(
                        Color.blue,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.5), value: loader.progressPercentage)
                
                Text("\(Int(loader.progressPercentage * 100))%")
                    .font(.title3)
                    .fontWeight(.medium)
            }
            
            // Progress Text
            Text(loader.loadProgress)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(height: 40)
            
            // Loading Animation
            if loader.isLoading {
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .scaleEffect(loader.isLoading ? 1 : 0.5)
                            .animation(
                                .easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                                value: loader.isLoading
                            )
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .task {
            await loader.loadPreMadeContentIfNeeded()
            onComplete()
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @StateObject private var mockLoader = PreMadeContentLoader(
            persistenceService: MockPersistenceService()
        )
        
        var body: some View {
            PreMadeContentLoadingView(loader: mockLoader) {
                print("Loading complete!")
            }
            .padding()
            .onAppear {
                // Simulate loading progress for preview
                mockLoader.isLoading = true
                mockLoader.loadProgress = "Loading stories from JSON..."
                mockLoader.progressPercentage = 0.3
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    mockLoader.loadProgress = "Saving to database..."
                    mockLoader.progressPercentage = 0.7
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    mockLoader.loadProgress = "✅ Pre-made content loaded successfully"
                    mockLoader.progressPercentage = 1.0
                    mockLoader.isLoading = false
                }
            }
        }
    }
    
    return PreviewWrapper()
}