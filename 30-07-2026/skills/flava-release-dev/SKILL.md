---
name: flava-release-dev
description: Create and push a new Release-dev semver tag for a Flava Console product (overview, shell, lb, vector-search, service-connect, etc.). Use whenever the user asks to "create a release dev tag", "cut a dev release", "tag a dev release", "release dev overview", "bump the dev release", or provides a product name and wants a new `Release-dev-<product>-vX.Y.Z` tag. This skill knows the tag naming convention, how to find the latest existing dev tag, how to bump the patch version, and pushes a lightweight tag on the current `main` HEAD to `origin` (git.linecorp.com/LYCC/flava-console).
---

# Flava Release-Dev Tag

Cut a new dev release tag for a Flava Console product.

## Tag convention

- Format: `Release-dev-<product>-v<MAJOR>.<MINOR>.<PATCH>`
  - Example: `Release-dev-overview-v0.0.27`
- **Lightweight** git tag (not annotated).
- Points at **current `main` HEAD** (release is cut from latest main).
- Product name matches the slug used in existing tags (`overview`, `shell`, `service-connect`, `vector-search`, `cloud-blueprint`, `lb`, ...).
- Prod counterpart exists as `Release-prod-<product>-v...` — this skill does **dev only**.
- Sibling artifact tags (`<product>-client-<sha>-<timestamp>`, `<product>-bff-...`) are CI build tags — ignore them.

## Version bump rule

Find the **highest existing** `Release-dev-<product>-v*` tag, bump **PATCH** by 1.
Note: sequence has gaps (v0.0.10 → v0.0.12 → v0.0.16). Always bump from the numeric max, not `+1` of a guessed value.

## Steps

1. **Resolve product** from user input. If ambiguous, ask. Default to what user names (e.g. "overview").

2. **Fetch tags** (ignore the benign ref-update warnings this repo emits):
   ```bash
   git fetch --tags 2>/dev/null
   ```

3. **Find latest dev tag** for the product. **Use `git ls-remote`, NOT local `git tag`** — this repo's broken-ref bug makes `git fetch --tags` silently skip updates, so local tags go stale and you will pick an already-taken version:
   ```bash
   git ls-remote --tags origin "Release-dev-<product>-v*" 2>/dev/null \
     | sed -E 's#.*refs/tags/##' | grep -v '\^{}' \
     | sed -E 's/.*-v([0-9]+)\.([0-9]+)\.([0-9]+)$/\1 \2 \3 &/' \
     | sort -k1,1n -k2,2n -k3,3n | tail -1
   ```
   Last field of output = latest tag name. Take its `MAJOR.MINOR.PATCH`.

4. **Compute next tag** = same MAJOR.MINOR, PATCH+1. Confirm not already on remote (local check is unreliable):
   ```bash
   git ls-remote --tags origin "Release-dev-<product>-v<X.Y.Z>"   # empty output = free
   ```

5. **Confirm with user** before pushing (irreversible outward action): show
   - new tag name
   - target commit: `git log -1 --format='%h %s' origin/main`
   Push only after user confirms.

6. **Create + push lightweight tag on current main:**
   ```bash
   git fetch origin main 2>/dev/null
   git tag <new-tag> origin/main
   git push origin <new-tag>
   ```
   This lands under the repo **Tags** tab — enough for deploy pipelines (they trigger off the tag ref).

## Optional: rich Release page

The **Releases** tab only shows GitHub Release objects, NOT plain tags. Pushing a tag does NOT create one.
The github MCP is **read-only** for releases (`get_release_by_tag`, `list_releases`, `get_latest_release` — no create tool), and no `git.linecorp.com` token is set for `gh`/curl. So creating the Release object is **manual**:

1. Generate notes (prod-style). Collect overview-scoped commits in range and the target sha:
   ```bash
   git log Release-dev-<product>-v<PREV>..origin/main --format='%s' | grep '(<product>)'
   git rev-parse --short=9 origin/main
   ```
2. Tell the user to: **Draft a new release** → **Choose a tag** = the existing `<new-tag>` (do NOT create new) → title = `<new-tag>` → paste body → Publish.
3. Body template (mirror existing prod releases):
   ```markdown
   ## <Product> v<X.Y.Z> (dev)

   Deployed image built from `<short-sha>`.

   ### Changes
   - <TICKET>: <summary>
   ```

## Notes

- Remote: `git@git.linecorp.com:LYCC/flava-console.git`. Use plain `git`, not `gh`/GitHub MCP (host is enterprise git.linecorp.com).
- If `git fetch` prints `cannot update the ref ... Not a directory` — benign, tags still fetch. Proceed.
- Tag on `origin/main` (fetched HEAD), not local branch, so release reflects real main tip.
