import Foundation
import CryptoKit
import CommonCrypto

/// Request signing service that provides HMAC-SHA256 request signing for API request integrity
/// Protects against request tampering and ensures API request authenticity
public final class RequestSigner: @unchecked Sendable {
    
    // MARK: - Constants
    
    /// HMAC signing key for request authentication
    private static let signingKey = "magical-stories-hmac-key-v1"
    
    /// Maximum timestamp age in seconds (5 minutes)
    private static let maxTimestampAge: TimeInterval = 300
    
    /// Signature version for compatibility tracking
    private static let signatureVersion = "1"
    
    // MARK: - Error Types
    
    public enum RequestSigningError: Error, LocalizedError {
        case invalidURL
        case invalidTimestamp
        case timestampExpired
        case invalidSignature
        case missingRequiredHeaders
        case signatureGenerationFailed
        case timestampValidationFailed
        case nonceValidationFailed
        case invalidSignatureFormat
        
        public var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid URL provided for request signing"
            case .invalidTimestamp:
                return "Invalid timestamp format"
            case .timestampExpired:
                return "Request timestamp has expired (max age: 5 minutes)"
            case .invalidSignature:
                return "Request signature validation failed"
            case .missingRequiredHeaders:
                return "Required signing headers are missing"
            case .signatureGenerationFailed:
                return "Failed to generate HMAC signature"
            case .timestampValidationFailed:
                return "Timestamp validation failed"
            case .nonceValidationFailed:
                return "Nonce validation failed"
            case .invalidSignatureFormat:
                return "Invalid signature format"
            }
        }
    }
    
    // MARK: - Initialization
    
    /// Initialize the request signer
    public init() {}
    
    // MARK: - Public Methods
    
    /// Signs a URLRequest with HMAC-SHA256 signature and required headers
    /// - Parameter request: The URLRequest to sign
    /// - Returns: A new URLRequest with signing headers added
    /// - Throws: RequestSigningError if signing fails
    public func signRequest(_ request: URLRequest) throws -> URLRequest {
        guard let url = request.url else {
            throw RequestSigningError.invalidURL
        }
        
        var signedRequest = request
        
        // Generate timestamp and nonce
        let timestamp = String(Int(Date().timeIntervalSince1970))
        let nonce = UUID().uuidString
        
        // Get method and path
        let method = request.httpMethod ?? "GET"
        let path = url.path
        
        // Calculate body hash
        let bodyHash = sha256Hash(request.httpBody ?? Data())
        
        // Create string to sign
        let stringToSign = "\(method)\n\(path)\n\(timestamp)\n\(nonce)\n\(bodyHash)"
        
        // Generate HMAC-SHA256 signature
        let signature = try hmacSHA256(stringToSign, key: Self.signingKey)
        
        // Add signing headers
        signedRequest.setValue(timestamp, forHTTPHeaderField: "X-Timestamp")
        signedRequest.setValue(nonce, forHTTPHeaderField: "X-Nonce")
        signedRequest.setValue(signature, forHTTPHeaderField: "X-Signature")
        signedRequest.setValue(Self.signatureVersion, forHTTPHeaderField: "X-Signature-Version")
        
        return signedRequest
    }
    
    /// Validates a signed request's timestamp and signature
    /// - Parameter request: The signed URLRequest to validate
    /// - Returns: True if the request is valid, false otherwise
    /// - Throws: RequestSigningError if validation fails
    public func validateRequest(_ request: URLRequest) throws -> Bool {
        guard let url = request.url else {
            throw RequestSigningError.invalidURL
        }
        
        // Extract required headers
        guard let timestamp = request.value(forHTTPHeaderField: "X-Timestamp"),
              let nonce = request.value(forHTTPHeaderField: "X-Nonce"),
              let signature = request.value(forHTTPHeaderField: "X-Signature"),
              let version = request.value(forHTTPHeaderField: "X-Signature-Version") else {
            throw RequestSigningError.missingRequiredHeaders
        }
        
        // Validate signature version
        guard version == Self.signatureVersion else {
            throw RequestSigningError.invalidSignatureFormat
        }
        
        // Validate timestamp
        try validateTimestamp(timestamp)
        
        // Validate nonce format
        try validateNonce(nonce)
        
        // Recreate string to sign
        let method = request.httpMethod ?? "GET"
        let path = url.path
        let bodyHash = sha256Hash(request.httpBody ?? Data())
        let stringToSign = "\(method)\n\(path)\n\(timestamp)\n\(nonce)\n\(bodyHash)"
        
        // Generate expected signature
        let expectedSignature = try hmacSHA256(stringToSign, key: Self.signingKey)
        
        // Compare signatures securely
        guard signature == expectedSignature else {
            throw RequestSigningError.invalidSignature
        }
        
        return true
    }
    
    /// Validates a timestamp to ensure it's not expired
    /// - Parameter timestamp: The timestamp string to validate
    /// - Returns: True if timestamp is valid, false otherwise
    /// - Throws: RequestSigningError if timestamp is invalid or expired
    public func validateTimestamp(_ timestamp: String) throws -> Bool {
        guard let timestampValue = TimeInterval(timestamp) else {
            throw RequestSigningError.invalidTimestamp
        }
        
        let currentTimestamp = Date().timeIntervalSince1970
        let age = currentTimestamp - timestampValue
        
        // Check if timestamp is not too old
        guard age >= 0 && age <= Self.maxTimestampAge else {
            throw RequestSigningError.timestampExpired
        }
        
        return true
    }
    
    /// Validates a nonce format
    /// - Parameter nonce: The nonce string to validate
    /// - Returns: True if nonce is valid, false otherwise
    /// - Throws: RequestSigningError if nonce is invalid
    public func validateNonce(_ nonce: String) throws -> Bool {
        // Validate UUID format for nonce
        guard UUID(uuidString: nonce) != nil else {
            throw RequestSigningError.nonceValidationFailed
        }
        
        return true
    }
    
    // MARK: - Private Methods
    
    /// Generates SHA256 hash of data
    /// - Parameter data: Data to hash
    /// - Returns: Hex string representation of hash
    private func sha256Hash(_ data: Data) -> String {
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    /// Generates HMAC-SHA256 signature
    /// - Parameters:
    ///   - string: String to sign
    ///   - key: HMAC key
    /// - Returns: Base64-encoded HMAC signature
    /// - Throws: RequestSigningError if signature generation fails
    private func hmacSHA256(_ string: String, key: String) throws -> String {
        guard let stringData = string.data(using: .utf8),
              let keyData = key.data(using: .utf8) else {
            throw RequestSigningError.signatureGenerationFailed
        }
        
        let symmetricKey = SymmetricKey(data: keyData)
        let signature = HMAC<SHA256>.authenticationCode(for: stringData, using: symmetricKey)
        
        return Data(signature).base64EncodedString()
    }
    
    /// Gets the maximum timestamp age for validation
    /// - Returns: Maximum timestamp age in seconds
    public static func getMaxTimestampAge() -> TimeInterval {
        return maxTimestampAge
    }
    
    /// Gets the current signature version
    /// - Returns: Current signature version string
    public static func getSignatureVersion() -> String {
        return signatureVersion
    }
}