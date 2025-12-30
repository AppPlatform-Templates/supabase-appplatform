#!/bin/bash

# Supabase JWT Key Generator

set -e

# Base64 URL encoding (replace + with -, / with _, remove =)
base64_url_encode() {
    openssl base64 -A | tr '+/' '-_' | tr -d '='
}

# Generate JWT token
generate_jwt() {
    local payload="$1"
    local secret="$2"

    # Header
    local header='{"alg":"HS256","typ":"JWT"}'

    # Encode header and payload
    local encoded_header=$(echo -n "$header" | base64_url_encode)
    local encoded_payload=$(echo -n "$payload" | base64_url_encode)

    # Create signature
    local signature=$(echo -n "${encoded_header}.${encoded_payload}" | \
        openssl dgst -sha256 -hmac "$secret" -binary | base64_url_encode)

    # Combine all parts
    echo "${encoded_header}.${encoded_payload}.${signature}"
}

# Generate JWT Secret
JWT_SECRET=$(openssl rand -base64 32)

# Generate Crypto Key for Meta/Studio encryption
CRYPTO_KEY=$(openssl rand -base64 32)

# Payloads
ANON_PAYLOAD='{"role":"anon","iss":"supabase","iat":1609459200,"exp":9999999999}'
SERVICE_PAYLOAD='{"role":"service_role","iss":"supabase","iat":1609459200,"exp":9999999999}'

# Generate tokens
ANON_KEY=$(generate_jwt "$ANON_PAYLOAD" "$JWT_SECRET")
SERVICE_KEY=$(generate_jwt "$SERVICE_PAYLOAD" "$JWT_SECRET")

# Display results
cat << EOF
================================================
Supabase JWT Key Generator
================================================

SUPABASE_JWT_SECRET: $JWT_SECRET

SUPABASE_ANON_KEY: $ANON_KEY

SUPABASE_SERVICE_KEY: $SERVICE_KEY

CRYPTO_KEY: $CRYPTO_KEY

================================================
EOF
