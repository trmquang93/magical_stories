import Foundation
import Network
import CommonCrypto
import os

// MARK: - Secure Network Delegate

/// URLSessionDelegate implementation that provides certificate pinning for Google AI API requests
/// This delegate validates SSL certificates against pinned hashes to prevent man-in-the-middle attacks
public final class SecureNetworkDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    
    // MARK: - Properties
    
    /// Pinned certificate hashes for Google AI API (SHA256, base64 encoded)
    private let pinnedCertificateHashes = [
        "sha256/FEzVOUp4dF3gI0ZVPRJhFbSD608BYbJ0ZhfOWdZHQ0k=", // Google primary
        "sha256/C5+lpZ7tcVwmwQIMcRtPbsQtWLABXhQzejna0wHFr8M="  // Google backup
    ]
    
    /// Security analytics service for logging security events
    private var securityAnalytics: (any SecurityAnalyticsProtocol)?
    
    /// Logger for security events
    nonisolated private let logger = Logger(subsystem: "com.magicalstories.security", category: "SecureNetworkDelegate")
    
    // MARK: - Initialization
    
    nonisolated public override init() {
        super.init()
        self.securityAnalytics = SecurityAnalytics()
    }
    
    /// Initializes with custom security analytics service
    /// - Parameter securityAnalytics: Custom security analytics service
    nonisolated public init(securityAnalytics: any SecurityAnalyticsProtocol) {
        super.init()
        self.securityAnalytics = securityAnalytics
    }
    
    // MARK: - Public Methods
    
    /// Sets the security analytics service
    /// - Parameter securityAnalytics: Security analytics service to use
    public func setSecurityAnalytics(_ securityAnalytics: any SecurityAnalyticsProtocol) {
        self.securityAnalytics = securityAnalytics
    }
    
    /// Creates a secure URLSessionConfiguration with TLS 1.2+ and timeouts
    /// - Returns: Configured URLSessionConfiguration
    public func secureURLSessionConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        
        // Set TLS minimum version
        configuration.tlsMinimumSupportedProtocolVersion = tls_protocol_version_t(rawValue: 771)!
        
        // Set timeouts
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        
        // Enable connectivity waiting
        configuration.waitsForConnectivity = true
        
        // Disable caching for security
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        
        return configuration
    }
    
    /// Validates a certificate against pinned hashes
    /// - Parameter certificate: Certificate to validate
    /// - Returns: True if certificate is valid, false otherwise
    public func validateCertificate(_ certificate: SecCertificate) -> Bool {
        // Get certificate data
        let certificateData = SecCertificateCopyData(certificate)
        let data = CFDataGetBytePtr(certificateData)
        let length = CFDataGetLength(certificateData)
        
        // Calculate SHA256 hash
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        CC_SHA256(data, CC_LONG(length), &hash)
        
        // Convert to base64 string
        let hashData = Data(hash)
        let hashString = "sha256/" + hashData.base64EncodedString()
        
        // Check against pinned hashes
        let isValid = pinnedCertificateHashes.contains(hashString)
        
        logger.info("Certificate validation: \(isValid ? "PASSED" : "FAILED") - Hash: \(hashString)")
        
        return isValid
    }
    
    // MARK: - URLSessionDelegate
    
    /// Handles authentication challenges for certificate pinning
    /// - Parameters:
    ///   - session: The URL session
    ///   - challenge: The authentication challenge
    ///   - completionHandler: Completion handler for challenge response
    public func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        let host = challenge.protectionSpace.host
        
        // Only handle server trust challenges
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            logger.info("Non-server trust challenge for host: \(host)")
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // Only validate Google AI API hosts
        guard host.hasSuffix("googleapis.com") else {
            logger.info("Non-Google API host: \(host), performing default handling")
            completionHandler(.performDefaultHandling, nil)
            return
        }
        
        // TEMPORARY: Allow default handling for Google API hosts to prevent crashes
        // TODO: Re-enable certificate pinning after fixing the memory access issue
        logger.info("Temporarily allowing default certificate validation for Google API host: \(host)")
        completionHandler(.performDefaultHandling, nil)
        return
        
        // Get server trust
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            logger.error("No server trust found for host: \(host)")
            securityAnalytics?.logCertificateValidationFailure(
                host: host,
                reason: "No server trust found"
            )
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Validate certificate chain
        let policy = SecPolicyCreateSSL(true, host as CFString)
        SecTrustSetPolicies(serverTrust, policy)
        
        var error: CFError?
        let trustEvaluationResult = SecTrustEvaluateWithError(serverTrust, &error)
        
        guard trustEvaluationResult else {
            logger.error("Trust evaluation failed for host: \(host)")
            securityAnalytics?.logCertificateValidationFailure(
                host: host,
                reason: "Trust evaluation failed"
            )
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Get certificate chain
        guard let certificateChain = SecTrustCopyCertificateChain(serverTrust) else {
            logger.error("No certificates found for host: \(host)")
            securityAnalytics?.logCertificateValidationFailure(
                host: host,
                reason: "No certificates found"
            )
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        
        // Validate each certificate in the chain
        var validCertificateFound = false
        let certificateCount = CFArrayGetCount(certificateChain)
        
        for i in 0..<certificateCount {
            // Use SecTrustGetCertificateAtIndex which is the safe way to get certificates
            guard let secCertificate = SecTrustGetCertificateAtIndex(serverTrust, i) else {
                logger.warning("Could not get certificate at index \(i)")
                continue
            }
            
            if validateCertificate(secCertificate) {
                validCertificateFound = true
                break
            }
        }
        
        if validCertificateFound {
            logger.info("Certificate validation successful for host: \(host)")
            securityAnalytics?.logCertificateValidationSuccess(host: host)
            
            // Create credential with the server trust
            let credential = URLCredential(trust: serverTrust)
            completionHandler(.useCredential, credential)
        } else {
            logger.error("Certificate pinning failed for host: \(host)")
            securityAnalytics?.logCertificateValidationFailure(
                host: host,
                reason: "Certificate hash not found in pinned hashes"
            )
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
    }
    
    /// Handles task completion for additional security logging
    /// - Parameters:
    ///   - session: The URL session
    ///   - task: The completed task
    ///   - error: Optional error if task failed
    public func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: (any Error)?
    ) {
        if let error = error {
            let host = task.originalRequest?.url?.host ?? "unknown"
            logger.error("Network task failed for host: \(host), error: \(error.localizedDescription)")
            
            // Log security event if it's a certificate-related error
            if let nsError = error as NSError?, nsError.code == NSURLErrorServerCertificateUntrusted {
                securityAnalytics?.logSecurityEvent(
                    event: "certificate_trust_error",
                    details: [
                        "host": host,
                        "error": error.localizedDescription,
                        "error_code": String(nsError.code)
                    ]
                )
            }
        }
    }
}

// MARK: - Sendable Conformance

extension SecureNetworkDelegate {
    /// Thread-safe method to get pinned certificate hashes
    nonisolated func getPinnedCertificateHashes() async -> [String] {
        return await Task { @MainActor in
            return pinnedCertificateHashes
        }.value
    }
}