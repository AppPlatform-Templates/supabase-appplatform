# Production Deployment Guide

This guide covers deploying the full production Supabase stack with Authentication, Storage, and Realtime services.

## What's Included

The production template (`.do/production-app.yaml`) includes all starter services plus:

**Core Services** (from starter):
- Studio - Web admin dashboard
- PostgREST - Auto-generated REST API
- Meta - Database introspection

**Additional Production Services**:
- **GoTrue** - Authentication service (email/password, OAuth, magic links)
- **Storage API** - File management with DigitalOcean Spaces
- **Realtime** - WebSocket subscriptions for database changes

**Production Features**:
- Auto-scaling (1-3 instances per service)
- Production-tier database with standby
- Professional instance sizes
- Health checks and monitoring

## Prerequisites

Before deploying, you'll need:

### 1. DigitalOcean Spaces Bucket

Create a Spaces bucket for file storage:

```bash
# Via UI: https://cloud.digitalocean.com/spaces/new
# Choose a region (e.g., nyc3)
# Bucket name example: supabase-storage-space
```

Generate Spaces API keys:
```bash
# Via UI: Account → API → Spaces Keys → Generate New Key
# Save both:
# - Access Key ID (e.g., DO00TPEJAYLRVX6TJRHQ)
# - Secret Access Key (e.g., No+A3SZT...)
```

### 2. PostgreSQL Database

Create a production database:

```bash
doctl databases create supabase-db \
  --engine pg \
  --version 17 \
  --size db-s-2vcpu-4gb \
  --region nyc3

# Wait for database to be ready (5-10 minutes)
doctl databases list --format Name,Status
```

**Status should show**: `online`

### 3. Generate All Required Keys

Clone the repository and generate keys:

```bash
git clone https://github.com/AppPlatform-Templates/supabase-appplatform.git
cd supabase-appplatform

chmod +x scripts/generate-keys.sh
./scripts/generate-keys.sh
```

**Save all generated keys** - you'll need:
- `SUPABASE_JWT_SECRET` (for JWT validation)
- `SUPABASE_ANON_KEY` (for client applications)
- `SUPABASE_SERVICE_KEY` (for admin operations)
- `CRYPTO_KEY` (for Studio-Meta encryption)
- `DB_ENC_KEY` (for Realtime database encryption)
- `SECRET_KEY_BASE` (for Realtime session encryption)

## Deployment Steps

### Step 1: Configure Production Template

Edit `.do/production-app.yaml` and replace all `<REQUIRED>` placeholders with generated keys:

#### JWT and Encryption Keys

| Service | Environment Variable | Generated Key to Use |
|---------|---------------------|---------------------|
| **studio** | `PG_META_CRYPTO_KEY` | `CRYPTO_KEY` |
| **studio** | `SUPABASE_ANON_KEY` | `SUPABASE_ANON_KEY` |
| **studio** | `SUPABASE_SERVICE_KEY` | `SUPABASE_SERVICE_KEY` |
| **rest** | `PGRST_JWT_SECRET` | `SUPABASE_JWT_SECRET` |
| **auth** | `GOTRUE_JWT_SECRET` | `SUPABASE_JWT_SECRET` |
| **storage** | `ANON_KEY` | `SUPABASE_ANON_KEY` |
| **storage** | `SERVICE_KEY` | `SUPABASE_SERVICE_KEY` |
| **storage** | `PGRST_JWT_SECRET` | `SUPABASE_JWT_SECRET` |
| **realtime** | `DB_ENC_KEY` | `DB_ENC_KEY` |
| **realtime** | `API_JWT_SECRET` | `SUPABASE_JWT_SECRET` |
| **realtime** | `SECRET_KEY_BASE` | `SECRET_KEY_BASE` |
| **meta** | `CRYPTO_KEY` | `CRYPTO_KEY` |

#### Spaces Configuration (for Storage service)

| Environment Variable | Your Value | Example |
|---------------------|------------|---------|
| `GLOBAL_S3_BUCKET` | Your bucket name | `supabase-storage-space` |
| `REGION` | Your Spaces region | `nyc3` |
| `GLOBAL_S3_ENDPOINT` | Your endpoint URL | `https://nyc3.digitaloceanspaces.com` |
| `AWS_ACCESS_KEY_ID` | Your Access Key ID | `DO00TPEJAYLRVX6TJRHQ` |
| `AWS_SECRET_ACCESS_KEY` | Your Secret Access Key | `No+A3SZT6vxe...` |

### Step 2: Deploy

```bash
doctl apps create --spec .do/production-app.yaml
```

### Step 3: Monitor Deployment

**Phase 1: Building** (2-3 minutes)
```bash
APP_ID=$(doctl apps list --format ID --no-header)
doctl apps list-deployments $APP_ID
```

You'll see: `BUILDING` → `DEPLOYING` → `ACTIVE`

**Phase 2: Database Initialization** (running during deployment)
```bash
# Check db-init logs
doctl apps logs $APP_ID db-init
```

Look for: `✓ Database initialization completed successfully`

**Phase 3: Service Health Checks** (1-2 minutes)

Services start and health checks begin. Wait for all to pass.

**Total deployment time**: ~8-12 minutes

### Step 4: Verify Deployment

```bash
# Get app URL
APP_URL=$(doctl apps get $APP_ID --format DefaultIngress --no-header)

echo "Studio: https://$APP_URL"
echo "REST API: https://$APP_URL/rest/v1/"
echo "Auth: https://$APP_URL/auth/v1/"
echo "Storage: https://$APP_URL/storage/v1/"
echo "Realtime: https://$APP_URL/realtime/v1/"
```

## Post-Deployment Testing

### 1. Test PostgREST API

```bash
# List available endpoints
curl "https://$APP_URL/rest/v1/" \
  -H "apikey: $SUPABASE_ANON_KEY"
```

### 2. Test Auth Service

```bash
# Health check
curl "https://$APP_URL/auth/v1/health" \
  -H "apikey: $SUPABASE_ANON_KEY"

# Create a test user
curl -X POST "https://$APP_URL/auth/v1/signup" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword123"
  }'
```

### 3. Test Storage Service

```bash
# Health check
curl "https://$APP_URL/storage/v1/status" \
  -H "apikey: $SUPABASE_SERVICE_KEY"

# Create a bucket
curl -X POST "https://$APP_URL/storage/v1/bucket" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "avatars",
    "name": "avatars",
    "public": true
  }'

# Upload a file
echo "test content" > test.txt
curl -X POST "https://$APP_URL/storage/v1/object/avatars/test.txt" \
  -H "apikey: $SUPABASE_SERVICE_KEY" \
  -H "Authorization: Bearer $SUPABASE_SERVICE_KEY" \
  -F "file=@test.txt"
```

### 4. Test Realtime Service

```bash
# Check Realtime status page
curl "https://$APP_URL/realtime/v1/status" \
  -H "apikey: $SUPABASE_ANON_KEY"
```

For WebSocket testing, use the Studio interface or a Supabase client library.

## Configuration Options

### Email Provider (Optional)

To enable email verification and password reset:

Edit `.do/production-app.yaml` auth service and add:

```yaml
# SMTP Configuration
- key: GOTRUE_SMTP_HOST
  value: smtp.sendgrid.net

- key: GOTRUE_SMTP_PORT
  value: "587"

- key: GOTRUE_SMTP_USER
  type: SECRET
  value: apikey

- key: GOTRUE_SMTP_PASS
  type: SECRET
  value: <your-sendgrid-api-key>

- key: GOTRUE_SMTP_ADMIN_EMAIL
  value: admin@yourdomain.com

# Disable auto-confirm
- key: GOTRUE_MAILER_AUTOCONFIRM
  value: "false"
```

### OAuth Providers (Optional)

Add OAuth configuration to GoTrue service:

```yaml
# Google OAuth
- key: GOTRUE_EXTERNAL_GOOGLE_ENABLED
  value: "true"

- key: GOTRUE_EXTERNAL_GOOGLE_CLIENT_ID
  type: SECRET
  value: <your-google-client-id>

- key: GOTRUE_EXTERNAL_GOOGLE_SECRET
  type: SECRET
  value: <your-google-client-secret>

- key: GOTRUE_EXTERNAL_GOOGLE_REDIRECT_URI
  value: https://$APP_URL/auth/v1/callback
```

## Monitoring

### Key Metrics to Watch

```bash
# View service logs
doctl apps logs $APP_ID studio --follow
doctl apps logs $APP_ID rest --follow
doctl apps logs $APP_ID auth --follow
doctl apps logs $APP_ID storage --follow
doctl apps logs $APP_ID realtime --follow

# Check deployment status
doctl apps get $APP_ID

# List deployments
doctl apps list-deployments $APP_ID
```

### Health Checks

Each service has health check endpoints:

- Studio: `https://$APP_URL/api/platform/profile`
- PostgREST: `https://$APP_URL/rest/v1/`
- Auth: `https://$APP_URL/auth/v1/health`
- Storage: `https://$APP_URL/storage/v1/status`
- Realtime: `https://$APP_URL/realtime/v1/`

## Troubleshooting

### View Logs for Debugging

```bash
# Recent errors from all services
doctl apps logs $APP_ID --type deploy --tail 100

# Specific service runtime logs
doctl apps logs $APP_ID <service-name> --type run --tail 50
```

## Resources

- [Supabase Documentation](https://supabase.com/docs)
- [App Platform Documentation](https://docs.digitalocean.com/products/app-platform/)
- [Spaces Documentation](https://docs.digitalocean.com/products/spaces/)
- [Managed PostgreSQL](https://docs.digitalocean.com/products/databases/postgresql/)
- [DigitalOcean Pricing](https://www.digitalocean.com/pricing)

## Support

- [DigitalOcean Community](https://www.digitalocean.com/community)
- [Supabase Discord](https://discord.supabase.com)
- [GitHub Issues](https://github.com/AppPlatform-Templates/supabase-appplatform/issues)
