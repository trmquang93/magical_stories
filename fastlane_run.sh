#!/bin/bash

# Load environment variables from .env file
if [ -f "fastlane/.env" ]; then
    export $(cat fastlane/.env | grep -v '^#' | xargs)
    echo "Loaded environment variables from fastlane/.env"
fi

# Run fastlane with all passed arguments
bundle exec fastlane "$@"