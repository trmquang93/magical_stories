#!/bin/bash

# Deploy legal pages to Firebase Hosting
# This script uses the service account key for authentication

set -e  # Exit on any error

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Set the service account key path
export GOOGLE_APPLICATION_CREDENTIALS="$SCRIPT_DIR/firebase-service-account.json"

# Check if service account file exists
if [ ! -f "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
    echo "❌ Service account key not found at: $GOOGLE_APPLICATION_CREDENTIALS"
    echo "Please ensure the firebase-service-account.json file is in the legal-pages directory"
    exit 1
fi

echo "🔑 Using service account: $GOOGLE_APPLICATION_CREDENTIALS"
echo "📂 Deploying from: $SCRIPT_DIR"
echo "🚀 Starting Firebase Hosting deployment..."

# Deploy to Firebase Hosting
firebase deploy --only hosting

echo "✅ Deployment completed successfully!"
echo "🌐 Your legal pages are now live at:"
echo "   https://magical-stories-60046.web.app/"
echo "   https://magical-stories-60046.firebaseapp.com/"