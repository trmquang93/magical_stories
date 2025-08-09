import Foundation

extension Bundle {
    /// Get the app version string from Info.plist
    var appVersion: String {
        return infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }
    
    /// Get the build number from Info.plist
    var buildNumber: String {
        return infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }
    
    /// Get a combined version and build string
    var fullVersion: String {
        return "\(appVersion) (\(buildNumber))"
    }
}