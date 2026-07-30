# Task: <task-name>

## Jira Ticket

<Ticket key, e.g. LYCC-1234 or CLOUDQA-84652. Use "N/A" if this is a free-form task not tied to a ticket.>

## Product Area

<Product name and monorepo path, e.g. "product-lb — apps/product-lb/" or "product-cloud-blueprint — apps/product-cloud-blueprint/">

## Goal

<What to accomplish in 1–2 sentences. E.g. "Add the `drainTimeoutSeconds` field to the Application LB revision DTO and expose it in the create/edit modal.">

## Steps

1. Investigate ticket / understand root cause (flava-jira-check)
2. Load product conventions skill (flava-lb-skill / flava-blueprint-skill / etc.)
3. Implement changes (BFF DTO + client form / composable / component)
4. Run unit tests to confirm no regressions
5. Commit following flava commitlint format (flava-commit-skill)
6. Create PR with structured description (flava-pr-skill)
7. Update Jira ticket to "In Review" with PR link

## Expected Output

```json
{
  "status": "success",
  "pr_url": "https://git.linecorp.com/LYCC/flava-console/pull/...",
  "branch": "LYCC-1234",
  "jira_status": "In Review",
  "notes": "Added drainTimeoutSeconds to AppLBRevisionDto and wired up form field."
}
```
