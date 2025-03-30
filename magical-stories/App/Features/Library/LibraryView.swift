import SwiftUI

struct LibraryView: View {
    var body: some View {
        NavigationStack {
            Text("Your Stories Library")
                .font(Theme.Typography.displayMedium)
                .navigationTitle("Library")
        }
    }
}

#Preview {
    LibraryView()
}
