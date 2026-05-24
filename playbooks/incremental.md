# Incremental / re-run playbook

`tester run` is incremental **by default**. The state stored in MongoDB makes that possible:

- **Routes** — each route has a `hashSignature` (links + forms + element intents). On re-run, a route with the same signature *and* `lastSeenAt` within the freshness window (default 7 days) is marked `unchanged` and the visual audit is skipped on it. Functional + performance audits always run.
- **Elements** — semantic intents persist. If a page restructures but keeps the same intents, the recorded selectors still work.
- **Baselines** — performance metrics from previous runs are kept; the latest baseline is what each new sample diffs against. Regressions ≥ 20% emit a finding.
- **Findings** — stored per run. The latest run's findings are what the report surfaces; previous runs are accessible via the API.

## Modes

| Flag | Behavior |
|---|---|
| (default) | Incremental. Visit every route; skip the visual audit on routes whose hashSignature matches AND are within freshness. |
| `--full` | Force-audit every route regardless of change. Use after a big refactor or before a release. |
| `--deep` | Implies `--full`. |
| `--stable-only` | **Skip the route ENTIRELY** if it's known + fresh + unchanged. No navigation, no audit, just counted. Much faster than the default incremental mode, but won't catch a route whose URL works the same but rendered content changed in a way the previous hashSignature missed. |
| `--freshness-days N` | Change the window (default 7). For fast-moving sites set to 1; for stable docs sites set to 30. |

**`--stable-only` use case:** you fixed CSS on `/admin/users` and want to re-run only that route's audit, not all 60 routes. Run with `--stable-only` and only routes whose content changed (or whose freshness expired) get audited. Combine with `--seed /admin/users` to force-audit the route you actually want.

## When to expect what

| Scenario | Expected outcome |
|---|---|
| First run, fresh project | Full crawl + audit. Baselines established. No regressions surfaced (nothing to compare to). |
| Re-run after a small change | Most routes skipped, perf metrics resampled, only changed routes deeply re-audited. Report mostly empty if nothing new is wrong. |
| Re-run after a refactor | Lots of routes show "hashSignature changed" → re-audited. Baselines still diff for perf. |
| Re-run after a deploy that broke something | Fewer routes (if some now 4xx/5xx) + new findings. Diff vs baseline highlights the regression. |
| Re-run weeks later with stale auth | Run fails or 401s everywhere. Run `tester auth <url>` first. |

## When to reset baselines

Don't reset casually — you'll lose the regression signal. Reset only when:

1. The app deliberately changes performance (e.g. removed a feature). Old baselines aren't comparable.
2. The infrastructure changed (CDN swap, region migration). Compare apples to oranges otherwise.

To reset: drop the project from the API and re-init.

```bash
curl -X DELETE -H "x-api-key: $TESTER_API_KEY" "$TESTER_API_URL/v1/projects/<projectKey>"
tester init <url>
```

## CI integration

The generated Playwright specs at `~/.tester/specs/<projectKey>/` are CI-ready. To gate merges on them:

1. Copy the suite into the user's repo (`cp -r ~/.tester/specs/<projectKey> ./e2e/tester-suite`).
2. Add the storageState path to the user's secrets manager (or generate fresh on every CI run with a service account).
3. Add a workflow step: `npx playwright test --config=e2e/tester-suite/playwright.config.ts`.
4. For perf gating: a separate Lighthouse-CI step is still needed. The tester's perf audit is for local diff, not for CI thresholds (yet).

Don't suggest CI integration unless the user asks. Most users want the local audit loop first.
