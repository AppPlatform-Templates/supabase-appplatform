#!/bin/bash

# Supabase JWT Key Generator
# Generates JWT_SECRET, ANON_KEY, and SERVICE_ROLE_KEY for Supabase

echo "================================================"
echo "Supabase JWT Key Generator"
echo "================================================"
echo ""

# Generate JWT Secret
JWT_SECRET=$(openssl rand -base64 32)
echo "1. JWT_SECRET (keep this secret!):"
echo "   $JWT_SECRET"
echo ""

echo "2. Now generate your API keys at:"
echo "   https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys"
echo ""
echo "   OR use jwt.io with the payloads below:"
echo ""

# ANON_KEY payload
echo "   ANON_KEY payload (for jwt.io):"
echo '   {'
echo '     "role": "anon",'
echo '     "iss": "supabase",'
echo '     "iat": 1609459200,'
echo '     "exp": 9999999999'
echo '   }'
echo ""

# SERVICE_ROLE_KEY payload
echo "   SERVICE_ROLE_KEY payload (for jwt.io):"
echo '   {'
echo '     "role": "service_role",'
echo '     "iss": "supabase",'
echo '     "iat": 1609459200,'
echo '     "exp": 9999999999'
echo '   }'
echo ""
echo "   Use HS256 algorithm and your JWT_SECRET above to sign both tokens."
echo ""

echo "================================================"
echo "Quick Setup Guide:"
echo "================================================"
echo ""
echo "1. Copy your JWT_SECRET above"
echo "2. Visit https://jwt.io"
echo "3. Select algorithm: HS256"
echo "4. Paste the ANON_KEY payload in the 'Payload' section"
echo "5. Paste your JWT_SECRET in the 'Verify Signature' section"
echo "6. Copy the generated token - this is your SUPABASE_ANON_KEY"
echo "7. Repeat steps 4-6 with SERVICE_ROLE_KEY payload"
echo ""
echo "Save these values for deployment:"
echo "- SUPABASE_JWT_SECRET=$JWT_SECRET"
echo "- SUPABASE_ANON_KEY=<generated from jwt.io>"
echo "- SUPABASE_SERVICE_ROLE_KEY=<generated from jwt.io>"
echo ""
