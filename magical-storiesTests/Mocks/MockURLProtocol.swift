// MockURLProtocol.swift
// A URL protocol implementation for mocking network requests in tests

import Foundation

/// A URL protocol implementation that intercepts network requests and returns mock responses.
class MockURLProtocol: URLProtocol {
    
    // Typealias for mock response handler
    typealias URLResponseHandler = (URLRequest) -> (HTTPURLResponse, Data?, Error?)
    
    // Static registry of mock handlers
    static var responseHandlers: [String: URLResponseHandler] = [:]
    
    // Reset all mock handlers - call this between tests
    static func reset() {
        responseHandlers.removeAll()
    }
    
    // Register a mock response handler for a specific URL string
    static func registerMock(for urlString: String, handler: @escaping URLResponseHandler) {
        responseHandlers[urlString] = handler
    }
    
    // Register a standard JSON mock response
    static func registerJSONResponse(for urlString: String, statusCode: Int, data: Data) {
        registerMock(for: urlString) { _ in
            let response = HTTPURLResponse(
                url: URL(string: urlString)!,
                statusCode: statusCode,
                httpVersion: "HTTP/1.1",
                headerFields: ["Content-Type": "application/json"]
            )!
            return (response, data, nil)
        }
    }
    
    // Register an error response
    static func registerError(for urlString: String, error: Error) {
        registerMock(for: urlString) { _ in
            let response = HTTPURLResponse(
                url: URL(string: urlString)!,
                statusCode: 0,  // Not used for error responses
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, nil, error)
        }
    }
    
    // MARK: - URLProtocol implementation
    
    override class func canInit(with request: URLRequest) -> Bool {
        // Check if we have a registered handler for this URL
        guard let url = request.url?.absoluteString else { return false }
        return responseHandlers.keys.contains { url.contains($0) }
    }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }
    
    override func startLoading() {
        guard let url = request.url?.absoluteString else {
            fatalError("URL is nil. This should never happen as we check in canInit.")
        }
        
        // Find the handler for this URL
        guard let handler = Self.responseHandlers.first(where: { url.contains($0.key) })?.value else {
            fatalError("No mock response handler found for \(url)")
        }
        
        // Get the mock response
        let (response, data, error) = handler(request)
        
        // Deliver the response to the client
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        
        if let data = data {
            client?.urlProtocol(self, didLoad: data)
        }
        
        if let error = error {
            client?.urlProtocol(self, didFailWithError: error)
        }
        
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() {
        // Not needed for this implementation
    }
}