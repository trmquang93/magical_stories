# Developer Setup Guide

Quick setup guide for new developers joining the Magical Stories project.

## Prerequisites

- macOS with Xcode 16+
- iOS 17.0+ deployment target
- Git access to this repository

## Quick Start

1. **Clone and setup** (first time only):
   ```bash
   git clone <repository-url>
   cd magical_stories
   ./scripts/setup-dev.sh
   ```

2. **Get your API key**:
   - Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Create a new API key
   - Copy the key (starts with `AIza`)

3. **Configure API key** (when prompted by setup script):
   ```bash
   ./scripts/setup-api-key.sh
   ```

4. **Build and run**:
   - Open `magical-stories.xcodeproj` in Xcode
   - Select iPhone simulator
   - Press ⌘+R to build and run

## Scripts Reference

| Script | Purpose |
|--------|---------|
| `./scripts/setup-dev.sh` | Complete development environment setup |
| `./scripts/setup-api-key.sh` | Configure/update API key only |
| `./scripts/check-setup.swift` | Verify current configuration |
| `./scripts/reset-dev-env.sh` | Clean reset for troubleshooting |

## Troubleshooting

### App crashes on launch
```bash
# Check if API key is configured
./scripts/check-setup.swift

# If not configured, set it up
./scripts/setup-api-key.sh
```

### Build failures
```bash
# Clean and reset everything
./scripts/reset-dev-env.sh

# Set up again
./scripts/setup-dev.sh
```

### Need to change API key
```bash
./scripts/setup-api-key.sh
# Choose option 2 to replace
```

## Security

- API keys are stored in macOS Keychain, **never in source code**
- Keys are not committed to version control
- Each developer manages their own API key locally

## Getting Help

1. Check this guide first
2. Run the setup scripts with fresh environment
3. Check build logs in Xcode
4. Ask team members for assistance

## Project Structure

```
magical_stories/
├── magical-stories.xcodeproj    # Main Xcode project
├── magical-stories-app/         # App source code
├── scripts/                     # Development scripts
├── DEVELOPER_SETUP.md          # This guide
└── README.md                   # Project documentation
```

Happy coding! 🚀