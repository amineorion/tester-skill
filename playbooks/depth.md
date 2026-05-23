# Depth tiers playbook

Three modes, ask which one every time. Don't run without knowing the tier.

## quick — 1–3 minutes

- Crawl ≤ 10 pages, BFS depth ≤ 2
- Functional audit only (status codes, console errors, broken links)
- Top-of-fold screenshot per page
- **Skipped:** performance audit, visual audit, baseline diff, Playwright codegen

Use for: "is it up", "smoke test", post-deploy gut check, demo runs.

CLI translation: `--max-pages 10 --max-depth 2 --skip performance --skip visual`

## standard — 5–15 minutes

This is the default. Use unless explicitly asked otherwise.

- Crawl ≤ 30 pages, BFS depth ≤ 3
- Functional + Performance + Visual audits
- Baselines saved + diffed against previous run
- Playwright smoke spec emitted (`smoke-routes.spec.ts`)
- Screenshots per page

CLI translation: `--max-pages 30 --max-depth 3`

## deep — 20+ minutes

Use when the user says "full report", "deep dive", "thoroughly test", "before release".

On top of standard:
- Interactive authentication (always asked — if you don't know the creds, the wizard opens a browser)
- Form-fill probes on every form (sends synthetic data, captures the response — does NOT submit destructive operations like Delete or Pay)
- Primary-CTA exercise on every page (clicks each visible button that isn't destructive, captures the resulting modal/navigation)
- API call tracing (records every XHR + response status during the walk)
- Multi-viewport screenshots: 1440 (desktop), 768 (tablet), 375 (mobile) per page
- Full-flow Playwright specs per discovered user journey, not just routes
- Learnings persistence to MongoDB so the next deep run starts from this one

CLI translation: `--max-pages 60 --max-depth 4 --deep`

## Time + cost guide

| Tier | Time | Mongo writes | Screenshots | Playwright specs emitted |
|---|---|---|---|---|
| quick | 1–3 min | ~50 docs | ≤ 10 | 0 |
| standard | 5–15 min | ~500 docs | ≤ 30 | 1 (smoke) |
| deep | 20+ min | ~2000+ docs | ≤ 180 (per viewport) | N (one per flow) |

If the user's API quota or DB plan is tight, suggest standard.

## Migration: user says "full"

"Full" is ambiguous. Ask:

> "I can do 'full' two ways — **deep** (20+ min, every flow exercised, auth required, multi-viewport) or **standard with all audits enabled** (10 min, all routes audited but no flow exercises). Which?"

Don't assume.
