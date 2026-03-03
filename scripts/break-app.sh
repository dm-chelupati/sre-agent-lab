#!/bin/bash
# =============================================================================
# Break App Script — Triggers HTTP 500 errors on Grubify
#
# This script:
#   1. Enables chaos mode on the Grubify app
#   2. Sends a burst of HTTP requests that return 500 errors
#   3. Azure Monitor detects the error spike and fires an alert
#   4. The SRE Agent picks up the alert and begins investigation
# =============================================================================
set -e

# Get Container App URL from azd environment or argument
APP_URL="${1:-}"
if [ -z "$APP_URL" ]; then
  APP_URL=$(azd env get-values 2>/dev/null | grep "^CONTAINER_APP_URL=" | cut -d'=' -f2 | tr -d '"')
fi

if [ -z "$APP_URL" ]; then
  echo "Error: Could not determine Grubify URL."
  echo "Usage: ./scripts/break-app.sh [https://your-app-url]"
  echo "   Or: Run from the lab directory after 'azd up'"
  exit 1
fi

echo ""
echo "============================================="
echo "  🔥 Breaking the Grubify App"
echo "============================================="
echo ""
echo "  Target: ${APP_URL}"
echo ""

# Step 1: Check app is healthy first
echo "Step 1: Checking app health..."
HEALTH_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${APP_URL}/health" 2>/dev/null || echo "000")
if [ "$HEALTH_STATUS" = "200" ]; then
  echo "  ✓ App is healthy (HTTP ${HEALTH_STATUS})"
else
  echo "  ⚠ App returned HTTP ${HEALTH_STATUS} — proceeding anyway"
fi
echo ""

# Step 2: Enable chaos mode
echo "Step 2: Enabling chaos mode..."
CHAOS_RESPONSE=$(curl -s -X POST "${APP_URL}/admin/chaos" -H "Content-Type: application/json" 2>/dev/null || echo "failed")
echo "  Response: ${CHAOS_RESPONSE}"
echo "  ✓ Chaos mode enabled"
echo ""

# Step 3: Send burst of requests to generate 500 errors
echo "Step 3: Sending 50 requests to generate HTTP 500 errors..."
ERROR_COUNT=0
SUCCESS_COUNT=0
for i in $(seq 1 50); do
  STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${APP_URL}/api/menu" 2>/dev/null || echo "000")
  if [ "$STATUS" = "500" ] || [ "$STATUS" = "503" ]; then
    ERROR_COUNT=$((ERROR_COUNT + 1))
  else
    SUCCESS_COUNT=$((SUCCESS_COUNT + 1))
  fi
  # Print progress every 10 requests
  if [ $((i % 10)) -eq 0 ]; then
    echo "  Sent ${i}/50 requests (${ERROR_COUNT} errors so far)"
  fi
  sleep 0.2
done

echo ""
echo "  Results: ${ERROR_COUNT} errors, ${SUCCESS_COUNT} successes out of 50 requests"
echo ""

# Step 4: Verify app is in bad state
echo "Step 4: Verifying app is returning errors..."
FINAL_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${APP_URL}/api/menu" 2>/dev/null || echo "000")
echo "  Current status: HTTP ${FINAL_STATUS}"
echo ""

echo "============================================="
echo "  ✅ App is now in a bad state!"
echo "============================================="
echo ""
echo "  What happens next:"
echo "    1. Azure Monitor detects the HTTP 5xx spike (~3-5 minutes)"
echo "    2. An alert fires and flows to your SRE Agent"
echo "    3. The agent starts investigating automatically"
echo "    4. Open https://sre.azure.com → Incidents to watch"
echo ""
echo "  ⏱  Wait 5-8 minutes, then check the SRE Agent portal."
echo ""
echo "  To restore the app later:"
echo "    curl -X POST ${APP_URL}/admin/chaos"
echo ""
