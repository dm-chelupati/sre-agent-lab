# Azure SRE Agent — MVP Lab Session
## Slide Deck (McKinsey Style)

---

## Slide 1: Title

**Azure SRE Agent**
*Your AI-Powered Operations Expert*

Generally Available — March 10, 2026

sre.azure.com

---

## Slide 2: The Problem We All Know

**Operations teams are drowning in toil**

| The pain | The cost |
|----------|----------|
| 2am alerts → manual runbook execution | MTTR measured in hours, not minutes |
| Context-switching between 5+ tools | Engineer burnout and attrition |
| Same investigation steps, every incident | Knowledge locked in individuals |
| Triage backlogs growing daily | Customer satisfaction drops |

> *"80% of incident response is gathering data. 20% is deciding what to do."*

**What if an AI agent could handle the 80%?**

---

## Slide 3: Introducing Azure SRE Agent

**Your AI teammate that learns and grows with your team**

```
    Connect              Enhance              Achieve
    ───────              ───────              ───────
    Azure resources      Your runbooks        Faster investigations
    Incident platforms   Your architecture    Automated triage
    Any API via MCP      Domain subagents     Reliable remediation
```

**Three words:** Connect. Enhance. Achieve.

- **Not a chatbot** — an autonomous agent that takes action
- **Not generic AI** — uses YOUR runbooks, YOUR data, YOUR procedures
- **Not locked-in** — connects to any tool via MCP (Model Context Protocol)

---

## Slide 4: Four Superpowers

| Superpower | What it does | Outcome |
|------------|-------------|---------|
| **Autonomous Incident Response** | Alert fires → agent gathers context, finds root cause, suggests or executes remediation | Lower MTTR from hours to minutes |
| **Lightning-Fast Root Cause Analysis** | Correlates logs + metrics + traces + code + deploys simultaneously | Actionable insights, not data dumps |
| **Extensible Automation** | Connect any tool via MCP. Build self-healing workflows. Schedule recurring tasks | Eliminate toil, free up engineers |
| **Conversational Operations** | Natural language + Python execution. Ask questions, get answers with evidence | Anyone on the team can investigate |

---

## Slide 5: How It Actually Works

```
┌──────────────────────────────────────────────────────┐
│                                                      │
│   Your App (Azure)          Azure SRE Agent          │
│   ┌─────────────┐          ┌──────────────────┐     │
│   │ Container   │──alerts──│  Knowledge Base   │     │
│   │ Apps / VMs  │          │  • Your runbooks  │     │
│   └─────────────┘          │  • Architecture   │     │
│                            │                    │     │
│   ┌─────────────┐          │  Subagents         │     │
│   │ Log         │──logs────│  • Incident handler│     │
│   │ Analytics   │          │  • Code analyzer   │     │
│   └─────────────┘          │  • Issue triager   │     │
│                            │                    │     │
│   ┌─────────────┐          │  Connectors        │     │
│   │ GitHub /    │──MCP─────│  • GitHub MCP      │     │
│   │ PagerDuty   │          │  • Any API via MCP │     │
│   └─────────────┘          └──────────────────┘     │
│                                                      │
└──────────────────────────────────────────────────────┘
```

**Key insight:** The agent uses YOUR procedures, not generic advice.
Upload a runbook → agent follows it. Every time. At 3am. Without mistakes.

---

## Slide 6: Three Personas, Three Scenarios

**Today's lab covers three real-world use cases:**

### 1. IT Operations / SRE
*"Stop running runbooks at 3am"*
- Alert fires → agent auto-investigates using your runbook
- Queries logs, checks metrics, applies remediation
- Creates a GitHub issue with findings
- **You wake up to results, not raw alerts**

### 2. Developer
*"From 'what happened' to 'why and how to fix it'"*
- Same investigation + source code search
- Agent finds the exact file:line causing the issue
- Creates a richer issue with code fix suggestions
- **Compare the two GitHub issues — see the delta**

### 3. Workflow Automation
*"Triage isn't the job, it's the tax on the job"*
- Agent triages GitHub issues: classify, label, comment
- Follows your triage runbook exactly
- Runs on a schedule — twice a day, automatically
- **Stop sorting tickets. Start shipping.**

---

## Slide 7: What You'll Do in the Lab

**One command. Everything configured.**

```bash
azd up
```

**What gets deployed automatically:**

| Component | How |
|-----------|-----|
| Grubify app (frontend + API) | Container Apps + ACR build |
| Azure SRE Agent | Bicep (Microsoft.App/agents) |
| Knowledge base (2 runbooks) | Dataplane API upload |
| 3 specialized subagents | Dataplane API |
| GitHub MCP connector | ARM API |
| Azure Monitor alerts | Bicep |
| Response plan → subagent | Dataplane API |
| Scheduled triage task | Dataplane API |

**Then you'll:**
1. Chat with the agent — ask it about your app
2. Break the app — trigger a memory leak
3. Watch the agent investigate and remediate
4. Compare log-only vs source-code-aware investigations
5. See automated issue triage in action

---

## Slide 8: GA Announcement — March 10, 2026

**Generally Available** with enterprise-grade reliability

| GA Feature | Detail |
|------------|--------|
| Production SLA | Enterprise support included |
| Regions | East US 2, Sweden Central, Australia East |
| Incident platforms | Azure Monitor, PagerDuty, ServiceNow |
| Extensibility | MCP connectors — connect any API |
| Subagents | Specialized agents for different domains |
| Scheduled tasks | Recurring automated workflows |
| Knowledge base | Your runbooks, architecture docs, TSGs |
| Memory | Learns from past incidents |

**Pricing:** Pay for what you use. No per-seat licensing.

---

## Slide 9: Roadmap Peek

**What's coming after GA:**

| Quarter | Capability |
|---------|------------|
| Q2 2026 | More incident platforms (Jira Service Desk, Opsgenie) |
| Q2 2026 | Copilot CLI integration (investigate from your terminal) |
| Q3 2026 | Skills marketplace (share and install community skills) |
| Q3 2026 | Multi-agent collaboration (agents that coordinate) |
| Q4 2026 | Custom model support (bring your own LLM) |

---

## Slide 10: Why This Matters to You

**Before SRE Agent:**
- 2 hours every morning sorting tickets
- Context-switch between 5 tools during incidents
- Knowledge locked in the heads of senior engineers
- Same diagnostic steps, every time, error-prone at 3am

**After SRE Agent:**
- Issues triaged before anyone logs in
- Investigations completed with evidence and recommendations
- Runbooks executed consistently, 24/7
- Engineers focus on solving problems, not gathering data

> *"The best incident response is the one you sleep through."*

---

## Slide 11: Let's Try It

**Prerequisites (already set up on your lab VM):**
- Azure subscription with Owner access
- Azure CLI + Azure Developer CLI (azd)
- GitHub account (optional, for bonus scenarios)

**Open your lab instructions and let's go!**

```
Portal:  https://sre.azure.com
Docs:    https://sre.azure.com/docs
Lab:     https://github.com/dm-chelupati/sre-agent-lab
```

---

## Slide 12: Resources

| Resource | Link |
|----------|------|
| **SRE Agent Portal** | sre.azure.com |
| **Documentation** | sre.azure.com/docs |
| **Lab Repo** | github.com/dm-chelupati/sre-agent-lab |
| **Blog** | aka.ms/sreagent/blog |
| **Samples** | github.com/microsoft/sre-agent/tree/main/samples |
| **Feedback** | github.com/microsoft/sre-agent/issues |

**Blog posts to read after the lab:**
- [Stop Running Runbooks at 3am](https://techcommunity.microsoft.com/blog/appsonazureblog/stop-running-runbooks-at-3-am-let-azure-sre-agent-do-your-on-call-grunt-work/4479811)
- [Build an Agentic Workflow to Triage Customer Issues](https://techcommunity.microsoft.com/blog/appsonazureblog/extend-sre-agent-with-mcp-build-an-agentic-workflow-to-triage-customer-issues/4480710)
