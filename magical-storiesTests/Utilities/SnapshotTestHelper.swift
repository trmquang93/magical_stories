import Foundation
import SnapshotTesting
import SwiftUI

/// Helper class for snapshot testing, providing common functionality
/// such as standardized snapshot directory paths
class SnapshotTestHelper {
    /// Returns the path to the root-level __Snapshots__ directory
    /// This ensures all snapshots are stored in a centralized location
    static var rootSnapshotDirectory: String {
        let fileManager = FileManager.default
        
        // Start with a reference file path and navigate to project root
        let basePath = Bundle(for: SnapshotTestHelper.self).bundlePath
            .components(separatedBy: "DerivedData")[0] // Go before DerivedData
        
        // Construct path to project's root snapshot directory
        let snapshotDirPath = basePath + "magical_stories/__Snapshots__"
        
        // Create directory if it doesn't exist
        if !fileManager.fileExists(atPath: snapshotDirPath) {
            try? fileManager.createDirectory(
                atPath: snapshotDirPath,
                withIntermediateDirectories: true,
                attributes: nil
            )
        }
        
        return snapshotDirPath
    }
    
    /// Standard image diffing strategy for UIKit snapshots
    static func standardDiff(precision: Float = 0.95) -> Snapshotting<UIViewController, UIImage> {
        return .image(precision: precision, perceptualPrecision: precision)
    }
    
    /// Common device frames
    struct Frames {
        static let iPhone11 = CGRect(x: 0, y: 0, width: 375, height: 812)
        static let iPhone13Pro = CGRect(x: 0, y: 0, width: 390, height: 844)
        static let iPadPro11 = CGRect(x: 0, y: 0, width: 834, height: 1194)
        static let enlarged = CGRect(x: 0, y: 0, width: 375, height: 1300)
    }
} 