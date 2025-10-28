# Version Information

This document tracks the versions of Supabase components used in this App Platform deployment.

## Current Deployment

**Last Updated**: October 2024

### Component Versions

| Component | Version | Docker Image | Source |
|-----------|---------|--------------|--------|
| **Studio** | 20241022 | `supabase/studio:20241022-ce94d1b` | [supabase/studio](https://github.com/supabase/studio) |
| **PostgREST** | v12.2.3 | `postgrest/postgrest:v12.2.3` | [PostgREST/postgrest](https://github.com/PostgREST/postgrest) |
| **GoTrue** | v2.174.0 | `supabase/gotrue:v2.174.0` | [supabase/auth](https://github.com/supabase/auth) |
| **Storage API** | v1.11.1 | `supabase/storage-api:v1.11.1` | [supabase/storage](https://github.com/supabase/storage) |
| **Postgres Meta** | v0.84.2 | `supabase/postgres-meta:v0.84.2` | [supabase/postgres-meta](https://github.com/supabase/postgres-meta) |
| **PostgreSQL** | 15 | Managed Database | [DigitalOcean Managed PostgreSQL](https://www.digitalocean.com/products/managed-databases-postgresql) |

## Upstream Project

This template is based on the official Supabase self-hosting setup:
- **Repository**: https://github.com/supabase/supabase
- **Documentation**: https://supabase.com/docs/guides/self-hosting
- **Docker Compose**: https://supabase.com/docs/guides/self-hosting/docker

## Update Policy

### When to Update

We update component versions in this template when:
1. **Security patches** are released for any component
2. **Major features** are added that benefit App Platform users
3. **Stability improvements** are released by upstream Supabase
4. **Breaking changes** require version alignment across components

### How to Update

To update to newer versions:

1. **Check compatibility** between component versions:
   - Visit the [Supabase releases page](https://github.com/supabase/supabase/releases)
   - Review the docker-compose.yml for version compatibility
   - Check for breaking changes in component changelogs

2. **Update image tags** in `.do/app.yaml` and `.do/deploy.template.yaml`:
   ```yaml
   image:
     registry_type: DOCKER_HUB
     registry: supabase
     repository: studio
     tag: "NEW_VERSION_HERE"
   ```

3. **Test thoroughly**:
   - Deploy to a test app first
   - Verify all services start successfully
   - Test authentication, API, and storage functionality
   - Check database migrations complete without errors

4. **Update this VERSION.md** with new versions and date

## Version History

### October 2024 - Initial Release
- Studio: 20241022-ce94d1b
- PostgREST: v12.2.3
- GoTrue: v2.174.0
- Storage API: v1.11.1
- Postgres Meta: v0.84.2
- PostgreSQL: 15

**Notes**: Initial App Platform template with basic deployment mode (Studio, PostgREST, Auth, Storage, Meta). Optimized for development and small production workloads.

## Component Update Channels

### Stable Releases
- **Studio**: Monthly releases, tagged with date (YYYYMMDD-hash)
- **PostgREST**: Semantic versioning (vX.Y.Z), stable releases
- **GoTrue**: Semantic versioning (vX.Y.Z), stable releases
- **Storage API**: Semantic versioning (vX.Y.Z), stable releases
- **Postgres Meta**: Semantic versioning (vX.Y.Z), stable releases

### Beta/RC Releases
We **do not** use beta or release candidate versions in this template to ensure stability.

## Compatibility Notes

### PostgreSQL Extensions
This deployment requires the following PostgreSQL extensions:
- `uuid-ossp` - UUID generation (required)
- `pgcrypto` - Cryptographic functions (required)
- `pgjwt` - JWT token handling (required)
- `pg_net` - HTTP client (optional, for Edge Functions)
- `vector` - Vector operations (optional, for AI/ML features)

DigitalOcean Managed PostgreSQL includes all required extensions by default.

### Component Dependencies
- **Studio** requires **Postgres Meta** for database management UI
- **Storage API** requires **PostgREST** for permission checks
- All components require **PostgreSQL 15+** with specific extensions
- All components must share the same **JWT_SECRET** for authentication

## Known Issues

### Current Version Known Issues
- None reported for the current stable versions

### Upstream Known Issues
Check the Supabase GitHub issues for current known problems:
- [Supabase Issues](https://github.com/supabase/supabase/issues)
- [PostgREST Issues](https://github.com/PostgREST/postgrest/issues)
- [GoTrue Issues](https://github.com/supabase/auth/issues)
- [Storage API Issues](https://github.com/supabase/storage/issues)

## Support

For version-specific questions or issues:
1. Check the [Supabase documentation](https://supabase.com/docs)
2. Search [GitHub discussions](https://github.com/orgs/supabase/discussions)
3. Join the [Supabase Discord](https://discord.supabase.com)
4. For App Platform specific issues, see the [main README](./README.md)

---

**Maintenance Schedule**: This VERSION.md file is updated with each component version change. Check git history for detailed update timeline.
