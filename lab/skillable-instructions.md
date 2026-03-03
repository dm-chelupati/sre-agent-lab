# Azure SRE Agent Hands-On Lab

Welcome, @lab.User.FirstName! In this lab you will deploy an **Azure SRE Agent** connected to a sample application, watch it diagnose and remediate issues autonomously, and explore three personas: **IT Operations**, **Developer**, and **Workflow Automation**.

**Estimated time:** 60 minutes

---

## Lab Environment

| Resource | Value |
|:---------|:------|
| **Azure Portal** | @lab.CloudPortal.SignInLink |
| **Username** | ++@lab.CloudPortalCredential(User1).Username++ |
| **Password** | ++@lab.CloudPortalCredential(User1).Password++ |
| **Subscription ID** | ++@lab.CloudSubscription.Id++ |

---

### Optional: GitHub Integration

> [!Note] The **core lab** (IT Persona — incident detection, log analysis, remediation) works **without GitHub**. If you have a GitHub account, entering your PAT and username below unlocks two bonus scenarios: source code root cause analysis and automated issue triage.

If you want to use GitHub:

1. **Fork the Grubify repo** — Go to [github.com/dm-chelupati/grubify](https://github.com/dm-chelupati/grubify) and click **Fork** to create a copy in your account
2. **Create a Personal Access Token** — Go to [github.com/settings/tokens](https://github.com/settings/tokens) → **Generate new token (classic)** → select **`repo`** scope → **Generate token**

**GitHub Username:** @lab.TextBox(githubUser)

**GitHub PAT (optional):** @lab.MaskedTextBox(githubPat)

> [!Alert] Your PAT needs the **`repo`** scope to create issues and search code in your forked repo. The agent will use `@lab.Variable(githubUser)/grubify` for all GitHub operations.

===

# Part 1: Deploy the Environment

In this section you will clone the lab repository and deploy all Azure resources with a single command. The deployment creates:

- **Grubify** — A sample food ordering app on Azure Container Apps
- **Azure SRE Agent** — Connected to the app's resource group with Azure Monitor
- **Knowledge Base** — HTTP error runbooks and app architecture documentation
- **Alert Rules** — Azure Monitor alerts for HTTP 5xx errors and error log spikes
- **Subagent** — Incident handler with search memory and log analysis tools
- *(If GitHub PAT provided)* GitHub MCP connector, code-analyzer, and issue-triager subagents

> [!Knowledge] Architecture Overview
>
> ```
> ┌──────────────────────────────────────────────────────────────┐
> │                    Azure Resource Group                      │
> │                                                              │
> │  ┌──────────────┐    alerts     ┌────────────────────────┐   │
> │  │  Grubify App  │─────────────▶│   Azure Monitor         │   │
> │  │ (Container    │              │   Alert Rules            │   │
> │  │  Apps)        │              └──────────┬─────────────┘   │
> │  └──────────────┘                         │ auto-flow        │
> │                                           ▼                  │
> │  ┌──────────────┐              ┌───────────────────────────┐ │
> │  │ Log Analytics │◄────logs────│      Azure SRE Agent      │ │
> │  │ + App Insights│              │                           │ │
> │  └──────────────┘              │  ┌─────────────────────┐  │ │
> │                                │  │  Knowledge Base      │  │ │
> │  ┌──────────────┐              │  │  • http-500-errors   │  │ │
> │  │ Managed       │              │  │  • app architecture  │  │ │
> │  │ Identity      │              │  └─────────────────────┘  │ │
> │  │ (Reader RBAC) │              │                           │ │
> │  └──────────────┘              │  ┌─────────────────────┐  │ │
> │                                │  │  Subagents           │  │ │
> │                                │  │  • incident-handler  │  │ │
> │                                │  │  • (code-analyzer)   │  │ │
> │                                │  │  • (issue-triager)   │  │ │
> │                                │  └─────────────────────┘  │ │
> │                                │                           │ │
> │                                │  ┌─────────────────────┐  │ │
> │                                │  │  GitHub MCP (opt.)  ─┼──┼─▶ GitHub
> │                                │  └─────────────────────┘  │ │
> │                                └───────────────────────────┘ │
> └──────────────────────────────────────────────────────────────┘
> ```

---

### Step 1: Sign in to Azure

1. [] Open a **Terminal** on the lab VM (VS Code terminal or command prompt).

1. [] Sign in to Azure CLI:

    ```
    az login
    ```

    Follow the browser prompts using the lab credentials shown above.

1. [] Set the subscription:

    ```
    az account set --subscription "@lab.CloudSubscription.Id"
    ```

---

### Step 2: Clone the lab repository

1. [] Clone the lab repo and navigate into it:

    ```
    git clone https://github.com/dm-chelupati/sre-agent-lab.git
    cd sre-agent-lab
    ```

---

### Step 3: Deploy with azd up

1. [] Initialize the azd environment:

    ```
    azd env new sre-lab
    ```

1. [] *(Only if you entered GitHub details above)* Set GitHub variables:

    ```
    azd env set GITHUB_PAT "@lab.Variable(githubPat)"
    azd env set GITHUB_USER "@lab.Variable(githubUser)"
    ```

> [!Hint] If you did **not** enter GitHub details, skip the commands above. The core lab works without GitHub.

1. [] Deploy everything with a single command:

    ```
    azd up
    ```

1. [] When prompted, select:
    - **Subscription**: Your lab subscription
    - **Location**: ++eastus2++

> [!Alert] Deployment takes approximately **8-12 minutes**. The command provisions Azure resources via Bicep, deploys the Grubify app, then runs a post-provision script that configures the SRE Agent with knowledge base, subagents, and response plans.

1. [] Wait for the deployment to complete. You will see a success banner:

    ```
    ✅ SRE Agent Lab Setup Complete!
    SRE Agent Portal:  https://sre.azure.com
    Grubify App:       https://ca-grubify-xxxxx.eastus2.azurecontainerapps.io
    ```

1. [] Copy the **Grubify App URL** from the output and paste it here for quick reference:

    **Grubify URL:** @lab.TextBox(grubifyUrl)

===

# Part 2: Explore the SRE Agent

Before diving into specific scenarios, explore what `azd up` configured for you.

---

### Step 1: Open the SRE Agent Portal

1. [] Open <[sre.azure.com](https://sre.azure.com)> in a browser and sign in with your lab credentials.

1. [] Find your agent in the list and click on it.

> [!Knowledge] The SRE Agent was created via Bicep as a `Microsoft.App/agents` resource with:
> - **Autonomous mode** — the agent takes actions without waiting for approval
> - **Azure Monitor integration** — alerts from your resource group flow to the agent automatically
> - **Managed Identity** — with Reader, Monitoring Reader, and Log Analytics Reader roles on the resource group

---

### Step 2: Explore the Knowledge Base

1. [] Click **Builder** in the left sidebar.

1. [] Select **Knowledge base**.

1. [] Verify you see uploaded files:

    | File | Purpose |
    |:-----|:--------|
    | **http-500-errors.md** | HTTP error troubleshooting runbook with KQL queries |
    | **grubify-architecture.md** | App architecture, endpoints, scaling config |
    | **github-issue-triage.md** | Grubify app issue triage runbook (if GitHub configured) |

> [!Note] These files were uploaded automatically by the post-provision script using `srectl doc upload`. The agent references YOUR runbooks during investigations — not generic advice.

---

### Step 3: Explore the Subagents

1. [] Click **Builder** → **Subagent builder**.

1. [] You should see the **incident-handler** subagent with:
    - **Autonomy:** Autonomous
    - **Tools:** search_memory (+ github-mcp/* if GitHub was configured)

1. [] Click on **incident-handler** to see its system prompt and tool assignments.

> [!Knowledge] If you provided a GitHub PAT, you'll also see **code-analyzer** and **issue-triager** subagents on the canvas.

---

### Step 4: Explore Connectors (if GitHub configured)

1. [] Click **Builder** → **Connectors**.

1. [] If you provided a GitHub PAT, you should see **github-mcp** with a green **Connected** status.

> [!Hint] If you didn't provide a GitHub PAT and want to add GitHub now, run:
>
> ```
> export GITHUB_PAT=<your-pat>
> ./scripts/setup-github.sh
> ```

---

### Step 5: Verify the Grubify App

1. [] In your terminal, check the app is running:

    ```
    curl https://@lab.Variable(grubifyUrl)/weatherforecast
    ```

    You should see a JSON response with weather data.

---

### Step 6: Chat with Your Agent

Before we break things, try a few prompts to see the agent in action. Start a **new chat** in the SRE Agent portal and try these:

1. [] Ask how many container apps are deployed:

    ```
    How many container apps are deployed for the Grubify application?
    List them with their endpoints.
    ```

    The agent should find both the API and frontend container apps and list their URLs.

1. [] Ask for the frontend endpoint:

    ```
    What is the public endpoint URL for the Grubify frontend
    container app?
    ```

    The agent should return the frontend FQDN. Copy the URL from the response.

1. [] Open the Grubify app in your browser:

    - [] Click the frontend URL the agent gave you
    - [] You should see the Grubify food ordering app with restaurants
    - [] Click on a restaurant, browse the menu
    - [] **Add an item to your cart** — it should work fine
    - [] This is the app working normally — remember this for when we break it!

1. [] Ask about the app's API routes using the knowledge base:

    ```
    Using the grubify-architecture document in the knowledge base,
    what are the API routes for the Grubify backend API?
    ```

    The agent should search the knowledge base and return the API endpoints (restaurants, food items, orders, cart).

> [!Knowledge] These prompts demonstrate the agent's built-in tools: `RunAzCliReadCommands` for Azure resource queries and `search_memory` for knowledge base search. All configured automatically by `azd up`.

===

# Part 3: IT Persona — Incident Detection & Remediation

> [!Knowledge] **This is the core lab — no GitHub required.**

**Scenario:** You are an SRE/Ops engineer. The Grubify application starts experiencing memory pressure from a cart API memory leak. Azure Monitor fires alerts for high memory usage and container restarts. The SRE Agent automatically investigates using logs, knowledge base, and memory — then remediates the issue.

```
                  IT Persona Flow
                  ================

  You (run script)                           SRE Agent
  ──────────────                             ─────────
  1. Flood cart API ———————▶ Grubify App ————▶ Memory grows
     (POST /api/cart)                │              │
                                     │              ▼
                                     │        OOM / 500 errors
                                     │
                                     ▼
                              Azure Monitor ————▶ Alerts fire:
                                     │            • High memory (>80%)
                                     │            • Container restarts
                                     │            • HTTP 5xx errors
                                     ▼ (auto-flow)
                               SRE Agent investigates:
                                 ├── Searches memory for similar incidents
                                 ├── Queries Log Analytics (KQL)
                                 │    • Memory metrics over time
                                 │    • OOM / restart events
                                 │    • Error logs + stack traces
                                 ├── Checks knowledge base (runbook)
                                 ├── Applies remediation (restart/scale)
                                 └── Shows investigation summary
```

---

### Step 1: Break the App

1. [] Run the fault injection script:

    ```
    ./scripts/break-app.sh
    ```

    This script:
    - Floods the `/api/cart/demo-user/items` endpoint with rapid POST requests
    - Each request adds items to an in-memory cart, causing memory to grow
    - Eventually the container hits its 1Gi memory limit → OOM kill → restarts
    - Azure Monitor fires alerts for high memory, container restarts, and HTTP errors

> [!Alert] After running the script, **wait 5-8 minutes** for Azure Monitor to fire the alert and the SRE Agent to pick it up. The memory leak takes a few minutes to build up enough pressure to trigger alerts.

---

### Step 2: Watch the Agent Investigate

1. [] Go back to the SRE Agent portal at <[sre.azure.com](https://sre.azure.com)>.

1. [] Click **Incidents** in the left sidebar.

1. [] A new incident should appear — the Azure Monitor alert for HTTP 5xx errors on Grubify.

1. [] Click on the incident to see the agent's investigation thread.

1. [] Observe the agent's workflow:

    - [] **Memory search**: The agent searches for similar past incidents
    - [] **Log analysis**: Queries Log Analytics for memory pressure indicators, OOM events, and error logs
    - [] **Metrics check**: Analyzes container memory usage trends (WorkingSetBytes rising over time)
    - [] **Knowledge base**: References the http-500-errors.md runbook for memory leak diagnosis steps
    - [] **Root cause**: Identifies the `/api/cart` endpoint accumulating data without eviction
    - [] **Remediation**: Takes corrective action (restart container revision, scale up memory)
    - [] **Summary**: Provides root cause analysis with evidence (memory timeline, error logs, KQL queries)

---

### Step 3: Examine the Investigation Details

1. [] In the agent's investigation thread, look for:

    - [] **Sources** showing references to your knowledge base files
    - [] KQL queries the agent executed against Log Analytics
    - [] Timeline of events (when errors started, when remediation was applied)
    - [] Root cause conclusion

1. [] Verify the app is responding:

    ```
    curl https://@lab.Variable(grubifyUrl)/weatherforecast
    ```

> [!Knowledge] **What just happened?** The entire investigation was autonomous. The response plan routes all Azure Monitor alerts from the managed resource group to the `incident-handler` subagent. That subagent used KQL queries from the knowledge base runbook, searched memory for patterns, checked metrics, and applied remediation — then created a GitHub issue documenting everything. All without human intervention.

===

# Part 4: Developer Persona — Deep Root Cause with Source Code

> [!Alert] **This section requires a GitHub PAT.** If you did not provide one during setup, skip to **Part 6: Review & Cleanup**. You can also add GitHub now by running: `export GITHUB_PAT=<pat> && ./scripts/setup-github.sh`

**Scenario:** The incident-handler subagent (Part 3) created a GitHub issue using only log analysis. Now use the **code-analyzer** subagent to create a RICHER issue that includes source code references. Compare the two issues to see the value of connecting source code.

> [!Knowledge] **What's different between the two subagents?**
>
> | | incident-handler (Part 3) | code-analyzer (Part 4) |
> |:--|:--|:--|
> | **Log analysis** | ✅ | ✅ |
> | **Knowledge base** | ✅ | ✅ |
> | **Source code search** | ❌ Told NOT to search code | ✅ Searches GitHub repo |
> | **File:line references** | ❌ | ✅ |
> | **Code fix suggestions** | ❌ | ✅ |
> | **GitHub issue detail** | Basic (log evidence only) | Rich (code + logs + fix) |

---

### Step 1: Investigate with Source Code

1. [] In the SRE Agent portal, start a **new chat**.

1. [] Ask the agent to use the code-analyzer subagent:

    ```
    Use the code-analyzer subagent to investigate the Grubify app.
    Check logs AND search the source code in @lab.Variable(githubUser)/grubify
    to find the exact root cause of the memory issues. Correlate
    log entries to specific code paths. Create a GitHub issue with
    detailed findings including file:line references and a suggested fix.
    ```

1. [] Observe the ADDITIONAL steps compared to the incident-handler:
    - [] **Source code search**: Searches the Grubify repo for cart API implementation
    - [] **Code correlation**: Maps error logs to specific functions and files
    - [] **File:line references**: Points to the exact code causing the memory leak
    - [] **Fix suggestion**: Proposes a code change (e.g., add cache eviction, size limit)

---

### Step 2: Compare the Two GitHub Issues

1. [] Go to [github.com/@lab.Variable(githubUser)/grubify/issues](https://github.com/@lab.Variable(githubUser)/grubify/issues).

1. [] Compare the two issues side by side:

    - [] **Issue from incident-handler** (Part 3): Log-based analysis — "Memory pressure detected, container restarted, KQL evidence shows error spike at timestamp X"
    - [] **Issue from code-analyzer** (Part 4): Same log evidence PLUS — "Root cause in `CartService.cs` line 45: in-memory dictionary grows unbounded. Suggested fix: add LRU eviction or max size limit"

> [!Knowledge] **The delta is clear:** Adding source code search to the investigation takes the agent from "what happened" (logs) to "why it happened and how to fix it" (code). Same tools, different instructions — the code-analyzer subagent is instructed to search source code and provide code-level fixes, producing significantly richer findings.

===

# Part 5: Workflow Automation — Issue Triage

> [!Alert] **This section requires a GitHub PAT.** If you did not provide one during setup, skip to **Part 6: Review & Cleanup**.

**Scenario:** The incident-handler and code-analyzer created GitHub issues in `@lab.Variable(githubUser)/grubify` during Parts 3 and 4. Now use the **issue-triager** subagent to triage those issues — classify them, add labels, and post a structured comment. A scheduled task has also been set up to run this automatically every 12 hours.

---

### Step 1: Check the Issues

1. [] Go to [github.com/@lab.Variable(githubUser)/grubify/issues](https://github.com/@lab.Variable(githubUser)/grubify/issues).

1. [] You should see the issues created by the agent in Parts 3 and 4 — currently without triage labels or comments.

---

### Step 2: Triage via Chat

1. [] In the SRE Agent portal, start a **new chat**.

1. [] Ask the agent:

    ```
    Use the issue-triager subagent to triage all open issues in
    @lab.Variable(githubUser)/grubify. For each issue, classify it, add appropriate
    labels, and post a triage comment following the triage runbook.
    ```

1. [] Watch the agent:
    - [] Lists open issues from the repository
    - [] Reads each issue and classifies it (Bug, Documentation, Feature Request)
    - [] Adds labels (bug, needs-more-info, etc.)
    - [] Posts a triage comment starting with "🤖 **SRE Agent Triage Bot**"

---

### Step 3: Verify the Results

1. [] Go back to [github.com/@lab.Variable(githubUser)/grubify/issues](https://github.com/@lab.Variable(githubUser)/grubify/issues).

1. [] Verify the issues now have:
    - [] **Labels** applied (bug, needs-more-info, etc.)
    - [] A **triage comment** from the agent

---

### Step 4: Check the Scheduled Task

1. [] In the SRE Agent portal, go to **Builder → Scheduled tasks**.

1. [] You should see **triage-grubify-issues** running every 12 hours.

> [!Knowledge] The scheduled task was created by `azd up`. It runs the issue-triager subagent automatically twice a day, so new issues get triaged without anyone manually triggering it. You can also click **Run task now** to trigger it immediately.

===

# Part 6: Review & Cleanup

## What You Learned

| Persona | What the Agent Did | Key Capabilities |
|:--------|:-------------------|:-----------------|
| **IT Operations** | Detected alert → investigated logs + KB → remediated → summarized | Azure Monitor, Knowledge base, Search memory, Autonomous mode |
| **Developer** | Searched source code → correlated logs to code → suggested fixes | GitHub MCP, Code search, file:line references |
| **Workflow Automation** | Triaged issues → classified → labeled → commented | GitHub MCP tools, Runbook-driven automation |

---

## What azd up Automated

Everything below was configured automatically when you ran `azd up`:

- [] SRE Agent resource (Bicep: `Microsoft.App/agents`)
- [] Managed Identity with Reader + Monitoring Reader + Log Analytics Reader RBAC (Bicep)
- [] Log Analytics Workspace + Application Insights (Bicep)
- [] Grubify Container App with external ingress (Bicep)
- [] Azure Monitor alert rules — HTTP 5xx metric + error log alerts (Bicep)
- [] Knowledge base files uploaded (srectl post-provision hook)
- [] Incident handler subagent created (srectl post-provision hook)
- [] Incident response plan created (srectl post-provision hook)
- [] *(If GitHub PAT)* GitHub MCP connector, code-analyzer, issue-triager (srectl post-provision hook)

---

## Key SRE Agent Concepts

> [!Knowledge] Quick reference for the concepts you explored:
>
> - **Managed Resources**: Resource group IDs the agent monitors — Azure Monitor alerts from these RGs flow automatically
> - **Knowledge Base**: Your team's runbooks, uploaded as files — the agent references them during investigations
> - **Subagents**: Specialized agents with specific tools and instructions for different tasks
> - **MCP Connectors**: External tool integrations (GitHub, Datadog, etc.) using the Model Context Protocol
> - **Response Plans**: Rules that match incoming alerts to subagents based on severity and title patterns
> - **Autonomous Mode**: The agent takes actions without requiring human approval

---

## Cleanup

1. [] Tear down all Azure resources:

    ```
    azd down --purge
    ```

1. [] Delete the SRE Agent resource (not removed by azd down):

    ```
    az resource delete --ids $(az resource list --resource-group rg-$(azd env get-value AZURE_ENV_NAME) --resource-type Microsoft.App/agents --query "[0].id" -o tsv) 2>/dev/null
    ```

1. [] Delete the resource group if it still exists:

    ```
    az group delete --name rg-$(azd env get-value AZURE_ENV_NAME) --yes --no-wait
    ```

> [!Alert] This **permanently deletes** all Azure resources. Make sure you have saved any notes or screenshots before proceeding.

> [!Note] `azd down` does not currently recognize the `Microsoft.App/agents` resource type, so the SRE Agent must be deleted separately.

===

# Congratulations! 🎉

You have successfully deployed and explored Azure SRE Agent across three personas:

1. **IT Operations** — Autonomous incident detection, investigation, and remediation using logs and knowledge base
2. **Developer** — Source code root cause analysis with file:line references
3. **Workflow Automation** — Automated GitHub issue triage following a custom runbook

All of this was set up with a single `azd up` command.

## Resources

- [Azure SRE Agent Documentation](https://sre.azure.com/docs)
- [Azure SRE Agent Portal](https://sre.azure.com)
- [Grubify Sample App](https://github.com/dm-chelupati/grubify)
- [Lab Source Code](https://github.com/dm-chelupati/sre-agent-lab)

**Thank you for completing this lab, @lab.User.FirstName!**
