# Supabase on DigitalOcean App Platform

Deploy your own Supabase instance on DigitalOcean App Platform with a managed PostgreSQL database. This template provides a simplified, production-ready Supabase setup optimized for App Platform.

> **Important**: This template requires a managed PostgreSQL database to be created before deployment. See [Setup Guide](./docs/SETUP.md) for step-by-step instructions.

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
| **DB Init** | Automatic schema setup | Post-deploy Job |

> **Note**: This is a simplified template. For authentication (GoTrue) and file storage, see the [Production Template](./docs/PRODUCTION.md).

### Routing

All requests are handled by App Platform ingress:
- `https://your-app.ondigitalocean.app/` → Studio dashboard
- `https://your-app.ondigitalocean.app/rest/v1/*` → PostgREST API

## Prerequisites

Before deploying, you need:

- **DigitalOcean Account** with billing enabled
- **doctl CLI** - [Install and authenticate](https://docs.digitalocean.com/reference/doctl/how-to/install/)
- **Managed PostgreSQL Database** - Must be created before deployment
- **JWT Keys** - Generated using the provided script

**Estimated Cost**: ~$30-35/month (Managed PostgreSQL + App Platform services)

## Quick Start

**Prerequisites** (⚠️ MUST DO):
- Generate Supabase encryption keys: `./scripts/generate-keys.sh`
- Replace required values in `.do/app.yaml` (see Step 2 below)
- Create managed PostgreSQL database (see Step 3 below)

### Step 1: Clone and Generate Keys

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
- `SUPABASE_SERVICE_ROLE_KEY`
- `CRYPTO_KEY`

### Step 2: Update App Spec with Keys

Open `.do/app.yaml` and replace the `<REQUIRED>` values with your generated keys:

| Key to Replace | Component | Line # | Generated Key to Use |
|----------------|-----------|---------|---------------------|
| `PG_META_CRYPTO_KEY` | studio | ~56 | `CRYPTO_KEY` |
| `SUPABASE_ANON_KEY` | studio | ~70 | `SUPABASE_ANON_KEY` |
| `SUPABASE_SERVICE_KEY` | studio | ~74 | `SUPABASE_SERVICE_ROLE_KEY` |
| `PGRST_JWT_SECRET` | rest | ~121 | `SUPABASE_JWT_SECRET` |
| `CRYPTO_KEY` | meta | ~165 | `CRYPTO_KEY` |

**Example:**
```yaml
# BEFORE:
- key: PGRST_JWT_SECRET
  value: <REQUIRED>

# AFTER (use your actual generated key):
- key: PGRST_JWT_SECRET
  value: JMYwheHInFvsqptZOnKHI5upvmphHlTN9QarvHswMvI=
```

### Step 3: Create Managed Database

```bash
doctl databases create supabase-db \
  --engine pg \
  --version 17 \
  --size db-s-1vcpu-2gb \
  --region nyc3
```

Wait for the database to be online (5-10 minutes).

### Step 4: Deploy

```bash
doctl apps create --spec .do/app.yaml
```

Deployment takes 10-15 minutes. The `db-init` job will automatically set up your database with required schemas and roles.

**For detailed step-by-step instructions, see [SETUP.md](./docs/SETUP.md)**

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

You should see confirmation that schemas, roles, and extensions were created.

### Test the REST API

```bash
# Create a test table in Studio, then query it via REST API
curl https://$APP_URL/rest/v1/ \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Authorization: Bearer $SUPABASE_ANON_KEY"
```

## Documentation

- **[Setup Guide](./docs/SETUP.md)** - Detailed deployment instructions
- **[Getting Started Guide](./docs/GETTING-STARTED.md)** - Build your first app with Supabase
- **[Production Setup](./docs/PRODUCTION.md)** - Add authentication and file storage
- **[Troubleshooting](./docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Version Info](./docs/VERSION.md)** - Component versions and updates

## Environment Variables

### Required

| Variable | Description | How to Generate |
|----------|-------------|-----------------|
| `SUPABASE_JWT_SECRET` | Secret for signing JWTs | Use `scripts/generate-keys.sh` |
| `SUPABASE_ANON_KEY` | JWT for anonymous access | Use `scripts/generate-keys.sh` |
| `SUPABASE_SERVICE_ROLE_KEY` | JWT for admin access | Use `scripts/generate-keys.sh` |

All JWT keys are automatically generated by running the `scripts/generate-keys.sh` script. The script uses a cryptographically secure method to create these keys.

### Database Connection (Auto-Injected)

These variables are automatically provided by App Platform when you reference the managed database:

- `${supabase-db.HOSTNAME}` - Database host
- `${supabase-db.PORT}` - Database port
- `${supabase-db.DATABASE}` - Database name
- `${supabase-db.USERNAME}` - Database user
- `${supabase-db.PASSWORD}` - Database password
- `${supabase-db.DATABASE_URL}` - Full connection string
- `${supabase-db.CA_CERT}` - SSL certificate for secure connections

## Pricing

For detailed pricing information based on instance sizes and resources, visit the [DigitalOcean App Platform Pricing](https://www.digitalocean.com/pricing/app-platform) page.

---

## Adding More Features

This template provides the core Supabase functionality. To add more features:

### Authentication (GoTrue)
Add user authentication with email, magic links, and OAuth. See [Production Setup](./docs/PRODUCTION.md) for:
- GoTrue authentication service
- SMTP configuration for email verification
- Social OAuth providers
- JWT-based authentication

### File Storage
Add file upload/download capabilities. See [Production Setup](./docs/PRODUCTION.md) for:
- Storage API service
- DigitalOcean Spaces integration
- File access controls
- Public and private buckets

### Production Optimizations
Upgrade your deployment with:
- Auto-scaling (2-10 instances per service)
- Larger instance sizes for better performance
- Custom domains with SSL
- Advanced monitoring and alerting
- Automated database backups

## Security Best Practices

1. **Never expose SERVICE_ROLE_KEY** to client applications
2. **Use Row Level Security (RLS)** on all tables with user data
3. **Rotate JWT_SECRET** periodically (requires regenerating API keys)
4. **Enable HTTPS only** (App Platform provides free SSL)
5. **Monitor API usage** for unusual patterns
6. **Set up database backups** (automatic with Managed PostgreSQL)

See [docs/PRODUCTION.md](./docs/PRODUCTION.md) for complete security checklist.

## What's Not Included

This simplified template focuses on core database and API functionality. The following are not included but can be added:

- **Authentication (GoTrue)**: User signup, login, OAuth - see [Production Setup](./docs/PRODUCTION.md)
- **File Storage**: Upload/download files - see [Production Setup](./docs/PRODUCTION.md)
- **Realtime**: WebSocket subscriptions (requires Redis and additional configuration)
- **Edge Functions**: Deno serverless functions (not supported on App Platform)
- **Multi-region**: Deploy to multiple regions for global coverage

See [docs/VERSION.md](./docs/VERSION.md) for current component versions.

## Known Limitations

When using DigitalOcean Managed PostgreSQL, the following limitations apply:

- **Schema Creation via Studio UI**: Creating new schemas through the Studio UI is not supported. Use the SQL Editor instead:
  ```sql
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

## Contributing

Found an issue or want to improve this template?

1. Open an issue on [GitHub](https://github.com/AppPlatform-Templates/supabase-appplatform/issues)
2. Submit a pull request with improvements
3. Share feedback in [Discussions](https://github.com/AppPlatform-Templates/supabase-appplatform/discussions)

---

**Need help?** Check out our [Getting Started Guide](./docs/GETTING-STARTED.md) for guides on building applications with Supabase.
