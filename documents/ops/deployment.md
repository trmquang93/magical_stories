# Deployment Guide

## Overview
This document outlines the deployment and release procedures for the Magical Stories app, ensuring consistent and reliable releases to the App Store.

## Environment Setup

### Configuration Files
```swift
// Config structure for different environments
struct Environment {
    static var current: Environment {
        #if DEBUG
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
    
    let apiBaseURL: URL
    let analyticsEnabled: Bool
    let logLevel: LogLevel
    
    static let development = Environment(
        apiBaseURL: URL(string: "https://api-dev.magicalstories.app")!,
        analyticsEnabled: false,
        logLevel: .debug
    )
    
    static let staging = Environment(
        apiBaseURL: URL(string: "https://api-staging.magicalstories.app")!,
        analyticsEnabled: true,
        logLevel: .info
    )
    
    static let production = Environment(
        apiBaseURL: URL(string: "https://api.magicalstories.app")!,
        analyticsEnabled: true,
        logLevel: .warning
    )
}
```

### Configuration Management
```swift
// xcconfig files structure

// Base.xcconfig
PRODUCT_NAME = Magical Stories
PRODUCT_BUNDLE_IDENTIFIER = com.magicalstories.app
SWIFT_VERSION = 5.0
TARGETED_DEVICE_FAMILY = 1,2
IPHONEOS_DEPLOYMENT_TARGET = 16.0

// Development.xcconfig
#include "Base.xcconfig"
PRODUCT_BUNDLE_IDENTIFIER = com.magicalstories.app.dev
GOOGLE_AI_API_KEY = dev_api_key
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG DEVELOPMENT

// Staging.xcconfig
#include "Base.xcconfig"
PRODUCT_BUNDLE_IDENTIFIER = com.magicalstories.app.staging
GOOGLE_AI_API_KEY = staging_api_key
SWIFT_ACTIVE_COMPILATION_CONDITIONS = STAGING

// Production.xcconfig
#include "Base.xcconfig"
GOOGLE_AI_API_KEY = prod_api_key
SWIFT_ACTIVE_COMPILATION_CONDITIONS = PRODUCTION
```

## Build Process

### Build Phases
```bash
# Build Phase Script for Version Increment
if [ "${CONFIGURATION}" = "Release" ]; then
    # Increment build number
    buildNumber=$(/usr/libexec/PlistBuddy -c "Print CFBundleVersion" "${PROJECT_DIR}/${INFOPLIST_FILE}")
    buildNumber=$(($buildNumber + 1))
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion $buildNumber" "${PROJECT_DIR}/${INFOPLIST_FILE}"
fi
```

### Build Configurations
1. **Debug**
   - Development environment
   - Debugging enabled
   - Additional logging
   - No optimization

2. **Release**
   - Production environment
   - Debugging disabled
   - Optimization enabled
   - Minimal logging

## Release Process

### Pre-Release Checklist
```swift
struct ReleaseChecklist {
    static let items = [
        "Code freeze completed",
        "All tests passing",
        "Release notes prepared",
        "Screenshots updated",
        "Privacy policy current",
        "API compatibility verified",
        "Performance tests passed",
        "Accessibility review done",
        "Legal requirements met",
        "Marketing materials ready"
    ]
    
    static func validate() -> [String] {
        // Return list of incomplete items
        return []
    }
}
```

### Version Management
```swift
struct Version {
    let major: Int
    let minor: Int
    let patch: Int
    
    var string: String {
        "\(major).\(minor).\(patch)"
    }
    
    static func increment(
        _ version: Version,
        type: IncrementType
    ) -> Version {
        switch type {
        case .major:
            return Version(
                major: version.major + 1,
                minor: 0,
                patch: 0
            )
        case .minor:
            return Version(
                major: version.major,
                minor: version.minor + 1,
                patch: 0
            )
        case .patch:
            return Version(
                major: version.major,
                minor: version.minor,
                patch: version.patch + 1
            )
        }
    }
}

enum IncrementType {
    case major
    case minor
    case patch
}
```

## App Store Connect

### Metadata Management
```swift
struct AppStoreMetadata {
    static let categories = [
        "Education",
        "Books",
        "Kids"
    ]
    
    static let ageRating = "4+"
    
    static let keywords = [
        "bedtime stories",
        "children stories",
        "ai stories",
        "personalized stories",
        "kids books"
    ]
    
    static let supportURL = "https://support.magicalstories.app"
    static let marketingURL = "https://magicalstories.app"
    static let privacyPolicyURL = "https://magicalstories.app/privacy"
}
```

### Screenshot Generation
```swift
struct ScreenshotGenerator {
    static let devices = [
        "iPhone 14 Pro",
        "iPhone 14 Pro Max",
        "iPad Pro (12.9-inch)"
    ]
    
    static let languages = [
        "en-US",
        "es-ES",
        "fr-FR",
        "de-DE"
    ]
    
    static func generateScreenshots() {
        // Implementation using UI Tests
    }
}
```

## CI/CD Pipeline

### Fastlane Configuration
```ruby
# Fastfile
default_platform(:ios)

platform :ios do
  desc "Run tests"
  lane :test do
    scan(
      scheme: "MagicalStories",
      devices: ["iPhone 14 Pro"],
      clean: true
    )
  end
  
  desc "Build and upload to TestFlight"
  lane :beta do
    increment_build_number
    build_app(
      scheme: "MagicalStories",
      export_method: "app-store"
    )
    upload_to_testflight
  end
  
  desc "Deploy to App Store"
  lane :release do
    capture_screenshots
    upload_to_app_store(
      force: true,
      submit_for_review: true,
      automatic_release: true
    )
  end
end
```

### GitHub Actions Workflow
```yaml
name: iOS Release
on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2
      
      - name: Set up Ruby
        uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.0'
          
      - name: Install Fastlane
        run: bundle install
        
      - name: Build and Deploy
        env:
          APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
        run: bundle exec fastlane release
```

## Testing Strategy

### Pre-Release Testing
1. Unit Tests
2. Integration Tests
3. UI Tests
4. Performance Tests
5. Beta Testing

### Test Environments
```swift
enum TestEnvironment {
    case unitTest
    case integrationTest
    case uiTest
    
    var configuration: String {
        switch self {
        case .unitTest: return "Test"
        case .integrationTest: return "Staging"
        case .uiTest: return "UITest"
        }
    }
}
```

## Release Documentation

### Release Notes Template
```markdown
# Version X.Y.Z

## New Features
- Feature 1
- Feature 2

## Improvements
- Improvement 1
- Improvement 2

## Bug Fixes
- Fix 1
- Fix 2

## Security Updates
- Update 1
- Update 2
```

### Changelog Management
```swift
struct ChangelogEntry {
    let version: String
    let date: Date
    let changes: [Change]
    
    struct Change {
        let type: ChangeType
        let description: String
    }
    
    enum ChangeType: String {
        case feature = "✨"
        case improvement = "📈"
        case bugfix = "🐛"
        case security = "🔒"
    }
}
```

## Post-Release

### Monitoring
1. Crash Reports
2. User Feedback
3. Performance Metrics
4. App Store Reviews

### Rollback Plan
```swift
struct RollbackPlan {
    static let steps = [
        "Identify critical issue",
        "Stop automated rollout",
        "Prepare previous version",
        "Submit expedited review",
        "Monitor metrics",
        "Communicate with users"
    ]
    
    static func initiateRollback() {
        // Implementation
    }
}
```

## Best Practices

1. **Version Control**
   - Use semantic versioning
   - Tag releases
   - Maintain release branches
   - Document changes

2. **Testing**
   - Automated testing
   - Beta testing
   - Performance testing
   - Security testing

3. **Documentation**
   - Update release notes
   - Maintain changelog
   - Document known issues
   - Update support docs

4. **Communication**
   - Notify stakeholders
   - Update users
   - Monitor feedback
   - Respond to issues

## Release Checklist

- [ ] Code freeze
- [ ] Tests passed
- [ ] Documentation updated
- [ ] Screenshots current
- [ ] Release notes prepared
- [ ] Legal compliance verified
- [ ] Marketing materials ready
- [ ] Team notified
- [ ] Beta testing completed
- [ ] App Store submission ready

---

This document should be updated when:
- Release process changes
- New environments added
- Build process updates
- Testing requirements change
