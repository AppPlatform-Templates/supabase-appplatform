# Supabase App Platform Deployment Status

## ✅ FIXED - Deploy to DO Button

**Latest Status**: All critical fixes applied to `.do/deploy.template.yaml`

### Issues Resolved

1. ✅ **Ingress Routing Error** - "ingress rules only support services"
   - **Fix**: Moved `auth` and `storage` from workers to services
   - **Reason**: Ingress can only route to services, not workers

2. ✅ **Source Type Conflict** - "oneof apps.AppServiceSpec.Source is already set"
   - **Fix**: Removed `git:` from all Docker Hub image services
   - **Reason**: Can't have both `git:` and `image:` sources

3. ✅ **Unknown Field http_port** - Error at character 5305 (storage service)
   - **Fix**: Removed `http_port` from storage service
   - **Reason**: Storage-api configures port via `SERVER_PORT` environment variable

### Current Configuration

**Services** (HTTP-accessible, for ingress routing):
- `studio`: Docker Hub image, `http_port: 3000`
- `rest` (PostgREST): Docker Hub image, `http_port: 3000`
- `auth` (GoTrue): Docker Hub image, `http_port: 9999`
- `storage`: Docker Hub image, **NO http_port** (uses `SERVER_PORT=5000` env var)

**Workers** (Internal only):
- `meta` (Postgres Meta): Docker Hub image, internal port 8080

**Jobs**:
- `db-init`: Builds from `Dockerfile.dbinit`, runs post-deploy

### Files Status

| File | Status | Notes |
|------|--------|-------|
| `.do/deploy.template.yaml` | ✅ FIXED | Ready for Deploy to DO button |
| `.do/app.yaml` | ✅ FIXED | Synced with deploy.template.yaml |
| `test-deployment.sh` | ⚠️ NEEDS UPDATE | Has old workers structure |
| `.do/examples/production.yaml` | ⚠️ NEEDS UPDATE | Has old workers structure |

### Test the Deploy to DO Button

Click here to test:
[![Deploy to DO](https://www.deploytodo.com/do-btn-blue.svg)](https://cloud.digitalocean.com/apps/new?repo=https://github.com/AppPlatform-Templates/supabase-appplatform/tree/main)

### Key Learnings

1. **Ingress Routing**: Only `services`, `functions`, and `static_sites` can be ingress targets
2. **Worker vs Service**: Workers are internal-only; services can have HTTP routing
3. **Docker Hub Images**: Can specify `http_port`, but some images (like storage-api) prefer env var configuration
4. **Source Types**: Use EITHER `git:` OR `image:`, never both

### Next Steps

If the Deploy to DO button still has issues:

1. Check the exact error message
2. The error will point to a specific line/character - find what field is at that position
3. Compare with working templates (n8n-appplatform, pocketbase-appplatform)
4. Use `doctl apps spec validate` for testing (note: it doesn't like the `spec:` wrapper)

### Manual Testing

```bash
# Test locally
cd /Users/bgupta/Documents/Builder/AppPlatform-Templates/supabase-appplatform

# Generate keys
./generate-keys.sh

# Create Spaces bucket and credentials manually in DO control panel

# Deploy using fixed app.yaml
doctl apps create --spec .do/app.yaml
```

---

**Last Updated**: 2024-10-27
**Repository**: https://github.com/AppPlatform-Templates/supabase-appplatform
