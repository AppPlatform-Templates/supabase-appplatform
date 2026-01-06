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

# Generate Realtime encryption keys
DB_ENC_KEY=$(openssl rand -base64 32)
SECRET_KEY_BASE=$(openssl rand -base64 48)  # Must be at least 64 characters

# Payloads
ANON_PAYLOAD='{"role":"anon","iss":"supabase","iat":1609459200,"exp":9999999999}'
SERVICE_PAYLOAD='{"role":"service_role","iss":"supabase","iat":1609459200,"exp":9999999999}'

# Generate tokens
ANON_KEY=$(generate_jwt "$ANON_PAYLOAD" "$JWT_SECRET")
SERVICE_KEY=$(generate_jwt "$SERVICE_PAYLOAD" "$JWT_SECRET")

# Display results
cat << EOF
================================================
Supabase Key Generator
================================================

Core JWT Keys:
--------------
SUPABASE_JWT_SECRET: $JWT_SECRET

SUPABASE_ANON_KEY: $ANON_KEY

SUPABASE_SERVICE_KEY: $SERVICE_KEY

Studio/Meta Encryption:
-----------------------
CRYPTO_KEY: $CRYPTO_KEY

Realtime Encryption:
--------------------
DB_ENC_KEY: $DB_ENC_KEY

SECRET_KEY_BASE: $SECRET_KEY_BASE

================================================
Usage:
- Use SUPABASE_JWT_SECRET for: PGRST_JWT_SECRET, GOTRUE_JWT_SECRET, API_JWT_SECRET
- Use CRYPTO_KEY for: PG_META_CRYPTO_KEY (Studio), CRYPTO_KEY (Meta)
- Use DB_ENC_KEY for: Realtime DB_ENC_KEY
- Use SECRET_KEY_BASE for: Realtime SECRET_KEY_BASE
================================================
EOF
