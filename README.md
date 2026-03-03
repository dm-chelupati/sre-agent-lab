# Azure SRE Agent Hands-On Lab

Deploy an Azure SRE Agent connected to a sample application with a single `azd up` command. Watch it diagnose and remediate issues autonomously.

## Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) | 2.60+ | `brew install azure-cli` |
| [Azure Developer CLI (azd)](https://learn.microsoft.com/azure/developer/azure-developer-cli/install-azd) | 1.9+ | `brew install azd` |
| [Git](https://git-scm.com/) | 2.x | `brew install git` |

**Azure Requirements:**
- Active Azure subscription with **Owner** or **User Access Administrator** role
- `Microsoft.App` resource provider registered on the subscription

**Optional (for GitHub integration):**
- GitHub account with a [Personal Access Token](https://github.com/settings/tokens) (repo scope)

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/dm-chelupati/sre-agent-lab.git
cd sre-agent-lab

# 2. Sign in to Azure
az login
azd auth login

# 3. Create environment
azd env new sre-lab

# 4. (Optional) Set GitHub PAT for bonus scenarios
azd env set GITHUB_PAT <your-github-pat>

# 5. Deploy everything
azd up
# Select your subscription and eastus2 as the region
```

Deployment takes ~8-12 minutes. When complete, you'll see the SRE Agent portal URL and Grubify app URL.

## What Gets Deployed

| Component | Azure Service | Purpose |
|-----------|--------------|---------|
| SRE Agent | `Microsoft.App/agents` | AI agent for incident investigation |
| Grubify App | Azure Container Apps | Sample app to monitor |
| Log Analytics | `Microsoft.OperationalInsights/workspaces` | Log storage |
| App Insights | `Microsoft.Insights/components` | Request tracing |
| Alert Rules | `Microsoft.Insights/metricAlerts` | HTTP 5xx and error alerts |
| Managed Identity | `Microsoft.ManagedIdentity` | Reader access for agent |

**Post-provision (automated via srectl):**
- Knowledge base: HTTP error runbook + app architecture doc
- Incident handler subagent with search memory
- Incident response plan for HTTP 500 alerts
- (If GitHub PAT) GitHub MCP connector + code-analyzer + issue-triager subagents

## Lab Scenarios

### Scenario 1: IT Operations (No GitHub required)

Break the app and watch the agent investigate:

```bash
./scripts/break-app.sh
```

Then open [sre.azure.com](https://sre.azure.com) → Incidents to watch the agent:
1. Detect the Azure Monitor alert
2. Query Log Analytics for error patterns
3. Reference the HTTP errors runbook
4. Apply remediation (restart/scale)
5. Summarize with root cause and evidence

### Scenario 2: Developer (Requires GitHub)

Ask the agent to search source code for root causes:
- File:line references to problematic code
- Correlation of production errors to code changes
- Suggested fixes with before/after examples

### Scenario 3: Workflow Automation (Requires GitHub)

Create sample support issues and let the agent triage them:

```bash
./scripts/create-sample-issues.sh <owner/repo>
```

The agent classifies issues (Documentation, Bug, Feature Request), applies labels, and posts triage comments following the runbook.

## Adding GitHub Later

If you skipped GitHub during setup:

```bash
export GITHUB_PAT=<your-pat>
./scripts/setup-github.sh
```

## Cleanup

```bash
azd down --purge
```

## Repository Structure

```
sre-agent-lab/
├── azure.yaml                      # azd template
├── infra/
│   ├── main.bicep                  # Subscription-scoped entry point
│   ├── main.bicepparam             # Parameter defaults
│   ├── resources.bicep             # Resource group module orchestrator
│   └── modules/
│       ├── sre-agent.bicep         # Microsoft.App/agents resource
│       ├── identity.bicep          # Managed identity + RBAC
│       ├── monitoring.bicep        # Log Analytics + App Insights
│       ├── container-app.bicep     # Grubify Container App
│       └── alert-rules.bicep       # Azure Monitor alert rules
├── knowledge-base/
│   ├── http-500-errors.md          # HTTP error investigation runbook
│   ├── grubify-architecture.md     # App architecture reference
│   └── github-issue-triage.md     # Issue triage runbook (GitHub)
├── sre-config/
│   ├── connectors/
│   │   └── github-mcp.yaml        # GitHub MCP connector
│   └── agents/
│       ├── incident-handler-core.yaml   # Core subagent (no GitHub)
│       ├── incident-handler-full.yaml   # Full subagent (with GitHub)
│       ├── code-analyzer.yaml           # Developer persona subagent
│       └── issue-triager.yaml           # Triage persona subagent
├── scripts/
│   ├── post-provision.sh           # azd postprovision hook
│   ├── break-app.sh                # Fault injection script
│   ├── setup-github.sh             # Add GitHub integration later
│   └── create-sample-issues.sh     # Create triage test issues
└── lab/
    └── skillable-instructions.md   # Skillable lab markdown (copy into Skillable)
```

## Regions

SRE Agent is available in: `eastus2`, `swedencentral`, `uksouth`, `australiaeast`

## License

MIT
