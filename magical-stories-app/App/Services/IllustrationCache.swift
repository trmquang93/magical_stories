import Foundation

/// A thread-safe caching system for illustration data
/// Provides both memory and disk caching with automatic cleanup policies
public final class IllustrationCache: @unchecked Sendable {
    
    // MARK: - Shared Instance
    
    /// Shared instance of the illustration cache
    public static let shared = IllustrationCache()
    
    // MARK: - Configuration
    
    private struct CacheConfig {
        static let memoryLimit: Int = 50 * 1024 * 1024 // 50MB
        static let diskLimit: Int = 200 * 1024 * 1024  // 200MB
        static let maxCacheAge: TimeInterval = 7 * 24 * 3600 // 7 days
        static let cacheDirectoryName = "IllustrationCache"
    }
    
    // MARK: - Properties
    
    private let memoryCache: NSCache<NSString, NSData>
    private let diskCacheURL: URL
    private let fileManager: FileManager
    private let serialQueue: DispatchQueue
    
    // MARK: - Initialization
    
    /// Initializes the illustration cache
    /// - Parameter fileManager: File manager for disk operations
    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
        self.serialQueue = DispatchQueue(label: "com.magicalstories.illustrationcache", qos: .utility)
        
        // Configure memory cache
        self.memoryCache = NSCache<NSString, NSData>()
        self.memoryCache.totalCostLimit = CacheConfig.memoryLimit
        self.memoryCache.countLimit = 100 // Maximum 100 items in memory
        
        // Setup disk cache directory
        let cacheDir = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.diskCacheURL = cacheDir.appendingPathComponent(CacheConfig.cacheDirectoryName, isDirectory: true)
        
        // Create cache directory if needed
        try? fileManager.createDirectory(at: diskCacheURL, withIntermediateDirectories: true)
        
        // Perform initial cleanup
        Task {
            await performMaintenanceTasks()
        }
    }
    
    // MARK: - Public Interface
    
    /// Stores image data in both memory and disk cache
    /// - Parameters:
    ///   - data: Image data to store
    ///   - key: Unique key for the image
    public func storeImage(_ data: Data, forKey key: String) {
        let nsKey = NSString(string: key)
        let nsData = NSData(data: data)
        
        // Store in memory cache
        memoryCache.setObject(nsData, forKey: nsKey, cost: data.count)
        
        // Store in disk cache asynchronously
        serialQueue.async { [weak self] in
            self?.storeToDisk(data, forKey: key)
        }
    }
    
    /// Retrieves image data from cache
    /// - Parameter key: The key to look up
    /// - Returns: Image data if found, nil otherwise
    public func getImage(forKey key: String) -> Data? {
        let nsKey = NSString(string: key)
        
        // Try memory cache first
        if let nsData = memoryCache.object(forKey: nsKey) {
            return Data(referencing: nsData)
        }
        
        // Try disk cache
        return loadFromDisk(forKey: key)
    }
    
    /// Removes image data for a specific key
    /// - Parameter key: The key to remove
    public func removeImage(forKey key: String) {
        let nsKey = NSString(string: key)
        
        // Remove from memory cache
        memoryCache.removeObject(forKey: nsKey)
        
        // Remove from disk cache
        serialQueue.async { [weak self] in
            self?.removeFromDisk(forKey: key)
        }
    }
    
    /// Clears all cached data
    public func clearAll() {
        // Clear memory cache
        memoryCache.removeAllObjects()
        
        // Clear disk cache
        serialQueue.async { [weak self] in
            self?.clearDiskCache()
        }
    }
    
    /// Gets current cache size information
    /// - Returns: Tuple with memory and disk cache sizes in bytes
    public func getCacheSize() async -> (memory: Int, disk: Int) {
        let memorySize = getMemoryCacheSize()
        let diskSize = await getDiskCacheSize()
        return (memory: memorySize, disk: diskSize)
    }
    
    /// Performs cache maintenance (cleanup old files, enforce size limits)
    public func performMaintenance() async {
        await performMaintenanceTasks()
    }
}

// MARK: - Private Implementation

private extension IllustrationCache {
    
    /// Creates file URL for a cache key
    /// - Parameter key: Cache key
    /// - Returns: File URL for the cached item
    func fileURL(forKey key: String) -> URL {
        let filename = key.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? key
        return diskCacheURL.appendingPathComponent("\(filename).cache")
    }
    
    /// Stores data to disk cache
    /// - Parameters:
    ///   - data: Data to store
    ///   - key: Cache key
    func storeToDisk(_ data: Data, forKey key: String) {
        let fileURL = fileURL(forKey: key)
        
        do {
            try data.write(to: fileURL)
            
            // Set file attributes for cache management
            try fileManager.setAttributes([
                .creationDate: Date(),
                .modificationDate: Date()
            ], ofItemAtPath: fileURL.path)
            
        } catch {
            print("[IllustrationCache] Failed to store to disk: \(error.localizedDescription)")
        }
    }
    
    /// Loads data from disk cache
    /// - Parameter key: Cache key
    /// - Returns: Data if found and valid, nil otherwise
    func loadFromDisk(forKey key: String) -> Data? {
        let fileURL = fileURL(forKey: key)
        
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }
        
        // Check if file is within age limit
        do {
            let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
            if let modDate = attributes[.modificationDate] as? Date {
                if Date().timeIntervalSince(modDate) > CacheConfig.maxCacheAge {
                    // File is too old, remove it
                    try? fileManager.removeItem(at: fileURL)
                    return nil
                }
            }
            
            let data = try Data(contentsOf: fileURL)
            
            // Update access time and store in memory cache
            let nsKey = NSString(string: key)
            let nsData = NSData(data: data)
            memoryCache.setObject(nsData, forKey: nsKey, cost: data.count)
            
            return data
            
        } catch {
            print("[IllustrationCache] Failed to load from disk: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Removes item from disk cache
    /// - Parameter key: Cache key
    func removeFromDisk(forKey key: String) {
        let fileURL = fileURL(forKey: key)
        try? fileManager.removeItem(at: fileURL)
    }
    
    /// Clears entire disk cache
    func clearDiskCache() {
        do {
            let contents = try fileManager.contentsOfDirectory(at: diskCacheURL, includingPropertiesForKeys: nil)
            for fileURL in contents {
                try fileManager.removeItem(at: fileURL)
            }
        } catch {
            print("[IllustrationCache] Failed to clear disk cache: \(error.localizedDescription)")
        }
    }
    
    /// Gets current memory cache size
    /// - Returns: Approximate memory cache size in bytes
    func getMemoryCacheSize() -> Int {
        // NSCache doesn't provide exact size, so we estimate
        // This is an approximation based on cost limit usage
        return min(memoryCache.totalCostLimit, CacheConfig.memoryLimit)
    }
    
    /// Gets current disk cache size
    /// - Returns: Total disk cache size in bytes
    func getDiskCacheSize() async -> Int {
        return await withCheckedContinuation { continuation in
            serialQueue.async { [weak self] in
                guard let self = self else {
                    continuation.resume(returning: 0)
                    return
                }
                
                var totalSize = 0
                
                do {
                    let contents = try self.fileManager.contentsOfDirectory(
                        at: self.diskCacheURL,
                        includingPropertiesForKeys: [.fileSizeKey]
                    )
                    
                    for fileURL in contents {
                        let attributes = try self.fileManager.attributesOfItem(atPath: fileURL.path)
                        if let fileSize = attributes[.size] as? Int {
                            totalSize += fileSize
                        }
                    }
                } catch {
                    print("[IllustrationCache] Failed to calculate disk cache size: \(error.localizedDescription)")
                }
                
                continuation.resume(returning: totalSize)
            }
        }
    }
    
    /// Performs maintenance tasks (cleanup old files, enforce size limits)
    func performMaintenanceTasks() async {
        await withCheckedContinuation { continuation in
            serialQueue.async { [weak self] in
                self?.cleanupOldFiles()
                self?.enforceDiskSizeLimit()
                continuation.resume()
            }
        }
    }
    
    /// Removes files older than the cache age limit
    func cleanupOldFiles() {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: diskCacheURL,
                includingPropertiesForKeys: [.contentModificationDateKey]
            )
            
            let cutoffDate = Date().addingTimeInterval(-CacheConfig.maxCacheAge)
            
            for fileURL in contents {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                if let modDate = attributes[.modificationDate] as? Date,
                   modDate < cutoffDate {
                    try fileManager.removeItem(at: fileURL)
                }
            }
        } catch {
            print("[IllustrationCache] Failed to cleanup old files: \(error.localizedDescription)")
        }
    }
    
    /// Enforces disk cache size limit by removing oldest files
    func enforceDiskSizeLimit() {
        do {
            let contents = try fileManager.contentsOfDirectory(
                at: diskCacheURL,
                includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey]
            )
            
            // Calculate total size and collect file info
            var fileInfos: [(url: URL, size: Int, date: Date)] = []
            var totalSize = 0
            
            for fileURL in contents {
                let attributes = try fileManager.attributesOfItem(atPath: fileURL.path)
                guard let fileSize = attributes[.size] as? Int,
                      let modDate = attributes[.modificationDate] as? Date else {
                    continue
                }
                
                fileInfos.append((url: fileURL, size: fileSize, date: modDate))
                totalSize += fileSize
            }
            
            // If over limit, remove oldest files
            if totalSize > CacheConfig.diskLimit {
                let sortedFiles = fileInfos.sorted { $0.date < $1.date }
                
                for fileInfo in sortedFiles {
                    if totalSize <= CacheConfig.diskLimit {
                        break
                    }
                    
                    try fileManager.removeItem(at: fileInfo.url)
                    totalSize -= fileInfo.size
                }
            }
            
        } catch {
            print("[IllustrationCache] Failed to enforce disk size limit: \(error.localizedDescription)")
        }
    }
}