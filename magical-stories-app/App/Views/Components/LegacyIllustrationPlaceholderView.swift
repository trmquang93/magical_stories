import SwiftUI

/// A placeholder view that displays while illustrations are being generated
/// This is a legacy version kept for reference; use IllustrationPlaceholderView from DesignSystem/Components instead
struct LegacyIllustrationPlaceholderView: View {
    let pageNumber: Int
    let totalPages: Int
    let isLoading: Bool
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(Color.gray.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(8)
            
            VStack(spacing: 16) {
                if isLoading {
                    ProgressView()
                        .controlSize(.large)
                    
                    Text("Creating your illustration...")
                        .font(.body)
                        .foregroundColor(Color.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .accessibilityLabel("Illustration is generating")
                } else {
                    Image(systemName: "photo")
                        .font(.system(size: 40))
                        .foregroundColor(Color.secondary.opacity(0.7))
                    
                    Text("Illustration will appear here")
                        .font(.body)
                        .foregroundColor(Color.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .accessibilityLabel("Illustration not available yet")
                }
                
                Text("Page \(pageNumber) of \(totalPages)")
                    .font(.caption)
                    .foregroundColor(Color.secondary)
            }
            .padding()
        }
        .aspectRatio(9/16, contentMode: .fit)
    }
}

// Preview
#Preview {
    VStack(spacing: 20) {
        LegacyIllustrationPlaceholderView(pageNumber: 1, totalPages: 5, isLoading: true)
            .frame(width: 300)
        
        LegacyIllustrationPlaceholderView(pageNumber: 2, totalPages: 5, isLoading: false)
            .frame(width: 300)
    }
    .padding()
}
