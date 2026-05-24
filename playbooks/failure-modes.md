# Failure modes playbook

The hard-won rules from a real 3-hour deep run. Every numbered rule traces to a wasted hour. Read this before designing any new audit phase.

## A — Run-level failure modes

### A1 · Auth tokens rotate → every audit hits the login fallback
**Symptom:** The report has ~100 "horizontal overflow" / "low-contrast" / "unclickable element" findings, all suspiciously uniform across routes. Screenshots all look the same — they're all the login page.

**Cause:** The SPA's session token rotated a few minutes into the crawl. `storageState.json` was loaded once at context-creation, never refreshed. Subsequent navigations had a stale token → 401 → SPA cleared localStorage → redirected to `/login`. Every "audit" then ran against the login page.

**The v0.2+ fix (active):**
- Crawler watches every response for 401 + final-URL-matches-`/login`.
- When detected, the route is marked `authLost: true`.
- The route is NOT audited; instead a `type=auth severity=high` finding is emitted with explicit "Session was rejected mid-crawl" description.
- Discovered links from that page are NOT followed (they're login-page links, not the app).

**The fix on the user side:**
1. Use `--auth-refresh-url https://your-app/auth/refresh` — the crawler will hit this before every navigation to keep tokens warm.
2. Re-run `tester auth <url>` to refresh `storageState.json` if it's old.
3. If your app uses short-lived (≤15 min) tokens, the fix is server-side: lengthen the token, or expose `/auth/refresh` as a `credentials: include` endpoint.

### A2 · Visual audit hangs silently
**Symptom:** Long run completes with exit code 0 but the report is empty or only has the first few routes. Last log line was hours ago.

**Cause:** Pre-v0.2 had no per-phase timeout. A page that never reached `networkidle` (because of a hanging WebSocket, a service worker, a `setInterval` that triggered re-renders forever) would block the audit phase indefinitely. The OS eventually killed it; the parent shell saw exit 0.

**The v0.2+ fix:**
- Each route gets a per-route timeout (default `phaseTimeout / 10`, ≈30s).
- Each phase prints a heartbeat (`↻ visual audit still running (Ns elapsed)`) every 15s.
- On timeout, a `severity=low type=visual` finding is emitted (`"Visual audit timed out on /foo"`) and the run continues.
- A `run.complete` sentinel file is written at the end of the run. **Callers must check it before trusting the report.**

**The check:**
```bash
test -f ~/.tester/projects/<key>/runs/<runId>/run.complete \
  || echo "INCOMPLETE — do not trust report"
```

### A3 · Hardcoded viewport
**Symptom:** Report mentions a 1440px viewport even when the app has a mobile-only bug.

**The v0.2+ fix:** `--viewport mobile|tablet|desktop|WxH` flag. `--deep` automatically loops all three. Findings include the viewport label (`[mobile]`) in the title.

### A4 · Seed URLs given as paths get garbled
**Symptom:** `tester run --seed /admin/x` produced "Failed to load /admin/x — invalid URL" in the report.

**The v0.2+ fix:** Seeds starting with `/` are automatically prefixed with the project's origin. So `--seed /admin/x` becomes `https://your-app/admin/x` before being queued.

## B — Visual-audit false positives

### B1 · Horizontal overflow on every page (always exactly +80px wider)
**Cause:** Reading `scrollWidth` once at `networkidle` catches a mid-hydration state where the SPA's scrollbar gutter or transition transforms make the doc temporarily wider.

**The v0.2+ fix:** Sample 3× over 500ms post-`networkidle` and use the median.

### B2 · Same 7 buttons flagged "unclickable" on every page
**Cause:** Mobile bottom-nav (`display: none` at desktop), collapsed overflow menus (`max-height: 0`), screen-reader-only links (`clip: rect(0,0,0,0)`). They're width=0 height=0 but NOT broken — they're correctly hidden.

**The v0.2+ fix:** `isInHiddenSubtree(el)` walks up `parentElement` and bails if any ancestor is `display:none`, `visibility:hidden`, `opacity:0`, or screen-reader-hidden via clip. Applied to every visual heuristic.

### B3 · "Low contrast 1:1" on white text over a colored gradient
**Cause:** `findBg(el)` walked parents looking for `background-color` only, missing `background-image: linear-gradient(...)`. It fell through to the body bg (near-white) → "white on white" → 1:1 contrast disaster.

**The v0.2+ fix:** `findBg` now also detects `background-image: gradient(`. When a gradient ancestor is present, the contrast check is **skipped** (we can't reliably sample a gradient mean against the foreground). False positives drop to zero on hero sections.

### B4 · 68 "tiny text" findings from one repeating selector
**Cause:** A table row template like `td[data-label]::before` produced 68 small text nodes (one per cell). The old audit emitted 68 separate findings.

**The v0.2+ fix:** Dedup by selector signature (`parent>tag.first-two-classes`). One pattern → one finding with `(N instances)` in the title. The 68 collapsed into 1.

## C — Workflow friction

### C1 · Always asks depth even when prompt was explicit
**Cause:** The skill always opened with "quick / standard / deep?" even if the user typed "deep audit".

**The v0.2+ fix:** See `SKILL.md` § Intent detection. Wording-to-flag mapping; one-sentence confirmation instead of the 3-question menu.

### C2 · Re-runs not actually incremental
**Status:** Partially fixed. The `hashSignature` comparison works, BUT auth-lost pages don't update their hashSignature (they ran against a login fallback, not the app), so they always count as "changed". With the v0.2+ auth-lost detection, this is now consistent.

### C3 · "Routes audited: 155" vs "Routes discovered: 5"
**Status:** Open. Use only the report's "Routes" section as ground truth; ignore the header counts when they conflict.

### C4 · No "open report in browser" command
**Status:** Open. Workaround: visit the dashboard share link instead of the local markdown.

### C5 · Background-task "completed" notifications on hung processes
**Status:** Fixed by A2's sentinel file. Callers must check `run.complete` exists — process exit code alone is not reliable.

## D — "Just go deep, don't ask" flags

`tester run --deep` is the one-shot:
- Multi-viewport (1440 / 768 / 375)
- `--max-pages 100 --max-depth 4`
- Forces `--full` (no incremental skip)
- If `~/.tester/projects/<key>/storageState.json` exists, uses it
- If not, runs unauthed (does NOT prompt — fail closed)

## E — Per-project config (planned, not yet wired)

Future: `.tester.config.js` checked into the user's repo, with `auth: { signin, refresh, seedPaths }`. Replaces interactive wizard on repeat runs. Track in github.com/amineorion/tester issues.

## F — Priorities for future improvements (post-v0.2)

1. **Per-project `.tester.config.js`** — already designed, not wired
2. **`tester report --open`** — package report + screenshots into a single HTML file with embedded base64 images
3. **Sticky last-answer cache** — remember the user's last dashboard-vs-local choice per project
4. **Better incremental** — currently `unchangedCount` rarely hits >0 because hashSignature changes too easily; add a `mode: 'stable-routes-only'` that skips the BFS entirely for routes seen in the last N days
