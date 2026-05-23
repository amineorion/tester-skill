# tester — Claude skill

Wrapper around the `@tester/cli` monorepo (at `~/workspaces/tester` by default). Lets Claude run autonomous web-app QA: crawl → audit → generate Playwright tests → report.

## Files

- `SKILL.md` — orchestrator instructions Claude reads when invoked
- `scripts/` — bash wrappers (`preflight`, `run-tester`, `parse-report`, `api-health`)
- `playbooks/` — detailed guides Claude reads when explaining findings
- `templates/` — Playwright spec template + findings summary template

## Quickstart

```bash
# 1. Start the backend (one-time per machine)
cd ~/workspaces/tester
pnpm install
pnpm --filter @tester/cli exec playwright install chromium
pnpm db:up
pnpm dev:api

# 2. From any Claude Code session, ask:
#    "QA https://your-app.example.com"
#
# Claude will invoke this skill, run preflight, init the project,
# crawl + audit, and walk you through the report.
```

## Env

- `TESTER_API_URL` — defaults to `http://localhost:4000`
- `TESTER_API_KEY` — defaults to `dev-local-key-change-me`
- `TESTER_BIN` — override CLI location (defaults to `tester` on PATH or `~/workspaces/tester/apps/cli/dist/index.js`)
