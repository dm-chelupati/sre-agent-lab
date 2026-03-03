# Grubify Application Architecture

## Overview

Grubify is a food ordering web application deployed on **Azure Container Apps**. It serves as the monitored application for the SRE Agent lab — the agent investigates and remediates issues with this app.

---

## Infrastructure

| Component | Azure Service | Details |
|-----------|---------------|---------|
| **Application** | Azure Container Apps | Node.js API, port 8080, external ingress |
| **Container Environment** | Container Apps Environment | Linked to Log Analytics |
| **Logs** | Log Analytics Workspace | Console logs via `ContainerAppConsoleLogs_CL` |
| **Telemetry** | Application Insights | Request metrics, exceptions, dependencies |
| **Identity** | User-Assigned Managed Identity | Reader + Monitoring Reader + Log Analytics Reader |
| **Alerts** | Azure Monitor | Metric alerts for HTTP 5xx, log alerts for errors |

---

## Application Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Home page / app info |
| `/health` | GET | Health check — returns 200 if healthy |
| `/api/menu` | GET | List menu items |
| `/api/orders` | GET | List orders |
| `/api/orders` | POST | Create a new order |
| `/api/cart/{userId}/items` | POST | Add item to user's cart (**memory leak trigger**) |
| `/api/cart/{userId}/items` | GET | Get cart items for a user |
| `/admin/chaos` | POST | **Fault injection** — toggles chaos mode |

---

## Fault Injection Methods

### Method 1: Memory Leak via Cart API (Primary)

The `/api/cart/{userId}/items` endpoint stores cart items **in memory** with no eviction policy. Rapid repeated calls cause:

- Memory working set to grow continuously
- Container to approach its 1Gi memory limit
- Eventually OOM kill → container restart → HTTP 500/503 errors
- Azure Monitor fires memory and restart alerts

**Trigger:** Send rapid POST requests to `/api/cart/demo-user/items`
```bash
while true; do
  curl -X POST "https://<app-url>/api/cart/demo-user/items" \
    -H "Content-Type: application/json" \
    -d '{"foodItemId":1,"quantity":1}'
  sleep 0.5
done
```

### Method 2: Chaos Mode Toggle

When chaos mode is enabled via `POST /admin/chaos`:

- All API endpoints start returning **HTTP 500** errors
- Error logs are written to stdout → picked up by Log Analytics
- The app simulates realistic failure patterns (unhandled exceptions, timeouts)

**Disable chaos mode:** `POST /admin/chaos` again (toggles off)

---

## Source Code

- **GitHub repository:** [github.com/dm-chelupati/grubify](https://github.com/dm-chelupati/grubify)
- **Language:** Node.js
- **Container image:** `ghcr.io/dm-chelupati/grubify:latest`

### Key Files

| File | Purpose |
|------|---------|
| `server.js` | Main application entry point |
| `routes/api.js` | API route handlers (menu, orders) |
| `routes/admin.js` | Admin endpoints including chaos mode |
| `middleware/errorHandler.js` | Error handling middleware |
| `Dockerfile` | Container build definition |

---

## Scaling Configuration

| Setting | Value |
|---------|-------|
| Min replicas | 1 |
| Max replicas | 5 |
| CPU | 0.5 cores |
| Memory | 1 Gi |
| Scale rule | HTTP concurrent requests > 50 |

---

## Monitoring & Alerting

### Log Analytics Queries

**Error logs:**
```kql
ContainerAppConsoleLogs_CL
| where TimeGenerated > ago(1h)
| where Log_s contains "error" or Log_s contains "Error" or Log_s contains "500"
| summarize ErrorCount = count() by bin(TimeGenerated, 5m)
| order by TimeGenerated desc
```

**Container app console output:**
```kql
ContainerAppConsoleLogs_CL
| where TimeGenerated > ago(1h)
| project TimeGenerated, Log_s, ContainerName_s
| order by TimeGenerated desc
| take 50
```

### Alert Rules

| Alert | Trigger | Severity |
|-------|---------|----------|
| HTTP 5xx errors | > 5 requests with 5xx status in 5 min | Sev3 |
| High memory usage | Working set > 800Mi (80% of 1Gi limit) | Sev2 |
| Container restarts | Any restart in 5 min window (OOM) | Sev2 |
| Log error spike | > 10 error-level log entries in 5 min | Sev3 |

These alerts flow automatically to the SRE Agent via the managed resource group configuration.

---

## Known Failure Modes

| Failure | Symptoms | Root Cause |
|---------|----------|------------|
| Chaos mode enabled | HTTP 500 on all endpoints | Intentional fault injection via `/admin/chaos` |
| Memory pressure | Slow responses, OOM restarts | Undersized container (1Gi), memory leak in error path |
| High CPU | Request timeouts | Unthrottled request processing under load |

---

## Troubleshooting Quick Reference

1. **Check health:** `curl https://<app-url>/health`
2. **Check logs:** Query `ContainerAppConsoleLogs_CL` in Log Analytics
3. **Check metrics:** Azure Monitor → Container App → Requests, CPU, Memory
4. **Restart:** `az containerapp revision restart -g <rg> -n <app> --revision <rev>`
5. **Scale out:** `az containerapp update -g <rg> -n <app> --min-replicas 3`
