#!/bin/bash

# Supabase App Deployment Script
# Generates JWT keys and deploys Supabase app to DigitalOcean App Platform
# Prerequisites: Managed PostgreSQL database must already be created
#
# WARNING: This script is for INITIAL deployment only!
# - Generates NEW encryption keys (JWT secrets, crypto key)
# - Creates a NEW app using 'doctl apps create'
# - DO NOT run this script to update an existing app
# - For updates: Use 'doctl apps update' with existing keys from .supabase-keys

set -e

echo "================================================"
echo "Supabase App Deployment - INITIAL SETUP"
echo "================================================"
echo ""
echo "WARNING: This script creates a NEW app with NEW keys."
echo "Do NOT use this to update an existing deployment."
echo ""

# Check prerequisites
if ! command -v doctl &> /dev/null; then
    echo "Error: doctl CLI not found. Please install it first:"
    echo "  https://docs.digitalocean.com/reference/doctl/how-to/install/"
    exit 1
fi

if ! command -v openssl &> /dev/null; then
    echo "Error: openssl not found. Please install it first."
    exit 1
fi

echo "Step 1: Generating JWT keys..."
echo "================================================"

# Generate JWT keys using the generate-keys.sh script
if [ ! -f "scripts/generate-keys.sh" ]; then
    echo "Error: scripts/generate-keys.sh not found"
    exit 1
fi

# Capture output from generate-keys.sh
KEYS_OUTPUT=$(./scripts/generate-keys.sh)

# Extract keys from output
JWT_SECRET=$(echo "$KEYS_OUTPUT" | grep "SUPABASE_JWT_SECRET:" | cut -d: -f2 | xargs)
ANON_KEY=$(echo "$KEYS_OUTPUT" | grep "SUPABASE_ANON_KEY:" | cut -d: -f2 | xargs)
SERVICE_ROLE_KEY=$(echo "$KEYS_OUTPUT" | grep "SUPABASE_SERVICE_ROLE_KEY:" | cut -d: -f2 | xargs)
CRYPTO_KEY=$(echo "$KEYS_OUTPUT" | grep "CRYPTO_KEY:" | cut -d: -f2 | xargs)

# Display generated keys
echo "$KEYS_OUTPUT"
echo ""

# Save keys to file
KEYS_FILE=".supabase-keys"
cat > "$KEYS_FILE" << EOF
# Supabase JWT Keys - Generated $(date)
# IMPORTANT: Keep these keys secure and never commit to version control

SUPABASE_JWT_SECRET=$JWT_SECRET
SUPABASE_ANON_KEY=$ANON_KEY
SUPABASE_SERVICE_ROLE_KEY=$SERVICE_ROLE_KEY
CRYPTO_KEY=$CRYPTO_KEY
EOF

echo "✓ Keys saved to: $KEYS_FILE"
echo ""

echo "Step 2: Creating deployment spec..."
echo "================================================"

# Create temporary deployment spec
TEMP_SPEC="/tmp/supabase-deploy-$(date +%s).yaml"
cp .do/app.yaml "$TEMP_SPEC"

# Replace placeholders (cross-platform sed)
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|\${SUPABASE_JWT_SECRET}|${JWT_SECRET}|g" "$TEMP_SPEC"
    sed -i '' "s|\${SUPABASE_ANON_KEY}|${ANON_KEY}|g" "$TEMP_SPEC"
    sed -i '' "s|\${SUPABASE_SERVICE_ROLE_KEY}|${SERVICE_ROLE_KEY}|g" "$TEMP_SPEC"
    sed -i '' "s|\${CRYPTO_KEY}|${CRYPTO_KEY}|g" "$TEMP_SPEC"
else
    # Linux
    sed -i "s|\${SUPABASE_JWT_SECRET}|${JWT_SECRET}|g" "$TEMP_SPEC"
    sed -i "s|\${SUPABASE_ANON_KEY}|${ANON_KEY}|g" "$TEMP_SPEC"
    sed -i "s|\${SUPABASE_SERVICE_ROLE_KEY}|${SERVICE_ROLE_KEY}|g" "$TEMP_SPEC"
    sed -i "s|\${CRYPTO_KEY}|${CRYPTO_KEY}|g" "$TEMP_SPEC"
fi

echo "✓ Deployment spec created"
echo ""

echo "Step 3: Creating app on DigitalOcean..."
echo "================================================"
echo ""

# Deploy the app
doctl apps create --spec "$TEMP_SPEC"

echo ""
echo "================================================"
echo "✓ Deployment Initiated!"
echo "================================================"
echo ""
echo "Your Supabase app is now deploying in the background."
echo ""
echo "Your JWT keys are saved in: $KEYS_FILE"
echo ""
echo "Monitor deployment status:"
echo "  doctl apps list"
echo ""
echo "Once active, get your app URL:"
echo "  APP_ID=\$(doctl apps list --format ID --no-header | head -1)"
echo "  doctl apps get \$APP_ID --format DefaultIngress --no-header"
echo ""
echo "================================================"

# Clean up
rm -f "$TEMP_SPEC"
