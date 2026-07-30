# Confluence storage-format recipes for proposals

The Deck of Cards, Card, code, and diagram macros are **storage-format XML** (`ac:structured-macro`), not markdown. Always create/update with `content_format: "storage"`. This file has the exact skeletons and the failure modes we hit building real proposals.

## Deck of Cards + two language cards

Verified working on workers-hub Confluence (`label` param, macros keep real `ac:macro-id` on round-trip):

```xml
<ac:structured-macro ac:name="deck">
  <ac:parameter ac:name="id">proposal-langs</ac:parameter>
  <ac:rich-text-body>
    <ac:structured-macro ac:name="card">
      <ac:parameter ac:name="label">🇻🇳 Tiếng Việt</ac:parameter>
      <ac:rich-text-body>
        <!-- VN content: <h2>, <table>, <h3>, <ul>, <hr/>, code macro, etc. -->
      </ac:rich-text-body>
    </ac:structured-macro>
    <ac:structured-macro ac:name="card">
      <ac:parameter ac:name="label">🇬🇧 English</ac:parameter>
      <ac:rich-text-body>
        <!-- EN content -->
      </ac:rich-text-body>
    </ac:structured-macro>
  </ac:rich-text-body>
</ac:structured-macro>
```

## Code block macro (works inside a card)

```xml
<ac:structured-macro ac:name="code">
  <ac:parameter ac:name="language">bash</ac:parameter>
  <ac:plain-text-body><![CDATA[
case "$ENVIRONMENT" in
  dev|prod) MANIFEST_HASH="$ENVIRONMENT-$HASH" ;;
  *)        MANIFEST_HASH="$HASH" ;;
esac
]]></ac:plain-text-body>
</ac:structured-macro>
```

Put the code inside `<![CDATA[ ... ]]>` so quotes, `$`, `*`, `<`, `>` survive verbatim. In prose (outside code macros), escape `<` `>` `&` as `&lt; &gt; &amp;`.

## Diagram macros — VERIFY before relying

Diagram macros are NOT guaranteed installed. An unsupported macro is silently normalized to an empty `<ac:macro ac:name="..."></ac:macro>` on save — the diagram body is dropped, no error. So:

**Round-trip verification recipe (do this on a SCRATCH page, not the live proposal):**
1. Create a throwaway page in LVN with one diagram macro containing a small diagram.
2. Fetch it back with `convert_to_markdown: false`.
3. PASS = the macro comes back with a real `ac:macro-id="..."` and its `<ac:plain-text-body><![CDATA[...]]>` intact.
   FAIL = it came back as `<ac:macro ac:name="..."></ac:macro>` (empty, no id) → macro not installed.
4. Delete the scratch page.

Candidates, in order:
- Mermaid: `ac:name="mermaid"` / `mermaid-cloud` / `easy-mermaid`, body `<ac:plain-text-body><![CDATA[flowchart TD\n A-->B]]>`.
- PlantUML: `ac:name="plantuml"` / `plantumlcloud`, body `<ac:plain-text-body><![CDATA[@startuml\n ... \n@enduml]]>`.

**Known result on workers-hub (2026-07):** **`plantuml` (native) IS installed and works** — survives round-trip with real macro-id + CDATA. Use PlantUML activity/flow syntax (`@startuml ... @enduml`). Mermaid (`mermaid`/`mermaid-cloud`/`easy-mermaid`) and the `*-cloud` PlantUML variants were NOT installed (stripped to empty `<ac:macro>`). `drawio` returns a macro-id but is attachment-based → unusable for headless text-defined flows. **So on workers-hub, default to `plantuml` and skip the Mermaid probe.** Re-verify if the instance changes.

**Fallback that always renders** (no macro) — a flow as a table or a nested list:

```xml
<p><strong>Flow:</strong></p>
<table><tbody>
<tr><td>PR opened</td><td>→</td><td>check-pr runs type_check + test_ci</td></tr>
<tr><td></td><td>→</td><td>NOT required on branch protection → can merge on fail (gap)</td></tr>
</tbody></table>
```

## Failure modes we actually hit

- **Whole-page wipe:** sending a *minimal* body to `confluence_update_page` replaces the entire page (we produced a stub v5 that dropped all content). ALWAYS fetch the full current storage, edit the whole body, then update. Never send a fragment.
- **Response markdown looks mangled:** `confluence_create_page`/`update_page` echo the new body re-converted to markdown, which flattens code/mermaid macros into run-together text (e.g. `bash# after HASH...`). That is a *display artifact of the tool response*, not the stored page. Verify with a `convert_to_markdown: false` fetch — the stored storage is usually fine.
- **Re-parent needs full body:** `confluence_update_page` with `parent_id` still requires `title` + `content`; pass the same full storage body, don't blank it.
- **Version churn:** each probe/update bumps the version. Probe diagrams on a scratch page so the live proposal's history stays clean.
