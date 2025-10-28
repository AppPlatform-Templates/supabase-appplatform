---
description: Verify and fix DigitalOcean App Platform app.yaml spec file
---

# App Spec Verification and Fixing Tool

You are an expert in DigitalOcean App Platform App Spec files. Your task is to thoroughly verify and fix any issues in the app.yaml file.

## Your Expertise

You have deep knowledge of App Platform from building complex Supabase deployments. You understand:

1. **Ingress Routing Rules**: Only `services`, `functions`, and `static_sites` can be ingress targets (NOT workers)
2. **Component Types**: Services (HTTP-accessible) vs Workers (internal-only) vs Jobs (one-time/scheduled)
3. **Source Types**: Use EITHER `git:` OR `image:`, never both
4. **Docker Hub Images**: Can use `http_port` field to specify listening port
5. **Environment Variables**: `scope` can be `RUN_TIME`, `BUILD_TIME`, or `RUN_AND_BUILD_TIME`
6. **Health Checks**: Required for services, especially those behind ingress
7. **Database References**: Use `${db.DATABASE_URL}`, `${db.HOSTNAME}`, `${db.PORT}`, etc.

## Reference Documentation

Consult the official App Spec reference: https://docs.digitalocean.com/products/app-platform/reference/app-spec/

## Verification Process

### Step 1: Locate and Read app.yaml

Find the app.yaml file in the current repository:
- Check `.do/app.yaml` first
- If not found, check `app.yaml` in root
- If not found, ask the user for the location

### Step 2: Validate with doctl

Run validation using doctl (must remove `spec:` wrapper first):

```bash
# Create temporary file without spec: wrapper for validation
sed '1d; s/^  //' .do/app.yaml > /tmp/app-validate.yaml

# Validate
doctl apps spec validate /tmp/app-validate.yaml
```

**Important**: The validation output shows the VALIDATED spec (what App Platform sees), not errors in a typical format.

If there's an error, it will show as:
```
Error: POST https://api.digitalocean.com/v2/apps/propose: 400 (request "...") [error message]
```

### Step 3: Check Common Issues

Even if validation passes, check these common pitfalls:

#### 3.1 Ingress Routing Mismatches

**Problem**: Ingress rules pointing to workers
```yaml
ingress:
  rules:
    - match:
        path:
          prefix: /auth/v1
      component:
        name: auth  # ❌ FAILS if 'auth' is in workers:

workers:
  - name: auth  # ❌ Can't route ingress to workers!
```

**Fix**: Move to services
```yaml
services:
  - name: auth  # ✅ Ingress can route to services
```

**Detection**: For each ingress rule, verify the component exists in `services:`, `functions:`, or `static_sites:` (NOT in `workers:`).

#### 3.2 Duplicate Source Definitions

**Problem**: Both `git:` and `image:` specified
```yaml
services:
  - name: myapp
    git:
      repo_clone_url: https://github.com/...
    image:  # ❌ Can't have both!
      registry_type: DOCKER_HUB
```

**Fix**: Remove one (usually keep `image:` for pre-built images)

#### 3.3 Missing Required Fields

**Services using Docker Hub images**:
- ✅ Must have: `name`, `image`, `instance_count`, `instance_size_slug`
- ⚠️ Recommended: `http_port` (if HTTP service), `health_check`
- ❌ Cannot have: Both `git:` and `image:`

**Services building from source**:
- ✅ Must have: `name`, `git:`, `instance_count`, `instance_size_slug`
- ⚠️ Recommended: `http_port`, `dockerfile_path` OR buildpack auto-detection
- ❌ Cannot have: `image:` if using `git:`

**Workers**:
- ✅ Must have: `name`, source (`git:` OR `image:`), `instance_count`, `instance_size_slug`
- ❌ Cannot have: `http_port`, `health_check`, `routes`
- ❌ Cannot be: Referenced in `ingress.rules`

**Jobs**:
- ✅ Must have: `name`, `kind` (PRE_DEPLOY, POST_DEPLOY, CRON), source
- ⚠️ For CRON: Must have `schedule` field

#### 3.4 Invalid Environment Variable Scopes

**Valid scopes**:
- `RUN_TIME`: Available at runtime only
- `BUILD_TIME`: Available at build time only (for git: sources)
- `RUN_AND_BUILD_TIME`: Available in both

**For Docker Hub images**: Use `RUN_TIME` or omit scope (defaults to `RUN_AND_BUILD_TIME`)

#### 3.5 Health Check Issues

**For services with `http_port`**:
```yaml
health_check:
  http_path: /health  # Must be a valid path
  initial_delay_seconds: 30  # Give service time to start
  period_seconds: 10
  timeout_seconds: 5
  failure_threshold: 3
  success_threshold: 1  # Optional, defaults to 1
```

**Common mistakes**:
- Health check path doesn't exist (e.g., `/api/health` returns 404)
- `initial_delay_seconds` too short (service not ready)
- Missing health check on HTTP services (causes deployment issues)

#### 3.6 Database Connection Issues

**Dev databases** (production: false):
- ✅ PostgreSQL only
- ✅ Single database limit (1GB)
- ✅ References: `${db.DATABASE_URL}`, `${db.HOSTNAME}`, etc.

**Managed databases** (created separately):
- Must provide connection strings as environment variables
- Cannot use `${db.*}` references (those are for App Platform databases)

#### 3.7 Port Mismatches

**Problem**: `http_port` doesn't match what container exposes
```yaml
services:
  - name: storage
    http_port: 5000  # But container listens on 8080
    envs:
      - key: SERVER_PORT
        value: "8080"  # ❌ Mismatch!
```

**Fix**:
- Option 1: Remove `http_port`, let Docker image expose its own port
- Option 2: Ensure `http_port` matches container's actual listening port

#### 3.8 Missing Secrets

**Problem**: Sensitive data in plain text
```yaml
envs:
  - key: DATABASE_PASSWORD
    value: "hardcoded-password"  # ❌ Not secure!
```

**Fix**: Mark as SECRET
```yaml
envs:
  - key: DATABASE_PASSWORD
    type: SECRET  # ✅ Encrypted at rest
    value: ${DATABASE_PASSWORD}  # Use placeholder
```

### Step 4: Validate Component Relationships

Check that components reference each other correctly:

**Internal service discovery**:
```yaml
# Service A can call Service B via:
- key: API_URL
  value: http://service-b:8080  # ✅ Uses service name

# NOT via public URL:
- key: API_URL
  value: https://myapp.ondigitalocean.app  # ❌ Unnecessary external call
```

**Database references**:
```yaml
# App Platform database (defined in spec):
- key: DATABASE_URL
  value: ${db.DATABASE_URL}  # ✅ Correct

# External database:
- key: DATABASE_URL
  value: ${EXTERNAL_DB_URL}  # ✅ Must be set by user
```

### Step 5: Check Resource Sizing

Ensure instance sizes are appropriate:

**Basic tier** (for development/testing):
- `basic-xxs`: 512MB RAM, 0.5 vCPU - $5/month
- `basic-xs`: 1GB RAM, 1 vCPU - $10/month

**Professional tier** (supports auto-scaling):
- `professional-xs`: 1GB RAM, 1 vCPU - $24/month
- `professional-s`: 2GB RAM, 2 vCPU - $48/month

**Warning signs**:
- All components using basic-xxs (may be underpowered for production)
- Database-heavy apps without sufficient memory
- Auto-scaling configured on non-professional tiers (not supported)

### Step 6: Auto-Fix Common Issues

When you find issues, automatically fix them:

1. **Move ingress-routed components from workers to services**
2. **Remove duplicate source definitions** (prefer `image:` for Docker Hub)
3. **Add missing health checks** for HTTP services
4. **Fix environment variable scopes** for Docker images
5. **Add SECRET type** to obvious secrets (PASSWORD, KEY, TOKEN, SECRET in name)
6. **Remove invalid fields** (e.g., `http_port` from workers)

### Step 7: Generate Report

Create a detailed report:

```markdown
# App Spec Validation Report

## Status: [PASS ✅ | ISSUES FOUND ⚠️ | ERRORS ❌]

### Validation Results
[Output from doctl apps spec validate]

### Issues Found
1. [Issue description]
   - Location: [component name, field path]
   - Impact: [What breaks]
   - Fix: [What was changed]

### Fixes Applied
- [List of automatic fixes made]

### Manual Review Needed
- [Issues that require user decisions]

### Recommendations
- [Performance, security, cost optimizations]

### Next Steps
1. Review the changes in `.do/app.yaml`
2. Test deployment: `doctl apps create --spec .do/app.yaml`
3. [Additional steps if needed]
```

## Execution Steps

1. **Read the current app.yaml file**
2. **Run doctl validation** and capture output
3. **Parse validation errors** (if any)
4. **Check all common issues** (even if validation passed)
5. **Apply automatic fixes** to a new version
6. **Show diff** between old and new versions
7. **Ask for confirmation** before saving changes
8. **Save fixed version** and re-validate
9. **Provide detailed report** with explanations

## Special Considerations

### For Supabase/Backend-as-a-Service Apps

- **Auth service**: Must be HTTP service (not worker) if ingress routes to it
- **Storage service**: Must be HTTP service if ingress routes to it
- **Meta/Admin services**: Can be workers if only accessed internally
- **Database initialization**: Use POST_DEPLOY jobs

### For Microservices

- **Service mesh**: Components can communicate via internal DNS (service-name:port)
- **API Gateway**: If one service routes to others, it should be an HTTP service
- **Background workers**: Should be workers, not services

### For Full-Stack Apps

- **Frontend**: Usually static_site (free tier)
- **Backend API**: HTTP service
- **Database**: App Platform database OR managed database reference
- **File uploads**: Use Spaces (S3-compatible) via environment variables

## Example Fixes

### Example 1: Moving Component from Worker to Service

**Before**:
```yaml
ingress:
  rules:
    - component:
        name: auth
workers:
  - name: auth
```

**After**:
```yaml
ingress:
  rules:
    - component:
        name: auth
services:
  - name: auth
```

### Example 2: Removing Duplicate Source

**Before**:
```yaml
services:
  - name: app
    git:
      repo_clone_url: https://...
    image:
      registry_type: DOCKER_HUB
```

**After**:
```yaml
services:
  - name: app
    image:
      registry_type: DOCKER_HUB
```

### Example 3: Adding Health Check

**Before**:
```yaml
services:
  - name: api
    http_port: 3000
```

**After**:
```yaml
services:
  - name: api
    http_port: 3000
    health_check:
      http_path: /health
      initial_delay_seconds: 30
      period_seconds: 10
      timeout_seconds: 3
      failure_threshold: 3
```

## Important Notes

- **Always backup** the original file before making changes
- **Validate twice**: Before and after fixes
- **Test deploy** in a separate environment if possible
- **Check logs** after deployment for runtime issues
- **Sync fixes** to deploy.template.yaml if it exists

## Start Verification

Now, verify and fix the app.yaml file in this repository. Follow all steps above, be thorough, and provide a detailed report.
