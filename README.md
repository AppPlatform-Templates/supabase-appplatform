# Supabase on DigitalOcean App Platform

Deploy your own Supabase instance on DigitalOcean App Platform with a managed PostgreSQL database. This template provides a simplified, production-ready setup that transforms your database into a complete backend platform with authentication-ready REST API.

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/AppPlatform-Templates/supabase-appplatform/tree/main)

## Overview

[Supabase](https://supabase.com) is an open-source Firebase alternative that provides a complete backend platform built on PostgreSQL. This template deploys the core Supabase services to App Platform, giving you a production-ready backend with web interface, auto-generated REST API, and database management capabilities.

## Key Features

**Core Functionality**:
- **Auto-generated REST API** - PostgREST instantly creates RESTful endpoints from your database schema
- **Web Dashboard** - Studio provides a visual interface for database management, SQL queries, and API exploration
- **Row Level Security** - PostgreSQL's built-in RLS provides fine-grained access control
- **Database Management** - Meta service powers Studio's database operations and schema inspection

**Included Components**:
- Supabase Studio (Web UI)
- PostgREST (REST API server)
- Postgres Meta (Database management API)
- Managed PostgreSQL 17 database with automatic initialization
- JWT-based authentication for API access
- SSL/TLS encryption

## Deployment Options

### Quick Deployment (Recommended)

**One-Click Deployment**: Click the "Deploy to DO" button above, then follow these steps before clicking "Create App":

**Before Deployment - Required Steps**:

1. **Create Managed Database** (if you don't have one):
   - Use Step 1 from CLI Deployment below to create a PostgreSQL database
   - Wait for the database to be ready (status: "online")

2. **Attach Database**:
   - In the App Platform UI, scroll to the "Database" section
   - Click "Attach Database" and select your `supabase-db` database

3. **Generate JWT Keys**:
   - Run the key generation script (see Step 2 from CLI Deployment below)
   - Save all four generated keys: `SUPABASE_JWT_SECRET`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_KEY`, `CRYPTO_KEY`

4. **Replace Required Keys**:
   - In the App Platform UI, expand each component (studio, rest, meta)
   - Find environment variables marked with `<REQUIRED>` and replace them:
     - **studio**: Replace `PG_META_CRYPTO_KEY`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_KEY`
     - **rest**: Replace `PGRST_JWT_SECRET`
     - **meta**: Replace `CRYPTO_KEY`

5. **Click "Create App"** to deploy

### CLI Deployment

For more control over your deployment configuration:

**Step 1: Create Managed Database**
```bash
# Create PostgreSQL database - name must match .do/app.yaml
doctl databases create supabase-db \
  --engine pg \
  --version 17 \
  --size db-s-1vcpu-2gb \
  --region nyc3

# Wait for database to be ready (5-10 minutes)
# Check status: doctl databases list --format Name,Status
```

**Step 2: Clone and Generate Keys**
```bash
git clone https://github.com/AppPlatform-Templates/supabase-appplatform.git
cd supabase-appplatform

# Generate all required keys (JWT secret, anon key, service key, crypto key)
chmod +x scripts/generate-keys.sh
./scripts/generate-keys.sh
```

**Step 3: Update Configuration**

Open `.do/app.yaml` and replace `<REQUIRED>` placeholders with your generated keys:

| Component | Key to Replace | Use Generated Key |
|-----------|----------------|-------------------|
| studio | `PG_META_CRYPTO_KEY` | `CRYPTO_KEY` |
| studio | `SUPABASE_ANON_KEY` | `SUPABASE_ANON_KEY` |
| studio | `SUPABASE_SERVICE_KEY` | `SUPABASE_SERVICE_KEY` |
| rest | `PGRST_JWT_SECRET` | `SUPABASE_JWT_SECRET` |
| meta | `CRYPTO_KEY` | `CRYPTO_KEY` |

**Step 4: Deploy**
```bash
doctl apps create --spec .do/app.yaml
```

The deployment includes a pre-deploy job that automatically initializes your database with required schemas, roles, and permissions.

## Customization Approaches

### Using the Included Database Initialization

The template includes a `db-init` pre-deploy job that automatically sets up:
- Database roles (`anon`, `authenticated`, `service_role`)
- PostgreSQL extensions (`pgcrypto`, `pgjwt`)
- Row Level Security policies
- API permissions

You can customize the initialization by modifying `db-init/init-db.sql` before deployment.

### Connecting Existing Databases

To use an existing PostgreSQL database:

1. Skip the database creation step
2. Update `.do/app.yaml` to reference your existing database
3. Manually run the initialization scripts from `db-init/init-db.sql`
4. Configure `PGRST_DB_SCHEMAS` to match your schema structure

### Schema Management

**Important**: Creating new schemas through the Studio UI is not supported due to DigitalOcean's managed database security model. Use the SQL Editor instead:

```bash
CREATE SCHEMA my_schema;
```

All other database operations work normally through Studio.

## Post-Deployment

### Access Your Instance

```bash
# Get your app ID and URL
APP_ID=$(doctl apps list --format ID --no-header)
APP_URL=$(doctl apps get $APP_ID --format DefaultIngress --no-header)

echo "Studio Dashboard: https://$APP_URL"
echo "REST API: https://$APP_URL/rest/v1/"
```

### Verify Deployment

```bash
# Check database initialization
doctl apps logs $APP_ID --component db-init

# Monitor services
doctl apps logs $APP_ID --component studio --follow
doctl apps logs $APP_ID --component rest --follow
```

### Test the REST API

```bash
# List available tables/endpoints
curl https://$APP_URL/rest/v1/ \
  -H "apikey: $SUPABASE_ANON_KEY"

# Query a table (after creating one in Studio)
curl https://$APP_URL/rest/v1/your_table \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY"
```

## Architecture

| Component | Purpose | Accessibility |
|-----------|---------|---------------|
| **Studio** | Web admin dashboard | Public (HTTPS) |
| **PostgREST** | Auto-generated REST API | Public (HTTPS at /rest/v1/*) |
| **Meta** | Database management API | Internal (Studio only) |
| **PostgreSQL** | Primary database | Managed service |

**Routing**:
- `https://your-app.ondigitalocean.app/` → Studio dashboard
- `https://your-app.ondigitalocean.app/rest/v1/*` → PostgREST API

## Pricing

For detailed pricing and instance sizing options, visit the [DigitalOcean App Platform Pricing](https://www.digitalocean.com/pricing/app-platform) page.

## Clean Up

To delete your deployment:

```bash
# Delete app
doctl apps delete $APP_ID

# Delete database
DB_ID=$(doctl databases list --format ID --no-header)
doctl databases delete $DB_ID
```

## Learn More

### Supabase Resources
- [Official Documentation](https://supabase.com/docs) - Complete guide to Supabase features
- [Self-Hosting Guide](https://supabase.com/docs/guides/self-hosting) - Advanced configuration options
- [PostgREST API Reference](https://postgrest.org/en/stable/references/api.html) - REST API documentation
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security) - Security patterns

### DigitalOcean Resources
- [App Platform Documentation](https://docs.digitalocean.com/products/app-platform/) - Platform features and guides
- [Managed PostgreSQL](https://docs.digitalocean.com/products/databases/postgresql/) - Database management
- [App Spec Reference](https://docs.digitalocean.com/products/app-platform/reference/app-spec/) - Configuration options

### Community & Support
- [Supabase Discord](https://discord.supabase.com) - Community chat and support
- [Supabase GitHub](https://github.com/supabase/supabase) - Source code and issues
- [DigitalOcean Community](https://www.digitalocean.com/community) - Tutorials and Q&A
- [DigitalOcean Support](https://www.digitalocean.com/support) - Official support channels

---

**Note**: This template provides core Supabase functionality (Studio, PostgREST, Meta). For additional features like authentication (GoTrue), real-time subscriptions, and file storage, see the production template (`.do/production-app.yaml`) with expanded services.
