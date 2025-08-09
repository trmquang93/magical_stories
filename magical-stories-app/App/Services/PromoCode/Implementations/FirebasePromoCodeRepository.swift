import Foundation

// MARK: - Firebase Repository Implementation

/// Firebase-based implementation of PromoCodeRepository
/// This implementation uses Firebase Firestore for promo code storage and retrieval
class FirebasePromoCodeRepository: PromoCodeRepository {
    
    // MARK: - Dependencies
    private let projectId: String
    private let apiKey: String
    private let baseURL: URL
    private let session: any URLSessionProtocol
    
    // MARK: - Configuration
    private let collectionName = "promoCodes"
    private let usageCollectionName = "promoCodeUsage"
    
    // MARK: - Initialization
    init(projectId: String = "magical-stories-promo-codes",
         apiKey: String = "your-firebase-api-key",
         session: any URLSessionProtocol = URLSession.shared) {
        self.projectId = projectId
        self.apiKey = apiKey
        self.baseURL = URL(string: "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/(default)/documents")!
        self.session = session
    }
    
    // MARK: - PromoCodeRepository Implementation
    
    func storeCodeAsync(_ code: StoredAccessCode) async throws {
        let documentURL = baseURL.appendingPathComponent("\(collectionName)/\(code.accessCode.code)")
        
        var request = URLRequest(url: documentURL)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let firebaseDoc = createFirebaseDocument(from: code)
        request.httpBody = try JSONSerialization.data(withJSONObject: firebaseDoc)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RepositoryError.storageUnavailable
        }
        
        switch httpResponse.statusCode {
        case 200, 201:
            if EnvironmentConfig.shouldLog {
                print("FirebasePromoCodeRepository: Successfully stored code: \(code.accessCode.code)")
            }
            
        case 409:
            throw RepositoryError.duplicateCode(code.accessCode.code)
            
        default:
            throw RepositoryError.storageUnavailable
        }
    }
    
    func fetchCodeAsync(_ codeString: String) async throws -> StoredAccessCode? {
        let documentURL = baseURL.appendingPathComponent("\(collectionName)/\(codeString)")
        
        var request = URLRequest(url: documentURL)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        do {
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw RepositoryError.storageUnavailable
            }
            
            switch httpResponse.statusCode {
            case 200:
                let firebaseDoc = try JSONDecoder().decode(FirebaseDocumentResponse.self, from: data)
                let storedCode = try parseStoredAccessCode(from: firebaseDoc)
                
                if EnvironmentConfig.shouldLog {
                    print("FirebasePromoCodeRepository: Successfully fetched code: \(codeString)")
                }
                
                return storedCode
                
            case 404:
                return nil
                
            default:
                throw RepositoryError.storageUnavailable
            }
            
        } catch {
            if error is RepositoryError {
                throw error
            }
            throw RepositoryError.storageUnavailable
        }
    }
    
    func updateCodeUsageAsync(_ code: String, _ usage: CodeUsageData) async throws {
        let usageDocumentURL = baseURL.appendingPathComponent("\(usageCollectionName)/\(code)")
        
        var request = URLRequest(url: usageDocumentURL)
        request.httpMethod = "PATCH"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let usageFields = createUsageFields(from: usage)
        let updateDoc = ["fields": usageFields]
        request.httpBody = try JSONSerialization.data(withJSONObject: updateDoc)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw RepositoryError.storageUnavailable
        }
        
        if EnvironmentConfig.shouldLog {
            print("FirebasePromoCodeRepository: Updated usage for code: \(code)")
        }
    }
    
    func removeCodeAsync(_ code: String) async throws {
        let documentURL = baseURL.appendingPathComponent("\(collectionName)/\(code)")
        
        var request = URLRequest(url: documentURL)
        request.httpMethod = "DELETE"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw RepositoryError.storageUnavailable
        }
        
        switch httpResponse.statusCode {
        case 200, 204:
            if EnvironmentConfig.shouldLog {
                print("FirebasePromoCodeRepository: Successfully removed code: \(code)")
            }
            
        case 404:
            throw RepositoryError.codeNotFound(code)
            
        default:
            throw RepositoryError.storageUnavailable
        }
    }
    
    func getAllCodesAsync() async throws -> [StoredAccessCode] {
        let collectionURL = baseURL.appendingPathComponent(collectionName)
        
        var request = URLRequest(url: collectionURL)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw RepositoryError.storageUnavailable
        }
        
        let queryResponse = try JSONDecoder().decode(FirebaseCollectionResponse.self, from: data)
        let storedCodes = try parseStoredAccessCodes(from: queryResponse)
        
        if EnvironmentConfig.shouldLog {
            print("FirebasePromoCodeRepository: Retrieved \(storedCodes.count) codes from Firebase")
        }
        
        return storedCodes
    }
    
    func getActiveCodesAsync() async throws -> [StoredAccessCode] {
        // Firebase query for active codes only
        let queryURL = baseURL.appendingPathComponent(collectionName)
        
        var urlComponents = URLComponents(url: queryURL, resolvingAgainstBaseURL: false)!
        
        // Add Firebase query parameters for active codes
        urlComponents.queryItems = [
            URLQueryItem(name: "pageSize", value: "100"),
            URLQueryItem(name: "orderBy", value: "isActive desc")
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw RepositoryError.storageUnavailable
        }
        
        let queryResponse = try JSONDecoder().decode(FirebaseCollectionResponse.self, from: data)
        let allCodes = try parseStoredAccessCodes(from: queryResponse)
        
        // Filter for truly active codes (not expired, not usage-exhausted)
        let activeCodes = allCodes.filter { $0.accessCode.isValid }
        
        if EnvironmentConfig.shouldLog {
            print("FirebasePromoCodeRepository: Retrieved \(activeCodes.count) active codes from Firebase")
        }
        
        return activeCodes
    }
    
    func cleanupExpiredCodesAsync() async throws {
        // Get all codes first
        let allCodes = try await getAllCodesAsync()
        let expiredCodes = allCodes.filter { $0.accessCode.isExpired }
        
        // Batch delete expired codes
        for expiredCode in expiredCodes {
            do {
                try await removeCodeAsync(expiredCode.accessCode.code)
            } catch {
                // Continue with other codes even if one fails
                if EnvironmentConfig.shouldLog {
                    print("FirebasePromoCodeRepository: Failed to remove expired code: \(expiredCode.accessCode.code)")
                }
            }
        }
        
        if EnvironmentConfig.shouldLog {
            print("FirebasePromoCodeRepository: Cleaned up \(expiredCodes.count) expired codes")
        }
    }
}

// MARK: - Firebase Response Models

private struct FirebaseDocumentResponse: Codable {
    let name: String
    let fields: [String: FirebaseFieldValue]
    let createTime: String
    let updateTime: String
}

private struct FirebaseCollectionResponse: Codable {
    let documents: [FirebaseDocumentResponse]?
    let nextPageToken: String?
}

private struct FirebaseFieldValue: Codable {
    let stringValue: String?
    let integerValue: String?
    let booleanValue: Bool?
    let timestampValue: String?
    let arrayValue: FirebaseArrayFieldValue?
}

private struct FirebaseArrayFieldValue: Codable {
    let values: [FirebaseFieldValue]?
}

// Remove unused struct that causes encoding issues

// MARK: - Helper Methods

private extension FirebasePromoCodeRepository {
    
    func createFirebaseDocument(from storedCode: StoredAccessCode) -> [String: Any] {
        let accessCode = storedCode.accessCode
        
        var fields: [String: [String: Any]] = [:]
        
        // Basic fields
        fields["code"] = ["stringValue": accessCode.code]
        fields["type"] = ["stringValue": accessCode.type.rawValue]
        fields["isActive"] = ["booleanValue": accessCode.isActive]
        fields["usageCount"] = ["integerValue": String(accessCode.usageCount)]
        
        // Optional fields
        if let usageLimit = accessCode.usageLimit {
            fields["usageLimit"] = ["integerValue": String(usageLimit)]
        }
        
        if let expiresAt = accessCode.expiresAt {
            fields["expiresAt"] = ["timestampValue": ISO8601DateFormatter().string(from: expiresAt)]
        }
        
        // Granted features array
        let featuresArray = accessCode.grantedFeatures.map { feature in
            ["stringValue": feature.rawValue]
        }
        fields["grantedFeatures"] = ["arrayValue": ["values": featuresArray]]
        
        // Stored code specific fields
        fields["activatedAt"] = ["timestampValue": ISO8601DateFormatter().string(from: storedCode.activatedAt)]
        
        if let lastUsedAt = storedCode.lastUsedAt {
            fields["lastUsedAt"] = ["timestampValue": ISO8601DateFormatter().string(from: lastUsedAt)]
        }
        
        return ["fields": fields]
    }
    
    func parseStoredAccessCode(from firebaseDoc: FirebaseDocumentResponse) throws -> StoredAccessCode {
        let fields = firebaseDoc.fields
        
        guard let codeString = fields["code"]?.stringValue,
              let typeString = fields["type"]?.stringValue,
              let type = AccessCodeType(rawValue: typeString) else {
            throw RepositoryError.invalidData
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
        
        var activatedAt = Date()
        if let activatedString = fields["activatedAt"]?.timestampValue {
            activatedAt = ISO8601DateFormatter().date(from: activatedString) ?? Date()
        }
        
        var lastUsedAt: Date?
        if let lastUsedString = fields["lastUsedAt"]?.timestampValue {
            lastUsedAt = ISO8601DateFormatter().date(from: lastUsedString)
        }
        
        return StoredAccessCode(
            accessCode: accessCode,
            activatedAt: activatedAt,
            lastUsedAt: lastUsedAt
        )
    }
    
    func parseStoredAccessCodes(from response: FirebaseCollectionResponse) throws -> [StoredAccessCode] {
        guard let documents = response.documents else {
            return []
        }
        
        return try documents.compactMap { document in
            try parseStoredAccessCode(from: document)
        }
    }
    
    func createUsageFields(from usage: CodeUsageData) -> [String: [String: Any]] {
        var fields: [String: [String: Any]] = [:]
        
        fields["usageCount"] = ["integerValue": String(usage.usageCount)]
        
        if let lastUsedAt = usage.lastUsedAt {
            fields["lastUsedAt"] = ["timestampValue": ISO8601DateFormatter().string(from: lastUsedAt)]
        }
        
        // Device IDs array
        let deviceIdsArray = usage.deviceIds.map { deviceId in
            ["stringValue": deviceId]
        }
        fields["deviceIds"] = ["arrayValue": ["values": deviceIdsArray]]
        
        // User IDs array
        let userIdsArray = usage.userIds.map { userId in
            ["stringValue": userId]
        }
        fields["userIds"] = ["arrayValue": ["values": userIdsArray]]
        
        return fields
    }
}