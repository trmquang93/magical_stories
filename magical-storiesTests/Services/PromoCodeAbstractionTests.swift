import XCTest
import Foundation
@testable import magical_stories

/// Simple tests to verify Phase 1 abstraction layer is working and Phase 2 ready
final class PromoCodeAbstractionTests: XCTestCase {
    
    func testAbstractionLayerBasics() {
        // Test that the factory can create services
        let factory = PromoCodeServiceFactory.shared
        let backendService = factory.createBackendService()
        let repository = factory.createRepository()
        
        // Verify services are created
        XCTAssertNotNil(backendService)
        XCTAssertNotNil(repository)
        
        // Test backend info
        let backendInfo = factory.currentBackendInfo
        XCTAssertEqual(backendInfo.configuredProvider, .offline)
        XCTAssertEqual(backendInfo.effectiveProvider, .offline)
    }
    
    func testOfflineImplementationsExist() {
        // Test that offline implementations are available
        let factory = PromoCodeServiceFactory.shared
        let backendService = factory.createBackendService()
        let repository = factory.createRepository()
        
        // These should be the offline implementations
        XCTAssertTrue(backendService is OfflinePromoCodeService)
        XCTAssertTrue(repository is OfflinePromoCodeRepository)
    }
    
    func testConfigurationManagement() {
        // Test configuration switching
        let config = BackendConfiguration.shared
        let originalProvider = config.currentProvider
        
        // Test switching to offline
        config.setProvider(.offline)
        XCTAssertEqual(config.currentProvider, .offline)
        XCTAssertEqual(config.getEffectiveProvider(), .offline)
        
        // Restore original
        config.setProvider(originalProvider)
    }
    
    func testDataStructures() {
        // Test that our abstraction data structures work
        let metadata = UsageMetadata(userId: "test123", deviceId: "device456")
        XCTAssertEqual(metadata.userId, "test123")
        XCTAssertEqual(metadata.deviceId, "device456")
        XCTAssertEqual(metadata.platform, "iOS")
        
        let filters = AnalyticsFilters(codeType: .demo, includeExpired: false)
        XCTAssertEqual(filters.codeType, .demo)
        XCTAssertFalse(filters.includeExpired)
        
        let analytics = CodeAnalytics(totalCodes: 10, usedCodes: 5, activeUsers: 3)
        XCTAssertEqual(analytics.totalCodes, 10)
        XCTAssertEqual(analytics.usedCodes, 5)
        XCTAssertEqual(analytics.activeUsers, 3)
    }
    
    func testPhase2Readiness() {
        // Test that the abstraction layer is ready for Phase 2 Firebase integration
        
        // These are the key integration points that Firebase will use:
        // 1. PromoCodeBackendService protocol
        // 2. PromoCodeRepository protocol  
        // 3. BackendConfiguration provider switching
        // 4. PromoCodeServiceFactory creation patterns
        
        let factory = PromoCodeServiceFactory.shared
        let config = BackendConfiguration.shared
        
        // Test provider capabilities
        XCTAssertTrue(config.canUseProvider(.offline))
        XCTAssertTrue(config.canUseProvider(.firebase)) // Network permitting
        XCTAssertTrue(config.canUseProvider(.customAPI)) // Network permitting
        
        // Test backend info structure
        let info = factory.currentBackendInfo
        XCTAssertNotNil(info.configuredProvider)
        XCTAssertNotNil(info.effectiveProvider)
        XCTAssertNotNil(info.statusDescription)
        
        // Test that the factory supports provider switching
        config.setProvider(.firebase)
        let firebaseService = factory.createBackendService()
        // Should fallback to offline since Firebase not implemented yet
        XCTAssertTrue(firebaseService is OfflinePromoCodeService)
        
        // Reset
        config.setProvider(.offline)
    }
}