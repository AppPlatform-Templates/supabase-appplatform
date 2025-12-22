# Production Deployment Guide

This guide covers upgrading from the basic development deployment to a production-ready configuration.

## Production Configuration Overview

The production configuration ([.do/examples/production.yaml](../.do/examples/production.yaml)) includes:
- Auto-scaling (2-10 instances per service)
- Managed PostgreSQL (production tier with standby)
- Professional instance sizes for better performance
- Health checks and monitoring
- Rate limiting configured

**Estimated Cost**: $200-600/month depending on scale (vs. $37/month for dev)

## Upgrade Steps

When your app is ready for production:

### 1. Upgrade Database

```bash
# Option A: In App Platform UI
# Database → Settings → Upgrade to Production

# Option B: Create new managed database via CLI
doctl databases create supabase-prod \
  --engine pg \
  --version 15 \
  --size db-s-2vcpu-4gb \
  --num-nodes 2 \
  --region nyc3
```

**Database Sizing Guide**:
- Small production (< 100 concurrent users): `db-s-2vcpu-4gb`, 1 node, $120/month
- Medium production (100-1000 users): `db-s-2vcpu-4gb`, 2 nodes (with standby), $240/month
- Large production (1000+ users): `db-s-4vcpu-8gb`, 2 nodes, $480/month

### 2. Enable Auto-scaling

Update your app spec with auto-scaling configuration:

```yaml
services:
  - name: rest
    autoscaling:
      min_instance_count: 2
      max_instance_count: 10
      metrics:
        cpu:
          percent: 70
```

See [.do/examples/production.yaml](../.do/examples/production.yaml) for complete configuration.

### 3. Configure Custom Domain

```bash
# Via UI: App Settings → Domains → Add Domain

# Or via CLI:
doctl apps update $APP_ID --spec production-spec.yaml
```

### 4. Enable Monitoring

**Set up Log Forwarding** (choose one):

```yaml
log_destinations:
  - name: datadog
    datadog:
      api_key: ${DATADOG_API_KEY}
      endpoint: https://http-intake.logs.datadoghq.com
```

Or use Logtail:

```yaml
log_destinations:
  - name: logtail
    logtail:
      token: ${LOGTAIL_TOKEN}
```

### 5. Set up Backups

Managed PostgreSQL includes automatic backups:

```bash
# Configure backup schedule via UI:
# Database → Settings → Configure Backup Schedule

# Or check current backup config:
doctl databases backups list <database-id>
```

## Security Checklist

Before going live:

- [ ] Rotate all JWT keys
- [ ] Enable database connection pooling
- [ ] Set up database firewall (restrict to App Platform IPs)
- [ ] Configure custom domain with SSL
- [ ] Enable log forwarding
- [ ] Set up monitoring alerts
- [ ] Test disaster recovery procedures
- [ ] Implement rate limiting (already configured in GoTrue)
- [ ] Review and test all RLS policies
- [ ] Never expose SERVICE_ROLE_KEY to clients
- [ ] Use strong SMTP credentials and enable 2FA

## Connection Pool Calculation

For production auto-scaling:

```
PostgREST: 10 connections × max 10 instances = 100 connections
GoTrue: 5 connections × max 8 instances = 40 connections
Storage: 5 connections × max 8 instances = 40 connections
Meta: 2 connections × 2 instances = 4 connections
Buffer: 10 connections
-----------------------------------------------------------
Total: ~194 connections needed at max scale
```

**Recommended**: `db-s-4vcpu-8gb` (220 connections) for full auto-scaling capacity.

## Performance Optimization

### Instance Sizing

Development (basic-xxs):
- 512MB RAM, 1 vCPU
- Good for testing and light workloads
- $5/instance/month

Production (professional-xs):
- 1GB RAM, 1 vCPU
- Better performance under load
- $12/instance/month

### Caching Strategies

1. **Enable CDN** for static assets via custom domain
2. **Configure HTTP caching headers** in PostgREST
3. **Use database connection pooling** (PgBouncer if needed)

## Monitoring

### Key Metrics to Watch

- CPU usage across all services
- Memory usage (watch for OOM errors)
- Database connection pool utilization
- API response times
- Error rates (4xx, 5xx)
- Storage API upload/download rates

### Alerts to Configure

- Service health check failures
- Database CPU > 80%
- Instance count approaching max autoscale limit
- Disk usage > 80%
- Unusual API traffic patterns

## Disaster Recovery

### Backup Strategy

1. **Database**: Automatic daily backups (managed PostgreSQL)
2. **Application State**: Store in database, not filesystem
3. **Spaces**: Enable versioning for object storage

### Recovery Procedures

```bash
# 1. Restore database from backup
doctl databases backups restore <database-id> <backup-id>

# 2. Redeploy application if needed
doctl apps create-deployment $APP_ID

# 3. Verify all services are healthy
doctl apps get $APP_ID
```

## Scaling Guidelines

### When to Scale Up

- CPU consistently > 70% for 10+ minutes
- Response times increasing
- Health check failures
- Database connection pool exhausted

### When to Scale Out

- Add more instances when:
  - Request rate increasing
  - Need better availability
  - Want zero-downtime deployments

### When to Optimize

Before adding resources, check for:
- N+1 query problems
- Missing database indexes
- Inefficient RLS policies
- Large file uploads blocking workers

## Cost Optimization

### Development vs. Production Costs

| Component | Development | Production | Notes |
|-----------|-------------|------------|-------|
| Services (5) | $25/month | $60-120/month | Based on instance count |
| Database | $7/month (dev) | $120-480/month | Managed PostgreSQL |
| Spaces | $5/month | $5-20/month | Based on storage usage |
| **Total** | **$37/month** | **$185-620/month** | |

### Tips to Reduce Costs

1. Start with smaller managed database, upgrade as needed
2. Use conservative autoscaling limits initially
3. Enable caching to reduce database load
4. Monitor and optimize expensive queries
5. Use Spaces lifecycle policies to archive old files

## Additional Resources

- [DigitalOcean App Platform Pricing](https://www.digitalocean.com/pricing/app-platform)
- [Managed Database Pricing](https://www.digitalocean.com/pricing/managed-databases)
- [Spaces Pricing](https://www.digitalocean.com/pricing/spaces)
- [Supabase Self-Hosting Guide](https://supabase.com/docs/guides/self-hosting)
