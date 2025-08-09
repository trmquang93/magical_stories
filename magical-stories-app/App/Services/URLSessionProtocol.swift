import Foundation

/// Protocol for URL session operations to allow mocking in tests
public protocol URLSessionProtocol: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
    func data(from url: URL) async throws -> (Data, URLResponse)
}

// Make URLSession conform to our protocol
extension URLSession: URLSessionProtocol {}

// URLSession is thread-safe so we can mark it as Sendable
extension URLSession: @unchecked Sendable {}
