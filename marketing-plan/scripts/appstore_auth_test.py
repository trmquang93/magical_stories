#!/usr/bin/env python3
"""
Fixed JWT Token Generator using proper JWT library
This should handle the signature format correctly for Apple's App Store Connect API
"""

import jwt
import time
import sys
import os
from cryptography.hazmat.primitives import serialization

def generate_jwt_token():
    # Configuration
    KEY_ID = "RHM24L7VXD"
    ISSUER_ID = "c419fd84-aa0b-4d05-9688-19d736cc2575"
    PRIVATE_KEY_PATH = "/Users/quang.tranminh/Library/Mobile Documents/com~apple~CloudDocs/DevelopmentCertificates/AuthKey_RHM24L7VXD.p8"
    
    # Check if private key exists
    if not os.path.exists(PRIVATE_KEY_PATH):
        print(f"Error: Private key not found at {PRIVATE_KEY_PATH}", file=sys.stderr)
        sys.exit(1)
    
    # Read and parse the private key
    try:
        with open(PRIVATE_KEY_PATH, 'rb') as key_file:
            private_key = serialization.load_pem_private_key(
                key_file.read(),
                password=None
            )
    except Exception as e:
        print(f"Error loading private key: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Generate timestamps
    now = int(time.time())
    exp = now + 1200  # 20 minutes from now
    
    # Create JWT payload
    payload = {
        "iss": ISSUER_ID,
        "iat": now,
        "exp": exp,
        "aud": "appstoreconnect-v1"
    }
    
    # Create JWT headers
    headers = {
        "kid": KEY_ID,
        "typ": "JWT"
    }
    
    # Generate JWT token using the proper library
    try:
        token = jwt.encode(
            payload, 
            private_key, 
            algorithm="ES256",
            headers=headers
        )
        return token
    except Exception as e:
        print(f"Error generating JWT: {e}", file=sys.stderr)
        sys.exit(1)

def test_token(token):
    """Test the token with App Store Connect API"""
    import requests
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    # Try different endpoints to see which one works
    endpoints_to_test = [
        ("/v1/apps", "Apps endpoint"),
        ("/v1/users/me", "Current user endpoint"),
        ("/v1/analyticsReports", "Analytics reports endpoint")
    ]
    
    for endpoint, description in endpoints_to_test:
        print(f"\n🧪 Testing {description}: {endpoint}")
        try:
            response = requests.get(
                f"https://api.appstoreconnect.apple.com{endpoint}",
                headers=headers,
                timeout=30
            )
            
            print(f"   Status: {response.status_code}")
            if response.status_code == 200:
                print("   ✅ Success!")
                data = response.json()
                if 'data' in data:
                    print(f"   📊 Found {len(data['data'])} items")
                return True
            else:
                print("   ❌ Failed")
                try:
                    error_data = response.json()
                    if 'errors' in error_data:
                        for error in error_data['errors']:
                            print(f"   Error: {error.get('title', 'Unknown error')}")
                except:
                    print(f"   Response: {response.text[:200]}...")
                
        except requests.exceptions.RequestException as e:
            print(f"   ❌ Request failed: {e}")
    
    return False

if __name__ == "__main__":
    print("🔑 Generating JWT token with proper library...")
    
    try:
        token = generate_jwt_token()
        print("✅ JWT token generated successfully")
        print(f"Token: {token}")
        
        # Decode and display token info for debugging
        try:
            import json
            from jwt import decode
            
            # Decode without verification to inspect contents
            decoded = jwt.decode(token, options={"verify_signature": False})
            print(f"\n📋 Token payload:")
            print(json.dumps(decoded, indent=2))
            
            # Check token format
            parts = token.split('.')
            print(f"\n🔍 Token structure:")
            print(f"   Parts: {len(parts)} (should be 3)")
            print(f"   Header length: {len(parts[0])}")
            print(f"   Payload length: {len(parts[1])}")
            print(f"   Signature length: {len(parts[2])}")
            
        except Exception as e:
            print(f"Warning: Could not decode token for inspection: {e}")
        
        # Test the token
        print(f"\n🧪 Testing token with App Store Connect API...")
        success = test_token(token)
        
        if not success:
            print("\n❌ All API tests failed. Check:")
            print("   1. App Store Connect API key permissions")
            print("   2. Key ID and Issuer ID values")
            print("   3. Private key file integrity")
            sys.exit(1)
        else:
            print("\n✅ Authentication successful!")
            
    except ImportError as e:
        print(f"❌ Missing required Python libraries: {e}")
        print("Install with: pip3 install PyJWT cryptography requests")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)