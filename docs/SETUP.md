# Supabase Setup Guide

Deploy Supabase on DigitalOcean App Platform with a managed PostgreSQL database.

## What You'll Deploy

- **Studio**: Database admin dashboard
- **PostgREST**: Auto-generated REST API
- **postgres-meta**: Database management API (internal)
- **Managed PostgreSQL**: Production database with backups

**Cost**: ~$30-35/month | **Time**: 15-20 minutes

## Prerequisites

- DigitalOcean account with billing enabled
- [doctl CLI](https://docs.digitalocean.com/reference/doctl/how-to/install/) installed
- Authenticate: `doctl auth init`

## Deployment Steps

### 1. Clone Repository

```bash
git clone https://github.com/digitalocean/supabase-appplatform.git
cd supabase-appplatform
```

### 2. Generate JWT Keys

```bash
chmod +x scripts/generate-keys.sh
./scripts/generate-keys.sh
```

**Save the output** - you'll need these keys for Step 4.

### 3. Create Database

```bash
doctl databases create supabase-db \
  --engine pg \
  --version 17 \
  --size db-s-1vcpu-2gb \
  --region nyc3
```

**Wait for database** to be online (5-10 minutes):
```bash
doctl databases list  # Status should show "online"
```

> Change `--region nyc3` to your preferred region. See all regions: `doctl databases options regions`

### 4. Set Environment Variables

You need to add the JWT keys from Step 2. Choose one method:

**Option A: DigitalOcean UI**
1. Deploy first (Step 5), then go to App Settings > Environment Variables
2. Add: `SUPABASE_JWT_SECRET`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_KEY`

**Option B: Update app.yaml**
Replace the placeholder values in `.do/app.yaml` with your actual keys before deploying.

### 5. Deploy

```bash
doctl apps create --spec .do/app.yaml
```

Deployment takes 10-15 minutes. The `db-init` job will automatically set up your database.

**Monitor progress**:
```bash
APP_ID=$(doctl apps list --format ID --no-header)
doctl apps logs $APP_ID --component db-init --follow
```

### 6. Access Your Instance

```bash
# Get your app URL
APP_URL=$(doctl apps get $APP_ID --format DefaultIngress --no-header)
echo "Studio: https://$APP_URL"
```

Open the URL in your browser.

## Quick Start

### Create a Table

1. Open Studio in your browser (the URL from Step 6)
2. Go to **Table Editor** → **New Table**
3. Create a table (e.g., `todos` with `id`, `title`, `completed`)
4. Insert some test data

### Test the API

```bash
# Query your table via REST API
curl https://$APP_URL/rest/v1/todos \
  -H "apikey: $SUPABASE_ANON_KEY"
```

### Monitor Logs

```bash
doctl apps logs $APP_ID --component studio --follow
```

## Common Issues

**Database init failed?**
```bash
doctl apps logs $APP_ID --component db-init
```
Ensure database is `online` before deployment.

**Studio can't connect?**
Check Meta service logs and verify `PG_META_CRYPTO_KEY` matches between services.

**API returns 401?**
Verify JWT keys are set correctly in environment variables.

See [TROUBLESHOOTING.md](./TROUBLESHOOTING.md) for more help.

## Add More Features

- **Authentication**: See [PRODUCTION.md](./PRODUCTION.md) to add GoTrue auth service
- **File Storage**: See [PRODUCTION.md](./PRODUCTION.md) to add Storage API with Spaces

## Clean Up

```bash
# Delete app and database
doctl apps delete $APP_ID
doctl databases delete $(doctl databases list --format ID --no-header)
```

## Resources

- [Getting Started Guide](./GETTING-STARTED.md) - Build your first app
- [Production Setup](./PRODUCTION.md) - Add auth and storage
- [Troubleshooting](./TROUBLESHOOTING.md) - Detailed debugging
- [Supabase Docs](https://supabase.com/docs) - API reference
