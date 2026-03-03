#!/bin/bash
# =============================================================================
# Create Sample GitHub Issues for Triage Lab
#
# Creates 10 sample issues spanning all triage runbook categories:
#   - 3 Documentation questions
#   - 5 Bug reports (1 onboarding, 1 AI, 1 non-AI, 1 incomplete, 1 integration)
#   - 2 Feature requests
#
# Usage:
#   export GITHUB_PAT=<your-github-pat>
#   ./scripts/create-sample-issues.sh <owner/repo>
#
# Example:
#   ./scripts/create-sample-issues.sh myuser/my-support-tickets
# =============================================================================
set -e

REPO="${1:?Usage: $0 <owner/repo>}"

if [ -z "$GITHUB_PAT" ]; then
  echo "Error: GITHUB_PAT environment variable is not set."
  echo "Set it with: export GITHUB_PAT=<your-token>"
  exit 1
fi

API="https://api.github.com/repos/${REPO}/issues"
AUTH="Authorization: token ${GITHUB_PAT}"
CONTENT="Content-Type: application/json"

echo ""
echo "============================================="
echo "  Creating Sample Issues in ${REPO}"
echo "============================================="
echo ""

# --- DOCUMENTATION ISSUES (3) ---

echo "1/10: Documentation — How to connect Azure DevOps..."
curl -s -X POST "$API" \
  -H "$AUTH" -H "$CONTENT" \
  -d '{
    "title": "How do I connect Azure DevOps to my SRE Agent?",
    "body": "Hi team,\n\nI just created my first SRE Agent in East US 2. I want to connect our ADO organization (contoso-dev) so the agent can search our repos during incidents.\n\nI went to Builder > Connectors but I only see GitHub and Kusto options. Where is the ADO connector?\n\nThanks!"
  }' > /dev/null
echo "  ✓ Created"

echo "2/10: Documentation — KQL query reference..."
curl -s -X POST "$API" \
  -H "$AUTH" -H "$CONTENT" \
  -d '{
    "title": "Where can I find documentation on KQL queries the agent uses?",
    "body": "Our team wants to understand what KQL queries the SRE Agent runs during incident investigations. Is there a reference doc that shows the default queries?\n\nWe want to customize them for our Cosmos DB telemetry tables."
  }' > /dev/null
echo "  ✓ Created"

echo "3/10: Documentation — Response plan severity filters..."
curl -s -X POST "$API" \
  -H "$AUTH" -H "$CONTENT" \
  -d '{
    "title": "How do response plan severity filters work with Azure Monitor?",
    "body": "I set up a response plan with Sev2 filter but my Azure Monitor alerts are coming in as Sev3. Does the agent map Azure Monitor severity levels differently?\n\nAlso, can I have multiple response plans for different severity levels?"
  }' > /dev/null
echo "  ✓ Created"

# --- BUG ISSUES (5) ---

echo "4/10: Bug — Onboarding/Access failure (complete info)..."
curl -s -X POST "$API" \
  -H "$AUTH" -H "$CONTENT" \
  -d '{
    "title": "Agent deployment failed with 403 Forbidden error",
    "body": "## Problem\nTrying to create an SRE Agent in East US 2 but getting a 403 error during deployment.\n\n## Details\n- **Region:** East US 2\n- **Subscription ID:** a1b2c3d4-e5f6-7890-abcd-ef1234567890\n- **Resource Group:** rg-sre-prod\n- **Error message:** `AuthorizationFailed: The client does not have authorization to perform action Microsoft.App/agents/write`\n\n## Steps to Reproduce\n1. Go to sre.azure.com\n2. Click Create Agent\n3. Fill in subscription and resource group\n4. Click Create\n5. Error appears after ~30 seconds\n\nI have Contributor role on the subscription. Do I need Owner?"
  }' > /dev/null
echo "  ✓ Created"

echo "5/10: Bug — AI issue with wrong RCA (complete info)..."
curl -s -X POST "$API" \
  -H "$AUTH" -H "$CONTENT" \
  -d '{
    "title": "Agent gives wrong root cause analysis - blames wrong service",
    "body": "## Problem\nThe agent investigated an incident on our payment-service but blamed the auth-service instead. The auth-service logs show no errors during the incident timeframe.\n\n## Details\n- **Agent name:** prod-sre-agent\n- **Thread ID:** thread_abc123xyz\n- **Region:** East US 2\n\n## Steps to Reproduce\n1. Created incident for payment-service HTTP 500 errors\n2. Agent started investigation\n3. Agent concluded auth-service certificate expiry was root cause\n4. But auth-service had 0 errors and certs are valid until 2027\n\n## Expected\nAgent should identify the actual root cause in payment-service (database connection pool exhaustion)\n\n## Actual\nAgent incorrectly attributed the issue to auth-service"
  }' > /dev/null
echo "  ✓ Created"

echo "6/10: Bug — Non-AI UI issue (complete info)..."
curl -s -X POST "$API" \
  -H "$AUTH" -H "$CONTENT" \
  -d '{
    "title": "Incident list page shows broken layout on Safari browser",
    "body": "The incidents page has overlapping text and broken table layout when using Safari 18.2 on macOS.\n\n- **Agent name:** team-alpha-agent\n- **Region:** Sweden Central\n\n## Steps to Reproduce\n1. Open sre.azure.com in Safari 18.2\n2. Navigate to Incidents\n3. Table columns overlap and severity badges are cut off\n\n## Expected\nClean table layout like in Chrome/Edge\n\n## Actual\nColumns overlap, badges truncated, horizontal scroll bar missing"
  }' > /dev/null
echo "  ✓ Created"

echo "7/10: Bug — Incomplete info (needs more info)..."
curl -s -X POST "$API" \
  -H "$AUTH" -H "$CONTENT" \
  -d '{
    "title": "Agent not responding to incidents anymore",
    "body": "Our agent stopped responding to PagerDuty incidents since yesterday. It was working fine before. Please help urgently."
  }' > /dev/null
echo "  ✓ Created"

echo "8/10: Bug — Integration issue (complete info)..."
curl -s -X POST "$API" \
  -H "$AUTH" -H "$CONTENT" \
  -d '{
    "title": "GitHub MCP connector disconnects every 4 hours",
    "body": "## Problem\nOur GitHub MCP connector keeps disconnecting. It shows Connected status, then after ~4 hours goes to Disconnected. We have to manually reconnect it each time.\n\n## Details\n- **Agent name:** devops-sre-agent\n- **Region:** East US 2\n- **Connector name:** github-mcp-prod\n\n## Steps to Reproduce\n1. Add GitHub MCP connector with PAT (repo + read:org scope)\n2. Connector shows Connected\n3. Wait 4 hours\n4. Connector shows Disconnected\n5. Click Reconnect -> works again for 4 hours\n\n## Expected\nConnector stays connected permanently\n\n## Actual\nDisconnects every ~4 hours. Suspect PAT token refresh issue?"
  }' > /dev/null
echo "  ✓ Created"

# --- FEATURE REQUESTS (2) ---

echo "9/10: Feature request — Slack integration..."
curl -s -X POST "$API" \
  -H "$AUTH" -H "$CONTENT" \
  -d '{
    "title": "Please add Slack connector for incident notifications",
    "body": "Would be nice to have a Slack connector so the agent can post investigation summaries to our #incidents Slack channel.\n\nRight now we use the Outlook email connector but our team prefers Slack for real-time updates.\n\nIdeal workflow:\n1. Incident fires\n2. Agent investigates\n3. Agent posts summary + root cause to Slack channel\n4. Team can reply in Slack thread to ask follow-up questions"
  }' > /dev/null
echo "  ✓ Created"

echo "10/10: Feature request — Custom KQL templates..."
curl -s -X POST "$API" \
  -H "$AUTH" -H "$CONTENT" \
  -d '{
    "title": "Feature: Let us define custom KQL query templates for the agent",
    "body": "We have very specific KQL queries for our telemetry tables that the agent does not know about.\n\nPlease add a way to define custom KQL query templates (like a library of queries) that the agent can use during investigations.\n\nExample:\n```kql\nCustomTelemetry_CL\n| where ServiceName == \"payment-api\"\n| where Level == \"Error\"\n| summarize count() by bin(TimeGenerated, 5m), ErrorCode\n```\n\nThis way the agent searches OUR tables instead of guessing generic table names."
  }' > /dev/null
echo "  ✓ Created"

echo ""
echo "============================================="
echo "  ✅ Created 10 sample issues in ${REPO}"
echo "============================================="
echo ""
echo "  Breakdown:"
echo "    📖 3 Documentation questions"
echo "    🐛 5 Bug reports (1 onboarding, 1 AI, 1 non-AI, 1 incomplete, 1 integration)"
echo "    💡 2 Feature requests"
echo ""
echo "  Now ask your SRE Agent to triage these issues!"
echo "  Example prompt:"
echo "    'List all open issues in ${REPO} and triage each one'"
echo ""
