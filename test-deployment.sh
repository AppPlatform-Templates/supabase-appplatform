#!/bin/bash

# Supabase App Platform Test Deployment Script
# This script deploys a test instance of Supabase to verify everything works

set -e

echo "================================================"
echo "Supabase on App Platform - Test Deployment"
echo "================================================"
echo ""

# Check prerequisites
if ! command -v doctl &> /dev/null; then
    echo "ERROR: doctl is not installed. Install it first:"
    echo "  https://docs.digitalocean.com/reference/doctl/how-to/install/"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    echo "WARNING: jq is not installed. Some features may not work."
    echo "  Install: brew install jq (macOS) or apt install jq (Linux)"
fi

echo "✓ Prerequisites check passed"
echo ""

# Check authentication
if ! doctl auth list &> /dev/null; then
    echo "ERROR: Not authenticated with DigitalOcean"
    echo "Run: doctl auth init"
    exit 1
fi

echo "✓ Authenticated with DigitalOcean"
echo ""

# Generate JWT Secret
echo "Step 1: Generating JWT Secret..."
JWT_SECRET=$(openssl rand -base64 32)
echo "JWT_SECRET: $JWT_SECRET"
echo ""

# Prompt for JWT keys
echo "Step 2: Generate API Keys"
echo ""
echo "Visit https://supabase.com/docs/guides/self-hosting/docker#generate-api-keys"
echo "Or generate at https://jwt.io with:"
echo ""
echo "ANON_KEY payload:"
echo '{"role":"anon","iss":"supabase","iat":1609459200,"exp":9999999999}'
echo ""
echo "SERVICE_ROLE_KEY payload:"
echo '{"role":"service_role","iss":"supabase","iat":1609459200,"exp":9999999999}'
echo ""
echo "Use algorithm HS256 and your JWT_SECRET above"
echo ""

read -p "Enter SUPABASE_ANON_KEY: " ANON_KEY
read -p "Enter SUPABASE_SERVICE_ROLE_KEY: " SERVICE_ROLE_KEY

if [ -z "$ANON_KEY" ] || [ -z "$SERVICE_ROLE_KEY" ]; then
    echo "ERROR: API keys are required"
    exit 1
fi

echo ""
echo "✓ API keys configured"
echo ""

# Create Spaces bucket
echo "Step 3: Setting up Spaces Storage..."
BUCKET_NAME="supabase-test-$(date +%s)"
echo "Creating bucket: $BUCKET_NAME"

# Note: Spaces buckets are created via control panel or API
# For testing, we'll assume user has created one or will create manually
read -p "Enter Spaces bucket name (or press Enter to use $BUCKET_NAME): " USER_BUCKET
if [ -n "$USER_BUCKET" ]; then
    BUCKET_NAME="$USER_BUCKET"
fi

SPACES_REGION="nyc3"
read -p "Enter Spaces region [nyc3]: " USER_REGION
if [ -n "$USER_REGION" ]; then
    SPACES_REGION="$USER_REGION"
fi

# Get Spaces credentials
echo ""
echo "You need Spaces access credentials."
echo "Create them at: https://cloud.digitalocean.com/account/api/tokens (Spaces Keys tab)"
echo ""

read -p "Enter SPACES_ACCESS_KEY: " SPACES_KEY
read -p "Enter SPACES_SECRET_KEY: " SPACES_SECRET

if [ -z "$SPACES_KEY" ] || [ -z "$SPACES_SECRET" ]; then
    echo "ERROR: Spaces credentials are required"
    exit 1
fi

echo ""
echo "✓ Spaces configured"
echo ""

# Optional SMTP configuration
echo "Step 4: SMTP Configuration (Optional)"
echo "Press Enter to skip email authentication features"
echo ""

read -p "SMTP Host (optional): " SMTP_HOST
read -p "SMTP Port [587]: " SMTP_PORT
SMTP_PORT=${SMTP_PORT:-587}
read -p "SMTP User (optional): " SMTP_USER
read -s -p "SMTP Pass (optional): " SMTP_PASS
echo ""
read -p "SMTP Admin Email (optional): " SMTP_EMAIL

echo ""
echo "✓ Configuration complete"
echo ""

# Create deployment spec
echo "Step 5: Creating deployment specification..."

cat > /tmp/supabase-test-spec.yaml <<EOF
spec:
  name: supabase-test-$(date +%s | tail -c 6)
  region: nyc

  ingress:
    rules:
      - match:
          path:
            prefix: /rest/v1
        component:
          name: rest
          rewrite: /
      - match:
          path:
            prefix: /auth/v1
        component:
          name: auth
          rewrite: /
      - match:
          path:
            prefix: /storage/v1
        component:
          name: storage
          rewrite: /
      - match:
          path:
            prefix: /
        component:
          name: studio

  services:
    - name: studio
      image:
        registry_type: DOCKER_HUB
        registry: supabase
        repository: studio
        tag: "20241022-ce94d1b"
      http_port: 3000
      instance_count: 1
      instance_size_slug: basic-xxs
      health_check:
        http_path: /api/profile
        initial_delay_seconds: 30
      envs:
        - key: STUDIO_PG_META_URL
          value: http://meta:8080
        - key: POSTGRES_PASSWORD
          scope: RUN_TIME
          value: \${db.PASSWORD}
        - key: DEFAULT_ORGANIZATION_NAME
          value: "Test Org"
        - key: DEFAULT_PROJECT_NAME
          value: "Test Project"
        - key: SUPABASE_URL
          scope: RUN_TIME
          value: \${APP_URL}
        - key: SUPABASE_PUBLIC_URL
          scope: RUN_TIME
          value: \${APP_URL}
        - key: SUPABASE_ANON_KEY
          scope: RUN_TIME
          type: SECRET
          value: $ANON_KEY
        - key: SUPABASE_SERVICE_KEY
          scope: RUN_TIME
          type: SECRET
          value: $SERVICE_ROLE_KEY
        - key: NEXT_PUBLIC_ENABLE_LOGS
          value: "false"

    - name: rest
      image:
        registry_type: DOCKER_HUB
        registry: postgrest
        repository: postgrest
        tag: v12.2.3
      http_port: 3000
      instance_count: 1
      instance_size_slug: basic-xxs
      health_check:
        http_path: /
      envs:
        - key: PGRST_DB_URI
          scope: RUN_TIME
          value: \${db.DATABASE_URL}
        - key: PGRST_DB_SCHEMAS
          value: public,storage,graphql_public
        - key: PGRST_DB_ANON_ROLE
          value: anon
        - key: PGRST_DB_POOL
          value: "10"
        - key: PGRST_SERVER_PORT
          value: "3000"
        - key: PGRST_JWT_SECRET
          scope: RUN_TIME
          type: SECRET
          value: $JWT_SECRET

  workers:
    - name: auth
      image:
        registry_type: DOCKER_HUB
        registry: supabase
        repository: gotrue
        tag: v2.174.0
      instance_count: 1
      instance_size_slug: basic-xxs
      envs:
        - key: GOTRUE_API_HOST
          value: "0.0.0.0"
        - key: GOTRUE_API_PORT
          value: "9999"
        - key: GOTRUE_DB_DRIVER
          value: postgres
        - key: GOTRUE_DB_DATABASE_URL
          scope: RUN_TIME
          value: \${db.DATABASE_URL}
        - key: GOTRUE_SITE_URL
          scope: RUN_TIME
          value: \${APP_URL}
        - key: GOTRUE_URI_ALLOW_LIST
          scope: RUN_TIME
          value: \${APP_URL}
        - key: GOTRUE_JWT_SECRET
          scope: RUN_TIME
          type: SECRET
          value: $JWT_SECRET
        - key: GOTRUE_JWT_EXP
          value: "3600"
        - key: GOTRUE_JWT_AUD
          value: authenticated
        - key: GOTRUE_DISABLE_SIGNUP
          value: "false"
        - key: API_EXTERNAL_URL
          scope: RUN_TIME
          value: \${APP_URL}
        - key: GOTRUE_SMTP_HOST
          value: "$SMTP_HOST"
        - key: GOTRUE_SMTP_PORT
          value: "$SMTP_PORT"
        - key: GOTRUE_SMTP_USER
          value: "$SMTP_USER"
        - key: GOTRUE_SMTP_PASS
          type: SECRET
          value: "$SMTP_PASS"
        - key: GOTRUE_SMTP_ADMIN_EMAIL
          value: "$SMTP_EMAIL"
        - key: GOTRUE_MAILER_AUTOCONFIRM
          value: "false"

    - name: meta
      image:
        registry_type: DOCKER_HUB
        registry: supabase
        repository: postgres-meta
        tag: v0.84.2
      instance_count: 1
      instance_size_slug: basic-xxs
      envs:
        - key: PG_META_PORT
          value: "8080"
        - key: PG_META_DB_HOST
          scope: RUN_TIME
          value: \${db.HOSTNAME}
        - key: PG_META_DB_PORT
          scope: RUN_TIME
          value: \${db.PORT}
        - key: PG_META_DB_NAME
          scope: RUN_TIME
          value: \${db.DATABASE}
        - key: PG_META_DB_USER
          scope: RUN_TIME
          value: \${db.USERNAME}
        - key: PG_META_DB_PASSWORD
          scope: RUN_TIME
          type: SECRET
          value: \${db.PASSWORD}

    - name: storage
      image:
        registry_type: DOCKER_HUB
        registry: supabase
        repository: storage-api
        tag: v1.11.1
      instance_count: 1
      instance_size_slug: basic-xxs
      envs:
        - key: ANON_KEY
          scope: RUN_TIME
          type: SECRET
          value: $ANON_KEY
        - key: SERVICE_KEY
          scope: RUN_TIME
          type: SECRET
          value: $SERVICE_ROLE_KEY
        - key: POSTGREST_URL
          value: http://rest:3000
        - key: PGRST_JWT_SECRET
          scope: RUN_TIME
          type: SECRET
          value: $JWT_SECRET
        - key: DATABASE_URL
          scope: RUN_TIME
          value: \${db.DATABASE_URL}
        - key: FILE_SIZE_LIMIT
          value: "52428800"
        - key: STORAGE_BACKEND
          value: s3
        - key: TENANT_ID
          value: stub
        - key: GLOBAL_S3_BUCKET
          value: $BUCKET_NAME
        - key: REGION
          value: $SPACES_REGION
        - key: GLOBAL_S3_ENDPOINT
          value: https://$SPACES_REGION.digitaloceanspaces.com
        - key: AWS_ACCESS_KEY_ID
          type: SECRET
          value: $SPACES_KEY
        - key: AWS_SECRET_ACCESS_KEY
          type: SECRET
          value: $SPACES_SECRET

  jobs:
    - name: db-init
      git:
        repo_clone_url: https://github.com/AppPlatform-Templates/supabase-appplatform.git
        branch: main
      kind: POST_DEPLOY
      dockerfile_path: Dockerfile.dbinit
      instance_count: 1
      instance_size_slug: basic-xxs
      envs:
        - key: DATABASE_URL
          scope: RUN_TIME
          value: \${db.DATABASE_URL}

  databases:
    - name: db
      engine: PG
      production: false
      version: "15"
EOF

echo "✓ Deployment spec created: /tmp/supabase-test-spec.yaml"
echo ""

# Deploy
echo "Step 6: Deploying to App Platform..."
echo ""

doctl apps create --spec /tmp/supabase-test-spec.yaml

APP_ID=$(doctl apps list --format ID,Name --no-header | head -1 | awk '{print $1}')

if [ -z "$APP_ID" ]; then
    echo "ERROR: Failed to get app ID"
    exit 1
fi

echo ""
echo "================================================"
echo "Deployment initiated successfully!"
echo "================================================"
echo ""
echo "App ID: $APP_ID"
echo ""
echo "Monitor deployment:"
echo "  doctl apps get $APP_ID"
echo ""
echo "View logs:"
echo "  doctl apps logs $APP_ID --type build --follow"
echo "  doctl apps logs $APP_ID --type run --follow"
echo ""
echo "Get app URL (after deployment completes):"
echo "  doctl apps get $APP_ID --format DefaultIngress --no-header"
echo ""
echo "Deployment typically takes 10-15 minutes."
echo ""
echo "To delete this test app later:"
echo "  doctl apps delete $APP_ID"
echo ""
