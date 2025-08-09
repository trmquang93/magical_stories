import Foundation

/// A persistent storage system for story illustrations that keeps images until explicitly deleted
/// Unlike IllustrationCache, this storage never expires or auto-deletes content
public final class PersistentIllustrationStore: @unchecked Sendable {
    
    // MARK: - Shared Instance
    
    /// Shared instance of the persistent illustration store
    public static let shared = PersistentIllustrationStore()
    
    // MARK: - Configuration
    
    private struct StoreConfig {
        static let memoryLimit: Int = 100 * 1024 * 1024 // 100MB memory cache
        static let storeDirectoryName = "StoryIllustrations"
    }
    
    // MARK: - Properties
    
    private let memoryCache: NSCache<NSString, NSData>
    private let storeURL: URL
    private let fileManager: FileManager
    private let serialQueue: DispatchQueue
    
    // MARK: - Initialization
    
    /// Initializes the persistent illustration store
    /// - Parameter fileManager: File manager for disk operations
    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.serialQueue = DispatchQueue(label: "com.magicalstories.persistentillustrationstore", qos: .utility)
        
        // Configure memory cache (for performance, but no size limits that would cause eviction)
        self.memoryCache = NSCache<NSString, NSData>()
        self.memoryCache.totalCostLimit = StoreConfig.memoryLimit
        self.memoryCache.countLimit = 200 // Reasonable limit to prevent excessive memory usage
        
        // Setup persistent storage directory in Documents (not Caches, to prevent iOS cleanup)
        let documentsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.storeURL = documentsDir.appendingPathComponent(StoreConfig.storeDirectoryName, isDirectory: true)
        
        // Create store directory if needed
        try? fileManager.createDirectory(at: storeURL, withIntermediateDirectories: true)
        
        print("[PersistentIllustrationStore] Initialized with storage at: \(storeURL.path)")
    }
    
    // MARK: - Public Interface
    
    /// Stores image data permanently until explicitly deleted
    /// - Parameters:
    ///   - data: Image data to store
    ///   - key: Unique key for the image (typically storyId_pageNumber)
    public func storeImage(_ data: Data, forKey key: String) {
        let nsKey = NSString(string: key)
        let nsData = NSData(data: data)
        
        // Store in memory cache for fast access
        memoryCache.setObject(nsData, forKey: nsKey, cost: data.count)
        
        // Store persistently on disk
        serialQueue.async { [weak self] in
            self?.storeToDisk(data, forKey: key)
        }
    }
    
    /// Retrieves image data from persistent storage
    /// - Parameter key: The key to look up
    /// - Returns: Image data if found, nil otherwise
    public func getImage(forKey key: String) -> Data? {
        let nsKey = NSString(string: key)
        
        // Try memory cache first for fast access
        if let nsData = memoryCache.object(forKey: nsKey) {
            return Data(referencing: nsData)
        }
        
        // Load from persistent disk storage
        return loadFromDisk(forKey: key)
    }
    
    /// Removes image data for a specific key (when user deletes story)
    /// - Parameter key: The key to remove
    public func removeImage(forKey key: String) {
        let nsKey = NSString(string: key)
        
        // Remove from memory cache
        memoryCache.removeObject(forKey: nsKey)
        
        // Remove from persistent storage
        serialQueue.async { [weak self] in
            self?.removeFromDisk(forKey: key)
        }
    }
    
    /// Removes all images for a specific story (when user deletes entire story)
    /// - Parameter storyId: The story UUID to remove all pages for
    public func removeImagesForStory(_ storyId: String) {
        serialQueue.async { [weak self] in
            self?.removeStoryFromDisk(storyId)
        }
        
        // Also remove from memory cache
        // Note: NSCache doesn't have a way to remove by prefix, so we'll let natural eviction handle this
    }
    
    /// Checks if an image exists for the given key
    /// - Parameter key: The key to check
    /// - Returns: True if image exists, false otherwise
    public func imageExists(forKey key: String) -> Bool {
        // Check memory cache first
        let nsKey = NSString(string: key)
        if memoryCache.object(forKey: nsKey) != nil {
            return true
        }
        
        // Check disk storage
        let fileURL = fileURL(forKey: key)
        return fileManager.fileExists(atPath: fileURL.path)
    }
    
    /// Gets current storage size information
    /// - Returns: Tuple with memory cache and disk storage sizes in bytes
    public func getStorageSize() async -> (memory: Int, disk: Int) {
        let memorySize = getMemoryCacheSize()
        let diskSize = await getDiskStorageSize()
        return (memory: memorySize, disk: diskSize)
    }
    
    /// Gets list of all stored image keys
    /// - Returns: Array of all stored image keys
    public func getAllStoredKeys() async -> [String] {
        return await withCheckedContinuation { continuation in
            serialQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: [])
                    return
                }
                
                do {
                    let contents = try self.fileManager.contentsOfDirectory(at: self.storeURL, includingPropertiesForKeys: nil)
                    let keys = contents.compactMap { url -> String? in
                        let filename = url.lastPathComponent
                        // Remove .store extension to get the key
                        return filename.hasSuffix(".store") ? String(filename.dropLast(6)) : nil
                    }
                    continuation.resume(returning: keys)
                } catch {
                    print("[PersistentIllustrationStore] Failed to list stored keys: \(error)")
                    continuation.resume(returning: [])
                }
            }
        }
    }
}

// MARK: - Private Implementation

private extension PersistentIllustrationStore {
    
    /// Creates file URL for a storage key
    /// - Parameter key: Storage key
    /// - Returns: File URL for the stored item
    func fileURL(forKey key: String) -> URL {
        let filename = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        return storeURL.appendingPathComponent("\(filename).store")
    }
    
    /// Stores data to persistent disk storage
    /// - Parameters:
    ///   - data: Data to store
    ///   - key: Storage key
    func storeToDisk(_ data: Data, forKey key: String) {
        let fileURL = fileURL(forKey: key)
        
        do {
            try data.write(to: fileURL)
            print("[PersistentIllustrationStore] Stored image for key: \(key) (\(data.count) bytes)")
        } catch {
            print("[PersistentIllustrationStore] Failed to store to disk: \(error.localizedDescription)")
        }
    }
    
    /// Loads data from persistent disk storage
    /// - Parameter key: Storage key
    /// - Returns: Data if found, nil otherwise
    func loadFromDisk(forKey key: String) -> Data? {
        let fileURL = fileURL(forKey: key)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        do {
            let data = try Data(contentsOf: fileURL)
            
            // Store in memory cache for future fast access
            let nsKey = NSString(string: key)
            let nsData = NSData(data: data)
            memoryCache.setObject(nsData, forKey: nsKey, cost: data.count)
            
            return data
            
        } catch {
            print("[PersistentIllustrationStore] Failed to load from disk: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Removes item from persistent disk storage
    /// - Parameter key: Storage key
    func removeFromDisk(forKey key: String) {
        let fileURL = fileURL(forKey: key)
        do {
            try fileManager.removeItem(at: fileURL)
            print("[PersistentIllustrationStore] Removed image for key: \(key)")
        } catch {
            print("[PersistentIllustrationStore] Failed to remove from disk: \(error.localizedDescription)")
        }
    }
    
    /// Removes all images for a story from persistent storage
    /// - Parameter storyId: The story UUID
    func removeStoryFromDisk(_ storyId: String) {
        do {
            let contents = try fileManager.contentsOfDirectory(at: storeURL, includingPropertiesForKeys: nil)
            
            // Find all files that start with the story ID
            let storyFiles = contents.filter { url in
                let filename = url.lastPathComponent
                return filename.hasPrefix(storyId)
            }
            
            for fileURL in storyFiles {
                try fileManager.removeItem(at: fileURL)
                print("[PersistentIllustrationStore] Removed story illustration: \(fileURL.lastPathComponent)")
            }
            
            print("[PersistentIllustrationStore] Removed \(storyFiles.count) illustrations for story: \(storyId)")
            
        } catch {
            print("[PersistentIllustrationStore] Failed to remove story illustrations: \(error.localizedDescription)")
        }
    }
    
    /// Gets current memory cache size
    /// - Returns: Approximate memory cache size in bytes
    func getMemoryCacheSize() -> Int {
        // NSCache doesn't provide exact size, estimate based on cost limit usage
        return min(memoryCache.totalCostLimit, StoreConfig.memoryLimit)
    }
    
    /// Gets current disk storage size
    /// - Returns: Total disk storage size in bytes
    func getDiskStorageSize() async -> Int {
        return await withCheckedContinuation { continuation in
            serialQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: 0)
                    return
                }
                
                var totalSize = 0
                
                do {
                    let contents = try self.fileManager.contentsOfDirectory(
                        at: self.storeURL,
                        includingPropertiesForKeys: [.fileSizeKey]
                    )
                    
                    for fileURL in contents {
                        let attributes = try self.fileManager.attributesOfItem(atPath: fileURL.path)
                        if let fileSize = attributes[.size] as? Int {
                            totalSize += fileSize
                        }
                    }
                } catch {
                    print("[PersistentIllustrationStore] Failed to calculate storage size: \(error.localizedDescription)")
                }
                
                continuation.resume(returning: totalSize)
            }
        }
    }
}