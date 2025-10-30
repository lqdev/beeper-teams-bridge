# Troubleshooting Guide

Common issues and solutions for beeper-teams-bridge.

---

## Table of Contents

1. [Bridge Won't Start](#bridge-wont-start)
2. [Login Issues](#login-issues)
3. [Messages Not Bridging](#messages-not-bridging)
4. [High Latency](#high-latency)
5. [Database Issues](#database-issues)
6. [Network Problems](#network-problems)
7. [Webhook Issues](#webhook-issues)
8. [Performance Issues](#performance-issues)
9. [Getting Help](#getting-help)

---

## Bridge Won't Start

### Symptoms
- Bridge process exits immediately
- Error messages in logs
- Health check fails

### Check Logs

**Docker:**
```bash
docker logs beeper-teams-bridge
```

**Systemd:**
```bash
sudo journalctl -u beeper-teams-bridge -n 50
```

**Manual:**
```bash
./beeper-teams-bridge -c config.yaml
```

### Common Causes

#### 1. Configuration Error

**Error:** `failed to parse config: yaml: ...`

**Solution:**
```bash
# Check YAML syntax
yamllint config.yaml

# Or test config
./beeper-teams-bridge -c config.yaml -t
```

**Common mistakes:**
- Incorrect indentation (use spaces, not tabs)
- Missing quotes around special characters
- Invalid values for enum fields

#### 2. Database Connection Failed

**Error:** `failed to connect to database: connection refused`

**Solution:**
```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Test connection manually
psql -h localhost -U mautrix -d mautrix_teams

# Verify connection string in config.yaml
database:
  uri: postgres://user:password@localhost/mautrix_teams?sslmode=disable
```

**Check:**
- PostgreSQL service is running
- Database exists
- User has correct permissions
- Password is correct
- Host/port are correct

#### 3. Port Already in Use

**Error:** `bind: address already in use`

**Solution:**
```bash
# Find process using port 29319
sudo lsof -i :29319
sudo netstat -tlnp | grep 29319

# Kill conflicting process or change port in config
appservice:
  port: 29320  # Use different port
```

#### 4. Homeserver Unreachable

**Error:** `failed to connect to homeserver: connection refused`

**Solution:**
```bash
# Test homeserver connectivity
curl http://localhost:8008/_matrix/client/versions

# Check homeserver address in config
homeserver:
  address: http://localhost:8008  # Correct address?
```

**Verify:**
- Homeserver is running
- Address/port are correct
- Firewall allows connection
- Network connectivity

#### 5. Missing Registration File

**Error:** `registration file not found` or similar

**Solution:**
```bash
# Generate registration
./beeper-teams-bridge -g

# Copy to homeserver config directory
sudo cp registration.yaml /etc/matrix-synapse/

# Add to homeserver.yaml
app_service_config_files:
  - /etc/matrix-synapse/registration.yaml

# Restart homeserver
sudo systemctl restart matrix-synapse
```

---

## Login Issues

### Symptoms
- OAuth link doesn't work
- "Login failed" message
- Redirect doesn't work

### Solutions

#### 1. Azure AD Configuration Issues

**Error:** `AADSTS500113: No reply address is registered for the application`

**Solution:**
- Go to Azure Portal → App Registration
- Navigate to **Authentication**
- Verify redirect URI matches exactly:
  ```
  Config:   http://localhost:29319/oauth/callback
  Azure AD: http://localhost:29319/oauth/callback
  ```
- Check protocol (http vs https)
- Check port number
- No trailing slashes

**Error:** `AADSTS65001: The user or administrator has not consented`

**Solution:**
- In Azure AD app → API permissions
- Click **Grant admin consent**
- If not admin, ask your IT admin to consent

#### 2. Permissions Not Granted

**Error:** `Insufficient permissions`

**Solution:**
Verify these delegated permissions are added and consented:
- `Chat.ReadWrite`
- `ChannelMessage.Read.All`
- `ChannelMessage.Send`
- `Team.ReadBasic.All`
- `User.Read`

#### 3. Redirect URI Not Accessible

**Error:** OAuth completes but bridge doesn't register login

**Solution:**
```bash
# Test redirect endpoint
curl http://localhost:29319/oauth/callback

# Should return: Method Not Allowed (expected)

# Check bridge logs during login attempt
```

**If using reverse proxy:**
- Ensure proxy forwards OAuth callback correctly
- Check proxy logs

#### 4. Token Validation Failed

**Error:** `invalid token` or `token expired`

**Solution:**
```bash
# Clear cached tokens
rm -rf /data/tokens/*  # or your token cache location

# Try login again
```

---

## Messages Not Bridging

### Symptoms
- Messages sent but not appearing on other side
- One-way bridging only
- Delayed messages

### Diagnostic Steps

#### 1. Check Bridge Status

In bridge bot chat:
```
status
```

Expected output:
```
✅ Logged in as John Doe
📊 Active portals: X
🔔 Webhook subscriptions: X active
```

#### 2. Check Logs

```bash
# Look for errors
docker logs -f beeper-teams-bridge | grep ERROR

# Or for specific portal
docker logs -f beeper-teams-bridge | grep "portal_id"
```

#### 3. Verify Portal Exists

```
list-teams
list-chats
```

Portal should show as "active" or "created"

### Common Causes

#### 1. Webhook Subscriptions Not Active

**Check webhook status in logs:**
```
INFO: Created webhook subscription for chat xyz
WARN: Webhook subscription expired for chat xyz
ERROR: Failed to renew webhook subscription
```

**Solution:**
```bash
# In bridge bot chat
sync

# This recreates subscriptions
```

**Check webhook public URL:**
```yaml
network:
  webhook_public_url: "https://your-domain.com"
```

**Test accessibility:**
```bash
# From external network
curl https://your-domain.com/webhook
```

#### 2. Rate Limiting

**Error:** `429 Too Many Requests`

**Solution:**
```yaml
# Adjust rate limits in config
network:
  max_requests_per_second: 2  # Reduce from 4
  burst_allowance: 5           # Reduce from 10
```

**Monitor rate limit headers in logs:**
```
DEBUG: Rate limit: 120 requests remaining, resets in 60s
```

#### 3. Portal Not Synced

**Solution:**
```
# Force sync
sync

# Or leave and rejoin portal room
```

#### 4. Network Connectivity Issues

**Test Graph API connectivity:**
```bash
curl https://graph.microsoft.com/v1.0/$metadata
```

**Check DNS resolution:**
```bash
nslookup graph.microsoft.com
```

**Check firewall:**
```bash
# Ensure outbound HTTPS allowed
telnet graph.microsoft.com 443
```

---

## High Latency

### Symptoms
- Messages take >5 seconds to bridge
- Slow command responses
- Timeouts

### Solutions

#### 1. Database Performance

**Check slow queries:**
```sql
-- In PostgreSQL
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
ORDER BY mean_time DESC
LIMIT 10;
```

**Solution:**
```bash
# Add indexes
# Run database migrations
./beeper-teams-bridge -m

# Vacuum database
psql -U mautrix -d mautrix_teams -c "VACUUM ANALYZE;"
```

**Monitor connections:**
```sql
SELECT count(*) FROM pg_stat_activity WHERE datname = 'mautrix_teams';
```

#### 2. Network Issues

**Test latency to Graph API:**
```bash
time curl -o /dev/null https://graph.microsoft.com/v1.0/$metadata
```

**Should be <500ms**

**Check homeserver latency:**
```bash
time curl -o /dev/null http://localhost:8008/_matrix/client/versions
```

#### 3. Resource Constraints

**Check CPU/Memory:**
```bash
# Docker
docker stats beeper-teams-bridge

# System
top -p $(pgrep beeper-teams-bridge)
```

**Solution:**
```yaml
# Increase resources in docker-compose.yml
services:
  beeper-teams-bridge:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 2G
```

#### 4. Too Many Portals

**Check portal count:**
```
stats
```

**Solution:**
- Leave unused portals
- Increase sync interval:
```yaml
network:
  sync_interval: 7200  # 2 hours instead of 1
```

---

## Database Issues

### Migration Failed

**Error:** `migration xxx failed`

**Solution:**
```bash
# Check current migration version
psql -U mautrix -d mautrix_teams -c "SELECT version FROM migration_version;"

# Manual migration if needed
psql -U mautrix -d mautrix_teams < migrations/xxx_migration.sql
```

### Database Corruption

**Symptoms:**
- Random errors
- Inconsistent state
- Bridge crashes

**Solution:**
```bash
# Backup first!
pg_dump -U mautrix mautrix_teams > backup.sql

# Check integrity
psql -U mautrix -d mautrix_teams -c "VACUUM FULL ANALYZE;"

# Restore from backup if needed
psql -U mautrix -d mautrix_teams < backup.sql
```

### Out of Disk Space

**Error:** `ERROR: could not extend file ... No space left on device`

**Solution:**
```bash
# Check disk usage
df -h

# Clean old logs
find /var/log -name "*.log" -mtime +30 -delete

# Clean PostgreSQL
psql -U mautrix -d mautrix_teams -c "VACUUM FULL;"
```

---

## Network Problems

### Proxy Configuration

**If bridge is behind proxy:**

```yaml
# config.yaml
# Add proxy environment variables
```

```bash
# Or export
export HTTP_PROXY=http://proxy:8080
export HTTPS_PROXY=http://proxy:8080
export NO_PROXY=localhost,127.0.0.1
```

### Firewall Rules

**Required outbound:**
- Port 443 to graph.microsoft.com
- Port 443 to login.microsoftonline.com
- Port 8008 to homeserver (or configured port)
- Port 5432 to PostgreSQL (or configured port)

**Required inbound:**
- Port 29319 from homeserver (or configured port)
- Port 29319 from Microsoft (for webhooks)

---

## Webhook Issues

### Webhooks Not Received

**Check webhook URL is accessible:**
```bash
# From external network
curl https://your-domain.com/webhook
```

**Should return:** `Method Not Allowed` or `Webhook endpoint`

**Check webhook subscriptions:**
```bash
# In bridge logs
grep "webhook" bridge.log
```

**Look for:**
```
INFO: Created subscription: sub_id=xxx, expires=2025-10-31
INFO: Received webhook: chat_id=xxx, event_type=message
```

### Webhook Validation Failed

**Error:** `webhook validation failed: invalid signature`

**Solution:**
```yaml
# Regenerate webhook secret
network:
  webhook_secret: "new-random-secret-here"
```

```bash
# Restart bridge
sudo systemctl restart beeper-teams-bridge
```

### SSL/TLS Issues

**Error:** `SSL certificate problem`

**For development with ngrok:**
```yaml
network:
  webhook_public_url: "https://abc123.ngrok.io"  # Use ngrok HTTPS URL
```

**For production:**
- Use valid SSL certificate
- Ensure certificate chain is complete
- Test with: `openssl s_client -connect your-domain.com:443`

---

## Performance Issues

### Memory Leaks

**Symptoms:**
- Memory usage grows over time
- OOM errors
- Bridge becomes slow

**Monitor:**
```bash
# Memory usage over time
watch -n 5 'docker stats beeper-teams-bridge --no-stream'
```

**Solution:**
- Restart bridge regularly (use systemd restart timer)
- Report to GitHub with heap dump

### CPU Usage High

**Check what's using CPU:**
```bash
# Get profile
curl http://localhost:8001/debug/pprof/profile?seconds=30 > cpu.prof

# Analyze with Go tools
go tool pprof cpu.prof
```

**Common causes:**
- Too many webhook events
- Inefficient database queries
- Rate limiting causing retries

---

## Getting Help

### Before Asking for Help

1. **Check logs** for specific errors
2. **Try common solutions** in this guide
3. **Collect information:**
   ```
   version
   status
   ```
4. **Reproduce the issue** to confirm it's persistent

### Where to Get Help

1. **Matrix Room:** [#teams:maunium.net](https://matrix.to/#/#teams:maunium.net)
   - Community support
   - Quick responses
   - Share experiences

2. **GitHub Issues:** [github.com/yourorg/beeper-teams-bridge/issues](https://github.com/yourorg/beeper-teams-bridge/issues)
   - Bug reports
   - Feature requests
   - Track progress

### Information to Provide

When asking for help, include:

1. **Bridge version:**
   ```
   version
   ```

2. **Status output:**
   ```
   status
   ```

3. **Relevant logs:**
   ```bash
   docker logs beeper-teams-bridge --tail 100
   ```

4. **Configuration** (redact secrets):
   - Homeserver type and version
   - Database type
   - Deployment method (Docker/systemd/manual)

5. **Description:**
   - What you tried to do
   - What actually happened
   - When it started happening
   - Any recent changes

### Debug Logging

Enable debug logging for more details:

```yaml
# config.yaml
logging:
  min_level: debug
```

```bash
# Restart bridge
sudo systemctl restart beeper-teams-bridge

# Watch logs
journalctl -u beeper-teams-bridge -f
```

**Warning:** Debug logs are verbose and may contain sensitive data. Don't share publicly without redacting.

---

## Quick Reference

### Restart Bridge

```bash
# Docker
docker restart beeper-teams-bridge

# Systemd
sudo systemctl restart beeper-teams-bridge

# Manual
killall beeper-teams-bridge && ./beeper-teams-bridge
```

### Clear Cache

```bash
# Stop bridge
docker stop beeper-teams-bridge

# Clear token cache (logs you out)
rm -rf /data/tokens/*

# Restart
docker start beeper-teams-bridge
```

### Reset Portal

```bash
# In Matrix: Leave portal room
# In bridge bot chat:
sync

# Portal will be recreated on next message
```

### Database Backup

```bash
pg_dump -U mautrix mautrix_teams > backup_$(date +%Y%m%d).sql
```

### Check Health

```bash
# Bridge health
curl http://localhost:29319/health

# Homeserver health
curl http://localhost:8008/_matrix/client/versions

# Database health
psql -U mautrix -d mautrix_teams -c "SELECT 1;"
```

---

**Still having issues?** Join [#teams:maunium.net](https://matrix.to/#/#teams:maunium.net) for help!
