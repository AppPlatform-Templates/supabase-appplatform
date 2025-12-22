# Supabase on DigitalOcean App Platform

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/AppPlatform-Templates/supabase-appplatform/tree/main)

Deploy your own Supabase instance on DigitalOcean App Platform in minutes! This template provides a production-ready Supabase setup optimized for App Platform.

## What is Supabase?

[Supabase](https://supabase.com) is an open-source Firebase alternative providing:
- **PostgreSQL Database** - Full-featured relational database with extensions
- **Authentication** - Email, magic links, and OAuth providers
- **Auto-generated REST API** - Instant RESTful API from your database schema
- **Row Level Security** - Fine-grained access control built into PostgreSQL
- **File Storage** - S3-compatible object storage for user uploads

Perfect for building modern web and mobile applications without managing backend infrastructure.

## Architecture

This deployment includes:

| Component | Purpose | Type |
|-----------|---------|------|
| **Studio** | Web admin dashboard | Service (HTTP) |
| **PostgREST** | Auto-generated REST API | Service (HTTP) |
| **GoTrue** | Authentication service | Service (HTTP via ingress) |
| **Storage** | File upload/download API | Service (HTTP via ingress) |
| **Meta** | Database management API | Worker (Internal) |
| **PostgreSQL** | Database (with extensions) | Managed Database (Dev tier) |
| **Spaces** | Object storage | DigitalOcean Spaces |
| **DB Init** | Automatic schema setup | Post-deploy Job |

### Routing

All requests are handled by App Platform ingress:
- `https://your-app.ondigitalocean.app/` → Studio dashboard
- `https://your-app.ondigitalocean.app/rest/v1/*` → PostgREST API
- `https://your-app.ondigitalocean.app/auth/v1/*` → Authentication
- `https://your-app.ondigitalocean.app/storage/v1/*` → File storage

## Prerequisites

**Prerequisites: (⚠️ MUST DO)**
- **DigitalOcean Account** with payment method
- **JWT Keys** - Generate with: `openssl rand -base64 32` for JWT secret, then create ANON and SERVICE_ROLE keys at [jwt.io](https://jwt.io)
- **Spaces Bucket** - For file storage (auto-created via Deploy to DO button)
- **(Optional) SMTP Credentials** - For email authentication (see [SMTP Providers](#smtp-providers))

## Quick Deploy (5 Minutes)

### Option 1: Deploy to DO Button (Easiest)

1. **Click the button above** or visit [this link](https://cloud.digitalocean.com/apps/new?repo=https://github.com/AppPlatform-Templates/supabase-appplatform/tree/main)

2. **Generate JWT keys**:
   ```bash
   # Clone and generate keys
   git clone https://github.com/AppPlatform-Templates/supabase-appplatform.git
   cd supabase-appplatform
   chmod +x scripts/generate-keys.sh
   ./scripts/generate-keys.sh
   ```

3. **Configure environment variables** in App Platform:
   - `SUPABASE_JWT_SECRET`
   - `SUPABASE_ANON_KEY`
   - `SUPABASE_SERVICE_ROLE_KEY`
   - `SPACES_BUCKET`, `SPACES_REGION`, `SPACES_ACCESS_KEY`, `SPACES_SECRET_KEY`

4. **Deploy** and wait 5-10 minutes

### Option 2: Deploy with doctl CLI

```bash
# 1. Clone and generate keys
git clone https://github.com/AppPlatform-Templates/supabase-appplatform.git
cd supabase-appplatform
chmod +x scripts/generate-keys.sh
./scripts/generate-keys.sh

# 2. Update .do/app.yaml with your environment variables

# 3. Create the app
doctl apps create --spec .do/app.yaml

# 4. Monitor deployment
doctl apps list
```

## Post-Deployment

### Access Your Instance

Visit your app URL (e.g., `https://supabase-xyz.ondigitalocean.app`) to access Studio.

### Test APIs

```bash
# Get your app URL
APP_URL=$(doctl apps get $APP_ID --format DefaultIngress --no-header)

# Test REST API
curl https://$APP_URL/rest/v1/ -H "apikey: $SUPABASE_ANON_KEY"

# Test Auth API
curl https://$APP_URL/auth/v1/health

# Test Storage API
curl https://$APP_URL/storage/v1/bucket -H "apikey: $SUPABASE_ANON_KEY"
```

## Documentation

- **[Getting Started Guide](./docs/GETTING-STARTED.md)** - Build your first app with Supabase
- **[Production Setup](./docs/PRODUCTION.md)** - Upgrade to production configuration
- **[Troubleshooting](./docs/TROUBLESHOOTING.md)** - Common issues and solutions
- **[Version Info](./docs/VERSION.md)** - Component versions and updates

## Environment Variables

### Required

| Variable | Description | How to Generate |
|----------|-------------|-----------------|
| `SUPABASE_JWT_SECRET` | Secret for signing JWTs | `openssl rand -base64 32` |
| `SUPABASE_ANON_KEY` | JWT for anonymous access | See [scripts/generate-keys.sh](./scripts/generate-keys.sh) |
| `SUPABASE_SERVICE_ROLE_KEY` | JWT for admin access | See [scripts/generate-keys.sh](./scripts/generate-keys.sh) |
| `SPACES_BUCKET` | Spaces bucket name | `supabase-<unique-name>` |
| `SPACES_REGION` | Spaces region | `nyc3`, `sfo3`, `ams3`, etc. |
| `SPACES_ACCESS_KEY` | Spaces access key ID | `doctl spaces access create` |
| `SPACES_SECRET_KEY` | Spaces secret key | `doctl spaces access create` |

### Optional (SMTP)

| Variable | Description | Default |
|----------|-------------|---------|
| `SMTP_HOST` | SMTP server hostname | _(empty)_ |
| `SMTP_PORT` | SMTP server port | `587` |
| `SMTP_USER` | SMTP username | _(empty)_ |
| `SMTP_PASS` | SMTP password | _(empty)_ |
| `SMTP_ADMIN_EMAIL` | From email address | _(empty)_ |

## SMTP Providers

For email authentication, choose an SMTP provider:

| Provider | Free Tier | Setup |
|----------|-----------|-------|
| **SendGrid** | 100 emails/day | [signup](https://sendgrid.com) → API Keys → Create |
| **Brevo** | 300 emails/day | [signup](https://brevo.com) → SMTP & API → SMTP |
| **Mailgun** | 5,000 emails/month | [signup](https://mailgun.com) → Sending → Domain settings |
| **Amazon SES** | 62,000/month | [setup guide](https://docs.aws.amazon.com/ses/latest/dg/send-email-smtp.html) |
| **Resend** | 3,000 emails/month | [signup](https://resend.com) → API Keys → Create |

## Pricing

### Basic Deployment (Development)

| Component | Monthly Cost |
|-----------|--------------|
| 5 Services (basic-xxs) | $25 |
| Dev Database (1GB) | $7 |
| Spaces (250GB storage) | $5 |
| **Total** | **~$37/month** |

### Production Deployment

See [docs/PRODUCTION.md](./docs/PRODUCTION.md) for production configuration details.

**Estimated**: $200-600/month with auto-scaling, managed PostgreSQL, and high availability.

## Upgrading to Production

Ready for production? See our [Production Setup Guide](./docs/PRODUCTION.md) for:
- Managed PostgreSQL configuration
- Auto-scaling setup
- Custom domains
- Monitoring and backups
- Security hardening

## Security Best Practices

1. **Never expose SERVICE_ROLE_KEY** to client applications
2. **Use Row Level Security (RLS)** on all tables with user data
3. **Rotate JWT_SECRET** periodically (requires regenerating API keys)
4. **Enable HTTPS only** (App Platform provides free SSL)
5. **Monitor API usage** for unusual patterns
6. **Set up database backups** (automatic with Managed PostgreSQL)

See [docs/PRODUCTION.md](./docs/PRODUCTION.md) for complete security checklist.

## Limitations

- **Dev Database**: 1GB storage limit (upgrade to managed database for more)
- **No Realtime**: WebSocket subscriptions not configured (Redis required)
- **No Edge Functions**: Deno runtime not included
- **Single Region**: One deployment per region

See [docs/VERSION.md](./docs/VERSION.md) for component version details.

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
