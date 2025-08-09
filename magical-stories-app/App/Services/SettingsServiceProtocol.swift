import Foundation

/// Protocol defining the interface for the settings service
@MainActor
protocol SettingsServiceProtocol {
    var parentalControlsEnabled: Bool { get }
    var maxStoriesPerDay: Int { get }
    var vocabularyBoostEnabled: Bool { get }

    func saveSettings() throws
    func loadSettings()
    func isContentAllowed(theme: String, age: Int) -> Bool
    func canReadMoreStoriesToday() -> Bool
    func recordStoryRead()
    func resetDailyCount()
}
