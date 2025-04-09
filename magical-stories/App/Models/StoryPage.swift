import Foundation
import SwiftData

@Model
final class StoryPage {
    @Attribute(.unique) var id: UUID

    init(id: UUID = UUID()) {
        self.id = id
    }
}