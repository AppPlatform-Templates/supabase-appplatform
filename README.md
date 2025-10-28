# Supabase on DigitalOcean App Platform

[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/AppPlatform-Templates/supabase-appplatform/tree/main)

Deploy your own Supabase instance on DigitalOcean App Platform in minutes! This template provides a production-ready Supabase setup optimized for App Platform, with automatic database initialization, scalable architecture, and secure configuration.

## What is Supabase?

[Supabase](https://supabase.com) is an open-source Firebase alternative that provides:
- **PostgreSQL Database** - Full-featured relational database with extensions
- **Authentication** - Email, magic links, and OAuth providers (Google, GitHub, etc.)
- **Auto-generated REST API** - Instant RESTful API from your database schema
- **Row Level Security** - Fine-grained access control built into PostgreSQL
- **File Storage** - S3-compatible object storage for user uploads
- **Realtime Subscriptions** - WebSocket-based database change notifications (coming soon)

Perfect for building modern web and mobile applications without managing backend infrastructure.

## Architecture

This deployment includes:

| Component | Purpose | Type |
|-----------|---------|------|
| **Studio** | Web admin dashboard | Service (HTTP) |
| **PostgREST** | Auto-generated REST API | Service (HTTP) |
| **GoTrue** | Authentication service | Worker (HTTP via ingress) |
| **Storage** | File upload/download API | Worker (HTTP via ingress) |
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

Before deploying, you'll need:

1. **DigitalOcean Account** with payment method
2. **JWT Keys** - Generate with `./generate-keys.sh` (see below)
3. **Spaces Bucket** - For file storage (auto-created via Deploy to DO button)
4. **(Optional) SMTP Credentials** - For email authentication (see [SMTP Providers](#smtp-providers))

## Quick Deploy (5 Minutes)

### Option 1: Deploy to DO Button (Easiest)

1. **Click the button above** or visit [this link](https://cloud.digitalocean.com/apps/new?repo=https://github.com/AppPlatform-Templates/supabase-appplatform/tree/main)

2. **Generate JWT keys locally**:
   ```bash
   # Clone this repo first
   git clone https://github.com/AppPlatform-Templates/supabase-appplatform.git
   cd supabase-appplatform

   # Generate keys
   chmod +x generate-keys.sh
   ./generate-keys.sh
   ```

   Copy the three values:
   - `SUPABASE_JWT_SECRET`
   - `SUPABASE_ANON_KEY` (generate at [jwt.io](https://jwt.io))
   - `SUPABASE_SERVICE_ROLE_KEY` (generate at [jwt.io](https://jwt.io))

3. **Configure in App Platform**:
   - App name: Choose a unique name
   - Region: Select closest to your users
   - Environment Variables (required):
     ```
     SUPABASE_JWT_SECRET=<your-jwt-secret>
     SUPABASE_ANON_KEY=<your-anon-key>
     SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
     SPACES_BUCKET=supabase-<your-app-name>
     SPACES_REGION=nyc3
     SPACES_ACCESS_KEY=<create-in-next-step>
     SPACES_SECRET_KEY=<create-in-next-step>
     ```
   - Optional SMTP variables (leave empty to skip email auth):
     ```
     SMTP_HOST=
     SMTP_PORT=587
     SMTP_USER=
     SMTP_PASS=
     SMTP_ADMIN_EMAIL=
     ```

4. **Create Spaces credentials**:
   - Visit [API Tokens page](https://cloud.digitalocean.com/account/api/tokens)
   - Click "Spaces Keys" tab → "Generate New Key"
   - Copy Access Key and Secret Key
   - Update environment variables in App Platform

5. **Deploy**: Click "Create Resources" and wait 5-10 minutes

6. **Access your Supabase**: Open the app URL to see Studio dashboard

### Option 2: Deploy with doctl CLI

```bash
# 1. Clone repository
git clone https://github.com/AppPlatform-Templates/supabase-appplatform.git
cd supabase-appplatform

# 2. Generate JWT keys
chmod +x generate-keys.sh
./generate-keys.sh
# Follow instructions to generate ANON_KEY and SERVICE_ROLE_KEY at jwt.io

# 3. Create Spaces bucket
doctl spaces create supabase-storage-$(whoami) --region nyc3

# 4. Generate Spaces credentials
doctl spaces access create
# Save the Access Key ID and Secret Access Key

# 5. Update .do/app.yaml with your environment variables
# Replace ${SUPABASE_JWT_SECRET}, ${SUPABASE_ANON_KEY}, etc. with actual values

# 6. Create the app
doctl apps create --spec .do/app.yaml

# 7. Get app ID and wait for deployment
APP_ID=$(doctl apps list --format ID,Name --no-header | grep supabase | awk '{print $1}')
doctl apps get $APP_ID

# 8. Monitor deployment
doctl apps logs $APP_ID --type build --follow
```

## Post-Deployment

### 1. Access Studio Dashboard

Visit your app URL (e.g., `https://supabase-xyz.ondigitalocean.app`) to access the Studio admin interface.

**First Login**:
- The database will be automatically initialized on first deployment (via post-deploy job)
- Check logs if Studio doesn't load: `doctl apps logs $APP_ID --type run`

### 2. Verify Database Initialization

The `db-init` job runs automatically after deployment. To check if it succeeded:

```bash
# View job logs
doctl apps logs $APP_ID --type run db-init

# You should see: "✓ Supabase database initialization complete!"
```

If initialization failed, you can manually run the SQL:
```bash
# Get database connection string
DB_URL=$(doctl apps get $APP_ID | grep DATABASE_URL | cut -d= -f2-)

# Run initialization
psql "$DB_URL" -f init-db.sql
```

### 3. Test Your Supabase Instance

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

All endpoints should return 200 OK.

## Building Your First App

See **[HOW_TO_USE_SUPABASE.md](./HOW_TO_USE_SUPABASE.md)** for:
- Creating your first table with Row Level Security
- Building a todo list app (CRUD operations)
- Implementing user authentication
- Uploading files to Storage
- Real-time subscriptions (when available)

## Environment Variables

### Required Variables

| Variable | Description | How to Generate |
|----------|-------------|-----------------|
| `SUPABASE_JWT_SECRET` | Secret for signing JWTs (32+ chars) | `openssl rand -base64 32` |
| `SUPABASE_ANON_KEY` | JWT for anonymous access | See [generate-keys.sh](./generate-keys.sh) |
| `SUPABASE_SERVICE_ROLE_KEY` | JWT for admin access | See [generate-keys.sh](./generate-keys.sh) |
| `SPACES_BUCKET` | Spaces bucket name | `supabase-<unique-name>` |
| `SPACES_REGION` | Spaces region | `nyc3`, `sfo3`, `ams3`, etc. |
| `SPACES_ACCESS_KEY` | Spaces access key ID | `doctl spaces access create` |
| `SPACES_SECRET_KEY` | Spaces secret key | `doctl spaces access create` |

### Optional Variables (SMTP)

| Variable | Description | Default |
|----------|-------------|---------|
| `SMTP_HOST` | SMTP server hostname | _(empty)_ |
| `SMTP_PORT` | SMTP server port | `587` |
| `SMTP_USER` | SMTP username | _(empty)_ |
| `SMTP_PASS` | SMTP password | _(empty)_ |
| `SMTP_ADMIN_EMAIL` | From email address | _(empty)_ |

**Note**: If SMTP variables are empty, email-based authentication (password reset, email confirmation) will not work, but OAuth providers and magic links can still be configured.

### Auto-Provided Variables

App Platform automatically provides:
- `${APP_URL}` - Your app's public URL
- `${db.DATABASE_URL}` - PostgreSQL connection string
- `${db.HOSTNAME}`, `${db.PORT}`, `${db.DATABASE}`, `${db.USERNAME}`, `${db.PASSWORD}` - Database connection details

See [.env-data](./.env-data) for complete reference.

## SMTP Providers

For email authentication, you'll need an SMTP provider. Here are some options:

| Provider | Free Tier | Setup |
|----------|-----------|-------|
| **SendGrid** | 100 emails/day | [signup](https://sendgrid.com) → API Keys → Create |
| **Brevo** | 300 emails/day | [signup](https://brevo.com) → SMTP & API → SMTP |
| **Mailgun** | 5,000 emails/month | [signup](https://mailgun.com) → Sending → Domain settings |
| **Amazon SES** | 62,000/month (free tier) | [setup guide](https://docs.aws.amazon.com/ses/latest/dg/send-email-smtp.html) |
| **Resend** | 3,000 emails/month | [signup](https://resend.com) → API Keys → Create |

**Configuration Example (SendGrid)**:
```bash
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_USER=apikey
SMTP_PASS=<your-sendgrid-api-key>
SMTP_ADMIN_EMAIL=noreply@yourdomain.com
```

## Pricing

### Basic Deployment (Development/Small Production)

| Component | Configuration | Monthly Cost |
|-----------|---------------|--------------|
| Studio (basic-xxs) | 512MB RAM, 1 vCPU | $5 |
| PostgREST (basic-xxs) | 512MB RAM, 1 vCPU | $5 |
| GoTrue (basic-xxs) | 512MB RAM, 1 vCPU | $5 |
| Meta (basic-xxs) | 512MB RAM, 1 vCPU | $5 |
| Storage (basic-xxs) | 512MB RAM, 1 vCPU | $5 |
| Dev Database (1GB) | PostgreSQL 15 | $7 |
| Spaces (250GB storage) | 1TB bandwidth included | $5 |
| **Total** | | **~$37/month** |

### Production Deployment

See [.do/examples/production.yaml](./.do/examples/production.yaml) for a production-hardened configuration with:
- Auto-scaling (2-10 instances per service)
- Managed PostgreSQL (production tier with standby)
- Redis for Realtime (when enabled)
- Monitoring and log forwarding

**Estimated**: $600-900/month depending on traffic

## Upgrading to Production

When your app is ready for production:

1. **Upgrade Database**:
   ```bash
   # In App Platform UI: Database → Settings → Upgrade to Production
   # Or create new managed database:
   doctl databases create supabase-prod --engine pg --version 15 --size db-s-2vcpu-4gb --num-nodes 2
   ```

2. **Enable Auto-scaling**: Update app spec with auto-scaling configuration

3. **Configure Custom Domain**: Settings → Domains → Add Domain

4. **Enable Monitoring**: Settings → Monitoring → Forward Logs

5. **Set up Backups**: Database → Settings → Configure Backup Schedule

See [.do/examples/production.yaml](./.do/examples/production.yaml) for complete production configuration.

## Troubleshooting

### Studio not loading

**Symptoms**: Blank page or "Unable to connect" error

**Solutions**:
1. Check db-init job completed successfully:
   ```bash
   doctl apps logs $APP_ID --type run db-init
   ```

2. Verify Meta service is running:
   ```bash
   doctl apps get $APP_ID
   ```

3. Check Studio logs:
   ```bash
   doctl apps logs $APP_ID --type run studio --tail 50
   ```

4. Ensure `POSTGRES_PASSWORD` matches database password:
   ```bash
   doctl apps get $APP_ID | grep PASSWORD
   ```

### REST API returns 401 Unauthorized

**Symptoms**: API calls fail with authentication error

**Solutions**:
1. Verify JWT_SECRET is identical across all services
2. Check ANON_KEY was signed with the same JWT_SECRET (at jwt.io)
3. Ensure you're including the `apikey` header:
   ```bash
   curl https://your-app.ondigitalocean.app/rest/v1/ \
     -H "apikey: your-anon-key"
   ```

### File uploads failing

**Symptoms**: Storage API returns errors when uploading files

**Solutions**:
1. Verify Spaces bucket exists:
   ```bash
   doctl spaces ls | grep your-bucket-name
   ```

2. Check Spaces credentials are correct:
   ```bash
   aws s3 ls s3://your-bucket-name \
     --endpoint-url=https://nyc3.digitaloceanspaces.com \
     --profile your-profile
   ```

3. Check Storage service logs:
   ```bash
   doctl apps logs $APP_ID --type run storage --tail 50
   ```

### Email authentication not working

**Symptoms**: Password reset or confirmation emails not sending

**Solutions**:
1. Verify SMTP credentials are correct
2. Test SMTP connection:
   ```bash
   telnet $SMTP_HOST $SMTP_PORT
   ```

3. Check GoTrue logs for SMTP errors:
   ```bash
   doctl apps logs $APP_ID --type run auth | grep -i smtp
   ```

4. If SMTP is not configured, disable email features:
   - In Studio → Authentication → Settings
   - Set "Enable Email Signup" to OFF
   - Use OAuth providers instead

### Database connection errors

**Symptoms**: Services can't connect to PostgreSQL

**Solutions**:
1. Check database is running:
   ```bash
   doctl apps get $APP_ID
   ```

2. Verify connection string format:
   ```bash
   # Should be: postgres://user:pass@host:port/dbname?sslmode=require
   doctl apps get $APP_ID | grep DATABASE_URL
   ```

3. Ensure database roles exist:
   ```bash
   psql "$DATABASE_URL" -c "SELECT rolname FROM pg_roles WHERE rolname IN ('anon', 'authenticated', 'service_role');"
   ```

## Security Best Practices

1. **Never expose SERVICE_ROLE_KEY** to client applications (it bypasses Row Level Security)
2. **Use Row Level Security (RLS)** on all tables with user data
3. **Rotate JWT_SECRET** periodically (requires regenerating API keys)
4. **Enable HTTPS only** (App Platform provides free SSL)
5. **Restrict Spaces bucket access** to your app only
6. **Monitor API usage** for unusual patterns
7. **Set up database backups** (automatic with Managed PostgreSQL)
8. **Use strong SMTP credentials** and enable 2FA on your email provider

## Limitations

### Current Limitations

- **Dev Database**: 1GB storage limit (upgrade to managed database for more)
- **No Realtime**: WebSocket subscriptions not yet configured (add Redis to enable)
- **No Edge Functions**: Deno runtime not included (can be added)
- **Single Region**: One deployment per region (multi-region requires multiple apps)

### App Platform Constraints

- **2GB ephemeral storage**: Use Spaces for file persistence
- **No IPv6**: Outbound connections are IPv4 only
- **No privileged containers**: Standard Docker only

See [VERSION.md](./VERSION.md) for component version details.

## Resources

### Supabase Documentation
- [Official Documentation](https://supabase.com/docs)
- [Self-Hosting Guide](https://supabase.com/docs/guides/self-hosting)
- [API Reference](https://supabase.com/docs/reference)
- [Database Guide](https://supabase.com/docs/guides/database)
- [Auth Guide](https://supabase.com/docs/guides/auth)
- [Storage Guide](https://supabase.com/docs/guides/storage)

### DigitalOcean Documentation
- [App Platform Docs](https://docs.digitalocean.com/products/app-platform/)
- [Managed PostgreSQL](https://docs.digitalocean.com/products/databases/postgresql/)
- [Spaces Storage](https://docs.digitalocean.com/products/spaces/)
- [Deploy to DO Button](https://docs.digitalocean.com/products/app-platform/how-to/add-deploy-do-button/)

### Community
- [Supabase Discord](https://discord.supabase.com)
- [Supabase GitHub](https://github.com/supabase/supabase)
- [DigitalOcean Community](https://www.digitalocean.com/community)

## Contributing

Found an issue or want to improve this template?

1. Open an issue on [GitHub](https://github.com/AppPlatform-Templates/supabase-appplatform/issues)
2. Submit a pull request with improvements
3. Share feedback in the [Discussions](https://github.com/AppPlatform-Templates/supabase-appplatform/discussions)

## License

This template is provided as-is under the MIT License. Supabase is licensed under Apache 2.0.

---

**Need help?** Check out [HOW_TO_USE_SUPABASE.md](./HOW_TO_USE_SUPABASE.md) for guides on building applications with Supabase.
