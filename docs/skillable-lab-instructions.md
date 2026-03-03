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

## Optional: GitHub Integration

> [!Note] The core lab (IT Persona) works **without GitHub**. If you have a GitHub account, entering your PAT unlocks two bonus scenarios: source code root cause analysis and automated issue triage.

Create a GitHub PAT at [github.com/settings/tokens](https://github.com/settings/tokens) with the **repo** scope (Classic token type).

**GitHub PAT (optional):** @lab.MaskedTextBox(githubPat)

===

# Part 1: Deploy the Environment

In this section, you will clone the lab repository and deploy all Azure resources with a single command.

> [!Knowledge] **What gets deployed**
>
> `azd up` provisions the following via Bicep and a post-provision script:
>
> - **Grubify** — A sample food ordering app on Azure Container Apps
> - **Azure SRE Agent** — Connected to the app's resource group with Azure Monitor
> - **Log Analytics + App Insights** — For log collection and request tracing
> - **Knowledge Base** — HTTP error runbooks and app architecture docs
> - **Incident Handler Subagent** — With search memory and knowledge base access
> - **Alert Rules** — Azure Monitor alerts for HTTP 5xx errors
> - **(If GitHub PAT provided)** GitHub MCP connector + code-analyzer and issue-triager subagents

> [!Knowledge] **Architecture**
>
> ```
> ┌─────────────────────────────────────────────────────────────────┐
> │                     Azure Resource Group                        │
> │                                                                 │
> │  ┌──────────────┐     alerts     ┌─────────────────────────┐   │
> │  │  Grubify App  │───────────────│   Azure Monitor          │   │
> │  │ (Container    │               │   Alert Rules             │   │
> │  │  Apps)        │               └───────────┬───────────────┘   │
> │  └──────────────┘                            │ auto-flow          │
> │                                              ▼                   │
> │  ┌──────────────┐               ┌─────────────────────────┐    │
> │  │ Log Analytics │◄────logs─────│   Azure SRE Agent        │    │
> │  │ + App Insights│               │                         │    │
> │  └──────────────┘               │  ┌────────────────────┐ │    │
> │                                 │  │ Knowledge Base      │ │    │
> │  ┌──────────────┐               │  │ • HTTP runbook      │ │    │
> │  │ Managed       │               │  │ • App architecture  │ │    │
> │  │ Identity      │               │  └────────────────────┘ │    │
> │  │ (Reader RBAC) │               │                         │    │
> │  └──────────────┘               │  ┌────────────────────┐ │    │
> │                                 │  │ Subagents            │ │    │
> │                                 │  │ • incident-handler   │ │    │
> │                                 │  │ • (code-analyzer)*   │ │    │
> │                                 │  │ • (issue-triager)*   │ │    │
> │                                 │  └────────────────────┘ │    │
> │                                 │                         │    │
> │                                 │  ┌────────────────────┐ │    │
> │                                 │  │ GitHub MCP*         │─┼──► GitHub
> │                                 │  └────────────────────┘ │    │
> │                                 └─────────────────────────┘    │
> │                                                                 │
> │                          * = requires GitHub PAT                 │
> └─────────────────────────────────────────────────────────────────┘
> ```

---

### Step 1: Sign in to Azure

1. [] Open a **Terminal** in VS Code on the lab VM.

1. [] Sign in to Azure CLI:

    ```
    az login
    ```

    Follow the browser prompts using the lab credentials above.

1. [] Set the subscription:

    ```
    az account set --subscription "@lab.CloudSubscription.Id"
    ```

---

### Step 2: Clone the lab repository

1. [] Clone the repo and open it:

    ```
    git clone https://github.com/dm-chelupati/sre-agent-lab.git
    cd sre-agent-lab
    code .
    ```

---

### Step 3: Deploy with azd up

1. [] Initialize the azd environment:

    ```
    azd env new sre-lab
    ```

1. [] **(Optional)** If you entered a GitHub PAT above, set it:

    ```
    azd env set GITHUB_PAT "@lab.Variable(githubPat)"
    ```

    > [!Hint] If you did not enter a GitHub PAT, skip this step. The core lab works without it.

1. [] Deploy everything with a single command:

    ```
    azd up
    ```

1. [] When prompted:
    - **Subscription**: Select your lab subscription
    - **Location**: Select ++eastus2++

> [!Alert] Deployment takes approximately **8-12 minutes**. The `azd up` command provisions all Azure resources, deploys the Grubify app, then runs a post-provision script that configures the SRE Agent.

1. [] Wait for the deployment to complete. You will see output like:

    ```
    =============================================
      ✅ SRE Agent Lab Setup Complete!
    =============================================

      SRE Agent Portal:  https://sre.azure.com
      Grubify App:       https://ca-grubify-xxxxx.eastus2.azurecontainerapps.io
      Resource Group:    rg-sre-lab
    ```

1. [] Note the **Grubify App URL** from the output:

    **Grubify URL:** @lab.TextBox(grubifyUrl)

===

# Part 2: Explore the SRE Agent

Before triggering an incident, explore what `azd up` configured for you.

---

### Step 1: Open the SRE Agent Portal

1. [] Navigate to <[sre.azure.com](https://sre.azure.com)> and sign in with your lab credentials.

1. [] Find your agent in the agent list and click on it.

> [!Knowledge] The SRE Agent was deployed via Bicep as a `Microsoft.App/agents` resource with:
> - **Autonomous mode** — the agent takes actions without requiring approval
> - **Azure Monitor integration** — alerts from the managed resource group automatically flow to the agent
> - **Managed Identity** — with Reader, Monitoring Reader, and Log Analytics Reader roles

---

### Step 2: Explore the Knowledge Base

1. [] Click **Builder** in the left sidebar.

1. [] Select **Knowledge base**.

1. [] Verify you see uploaded files:
    - **http-500-errors.md** — Troubleshooting runbook with KQL queries for CPU, memory, error patterns, dependency health, and remediation steps
    - **grubify-architecture.md** — App architecture, endpoints, log tables, and known failure modes

> [!Knowledge] These files were uploaded automatically by the post-provision script using `srectl doc upload`. When the agent investigates an incident, it searches YOUR knowledge base — not generic advice. You can see **Sources** references in investigation responses pointing to these files.

---

### Step 3: Explore the Subagent

1. [] Click **Builder** → **Subagent builder**.

1. [] Verify you see the **incident-handler** subagent.

1. [] Click on it to see:
    - **System prompt** — instructions for the agent to investigate HTTP errors
    - **Autonomy level** — Autonomous
    - **Tools** — search_memory (plus github-mcp/* if you provided a PAT)

> [!Note] If you provided a GitHub PAT, you should also see **code-analyzer** and **issue-triager** subagents.

---

### Step 4: Check Connectors

1. [] Click **Builder** → **Connectors**.

1. [] If you provided a GitHub PAT, verify **github-mcp** shows a green **Connected** status.

    > [!Knowledge] The GitHub MCP connector uses the Streamable-HTTP transport to connect to `https://api.githubcopilot.com/mcp/`. This gives the agent GitHub tools: `github_search_code`, `github_create_issue`, `github_list_issues`, and more.

---

### Step 5: Verify the Grubify App

1. [] In the terminal, check the app is running:

    ```
    curl https://@lab.Variable(grubifyUrl)/health
    ```

    You should see a **200 OK** health response.

===

# Part 3: IT Persona — Incident Detection & Remediation

**Scenario:** You are an SRE/Ops engineer. Your application starts returning HTTP 500 errors. Azure Monitor fires an alert. The SRE Agent automatically investigates using logs, knowledge base, and applies remediation.

> [!Knowledge] **How it works**
>
> ```
> break-app.sh ──► Grubify App ──► HTTP 500 errors
>                       │
>                       ▼
>                Azure Monitor ──► Alert fires (5xx threshold exceeded)
>                       │
>                       ▼ (auto-flow via managed resource group)
>                SRE Agent incident-handler
>                  ├── Searches memory for similar past incidents
>                  ├── Queries Log Analytics (KQL from runbook)
>                  │    • CPU/memory metrics
>                  │    • Error patterns and stack traces
>                  │    • Container health and restarts
>                  ├── Checks knowledge base (http-500-errors.md)
>                  ├── Applies remediation (restart/scale)
>                  └── Summarizes with root cause + evidence
> ```

---

### Step 1: Break the App

1. [] Run the fault injection script:

    ```
    cd ~/sre-agent-lab
    ./scripts/break-app.sh
    ```

    This script:
    - Enables chaos mode on the Grubify app
    - Sends 50 HTTP requests that return 500 errors
    - You will see a summary showing the error count

> [!Alert] After running the script, **wait 5-8 minutes** for Azure Monitor to fire the alert and the SRE Agent to pick it up. This is normal — Azure Monitor evaluates metrics every 1-5 minutes.

---

### Step 2: Watch the Agent Investigate

1. [] Go back to the SRE Agent portal at <[sre.azure.com](https://sre.azure.com)>.

1. [] Click **Incidents** in the left sidebar.

1. [] You should see a new incident appear — the Azure Monitor alert for HTTP 5xx errors on Grubify.

1. [] Click on the incident to see the agent's investigation thread.

1. [] Observe the agent's workflow:

    - [] **Memory search**: The agent searches for similar past incidents
    - [] **Log analysis**: Queries Log Analytics using KQL queries from the runbook — error counts, CPU spikes, memory pressure, container restarts
    - [] **Knowledge base lookup**: References `http-500-errors.md` for the investigation checklist
    - [] **Root cause determination**: Correlates the evidence to identify what went wrong
    - [] **Remediation**: Takes corrective action (restart container revision, scale out)
    - [] **Summary**: Provides a complete investigation report with timeline, evidence, and actions

---

### Step 3: Review the Investigation

1. [] In the agent's investigation thread, look for:
    - [] **Sources** — references to your uploaded knowledge base files
    - [] **KQL queries** — actual queries the agent ran against Log Analytics
    - [] **Metrics** — CPU, memory, and error rate data
    - [] **Actions taken** — what the agent did to fix the issue

1. [] Back in the terminal, verify the app is recovering:

    ```
    curl https://@lab.Variable(grubifyUrl)/health
    ```

> [!Knowledge] **What just happened?**
>
> The entire investigation was autonomous. The SRE Agent:
> 1. Detected the Azure Monitor alert via its managed resource group connection
> 2. Matched the alert to the `incident-handler` subagent via the response plan (Sev3 alerts with "500" in the title)
> 3. The subagent used `search_memory` for similar incidents, ran KQL queries from the knowledge base, and correlated evidence
> 4. Applied remediation and generated a summary — all without human intervention
>
> This is what the agent does for every matching alert — 24/7, automatically.

---

### Step 4: Chat with the Agent

1. [] Start a **new chat** in the SRE Agent portal.

1. [] Ask about the incident:

    ```
    What happened with the most recent incident on the Grubify app? 
    Show me the timeline and root cause.
    ```

1. [] Ask the agent to check current health:

    ```
    Query the last 30 minutes of logs for the Grubify container app. 
    Are there any remaining errors?
    ```

> [!Hint] Try asking the agent other questions to explore its capabilities:
> - "What KQL queries would you run to check for memory leaks?"
> - "Show me the error rate trend for the last hour"
> - "What does the http-500-errors runbook say about dependency failures?"

===

# Part 4: Developer Persona — Source Code Root Cause Analysis (Optional)

> [!Alert] This section requires a GitHub PAT. If you did not provide one during setup, you can add it now:
>
> ```
> export GITHUB_PAT="<your-github-pat>"
> ./scripts/setup-github.sh
> ```
>
> Or skip to **Part 6: Review & Cleanup**.

**Scenario:** You are a developer with access to the Grubify source code. You want the SRE Agent to find the root cause at the code level.

---

### Step 1: Search Source Code for Root Cause

1. [] In the SRE Agent portal, start a **new chat**.

1. [] Ask the agent to analyze the code:

    ```
    Search the dm-chelupati/grubify repository for error handling code. 
    What could cause HTTP 500 errors? Show me the specific files and lines.
    ```

1. [] Observe the agent:
    - [] Uses `github_search_code` to find error handling patterns
    - [] Returns **file:line references** pointing to specific code
    - [] Suggests code fixes based on the source analysis

---

### Step 2: Correlate Production Issues to Code

1. [] Ask the agent:

    ```
    What recent commits or code changes in dm-chelupati/grubify could have 
    introduced the HTTP 500 errors we saw in the last incident?
    ```

1. [] The agent searches commit history and correlates production symptoms to code changes.

---

### Step 3: Deep Investigation with Code Context

1. [] Ask for a comprehensive root cause analysis:

    ```
    Do a deep investigation of the last incident. Cross-reference the error 
    logs with the source code in dm-chelupati/grubify to find the exact 
    root cause. Include file names, line numbers, and a suggested fix.
    ```

1. [] Review the agent's response — it should include code references, log evidence, and actionable fix suggestions.

> [!Knowledge] The **code-analyzer** subagent specializes in source code analysis with `github_search_code` and `search_memory` tools. Combined with your knowledge base (which describes Grubify's architecture), it can correlate production symptoms to specific code paths.

===

# Part 5: Workflow Automation — GitHub Issue Triage (Optional)

> [!Alert] This section requires a GitHub PAT. If you did not provide one, skip to **Part 6: Review & Cleanup**.

**Scenario:** You want to automate repetitive workflows like triaging GitHub issues, classifying them, and routing to the right team.

---

### Step 1: Create a Support Tickets Repo

1. [] In the terminal, create a test repo for sample issues:

    ```
    gh repo create my-support-tickets --public --description "Test repo for SRE Agent issue triage"
    ```

    **Your repo name:** @lab.TextBox(triageRepo)

    Enter the repo in `owner/repo` format (e.g., `yourusername/my-support-tickets`).

---

### Step 2: Create Sample Issues

1. [] Run the script to create 10 sample issues:

    ```
    ./scripts/create-sample-issues.sh @lab.Variable(triageRepo)
    ```

    This creates:
    - 3 Documentation questions
    - 5 Bug reports (various sub-categories, some with incomplete info)
    - 2 Feature requests

---

### Step 3: Ask the Agent to Triage

1. [] In the SRE Agent portal, start a **new chat**.

1. [] Ask the agent to triage:

    ```
    List all open issues in @lab.Variable(triageRepo). For each issue, 
    follow the GitHub Issue Triage Runbook in your knowledge base to:
    1. Classify it (Documentation, Bug, or Feature Request)
    2. Apply the appropriate labels
    3. Post a triage comment starting with "🤖 SRE Agent Triage Bot"
    4. For bugs missing info, request the needed details
    ```

1. [] Watch the agent:
    - [] List issues from the repository
    - [] Classify each issue based on title and description
    - [] Apply labels (`documentation`, `bug`, `needs-more-info`, `enhancement`, etc.)
    - [] Post triage comments with status

---

### Step 4: Verify Results

1. [] Open your GitHub repo issues page to verify:
    - [] Each issue has appropriate labels
    - [] Each issue has a triage comment from the agent
    - [] The incomplete bug report (#7) has a "needs-more-info" label and a request for details
    - [] Feature requests have "enhancement" and "feature request" labels

> [!Knowledge] The **issue-triager** subagent follows the `github-issue-triage.md` runbook from the knowledge base. It classifies issues into Documentation, Bug (with sub-categories), and Feature Request — matching the exact workflow defined in your runbook.

===

# Part 6: Review & Cleanup

## What You Accomplished

| Persona | What the Agent Did | Key Capabilities |
|:--------|:-------------------|:-----------------|
| **IT Operations** | Detected HTTP 500 alert → investigated via KQL + knowledge base → remediated → summarized | Azure Monitor, Knowledge base, Search memory, Autonomous mode |
| **Developer** *(optional)* | Searched source code → correlated logs to code → suggested fixes with file:line refs | GitHub code search, Deep investigation |
| **Workflow** *(optional)* | Triaged issues → classified → labeled → commented per runbook | GitHub MCP tools, Triage runbook |

## What azd up Automated

- [] Azure SRE Agent with autonomous mode (Bicep)
- [] Managed Identity with Reader RBAC on resource group (Bicep)
- [] Log Analytics Workspace + Application Insights (Bicep)
- [] Grubify Container App with scaling rules (Bicep)
- [] Azure Monitor alert rules for HTTP 5xx and log errors (Bicep)
- [] Knowledge base files uploaded (post-provision hook)
- [] Incident handler subagent created (post-provision hook)
- [] Incident response plan for HTTP 500 alerts (post-provision hook)
- [] *(If GitHub PAT)* GitHub MCP connector + code-analyzer + issue-triager (post-provision hook)

---

## Cleanup

1. [] When finished, tear down all resources:

    ```
    azd down --purge
    ```

> [!Alert] This deletes all Azure resources created during the lab. Make sure you have saved any notes or screenshots.

===

# Congratulations!

You have successfully deployed and explored **Azure SRE Agent** with a single `azd up` command.

**Key takeaways:**
- SRE Agent connects to Azure Monitor automatically via managed resource groups — no webhook setup required
- Knowledge base files (runbooks) make the agent use YOUR procedures, not generic advice
- Subagents specialize in different tasks (incident handling, code analysis, issue triage)
- Everything can be configured as code: Bicep for infrastructure, srectl YAML for agent configuration

## Resources

- [Azure SRE Agent Documentation](https://sre.azure.com/docs)
- [SRE Agent Portal](https://sre.azure.com)
- [Grubify Source Code](https://github.com/dm-chelupati/grubify)
- [Lab Source Code](https://github.com/dm-chelupati/sre-agent-lab)

**Thank you for completing this lab, @lab.User.FirstName!**
