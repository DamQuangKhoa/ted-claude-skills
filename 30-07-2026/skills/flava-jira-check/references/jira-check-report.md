# Jira check HTML report (flava-jira-check + flava-md-to-html)

Used when **flava-jira-check** finishes investigation. Generate one file per ticket:

`.claude/flava-md-to-html/docs/<TICKET-ID>-jira-check.html`

Follow **flava-md-to-html** for styling, `lang="vi"`, and validation. Tab `id`s below are stable; labels are Vietnamese unless the user requested English.

## Tab: Tổng quan (`overview`)

- `<h1>`: `[TICKET-ID] — short title from Jira summary`
- Meta badges: status, priority, component
- Links: Jira (`https://jira.workers-hub.com/browse/<KEY>`)
- Table or bullets: reporter, environment, repro steps (from ticket)
- **Triệu chứng** callout (what the user sees)

## Tab: Nguyên nhân (`root-cause`)

- **Nguyên nhân trực tiếp** — what triggers the bug
- **Yếu tố góp phần** — table: factor | detail
- **Phạm vi ảnh hưởng** — who / which env / which flow
- **Độ tin cậy** — High / Medium / Low + what would confirm
- Optional: inline SVG (request flow, wrong region, etc.)

## Tab: Kế hoạch thay đổi (`plan`)

- **Thay đổi đề xuất** — numbered list with `file/path` — what & why
- **Hướng xử lý** — strategy, alternatives considered
- **Rủi ro** — Low/Medium/High + side effects
- **Kế hoạch kiểm thử** — manual steps (checklist)
- **Todo triển khai** — `<ul class="checklist">` with one item per implementation step (same items used for editor todos after approval)

## Tab: Cần làm rõ (`questions`)

- Bullets or table of **open questions** only — things you need from user, QA, SRE, or PM before/during fix
- Examples: missing repro, env access, expected vs actual product behavior, upstream API ownership
- If none: single callout **Không có câu hỏi mở — sẵn sàng triển khai sau khi được duyệt.**

## After implementation (optional tab or section)

Add tab **Kết quả** (`results`) or append to **Kế hoạch thay đổi**:

- Files changed, PR link, commit message
- Verification status
- Checked todos

## Footer

`Tạo <date> · Nguồn: Jira <TICKET-ID> · flava-jira-check`
