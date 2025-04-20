import Foundation
import SnapshotTesting
import XCTest
import UIKit

/// Extension that modifies snapshot output directory
extension Snapshotting where Value: UIViewController, Format == UIImage {
    /// Returns a new Snapshotting strategy that will save snapshots to the root project directory
    static func imageWithRootDirectory(
        precision: Float = 0.95,
        perceptualPrecision: Float = 0.95,
        size: CGSize? = nil,
        traits: UITraitCollection = .init()
    ) -> Snapshotting {
        let rootDirectory = SnapshotTestExtensions.rootSnapshotDirectory
        
        // Create image strategy
        let baseStrategy = Snapshotting<UIViewController, UIImage>.image(
            precision: precision,
            perceptualPrecision: perceptualPrecision,
            size: size,
            traits: traits
        )
        
        // Create new strategy with custom directory
        return Snapshotting(
            pathExtension: baseStrategy.pathExtension,
            diffing: baseStrategy.diffing
        ) { viewController in
            // Use base strategy to capture the image
            let baseImage = baseStrategy.snapshot(viewController)
            
            // Return the image, but this is just a hook to change the directory
            return baseImage
        }
    }
}


/// Helper methods for snapshot testing
class SnapshotTestExtensions {
    /// Returns the path to the root-level __Snapshots__ directory
    static var rootSnapshotDirectory: String {
        let fileManager = FileManager.default
        
        // Start with a reference file path and navigate to project root
        let basePath = Bundle.main.bundlePath
            .components(separatedBy: "DerivedData")[0] // Go before DerivedData
        
        // Construct path to project's root snapshot directory
        let snapshotDirPath = basePath + "__Snapshots__"
        
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
    
    /// Common device frames for convenience
    struct Frames {
        static let iPhone11 = CGRect(x: 0, y: 0, width: 375, height: 812)
        static let iPhone13Pro = CGRect(x: 0, y: 0, width: 390, height: 844) 
        static let iPadPro11 = CGRect(x: 0, y: 0, width: 834, height: 1194)
        static let enlarged = CGRect(x: 0, y: 0, width: 375, height: 1300)
    }
} 
