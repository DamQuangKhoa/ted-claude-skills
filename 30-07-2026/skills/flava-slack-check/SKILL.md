---
name: flava-slack-check
description: Read a Slack thread, summarize the issue, and optionally create a Jira ticket via flava-jira-create-dev-ticket. Requires Slack MCP and Jira MCP to be configured. Use when the user pastes a Slack thread URL, says "check this slack thread", "summarize this slack", "what's this thread about", or wants to turn a Slack discussion into a Jira ticket. Also triggers for "slack to jira", "create ticket from slack", or just a pasted Slack URL.
---

# Flava Slack Check

Read a Slack thread, summarize the issue/discussion, and optionally create a Jira ticket using **flava-jira-create-dev-ticket**.

## Prerequisites Check (mandatory — run FIRST)

Before doing anything else, verify that both required MCP servers are available by attempting to list their tools. Check for tools matching these patterns:

### 1. Slack MCP

Look for any MCP tools with `slack` in the name (e.g. `slack_get_thread`, `slack_get_channel_history`, `slack_search_messages`, `mcp__slack__*`).

**If not found**, stop and tell the user:

```
Slack MCP not configured. To use this skill, add a Slack MCP server to your Claude Code settings.

Common options:
- https://github.com/modelcontextprotocol/servers/tree/main/src/slack
- Any MCP server that provides Slack thread/message reading

Add it to .claude/settings.json or ~/.claude/settings.json under "mcpServers".
```

### 2. Jira MCP

Look for tools like `jira_get_issue`, `jira_create_issue`, `mcp__jira__*`.

**If not found**, stop and tell the user:

```
Jira MCP not configured. To use this skill, add a Jira MCP server to your Claude Code settings.
```

**If both are available**, proceed to the workflow.

---

## Workflow

| Step | Action |
|------|--------|
| **0** | **Check prerequisites** — verify Slack + Jira MCP (above). |
| **1** | **Parse input** — extract channel ID and thread timestamp from URL or user input (§1). |
| **2** | **Fetch thread** — read all messages in the thread via Slack MCP (§2). |
| **3** | **Summarize** — produce a structured summary for the user (§3). |
| **4** | **Ask about Jira** — offer to create a ticket (§4). |
| **5** | **Create ticket** — if user says yes, delegate to flava-jira-create-dev-ticket (§5). |

---

## 1. Parse input

Accept these input formats:

- **Slack URL**: `https://<workspace>.slack.com/archives/<CHANNEL_ID>/p<TIMESTAMP>`
  - Channel ID: the `C...` or `G...` segment after `/archives/`
  - Thread timestamp: the `p` prefix number, converted to Slack ts format (insert `.` before last 6 digits, e.g. `p1234567890123456` → `1234567890.123456`)
- **Channel + timestamp**: user provides channel name/ID and thread ts directly
- **Just a URL**: if user pastes only a URL with no other context, parse it and proceed

If the URL format is unrecognized, ask the user for the channel and thread timestamp.

## 2. Fetch thread

Use the Slack MCP to read the thread. Try these tool patterns (adapt to whatever the configured MCP provides):

- `slack_get_thread(channel_id, thread_ts)` — preferred, gets full thread
- `slack_get_channel_history(channel_id)` + filter by thread_ts — fallback
- `slack_search_messages` — last resort

Read **all replies** in the thread, not just the root message. Note:
- Message authors (display names)
- Timestamps
- Any attachments, links, or code blocks
- Reactions (if available — can indicate agreement/urgency)

## 3. Summarize

Present a structured summary in chat:

```
**Thread Summary**

**Channel**: #channel-name
**Started by**: @author (date)
**Participants**: @person1, @person2, ...
**Messages**: N messages

**Issue/Topic**:
<1-3 sentences: what the thread is about>

**Key Points**:
- <bullet points of important information, decisions, or requests>

**Action Items** (if any):
- <extracted action items with assignees if mentioned>

**Severity/Urgency**: <Low/Medium/High — based on tone, reactions, escalation patterns>
```

Keep it concise. Preserve technical details (error messages, stack traces, URLs) verbatim.

## 4. Ask about Jira

After showing the summary, ask:

> Want me to create a Jira ticket for this? If yes, which component? (e.g. Load balancer, DBS for Cassandra, Vector search, etc.)

If user already mentioned the component or it's obvious from the thread content, suggest it.

## 5. Create Jira ticket

If user says yes, invoke **flava-jira-create-dev-ticket** with:

- **Summary**: derived from thread topic (short, actionable)
- **Description**: structured using the Jira wiki markup template from flava-jira-create-dev-ticket, populated with:
  - Thread summary as the Summary section
  - Key points and context as the Background section
  - Slack thread URL as reference in the Contact Point section
- **Issue type**: infer from thread content — `Bug` if it's about something broken, `Task` for action items, `Improvement` for enhancement requests. Default: `Task`.
- **Component**: as confirmed by user
- **Priority**: mapped from the severity assessment

After ticket creation, share the Jira URL and ask if any adjustments needed.

---

## Tips

- Threads about incidents or outages → suggest `Bug` with `High` priority
- Threads with design discussions → suggest `Task` or `Story`
- If thread is very long (50+ messages), focus summary on the conclusion/decision, not the full back-and-forth
- Preserve any mentioned ticket IDs (LYCC-*, CLOUDQA-*) — they may be related issues worth linking

## Relationship to other skills

- **flava-slack-check** (this): read Slack → summarize → optionally create ticket
- **flava-jira-create-dev-ticket**: creates the actual Jira ticket (delegated to)
- **flava-jira-check**: investigates existing Jira tickets (different direction — Jira → code)
