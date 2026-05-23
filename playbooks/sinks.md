# Ticket sinks playbook

Sinks are *opt-in per project*. When configured, every `tester run` automatically dispatches findings above the configured threshold to the external system. Three sinks are built in: GitHub Issues, Linear, Slack.

## Configuring a sink

Interactive (recommended for first-time setup):

```bash
tester sink add --url https://your-app.example.com
```

Non-interactive (CI / scripting):

```bash
# GitHub
tester sink add --url <url> --type github --min-severity high --repo owner/repo

# Linear
tester sink add --url <url> --type linear --min-severity medium --team-id <uuid> --api-key lin_api_xxx

# Slack
tester sink add --url <url> --type slack --min-severity medium --webhook-url https://hooks.slack.com/services/.../...
```

`min-severity` filters which findings dispatch. `medium` is the default sweet spot — low/info noise is suppressed, but real bugs get tickets.

## Sink behavior

### GitHub

- Uses the local `gh` CLI (no separate API key needed; relies on `gh auth status`).
- Creates one issue per finding above threshold.
- Adds labels: `tester`, `tester:<severity>`, plus any extra labels from `--labels`.
- **Dedupes** against existing open issues whose title matches verbatim. Reopening a closed issue with the same title is NOT deduped — closed issues are intentionally re-opened on re-occurrence so you see it.
- If `gh` isn't installed or unauthenticated, the run still succeeds; dispatch fails are logged as warnings.

### Linear

- Uses Linear's GraphQL API. Get your API key at `https://linear.app/settings/api`.
- Maps severity → Linear priority: critical=1, high=2, medium=3, low=4, info=0 (No priority).
- **Dedupes** against open issues in the team with matching title.
- Requires `team-id` (find at `https://linear.app/<workspace>/team/<TEAM>/settings`).

### Slack

- Uses an incoming webhook URL (set up at `https://api.slack.com/messaging/webhooks`).
- Sends ONE summary message per run with up to 10 findings inlined. Beyond 10, the message says "…and N more, see report".
- **No dedupe** — Slack is for notifications, not ticket tracking. If you don't want repeated pings, raise the severity threshold or remove the sink.

## When to recommend a sink

Suggest a sink **only** when the user has indicated they want to track findings outside the markdown report:

- "Can you file these as issues?"
- "I want to be alerted when this regresses."
- "How do I get the team to see these?"

**Don't** proactively recommend sinks. They're easy to misconfigure (wrong repo, wrong webhook, wrong severity threshold) and once configured will spam the destination on every run until removed.

## Removing a sink

```bash
tester sink remove --url <url> --type github
tester sink list --url <url>
```

## Severity threshold guidance

| Project type | Recommended threshold | Why |
|---|---|---|
| Production app | `medium` | Catches user-facing regressions; suppresses cosmetic noise. |
| Marketing site | `high` | Functional/perf bugs only; visual heuristics generate too many low findings on heavily-styled pages. |
| Internal admin | `critical` | Only page-down 5xx and intentional auth failures. |
| New product (pre-launch) | `low` | Everything is interesting when you're still polishing. |

If the user picks `low` and then complains about noise after a few runs, raise to `medium`. Threshold is per-sink, so you can have Slack at `high` (alerts) and GitHub at `medium` (tracking) simultaneously.

## Testing a sink without a full run

```bash
tester sink test --url <url>
```

Dispatches the *latest* run's findings to all configured sinks. Useful right after `sink add` to verify credentials and routing.
