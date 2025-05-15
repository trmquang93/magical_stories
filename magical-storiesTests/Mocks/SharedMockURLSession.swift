import Foundation
@testable import magical_stories

/// A mock URLSession implementation that can be shared across tests
class SharedMockURLSession: URLSessionProtocol {
    /// Stores all requests that have been made
    var capturedRequests: [URLRequest] = []
    
    /// Dictionary of response data by URL string
    private var responseData: [String: (statusCode: Int, data: Data)] = [:]
    
    /// Add a response for a specific URL path
    func addResponse(for urlPath: String, statusCode: Int, data: Data) {
        responseData[urlPath] = (statusCode, data)
    }
    
    /// Implements the URLSessionProtocol data method for URLRequest
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        capturedRequests.append(request)
        
        guard let url = request.url else {
            throw NSError(domain: "SharedMockURLSession", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // Find a matching response
        for (urlPath, response) in responseData {
            if url.absoluteString.contains(urlPath) {
                let httpResponse = HTTPURLResponse(
                    url: url,
                    statusCode: response.statusCode,
                    httpVersion: "HTTP/1.1",
                    headerFields: nil
                )!
                
                return (response.data, httpResponse)
            }
        }
        
        // No matching response found
        throw NSError(domain: "SharedMockURLSession", code: 404, userInfo: [NSLocalizedDescriptionKey: "No mock response defined for \(url.absoluteString)"])
    }
    
    /// Implements the URLSessionProtocol data method for URL
    func data(from url: URL) async throws -> (Data, URLResponse) {
        let request = URLRequest(url: url)
        return try await data(for: request)
    }
}