import Foundation
import Combine

// MARK: - Firebase Service Implementation

/// Firebase-based implementation of PromoCodeBackendService
/// This implementation integrates with Firebase Firestore for promo code validation and management
@MainActor
class FirebasePromoCodeService: PromoCodeBackendService {
    
    // MARK: - Dependencies
    private let projectId: String
    private let apiKey: String
    private let baseURL: URL
    nonisolated private let session: any URLSessionProtocol
    
    // MARK: - Configuration
    private let collectionName = "promoCodes"
    private let analyticsCollection = "promoCodeAnalytics"
    
    // MARK: - Initialization
    init(projectId: String = "magical-stories-promo-codes",
         apiKey: String = "your-firebase-api-key",
         session: any URLSessionProtocol = URLSession.shared) {
        self.projectId = projectId
        self.apiKey = apiKey
        self.baseURL = URL(string: "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents")!
        self.session = session
    }
    
    // MARK: - PromoCodeBackendService Implementation
    
    func validateCodeAsync(_ code: String) async throws -> BackendValidationResult {
        // Firebase Firestore document retrieval
        let documentURL = baseURL.appendingPathComponent("\(collectionName)/\(code)")
        
        var request = URLRequest(url: documentURL)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AccessCodeValidationError.networkError("Invalid response")
            }
            
            switch httpResponse.statusCode {
            case 200:
                // Parse Firebase document response
                let firebaseDoc = try JSONDecoder().decode(FirebaseDocument.self, from: data)
                let accessCode = try parseAccessCodeFromFirebase(firebaseDoc)
                
                // Validate the code is still active and not expired
                guard accessCode.isValid else {
                    if accessCode.isExpired {
                        throw AccessCodeValidationError.codeExpired(expirationDate: accessCode.expiresAt ?? Date())
                    } else if accessCode.isUsageLimitReached {
                        throw AccessCodeValidationError.usageLimitReached(limit: accessCode.usageLimit ?? 0)
                    } else {
                        throw AccessCodeValidationError.codeInactive
                    }
                }
                
                let result = BackendValidationResult(
                    accessCode: accessCode,
                    validatedAt: Date(),
                    backendProvider: .firebase,
                    isOfflineValidation: false,
                    serverMetadata: [
                        "firebase_document_id": firebaseDoc.name,
                        "server_timestamp": firebaseDoc.updateTime,
                        "validation_server": "firebase-firestore"
                    ]
                )
                
                if EnvironmentConfig.shouldLog {
                    print("FirebasePromoCodeService: Successfully validated code via Firebase")
                }
                
                return result
                
            case 404:
                throw AccessCodeValidationError.codeNotFound
                
            default:
                throw AccessCodeValidationError.networkError("Firebase error: \(httpResponse.statusCode)")
            }
            
        } catch {
            if EnvironmentConfig.shouldLog {
                print("FirebasePromoCodeService: Validation failed - \(error)")
            }
            
            // Re-throw known errors
            if let validationError = error as? AccessCodeValidationError {
                throw validationError
            }
            
            // Wrap network errors
            throw AccessCodeValidationError.networkError(error.localizedDescription)
        }
    }
    
    func trackUsageAsync(_ code: String, _ metadata: UsageMetadata) async throws {
        // Create usage tracking document in Firebase
        let usageData = FirebaseUsageData(
            codeId: code,
            userId: metadata.userId,
            deviceId: metadata.deviceId,
            appVersion: metadata.appVersion,
            platform: metadata.platform,
            timestamp: metadata.timestamp,
            location: metadata.location
        )
        
        let analyticsURL = baseURL.appendingPathComponent("\(analyticsCollection)")
        
        var request = URLRequest(url: analyticsURL)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let usageFields = usageData.toFirebaseFields()
        let requestBody = ["fields": usageFields]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AccessCodeValidationError.networkError("Failed to track usage")
        }
        
        if EnvironmentConfig.shouldLog {
            print("FirebasePromoCodeService: Usage tracked successfully for code: \(code)")
        }
    }
    
    func getAnalyticsAsync(_ filters: AnalyticsFilters) async throws -> CodeAnalytics {
        // Query Firebase for analytics data
        let queryURL = baseURL.appendingPathComponent("\(analyticsCollection)")
        
        var request = URLRequest(url: queryURL)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw AccessCodeValidationError.networkError("Failed to retrieve analytics")
        }
        
        let firebaseResponse = try JSONDecoder().decode(FirebaseQueryResponse.self, from: data)
        let analytics = try processFirebaseAnalytics(firebaseResponse, filters: filters)
        
        if EnvironmentConfig.shouldLog {
            print("FirebasePromoCodeService: Retrieved analytics for \(analytics.totalCodes) codes")
        }
        
        return analytics
    }
    
    func isBackendAvailable() async -> Bool {
        // Simple connectivity check to Firebase
        let healthCheckURL = URL(string: "https://firebase.googleapis.com/")!
        
        do {
            let (_, response) = try await session.data(from: healthCheckURL)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
}

// MARK: - Firebase Data Models

private struct FirebaseDocument: Codable {
    let name: String
    let fields: [String: FirebaseValue]
    let createTime: String
    let updateTime: String
}

private struct FirebaseValue: Codable {
    let stringValue: String?
    let integerValue: String?
    let booleanValue: Bool?
    let timestampValue: String?
    let arrayValue: FirebaseArrayValue?
}

private struct FirebaseArrayValue: Codable {
    let values: [FirebaseValue]?
}

private struct FirebaseQueryResponse: Codable {
    let documents: [FirebaseDocument]?
}

private struct FirebaseUsageData: Codable {
    let codeId: String
    let userId: String?
    let deviceId: String?
    let appVersion: String
    let platform: String
    let timestamp: Date
    let location: String?
    
    func toFirebaseFields() -> [String: [String: Any]] {
        var fields: [String: [String: Any]] = [:]
        
        fields["codeId"] = ["stringValue": codeId]
        fields["appVersion"] = ["stringValue": appVersion]
        fields["platform"] = ["stringValue": platform]
        fields["timestamp"] = ["timestampValue": ISO8601DateFormatter().string(from: timestamp)]
        
        if let userId = userId {
            fields["userId"] = ["stringValue": userId]
        }
        
        if let deviceId = deviceId {
            fields["deviceId"] = ["stringValue": deviceId]
        }
        
        if let location = location {
            fields["location"] = ["stringValue": location]
        }
        
        return fields
    }
}

// MARK: - Helper Methods

private extension FirebasePromoCodeService {
    
    func parseAccessCodeFromFirebase(_ document: FirebaseDocument) throws -> AccessCode {
        let fields = document.fields
        
        guard let codeString = fields["code"]?.stringValue,
              let typeString = fields["type"]?.stringValue,
              let type = AccessCodeType(rawValue: typeString) else {
            throw AccessCodeValidationError.invalidFormat
        }
        
        let isActive = fields["isActive"]?.booleanValue ?? true
        let usageCount = Int(fields["usageCount"]?.integerValue ?? "0") ?? 0
        let usageLimit = fields["usageLimit"]?.integerValue.flatMap(Int.init)
        
        var expiresAt: Date?
        if let expirationString = fields["expiresAt"]?.timestampValue {
            expiresAt = ISO8601DateFormatter().date(from: expirationString)
        }
        
        var grantedFeatures: [PremiumFeature] = []
        if let featuresArray = fields["grantedFeatures"]?.arrayValue?.values {
            grantedFeatures = featuresArray.compactMap { value in
                guard let featureString = value.stringValue else { return nil }
                return PremiumFeature(rawValue: featureString)
            }
        }
        
        let accessCode = AccessCode(
            code: codeString,
            type: type,
            grantedFeatures: grantedFeatures.isEmpty ? type.defaultGrantedFeatures : grantedFeatures,
            expiresAt: expiresAt,
            usageLimit: usageLimit,
            usageCount: usageCount,
            isActive: isActive
        )
        
        return accessCode
    }
    
    func processFirebaseAnalytics(_ response: FirebaseQueryResponse, filters: AnalyticsFilters) throws -> CodeAnalytics {
        let documents = response.documents ?? []
        
        // Process documents and apply filters
        var filteredUsage: [FirebaseUsageData] = []
        
        for document in documents {
            // Parse usage data from Firebase document
            let fields = document.fields
            
            guard let codeId = fields["codeId"]?.stringValue,
                  let platform = fields["platform"]?.stringValue,
                  let appVersion = fields["appVersion"]?.stringValue,
                  let timestampString = fields["timestamp"]?.timestampValue,
                  let timestamp = ISO8601DateFormatter().date(from: timestampString) else {
                continue
            }
            
            let usageData = FirebaseUsageData(
                codeId: codeId,
                userId: fields["userId"]?.stringValue,
                deviceId: fields["deviceId"]?.stringValue,
                appVersion: appVersion,
                platform: platform,
                timestamp: timestamp,
                location: fields["location"]?.stringValue
            )
            
            // Apply filters
            if let dateRange = filters.dateRange,
               !dateRange.contains(timestamp) {
                continue
            }
            
            filteredUsage.append(usageData)
        }
        
        // Calculate analytics
        let uniqueCodes = Set(filteredUsage.map { $0.codeId })
        let uniqueUsers = Set(filteredUsage.compactMap { $0.userId })
        
        // Group by date
        let calendar = Calendar.current
        var usageByDate: [Date: Int] = [:]
        
        for usage in filteredUsage {
            let dateKey = calendar.startOfDay(for: usage.timestamp)
            usageByDate[dateKey, default: 0] += 1
        }
        
        // For type breakdown, we'd need to query the codes collection
        // For now, provide a simplified version
        let usageByType: [AccessCodeType: Int] = [:]
        
        let analytics = CodeAnalytics(
            totalCodes: uniqueCodes.count,
            usedCodes: uniqueCodes.count, // All queried codes are considered "used"
            activeUsers: uniqueUsers.count,
            usageByType: usageByType,
            usageByDate: usageByDate,
            generatedAt: Date()
        )
        
        return analytics
    }
}

// MARK: - Firebase Error Types

private enum FirebaseError: LocalizedError {
    case invalidResponse
    case documentNotFound
    case permissionDenied
    case quotaExceeded
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from Firebase"
        case .documentNotFound:
            return "Document not found in Firebase"
        case .permissionDenied:
            return "Permission denied for Firebase operation"
        case .quotaExceeded:
            return "Firebase quota exceeded"
        }
    }
}