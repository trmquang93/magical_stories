# Security Guidelines

## Overview
This document outlines security best practices and implementation guidelines for the Magical Stories app, ensuring data protection and compliance with privacy regulations.

## API Key Security

### Configuration Management
```swift
// Config.xcconfig (Do NOT commit to version control)
GOOGLE_AI_API_KEY = your_api_key_here

// Example.xcconfig (Safe to commit)
GOOGLE_AI_API_KEY = your_api_key_here // Replace with actual key
```

### Key Storage
1. Use Xcode configuration files
2. Add `*.xcconfig` to `.gitignore`
3. Never hardcode keys in source code
4. Use different keys for development and production

### Key Access
```swift
enum SecureConfig {
    static let googleAIApiKey: String = {
        guard let key = Bundle.main.infoDictionary?["GOOGLE_AI_API_KEY"] as? String,
              !key.isEmpty else {
            fatalError("Google AI API key not found in configuration")
        }
        return key
    }()
}
```

## Data Protection

### Local Storage Security
```swift
enum DataProtection {
    static func enableDataProtection(for url: URL) throws {
        try (url as NSURL).setResourceValue(
            URLFileProtection.complete,
            forKey: .fileProtectionKey
        )
    }
    
    static func secureCacheDirectory() throws -> URL {
        let cacheDir = try FileManager.default.url(
            for: .cachesDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        
        try enableDataProtection(for: cacheDir)
        return cacheDir
    }
}
```

### Secure Data Models
```swift
// Add @SecureStorageWrapper to sensitive data
@propertyWrapper
struct SecureStorageWrapper<T> {
    private let key: String
    private let defaultValue: T
    
    init(key: String, defaultValue: T) {
        self.key = key
        self.defaultValue = defaultValue
    }
    
    var wrappedValue: T {
        get {
            // Implement secure storage retrieval
        }
        set {
            // Implement secure storage
        }
    }
}

// Usage example
struct UserData {
    @SecureStorageWrapper(key: "childName", defaultValue: "")
    var childName: String
}
```

## Network Security

### URLSession Configuration
```swift
struct NetworkSecurity {
    static var secureConfiguration: URLSessionConfiguration {
        let config = URLSessionConfiguration.default
        config.tlsMinimumSupportedProtocolVersion = .TLSv12
        config.httpAdditionalHeaders = [
            "X-Client-Version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
        ]
        return config
    }
    
    static var secureSession: URLSession {
        URLSession(configuration: secureConfiguration)
    }
}
```

### Certificate Pinning
```swift
class CertificatePinningDelegate: NSObject, URLSessionDelegate {
    private let pinnedCertificateHashes: [String]
    
    init(pinnedHashes: [String]) {
        self.pinnedCertificateHashes = pinnedHashes
        super.init()
    }
    
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard let serverTrust = challenge.protectionSpace.serverTrust,
              let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0) else {
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        let serverCertificateHash = calculateHash(certificate)
        
        if pinnedCertificateHashes.contains(serverCertificateHash) {
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
}
```

## Input Validation

### Story Generation Input
```swift
struct StoryInputValidator {
    static func validate(
        childName: String,
        age: Int,
        theme: String
    ) -> ValidationResult {
        // Validate child's name
        guard childName.count <= 50,
              childName.rangeOfCharacter(from: .alphanumerics) != nil else {
            return .failure(.invalidChildName)
        }
        
        // Validate age
        guard (3...10).contains(age) else {
            return .failure(.invalidAge)
        }
        
        // Validate theme
        guard !theme.isEmpty,
              !containsInappropriateContent(theme) else {
            return .failure(.invalidTheme)
        }
        
        return .success
    }
    
    private static func containsInappropriateContent(_ text: String) -> Bool {
        // Implementation of content filtering
        return false
    }
}

enum ValidationResult {
    case success
    case failure(ValidationError)
}

enum ValidationError: LocalizedError {
    case invalidChildName
    case invalidAge
    case invalidTheme
    
    var errorDescription: String? {
        switch self {
        case .invalidChildName:
            return "Please enter a valid name (up to 50 characters)"
        case .invalidAge:
            return "Age must be between 3 and 10"
        case .invalidTheme:
            return "Please enter an appropriate theme"
        }
    }
}
```

## Encryption

### Data Encryption
```swift
struct Encryption {
    static func encrypt(_ data: Data) throws -> Data {
        guard let key = generateKey() else {
            throw EncryptionError.keyGenerationFailed
        }
        
        // Store key in Keychain
        try storeKey(key)
        
        // Implement encryption
        return data // Replace with actual encryption
    }
    
    static func decrypt(_ data: Data) throws -> Data {
        guard let key = retrieveKey() else {
            throw EncryptionError.keyNotFound
        }
        
        // Implement decryption
        return data // Replace with actual decryption
    }
}

enum EncryptionError: Error {
    case keyGenerationFailed
    case keyNotFound
    case encryptionFailed
    case decryptionFailed
}
```

## Keychain Integration

### Keychain Service
```swift
class KeychainService {
    static let shared = KeychainService()
    
    func save(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status)
        }
    }
    
    func retrieve(_ key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data else {
            throw KeychainError.retrieveFailed(status)
        }
        
        return data
    }
}

enum KeychainError: Error {
    case saveFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)
}
```

## App Transport Security

### ATS Configuration
```xml
<!-- Info.plist -->
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <false/>
    <key>NSExceptionDomains</key>
    <dict>
        <key>api.example.com</key>
        <dict>
            <key>NSExceptionAllowsInsecureHTTPLoads</key>
            <false/>
            <key>NSIncludesSubdomains</key>
            <true/>
            <key>NSRequiresCertificateTransparency</key>
            <true/>
        </dict>
    </dict>
</dict>
```

## Security Monitoring

### Analytics Integration
```swift
struct SecurityAnalytics {
    static func logSecurityEvent(
        _ event: SecurityEvent,
        metadata: [String: Any]? = nil
    ) {
        let eventData: [String: Any] = [
            "event": event.rawValue,
            "timestamp": Date(),
            "metadata": metadata ?? [:]
        ]
        
        Analytics.logEvent("security_event", parameters: eventData)
    }
}

enum SecurityEvent: String {
    case invalidAuthAttempt = "invalid_auth_attempt"
    case certificatePinningFailure = "cert_pinning_failure"
    case encryptionFailure = "encryption_failure"
    case suspiciousActivity = "suspicious_activity"
}
```

## Best Practices

1. **API Security**
   - Use HTTPS for all network communications
   - Implement certificate pinning
   - Validate server responses
   - Implement rate limiting

2. **Data Protection**
   - Encrypt sensitive data
   - Use Keychain for secure storage
   - Implement proper access controls
   - Regular security audits

3. **Input Validation**
   - Validate all user inputs
   - Sanitize data before processing
   - Implement content filtering
   - Use proper error handling

4. **Code Security**
   - Keep dependencies updated
   - Regular security reviews
   - Implement proper logging
   - Use static analysis tools

5. **Testing**
   - Security penetration testing
   - Regular vulnerability assessments
   - Compliance testing
   - Error handling testing

## Security Checklist

- [ ] API keys securely stored
- [ ] Network calls use HTTPS
- [ ] Certificate pinning implemented
- [ ] Sensitive data encrypted
- [ ] Input validation in place
- [ ] Error handling implemented
- [ ] Logging configured properly
- [ ] Keychain integration tested
- [ ] ATS exceptions reviewed
- [ ] Security monitoring active

---

This document should be updated when:
- Security requirements change
- New features are added
- Vulnerabilities are discovered
- Best practices evolve
