# Supabase on DigitalOcean App Platform

Deploy your own Supabase instance on DigitalOcean App Platform with a managed PostgreSQL database. This template provides a simplified, production-ready Supabase setup optimized for App Platform.

## What is Supabase?

[Supabase](https://supabase.com) is an open-source Firebase alternative providing:
- **PostgreSQL Database** - Full-featured relational database with extensions
- **Authentication** - Email, magic links, and OAuth providers
- **Auto-generated REST API** - Instant RESTful API from your database schema
- **Row Level Security** - Fine-grained access control built into PostgreSQL
- **File Storage** - S3-compatible object storage for user uploads

Perfect for building modern web and mobile applications without managing backend infrastructure.

## Architecture

This simplified deployment includes:

| Component | Purpose | Type |
|-----------|---------|------|
| **Studio** | Web admin dashboard | Service (HTTP) |
| **PostgREST** | Auto-generated REST API | Service (HTTP) |
| **Meta** | Database management API | Service (Internal) |
| **PostgreSQL** | Database (with extensions) | Managed Database (Production) |
| **DB Init** | Automatic schema setup | Pre-deploy Job |

> **Note**: This is a simplified template. For authentication (GoTrue) and file storage, see the [Production Template](./PRODUCTION.md).

### Routing

All requests are handled by App Platform ingress:
- `https://your-app.ondigitalocean.app/` → Studio dashboard
- `https://your-app.ondigitalocean.app/rest/v1/*` → PostgREST API

## Prerequisites

Before deploying, you need:

- **Managed PostgreSQL Database** - Must be created before deployment (database name must match the name specified in `.do/app.yaml`)
- **DigitalOcean Account** with billing enabled
- **doctl CLI** - [Install and authenticate](https://docs.digitalocean.com/reference/doctl/how-to/install/)
- **JWT Keys** - Generated using the provided script

## Quick Start

**Prerequisites** (⚠️ MUST DO):
- Create managed PostgreSQL database (see Step 1 below)
- Generate Supabase encryption keys: `./scripts/generate-keys.sh`
- Replace required values in `.do/app.yaml` (see Step 3 below)

### Step 1: Create Managed Database

```bash
# Create database (if not already exists) - name must match .do/app.yaml
doctl databases create supabase-db \
  --engine pg \
  --version 17 \
  --size db-s-1vcpu-2gb \
  --region nyc3

# Wait for database to be ready (provisioning takes 5-10 minutes)
# Check status with: doctl databases list --format Name,Status
# Proceed to next steps only when status shows "online"
```

### Step 2: Clone and Generate Keys

```bash
git clone https://github.com/digitalocean/supabase-appplatform.git
cd supabase-appplatform

# Generate all required keys
chmod +x scripts/generate-keys.sh
./scripts/generate-keys.sh
```

**Save the output** - you'll need these 4 keys in the next step:
- `SUPABASE_JWT_SECRET`
- `SUPABASE_ANON_KEY`
- `SUPABASE_SERVICE_KEY`
- `CRYPTO_KEY`

### Step 3: Update App Spec with Keys

Open `.do/app.yaml` and replace the `<REQUIRED>` values with your generated keys:

| Key to Replace | Component | Generated Key to Use |
|----------------|-----------|---------------------|
| `PG_META_CRYPTO_KEY` | studio | `CRYPTO_KEY` |
| `SUPABASE_ANON_KEY` | studio | `SUPABASE_ANON_KEY` |
| `SUPABASE_SERVICE_KEY` | studio | `SUPABASE_SERVICE_KEY` |
| `PGRST_JWT_SECRET` | rest | `SUPABASE_JWT_SECRET` |
| `CRYPTO_KEY` | meta | `CRYPTO_KEY` |

**Example:**
```yaml
# BEFORE:
- key: PGRST_JWT_SECRET
  value: <REQUIRED>

# AFTER (use your actual generated key):
- key: PGRST_JWT_SECRET
  value: JMYwheHInFvsqptZOnKHI5upvmphHlTN9QarvHswMvI=
```

### Step 4: Deploy

```bash
doctl apps create --spec .do/app.yaml
```

The `db-init` job will automatically set up your database with required schemas and roles.

> **Customization**: If you need to customize the deployment (modify database initialization scripts, adjust component configurations, etc.), fork this repository, make your changes, and update the `github.repo` field in the template yaml to point to your forked repository before deploying.

## Post-Deployment

### Access Your Instance

Get your app URL and access Supabase Studio:

```bash
# Get your app ID
APP_ID=$(doctl apps list --format ID --no-header)

# Get your app URL
APP_URL=$(doctl apps get $APP_ID --format DefaultIngress --no-header)
echo "Visit: https://$APP_URL"
```

Open the URL in your browser to access the Studio dashboard.

### Verify Database Initialization

Check that the database was properly initialized:

```bash
# Check db-init job logs
doctl apps logs $APP_ID --component db-init
```

### Monitor Logs

```bash
# Monitor Studio service logs
doctl apps logs $APP_ID --component studio --follow

# Check other components
doctl apps logs $APP_ID --component rest --follow
doctl apps logs $APP_ID --component meta --follow
```

### Test the REST API

```bash
# Create a test table in Studio, then query it via REST API
curl https://$APP_URL/rest/v1/ \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY"
```

## Clean Up

To delete your deployment and database:

```bash
# Delete app
doctl apps delete $APP_ID

# Delete database
doctl databases delete $(doctl databases list --format ID --no-header)
```

## Documentation

- **[Production Setup](./PRODUCTION.md)** - Add authentication and file storage

## Pricing

For detailed pricing information based on instance sizes and resources, visit the [DigitalOcean App Platform Pricing](https://www.digitalocean.com/pricing/app-platform) page.

---

## Important Notes

### Schema Creation via Studio UI

Creating new schemas through the Studio UI is currently not supported. Use the SQL Editor instead:

```bash
CREATE SCHEMA my_schema;
```

This is due to DigitalOcean's security model where the `doadmin` user does not have full SUPERUSER privileges. All other database operations work normally.

## Resources

### Supabase Documentation
- [Official Documentation](https://supabase.com/docs)
- [Self-Hosting Guide](https://supabase.com/docs/guides/self-hosting)
- [API Reference](https://supabase.com/docs/reference)

### DigitalOcean Documentation
- [App Platform Docs](https://docs.digitalocean.com/products/app-platform/)
- [Managed PostgreSQL](https://docs.digitalocean.com/products/databases/postgresql/)
- [Spaces Storage](https://docs.digitalocean.com/products/spaces/)

### Community
- [Supabase Discord](https://discord.supabase.com)
- [Supabase GitHub](https://github.com/supabase/supabase)
- [DigitalOcean Community](https://www.digitalocean.com/community)

