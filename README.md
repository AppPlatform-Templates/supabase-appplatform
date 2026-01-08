# Supabase on DigitalOcean App Platform

Deploy your own Supabase instance on DigitalOcean App Platform with a managed PostgreSQL database. This template provides a simplified setup that transforms your database into a complete backend platform with an auto-generated REST API and web dashboard.

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/AppPlatform-Templates/supabase-appplatform/tree/main)

## What You Get

This starter template includes:

- **Studio** - Web-based admin dashboard for database management
- **PostgREST** - Auto-generated REST API from your database schema
- **Meta** - Database introspection API (powers Studio features)
- **PostgreSQL 17** - Managed database with automatic initialization
- **JWT Authentication** - Secure API access with row-level security

## Deployment Options

### Option 1: One-Click Deploy (Recommended)

#### Prerequisites

1. **Create Database** (if you don't have one):
   ```bash
   doctl databases create supabase-db \
     --engine pg \
     --version 17 \
     --size db-s-1vcpu-2gb \
     --region nyc3
   ```

   Wait for database status to be `online` (5-10 minutes):
   ```bash
   doctl databases list --format Name,Status
   ```

2. **Generate Keys**:
   ```bash
   git clone https://github.com/AppPlatform-Templates/supabase-appplatform.git
   cd supabase-appplatform
   chmod +x scripts/generate-keys.sh
   ./scripts/generate-keys.sh
   ```

   Save the generated keys - you'll need them in the next step.

#### Deployment Steps

1. Click "Deploy to DO" button
2. In App Platform UI, scroll to **Resources** section
3. Click "Attach Database" and select `supabase-db`
4. Expand each component and replace `<REQUIRED>` values:

   | Component | Environment Variable | Use This Key |
   |-----------|---------------------|--------------|
   | **studio** | `PG_META_CRYPTO_KEY` | `CRYPTO_KEY` |
   | **studio** | `SUPABASE_ANON_KEY` | `SUPABASE_ANON_KEY` |
   | **studio** | `SUPABASE_SERVICE_KEY` | `SUPABASE_SERVICE_KEY` |
   | **rest** | `PGRST_JWT_SECRET` | `SUPABASE_JWT_SECRET` |
   | **meta** | `CRYPTO_KEY` | `CRYPTO_KEY` |

5. Click **Create App**
6. Wait for deployment to complete (3-5 minutes)

### Option 2: CLI Deployment

For more control over your deployment:

#### Step 1: Prerequisites

Create a managed database:
```bash
doctl databases create supabase-db \
  --engine pg \
  --version 17 \
  --size db-s-1vcpu-2gb \
  --region nyc3

# Wait for database to be ready (5-10 minutes)
doctl databases list --format Name,Status
```

#### Step 2: Clone and Configure

```bash
git clone https://github.com/AppPlatform-Templates/supabase-appplatform.git
cd supabase-appplatform

# Generate JWT and encryption keys
chmod +x scripts/generate-keys.sh
./scripts/generate-keys.sh
```

#### Step 3: Update App Spec

Edit `.do/starter-app.yaml` and replace all `<REQUIRED>` placeholders with generated keys:

| Service | Environment Variable | Generated Key to Use |
|---------|---------------------|---------------------|
| **studio** | `PG_META_CRYPTO_KEY` | `CRYPTO_KEY` |
| **studio** | `SUPABASE_ANON_KEY` | `SUPABASE_ANON_KEY` |
| **studio** | `SUPABASE_SERVICE_KEY` | `SUPABASE_SERVICE_KEY` |
| **rest** | `PGRST_JWT_SECRET` | `SUPABASE_JWT_SECRET` |
| **meta** | `CRYPTO_KEY` | `CRYPTO_KEY` |

#### Step 4: Deploy

```bash
doctl apps create --spec .do/starter-app.yaml
```

Wait for deployment to complete (3-5 minutes):
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

   Edit `.do/starter-app.yaml` (or `.do/production-app.yaml`) and update the `db-init` job:
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

echo "Studio Dashboard: https://$APP_URL"
echo "REST API: https://$APP_URL/rest/v1/"
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

# Create a test table in Studio, then query it
curl "https://$APP_URL/rest/v1/your_table" \
  -H "apikey: $ANON_KEY" \
  -H "Authorization: Bearer $ANON_KEY"
```

## What's Included

### Database Initialization

The deployment automatically sets up:
- Database roles: `anon`, `authenticated`, `service_role`
- PostgreSQL extensions: `pgcrypto`, `pgjwt`, `uuid-ossp`
- Default search paths for each role
- Permissions for API access

### Components

| Component | Purpose | Accessible At |
|-----------|---------|---------------|
| **Studio** | Web admin dashboard | `https://your-app.ondigitalocean.app/` |
| **PostgREST** | Auto-generated REST API | `https://your-app.ondigitalocean.app/rest/v1/` |
| **Meta** | Database introspection | Internal (used by Studio) |

### Important Notes

- **Schema Creation**: Use Studio's SQL Editor to create schemas (not the UI). DigitalOcean's managed databases have security restrictions.
  ```sql
  CREATE SCHEMA my_schema;
  ```

- **JWT Keys**: Keep your `SUPABASE_SERVICE_KEY` secure - it bypasses all Row Level Security policies.

- **API Key**: The `SUPABASE_ANON_KEY` is safe to use in client applications.

## Need More Features?

This starter template focuses on core functionality. For production deployments with additional services:

- **Authentication** (email/password, OAuth, magic links)
- **File Storage** (S3-compatible with DigitalOcean Spaces)
- **Realtime** (WebSocket subscriptions for database changes)

See **[PRODUCTION.md](PRODUCTION.md)** for the full production deployment guide.

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
