# Grubify App Issue Triage Runbook

Triage incoming issues for the Grubify food ordering application. Classify them, add labels, and route to the right team.

---

## Step 1: Get Open Issues

Fetch all open issues from the repo. Focus on issues that are unassigned and unlabeled.

---

## Step 2: Skip Already Triaged Issues

For each issue, check if it's already been triaged:

- Look for a comment starting with "🤖 **SRE Agent Triage Bot**"
- Check if it has labels

**If both exist and issue hasn't been updated** → Skip it, already handled.

**Otherwise** → Triage it now.

---

## Step 3: Classify the Issue

Read the title and description. Pick ONE category:

| Category | What it looks like |
|----------|-------------------|
| **Bug** | "Error", "500", "crash", "not working", "broken", "OOM", "memory leak" |
| **Performance** | "slow", "timeout", "high CPU", "high memory", "latency" |
| **Feature Request** | "Would be nice to have...", "Please add...", suggestions |
| **Question** | "How do I...", "Where can I find...", configuration help |

---

## Step 4: Handle Bugs

### Pick a sub-category:

| Type | Examples |
|------|----------|
| **API Bug** | Cart API errors, order failures, menu not loading, 500 errors |
| **Frontend Bug** | UI broken, page not rendering, CORS errors, failed to load |
| **Infrastructure** | Container restarts, OOM kills, deployment failures, scaling issues |
| **Memory Leak** | Memory growing over time, cart accumulating without cleanup |

### Check if user provided enough info:

**Need at minimum:**
- What happened (error message or behavior)
- Steps to reproduce
- Which endpoint or page was affected

### If info is missing:

**Post comment:**
```
🤖 **SRE Agent Triage Bot**

Thanks for reporting this issue with Grubify. To investigate, we need:
- [list what's missing]

⚠️ Status: **Waiting for info from user**
```

**Add labels:** `needs-more-info` + sub-category label

### If info is complete:

**Post comment:**
```
🤖 **SRE Agent Triage Bot**

Thanks for the details. This bug report is ready for investigation.

Issue summary: [brief summary]
Affected component: [API / Frontend / Infrastructure]
Severity: [Critical / High / Medium / Low]

✅ Status: **Ready for investigation**
```

**Add labels:** `bug` + sub-category label + severity label

**Sub-category labels:**
- `api-bug`
- `frontend-bug`
- `infrastructure`
- `memory-leak`

---

## Step 5: Handle Performance Issues

**Post comment:**
```
🤖 **SRE Agent Triage Bot**

Performance issue identified.

Affected area: [API response time / Memory usage / CPU / Scaling]
Recommended investigation: [Check metrics / Review logs / Load test]

🔧 Status: **Performance investigation needed**
```

**Add labels:** `performance` + relevant sub-category

---

## Step 6: Handle Feature Requests

**Post comment:**
```
🤖 **SRE Agent Triage Bot**

Thanks for the suggestion for Grubify!

[If feature exists: explain how to use it]
[If new: "This is a great idea. We'll consider it for future development."]

💡 Status: **Feature request**
```

**Add labels:** `enhancement`, `feature-request`

---

## Step 7: Handle Questions

**Post comment:**
```
🤖 **SRE Agent Triage Bot**

[Answer the question based on the grubify-architecture knowledge base document]

📖 Status: **Question answered**
```

**Add labels:** `question`, `answered`

---

## Labels Cheat Sheet

| Situation | Labels to Add |
|-----------|---------------|
| Bug, need more info | `needs-more-info` + sub-category |
| Bug, ready to investigate | `bug` + sub-category + severity |
| Performance issue | `performance` + sub-category |
| Feature request | `enhancement`, `feature-request` |
| Question | `question`, `answered` |

**Severity labels:**
- `critical` — App completely down, all users affected
- `high` — Major feature broken, many users affected
- `medium` — Feature partially broken, workaround exists
- `low` — Minor issue, cosmetic, edge case

---

## Comment Template

Always start with: `🤖 **SRE Agent Triage Bot**`

Always end with a status line:
- `⚠️ Status: **Waiting for info from user**`
- `✅ Status: **Ready for investigation**`
- `🔧 Status: **Performance investigation needed**`
- `💡 Status: **Feature request**`
- `📖 Status: **Question answered**`
