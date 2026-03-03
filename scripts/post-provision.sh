#!/bin/bash
# =============================================================================
# post-provision.sh — Runs automatically after azd provision
#
# Configures the SRE Agent using REST APIs (no srectl dependency):
#   - Uploads knowledge base files via dataplane API
#   - Creates incident handler subagent via ARM API
#   - Creates incident response plan via dataplane API
#   - (Optional) Configures GitHub MCP + additional subagents
# =============================================================================
set -e

echo ""
echo "============================================="
echo "  SRE Agent Lab — Post-Provision Setup"
echo "============================================="
echo ""

# ── Read azd outputs ─────────────────────────────────────────────────────────
AGENT_ENDPOINT=$(azd env get-value SRE_AGENT_ENDPOINT 2>/dev/null || echo "")
AGENT_NAME=$(azd env get-value SRE_AGENT_NAME 2>/dev/null || echo "")
RESOURCE_GROUP=$(azd env get-value AZURE_RESOURCE_GROUP 2>/dev/null || echo "")
CONTAINER_APP_URL=$(azd env get-value CONTAINER_APP_URL 2>/dev/null || echo "")
SUBSCRIPTION_ID=$(az account show --query id -o tsv 2>/dev/null || echo "")
GITHUB_PAT_VALUE=$(azd env get-value GITHUB_PAT 2>/dev/null || echo "")

if [ -z "$AGENT_ENDPOINT" ] || [ -z "$AGENT_NAME" ]; then
  echo "❌ ERROR: Could not read agent details from azd environment."
  echo "   Make sure Bicep deployment completed successfully."
  exit 1
fi

echo "📡 Agent endpoint: ${AGENT_ENDPOINT}"
echo "🤖 Agent name:     ${AGENT_NAME}"
echo "📦 Resource group:  ${RESOURCE_GROUP}"
echo "🔑 Subscription:   ${SUBSCRIPTION_ID}"
echo ""

# ── Helper: Get bearer token for SRE Agent dataplane ─────────────────────────
get_token() {
  az account get-access-token --resource https://azuresre.dev/.default --query accessToken -o tsv 2>/dev/null
}

# ARM resource ID for the agent
AGENT_RESOURCE_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.App/agents/${AGENT_NAME}"
API_VERSION="2025-05-01-preview"

# ── Step 1: Upload knowledge base files ──────────────────────────────────────
echo "📚 Step 1/4: Uploading knowledge base files..."
TOKEN=$(get_token)

curl -s -X POST "${AGENT_ENDPOINT}/api/v1/AgentMemory/upload" \
  -H "Authorization: Bearer ${TOKEN}" \
  -F "triggerIndexing=true" \
  -F "files=@./knowledge-base/http-500-errors.md;type=text/plain" \
  -F "files=@./knowledge-base/grubify-architecture.md;type=text/plain" \
  > /dev/null 2>&1

echo "   ✅ Uploaded: http-500-errors.md"
echo "   ✅ Uploaded: grubify-architecture.md"
echo ""

# ── Step 2: Create incident-handler subagent ─────────────────────────────────
echo "🤖 Step 2/4: Creating incident-handler subagent..."

# Choose the right config based on GitHub availability
if [ -n "$GITHUB_PAT_VALUE" ]; then
  echo "   GitHub PAT detected — using full config"
  SUBAGENT_YAML="sre-config/agents/incident-handler-full.yaml"
else
  echo "   No GitHub PAT — using core config (log analysis only)"
  SUBAGENT_YAML="sre-config/agents/incident-handler-core.yaml"
fi

# Extract the spec from YAML and create via ARM
SPEC_JSON=$(python3 -c "
import yaml, json
with open('${SUBAGENT_YAML}') as f:
    data = yaml.safe_load(f)
spec = data['spec']
print(json.dumps(spec))
")
SPEC_B64=$(echo -n "$SPEC_JSON" | base64)

az rest --method PUT \
  --url "https://management.azure.com${AGENT_RESOURCE_ID}/subagents/incident-handler?api-version=${API_VERSION}" \
  --body "{\"properties\":{\"value\":\"${SPEC_B64}\"}}" \
  --output none 2>/dev/null

echo "   ✅ Created: incident-handler subagent"
echo ""

# ── Step 3: Create incident response plan ────────────────────────────────────
echo "🚨 Step 3/4: Creating incident response plan..."
TOKEN=$(get_token)

curl -s -X PUT "${AGENT_ENDPOINT}/api/v1/incidentplayground/filters/grubify-http-errors" \
  -H "Authorization: Bearer ${TOKEN}" \
  -H "Content-Type: application/json" \
  -d '{
    "id": "grubify-http-errors",
    "name": "Grubify HTTP 5xx Errors",
    "priority": "3",
    "titleContains": "5xx",
    "handlingAgent": "incident-handler",
    "agentMode": "autonomous",
    "maxAttempts": 3
  }' > /dev/null 2>&1

echo "   ✅ Created: grubify-http-errors response plan"
echo ""

# ── Step 4: GitHub integration (optional) ────────────────────────────────────
echo "🔗 Step 4/4: GitHub integration..."

if [ -n "$GITHUB_PAT_VALUE" ]; then
  echo "   Configuring GitHub MCP connector..."
  TOKEN=$(get_token)

  # Upload triage runbook
  curl -s -X POST "${AGENT_ENDPOINT}/api/v1/AgentMemory/upload" \
    -H "Authorization: Bearer ${TOKEN}" \
    -F "triggerIndexing=true" \
    -F "files=@./knowledge-base/github-issue-triage.md;type=text/plain" \
    > /dev/null 2>&1
  echo "   ✅ Uploaded: github-issue-triage.md"

  # Create code-analyzer subagent
  SPEC_JSON=$(python3 -c "
import yaml, json
with open('sre-config/agents/code-analyzer.yaml') as f:
    data = yaml.safe_load(f)
print(json.dumps(data['spec']))
")
  SPEC_B64=$(echo -n "$SPEC_JSON" | base64)
  az rest --method PUT \
    --url "https://management.azure.com${AGENT_RESOURCE_ID}/subagents/code-analyzer?api-version=${API_VERSION}" \
    --body "{\"properties\":{\"value\":\"${SPEC_B64}\"}}" \
    --output none 2>/dev/null
  echo "   ✅ Created: code-analyzer subagent"

  # Create issue-triager subagent
  SPEC_JSON=$(python3 -c "
import yaml, json
with open('sre-config/agents/issue-triager.yaml') as f:
    data = yaml.safe_load(f)
print(json.dumps(data['spec']))
")
  SPEC_B64=$(echo -n "$SPEC_JSON" | base64)
  az rest --method PUT \
    --url "https://management.azure.com${AGENT_RESOURCE_ID}/subagents/issue-triager?api-version=${API_VERSION}" \
    --body "{\"properties\":{\"value\":\"${SPEC_B64}\"}}" \
    --output none 2>/dev/null
  echo "   ✅ Created: issue-triager subagent"

  echo ""
  echo "   GitHub integration: ✅ Configured"
else
  echo "   ⏭️  No GITHUB_PAT — skipping GitHub integration"
  echo "   To add GitHub later: GITHUB_PAT=<pat> ./scripts/setup-github.sh"
fi
echo ""

# ── Summary ──────────────────────────────────────────────────────────────────
echo "============================================="
echo "  ✅ SRE Agent Lab Setup Complete!"
echo "============================================="
echo ""
echo "  🤖 Agent Portal:  https://sre.azure.com"
echo "  🌐 Grubify App:   ${CONTAINER_APP_URL}"
echo "  📦 Resource Group: ${RESOURCE_GROUP}"
echo ""
echo "  What was configured:"
echo "  ├── Knowledge base: http-500-errors.md, grubify-architecture.md"
echo "  ├── Subagent: incident-handler"
echo "  ├── Response plan: grubify-http-errors (Sev3, title contains '5xx')"
if [ -n "$GITHUB_PAT_VALUE" ]; then
echo "  ├── Subagents: code-analyzer, issue-triager"
echo "  └── Knowledge base: github-issue-triage.md"
else
echo "  └── GitHub: skipped (run setup-github.sh to add later)"
fi
echo ""
echo "  Next: Run ./scripts/break-app.sh to trigger an incident!"
echo "============================================="
