# GitHub Issue Triage Runbook

Triage incoming customer issues for repo https://github.com/dm-chelupati/SREagentsupporttickets.git, classify them, and route to the right team.

---

## Step 1: Get Open Issues

Fetch all open issues from the repo. Focus on issues that are unassigned and unlabeled.

---

## Step 2: Skip Already Triaged Issues

For each issue, check if it's already been triaged:

- Look for a comment starting with "🤖 **SRE Agent Triage Bot**"
- Check if it has labels (documentation, bug, enhancement, etc.)

**If both exist and issue hasn't been updated** → Skip it, already handled.

**If user added new info since last comment** → Re-triage it.

**Otherwise** → Triage it now.

---

## Step 3: Classify the Issue

Read the title and description. Pick ONE category:

| Category | What it looks like |
|----------|-------------------|
| **Documentation** | "How do I...", "Where can I find...", config questions |
| **Bug** | "Error", "Not working", "Failed", "Broken", crashes |
| **Feature Request** | "Would be nice to have...", "Please add...", suggestions |

---

## Step 4: Handle Documentation Questions

**Post a comment:**
```
🤖 **SRE Agent Triage Bot**

[Answer the question]

Docs: https://learn.microsoft.com/en-us/azure/sre-agent/

📖 Status: **PM to review**
```

**Add labels:** `documentation`, `PM to review`

---

## Step 5: Handle Bugs

### First, pick a sub-category:

| Type | Examples |
|------|----------|
| **Onboarding/Access** | Deploy failures, 403/404, agent won't load |
| **AI Issues** | Bad responses, thread problems, RCA issues |
| **Non-AI Issues** | Alerts, integrations, UI bugs |

### Check if user provided enough info:

**For Onboarding/Access issues, need:**
- Region
- Subscription ID + resource group
- Error message
- Steps to reproduce

**For AI issues, need:**
- Agent name
- Thread ID
- Region
- Steps to reproduce
- Expected vs actual

**For Non-AI issues, need:**
- Agent name
- Region
- Steps to reproduce
- Expected vs actual

### If info is missing:

**Post comment:**
```
🤖 **SRE Agent Triage Bot**

Thanks for reporting. To investigate, we need:
- [list what's missing]

⚠️ Status: **Waiting for info from user**
```

**Add labels:** `needs-more-info` + sub-category label

### If info is complete:

**Post comment:**
```
🤖 **SRE Agent Triage Bot**

Thanks for the details. This is ready for investigation.

✅ Status: **Engineering to investigate**
```

**Add labels:** `bug` + sub-category label

**Create PagerDuty incident:**
- Title: `[GitHub #<issue_number>] <issue_title>`
- Service: SRE Agent
- Urgency: High for `onboarding-create-access-failure`, Low for others
- Description: Include issue link, sub-category, and summary of the bug

**Sub-category labels:**
- `onboarding-create-access-failure`
- `ai-issue`
- `non-ai-issue`

---

## Step 6: Handle Feature Requests

**First:** Check if the feature already exists. If yes, explain how to use it.

**Post comment:**
```
🤖 **SRE Agent Triage Bot**

Thanks for the suggestion! [If exists: explain. If new: "We'll review for our roadmap."]

Azure SRE Agent is in preview—we're actively collecting feedback.

💡 Status: **Feature request**
```

**Add labels:** `enhancement`, `feature request`

**Close the issue.**

---

## Labels Cheat Sheet

| Situation | Labels to Add |
|-----------|---------------|
| Doc question | `documentation`, `PM to review` |
| Bug, need more info | `needs-more-info` + sub-category |
| Bug, ready to investigate | `bug` + sub-category |
| Feature request | `enhancement`, `feature request` |

---

## Comment Template

Always start with: `🤖 **SRE Agent Triage Bot**`

Always end with status:
- `📖 Status: **PM to review**`
- `⚠️ Status: **Waiting for info from user**`
- `✅ Status: **Engineering to investigate**`
- `💡 Status: **Feature request**`
- `🎉 Status: **Addressed user request, issue resolved and closed**`
