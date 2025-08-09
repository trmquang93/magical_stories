# Magical Stories Tools

This directory contains utility scripts and tools for development, testing, and maintenance of the Magical Stories app.

## Available Tools

### IllustrationServiceTester

A command-line tool for testing the `IllustrationService` integration with the Google Generative AI API.

**Purpose:**
- Perform end-to-end integration testing of the illustration generation service
- Test different prompts and themes to see how they affect the generated illustrations
- Verify that the API key and service configuration are working correctly

**Usage:**
```bash
cd magical-stories/Tools
swift IllustrationServiceTester.swift --prompt "Your story prompt" --theme "Your theme" [--api-key "YOUR_API_KEY"]
```

**Arguments:**
- `--prompt`: (Required) The text prompt for generating the illustration
- `--theme`: (Required) The theme for the illustration
- `--api-key`: (Optional) API key for Google AI services. If not provided, the tool will try to use the key from Config.plist

**Examples:**
```bash
# Using the API key from Config.plist
swift IllustrationServiceTester.swift --prompt "A happy elephant playing in water" --theme "Animal Adventures"

# Using a custom API key
swift IllustrationServiceTester.swift --prompt "A magical forest with glowing trees" --theme "Fantasy World" --api-key "YOUR_API_KEY"
```

**Output:**
The tool will output detailed information about the API request and response, including:
- The generated image path (if successful)
- Any errors that occurred during the process
- Request/response details for debugging

When an image is successfully generated, you can open it directly using the provided command.