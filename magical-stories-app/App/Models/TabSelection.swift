import SwiftUI

@MainActor
class TabSelection: ObservableObject {
    @Published var selectedTab: TabItem = .home
}