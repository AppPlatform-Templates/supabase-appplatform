# Supabase on DigitalOcean App Platform

Deploy your own Supabase instance on DigitalOcean App Platform with a managed PostgreSQL database. This template provides a complete backend platform with auto-generated REST API, authentication, file storage, and realtime subscriptions.

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/AppPlatform-Templates/supabase-appplatform/tree/main)

## What You Get

This template includes:

- **PostgREST** - Auto-generated REST API from your database schema
- **GoTrue** - Authentication service (email/password, OAuth, magic links)
- **Storage** - File management with DigitalOcean Spaces integration
- **Realtime** - WebSocket subscriptions for database changes
- **PostgreSQL 17** - Managed database with automatic initialization
- **JWT Authentication** - Secure API access with row-level security

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Client/User                         │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    App Platform Ingress                     │
│   /rest/v1   /auth/v1   /storage/v1   /realtime/v1          │
└─────────────────────────────────────────────────────────────┘
       │            │            │               │
       ▼            ▼            ▼               ▼
┌───────────┐ ┌──────────┐ ┌──────────┐  ┌────────────┐
│ PostgREST │ │  GoTrue  │ │ Storage  │  │  Realtime  │
│   (API)   │ │  (Auth)  │ │  (Files) │  │    (WS)    │
└───────────┘ └──────────┘ └──────────┘  └────────────┘
       │            │            │               │
       └────────────┴────────────┴───────────────┘
                    │            │
                    ▼            ▼
          ┌──────────────┐  ┌──────────────┐
          │  PostgreSQL  │  │  DO Spaces   │
          └──────────────┘  └──────────────┘
```

## Deployment Options

### Option 1: One-Click Deploy (Recommended)

#### Prerequisites

1. **Create Database** (if you don't have one):
   ```bash
   doctl databases create supabase-db \
     --engine pg \
     --version 17 \
     --size db-s-2vcpu-4gb \
     --region nyc3
   ```

   Wait for database status to be `online` (5-10 minutes):
   ```bash
   doctl databases list --format Name,Status
   ```

2. **Create DigitalOcean Spaces Bucket**:
   - Go to https://cloud.digitalocean.com/spaces/new
   - Choose a region (e.g., nyc3)
   - Create bucket (e.g., `supabase-storage-space`)
   - Generate Spaces API keys: Account → API → Spaces Keys → Generate New Key
   - Note your endpoint URL format: `https://{region}.digitaloceanspaces.com`
     - Example for nyc3: `https://nyc3.digitaloceanspaces.com`

3. **Generate Keys**:
   ```bash
   git clone https://github.com/AppPlatform-Templates/supabase-appplatform.git
   cd supabase-appplatform

   chmod +x scripts/generate-keys.sh
   ./scripts/generate-keys.sh
   ```

   Save the generated keys - you'll need them in the next step.

#### Deployment Steps

1. Click on "Deploy to DigitalOcean" button
2. In App Platform UI, scroll to **Resources** section
3. Click "Attach Database" and select `supabase-db`
4. Expand each component and replace `<REQUIRED>` values:

   | Component | Environment Variable | Use This Key |
   |-----------|---------------------|--------------|
   | **rest** | `PGRST_JWT_SECRET` | `SUPABASE_JWT_SECRET` |
   | **auth** | `GOTRUE_JWT_SECRET` | `SUPABASE_JWT_SECRET` |
   | **storage** | `ANON_KEY` | `SUPABASE_ANON_KEY` |
   | **storage** | `SERVICE_KEY` | `SUPABASE_SERVICE_KEY` |
   | **storage** | `PGRST_JWT_SECRET` | `SUPABASE_JWT_SECRET` |
   | **storage** | `GLOBAL_S3_BUCKET` | Your bucket name |
   | **storage** | `REGION` | Your region (e.g., `nyc3`) |
   | **storage** | `GLOBAL_S3_ENDPOINT` | Your endpoint URL |
   | **storage** | `AWS_ACCESS_KEY_ID` | Your Spaces access key |
   | **storage** | `AWS_SECRET_ACCESS_KEY` | Your Spaces secret key |
   | **realtime** | `DB_ENC_KEY` | `DB_ENC_KEY` |
   | **realtime** | `API_JWT_SECRET` | `SUPABASE_JWT_SECRET` |
   | **realtime** | `SECRET_KEY_BASE` | `SECRET_KEY_BASE` |

5. Click **Create App**
6. Wait for deployment to complete (8-12 minutes)

### Option 2: CLI Deployment

For more control over your deployment:

#### Step 1: Prerequisites

Create a managed database:
```bash
doctl databases create supabase-db \
  --engine pg \
  --version 17 \
  --size db-s-2vcpu-4gb \
  --region nyc3

# Wait for database to be ready (5-10 minutes)
doctl databases list --format Name,Status
```

Create DigitalOcean Spaces bucket at https://cloud.digitalocean.com/spaces/new and generate API keys.

Note your endpoint URL format: `https://{region}.digitaloceanspaces.com` (e.g., `https://nyc3.digitaloceanspaces.com`)

#### Step 2: Clone and Configure

```bash
git clone https://github.com/AppPlatform-Templates/supabase-appplatform.git
cd supabase-appplatform

# Generate JWT and encryption keys
chmod +x scripts/generate-keys.sh
./scripts/generate-keys.sh
```

#### Step 3: Update App Spec

Edit `.do/production-app.yaml` and replace all `<REQUIRED>` placeholders:

| Service | Environment Variable | Value / Generated Key |
|---------|---------------------|---------------------|
| **rest** | `PGRST_JWT_SECRET` | `SUPABASE_JWT_SECRET` |
| **auth** | `GOTRUE_JWT_SECRET` | `SUPABASE_JWT_SECRET` |
| **storage** | `ANON_KEY` | `SUPABASE_ANON_KEY` |
| **storage** | `SERVICE_KEY` | `SUPABASE_SERVICE_KEY` |
| **storage** | `PGRST_JWT_SECRET` | `SUPABASE_JWT_SECRET` |
| **storage** | `GLOBAL_S3_BUCKET` | Your bucket name |
| **storage** | `REGION` | Your region (e.g., `nyc3`) |
| **storage** | `GLOBAL_S3_ENDPOINT` | Your endpoint URL |
| **storage** | `AWS_ACCESS_KEY_ID` | Your Spaces access key |
| **storage** | `AWS_SECRET_ACCESS_KEY` | Your Spaces secret key |
| **realtime** | `DB_ENC_KEY` | `DB_ENC_KEY` |
| **realtime** | `API_JWT_SECRET` | `SUPABASE_JWT_SECRET` |
| **realtime** | `SECRET_KEY_BASE` | `SECRET_KEY_BASE` |

#### Step 4: Deploy

```bash
doctl apps create --spec .do/production-app.yaml
```

Wait for deployment to complete (8-12 minutes):
```bash
# Check deployment status
doctl apps list

# View logs
APP_ID=$(doctl apps list --format ID --no-header)
doctl apps logs $APP_ID db-init
```

### Option 3: Fork and Customize

For custom modifications:

1. **Fork the repository** on GitHub

2. **Clone your fork**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/supabase-appplatform.git
   cd supabase-appplatform
   ```

3. **Update git repository URLs** in app spec files:

   Edit `.do/production-app.yaml` and update the `db-init` job:
   ```yaml
   jobs:
     - name: db-init
       git:
         repo_clone_url: https://github.com/YOUR_USERNAME/supabase-appplatform.git
         branch: main
   ```

4. **Customize** `db-init/init-db.sql` or other files as needed

5. **Update the Deploy button** in your fork's README to point to your repository

6. **Deploy** using the Deploy to DO button or CLI

## Post-Deployment

### Access Your Instance

```bash
# Get your app URL
APP_ID=$(doctl apps list --format ID --no-header)
APP_URL=$(doctl apps get $APP_ID --format DefaultIngress --no-header)

echo "REST API: https://$APP_URL/rest/v1/"
echo "Auth: https://$APP_URL/auth/v1/"
echo "Storage: https://$APP_URL/storage/v1/"
echo "Realtime: https://$APP_URL/realtime/v1/"
```

### Verify Deployment

Check that database initialization completed:
```bash
doctl apps logs $APP_ID db-init
```

You should see: `✓ Database initialization completed successfully`

### Test the REST API

```bash
# Replace with your SUPABASE_ANON_KEY
ANON_KEY="your-anon-key-here"

# List available endpoints
curl "https://$APP_URL/rest/v1/" \
  -H "apikey: $ANON_KEY"
```

### Test Authentication

```bash
# Create a test user
curl -X POST "https://$APP_URL/auth/v1/signup" \
  -H "apikey: $ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "testpassword123"
  }'
```

## What's Included

### Database Initialization

The deployment automatically sets up:
- Database roles: `anon`, `authenticated`, `service_role`
- Auth helper functions: `auth.uid()`, `auth.jwt()`, `auth.role()`, `auth.email()`
- PostgreSQL extensions: `pgcrypto`, `pgjwt`, `uuid-ossp`
- Default search paths for each role
- Permissions for API access

### Components

| Component | Purpose | Accessible At |
|-----------|---------|---------------|
| **PostgREST** | Auto-generated REST API | `https://your-app.ondigitalocean.app/rest/v1/` |
| **GoTrue** | Authentication service | `https://your-app.ondigitalocean.app/auth/v1/` |
| **Storage** | File management | `https://your-app.ondigitalocean.app/storage/v1/` |
| **Realtime** | WebSocket subscriptions | `https://your-app.ondigitalocean.app/realtime/v1/` |

### Important Notes

- **JWT Keys**: Keep your `SUPABASE_SERVICE_KEY` secure - it bypasses all Row Level Security policies.

- **API Key**: The `SUPABASE_ANON_KEY` is safe to use in client applications.

- **Auto-scaling**: Each service automatically scales between 1-3 instances based on CPU usage.

## Database Management

Since this template focuses on production APIs without Studio, you have several options for database management:

### Option 1: Connect with psql

```bash
# Get database connection details
DB_ID=$(doctl databases list --format ID --no-header)
doctl databases connection $DB_ID

# Connect directly
psql "postgresql://doadmin:password@host:25060/defaultdb?sslmode=require"
```

### Option 2: Use pgAdmin or Other PostgreSQL Tools

Connect using your database credentials with any PostgreSQL client:
- Host: Your database hostname
- Port: 25060
- Database: defaultdb
- User: doadmin
- SSL Mode: require

### Option 3: Run Studio Locally

You can run Supabase Studio locally and connect to your remote database:

```bash
docker run -p 3000:3000 \
  -e POSTGRES_HOST=your-db-host.db.ondigitalocean.com \
  -e POSTGRES_PORT=25060 \
  -e POSTGRES_DB=defaultdb \
  -e POSTGRES_USER=doadmin \
  -e POSTGRES_PASSWORD=your-password \
  supabase/studio:latest
```

Then access Studio at `http://localhost:3000`

**Note**: Studio is not included in production deployments for security reasons (no built-in authentication).

## Advanced Configuration

### Email Setup (Optional)

Add SMTP configuration to GoTrue service in `.do/production-app.yaml`:

```yaml
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

### Monitoring

```bash
# Check deployment status
doctl apps get $APP_ID

# View service logs
doctl apps logs $APP_ID rest --follow
doctl apps logs $APP_ID auth --follow
doctl apps logs $APP_ID storage --follow
doctl apps logs $APP_ID realtime --follow
```

## Clean Up

To delete your deployment:

```bash
# Delete the app
APP_ID=$(doctl apps list --format ID --no-header)
doctl apps delete $APP_ID

# Delete the database
DB_ID=$(doctl databases list --format ID --no-header)
doctl databases delete $DB_ID
```

## Resources

- [Supabase Documentation](https://supabase.com/docs)
- [PostgREST API Reference](https://postgrest.org/en/stable/references/api.html)
- [App Platform Documentation](https://docs.digitalocean.com/products/app-platform/)
- [Row Level Security Guide](https://supabase.com/docs/guides/auth/row-level-security)

## Support

- [DigitalOcean Community](https://www.digitalocean.com/community)
- [Supabase Discord](https://discord.supabase.com)
- [GitHub Issues](https://github.com/AppPlatform-Templates/supabase-appplatform/issues)
