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

