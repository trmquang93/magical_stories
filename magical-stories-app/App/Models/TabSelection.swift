import SwiftUI

class TabSelection: ObservableObject {
    @Published var selectedTab: TabItem = .home
}