#!/usr/bin/env swift

// Tool to generate valid access codes for testing purposes
// This creates codes with proper checksums that will validate

import Foundation
import CryptoKit

// Access code format and types
struct AccessCodeFormat {
    static let codeLength = 12
    static let prefixLength = 2
    static let checksumLength = 2
    static let dataLength = codeLength - prefixLength - checksumLength
    
    static let typePrefixes: [String: String] = [
        "reviewer": "RV",
        "press": "PR", 
        "demo": "DM",
        "unlimited": "UN",
        "specialAccess": "SA"
    ]
    
    static let allowedCharacters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
    
    static func calculateChecksum(for data: String) -> String {
        let hash = SHA256.hash(data: Data(data.utf8))
        let hashString = hash.compactMap { String(format: "%02x", $0) }.joined()
        
        let checksumValue = hashString.prefix(4).reduce(0) { result, char in
            result + Int(String(char), radix: 16)!
        }
        
        let char1Index = checksumValue % allowedCharacters.count
        let char2Index = (checksumValue / allowedCharacters.count) % allowedCharacters.count
        
        let char1 = allowedCharacters[allowedCharacters.index(allowedCharacters.startIndex, offsetBy: char1Index)]
        let char2 = allowedCharacters[allowedCharacters.index(allowedCharacters.startIndex, offsetBy: char2Index)]
        
        return String([char1, char2])
    }
}

// Generate access codes
func generateAccessCode(type: String) -> String {
    guard let prefix = AccessCodeFormat.typePrefixes[type] else {
        print("Error: Unknown type '\(type)'. Valid types: \(AccessCodeFormat.typePrefixes.keys.joined(separator: ", "))")
        exit(1)
    }
    
    // Generate random data portion
    let dataLength = AccessCodeFormat.dataLength
    let allowedChars = AccessCodeFormat.allowedCharacters
    let randomData = (0..<dataLength).map { _ in
        allowedChars.randomElement()!
    }
    let dataString = String(randomData)
    
    // Combine prefix and data
    let baseCode = prefix + dataString
    
    // Calculate and append checksum
    let checksum = AccessCodeFormat.calculateChecksum(for: baseCode)
    
    return baseCode + checksum
}

func formatCode(_ code: String) -> String {
    guard code.count == AccessCodeFormat.codeLength else { return code }
    
    let prefix = String(code.prefix(2))
    let middle1 = String(code.dropFirst(2).prefix(4))
    let middle2 = String(code.dropFirst(6).prefix(4))
    let suffix = String(code.suffix(2))
    
    return "\(prefix)-\(middle1)-\(middle2)-\(suffix)"
}

// Main function
print("=== Magical Stories Access Code Generator ===\n")
print("Generating valid access codes for testing purposes...\n")

let types = ["reviewer", "press", "demo", "unlimited", "specialAccess"]

for type in types {
    let code = generateAccessCode(type: type)
    let formattedCode = formatCode(code)
    let prefix = AccessCodeFormat.typePrefixes[type]!
    
    print("Type: \(type.capitalized)")
    print("Code: \(formattedCode)")
    print("Raw:  \(code)")
    
    // Show what features this code type grants
    switch type {
    case "reviewer":
        print("Features: Unlimited Story Generation, Advanced Illustrations")
        print("Duration: 30 days")
        print("Usage Limit: 50 uses")
    case "press":
        print("Features: Unlimited Story Generation, Growth Path Collections, Advanced Illustrations") 
        print("Duration: 14 days")
        print("Usage Limit: 25 uses")
    case "demo":
        print("Features: Unlimited Story Generation")
        print("Duration: 7 days")
        print("Usage Limit: 10 uses")
    case "unlimited":
        print("Features: All Premium Features")
        print("Duration: 365 days")
        print("Usage Limit: Unlimited")
    case "specialAccess":
        print("Features: Custom (must be explicitly defined)")
        print("Duration: 30 days")
        print("Usage Limit: Unlimited")
    default:
        break
    }
    
    print("")
}

print("=== Usage Instructions ===")
print("1. Copy any of the formatted codes above")
print("2. Open the Magical Stories app")
print("3. Go to Settings")
print("4. Tap 'Promo Code' card")
print("5. Enter the code (dashes are optional)")
print("6. Tap 'Redeem Code'")
print("")
print("Note: These codes are generated for testing and will validate properly.")
print("Each code can only be used once and will expire after the specified duration.")