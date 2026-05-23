# Dashboard playbook

The dashboard at `$TESTER_API_URL` (default `https://api.tester.dev` in prod, `http://localhost:4000` locally) gives the user a shareable HTML report with screenshots after every run that's uploaded with `--share`.

## When to recommend dashboard

- The user wants to share findings with a teammate / dev / stakeholder
- They want to keep a history of runs across machines
- They explicitly say "upload" or "dashboard" or "share link"

## When to recommend local-only

- The app being tested has sensitive data visible in screenshots (CRM, healthcare, internal admin)
- The user is in a regulated environment (financial / medical / gov)
- The user explicitly says "don't upload" or "keep local" or "private"
- Air-gapped or offline scenarios

## What gets uploaded with `--share`

| Asset | Uploaded? |
|---|---|
| `runId` + timestamps | yes |
| Findings (title, severity, description, repro steps) | yes |
| Routes discovered | yes |
| Performance metrics + baselines | yes |
| Screenshots | yes — stored as binary in MongoDB |
| Source code of the user's app | **NO — never** |
| `storageState.json` / auth tokens | **NO — never** |
| Network response bodies | **NO** (only status codes + URLs) |

The storageState stays in `~/.tester/projects/<projectKey>/storageState.json` no matter what.

## Sign-in flow (one time)

```bash
./scripts/run-tester.sh signin <email>
# → "Code sent to <email>. Paste it back here:"
# → User pastes 6-digit code
# → Session token saved to ~/.tester/auth.json (30 day TTL)
```

After that, every `--share` run just works.

## Sharing a run that was originally local

```bash
./scripts/run-tester.sh share --url <url> --run <runId>
```

Uploads retroactively. Useful when the user finished a local run and *then* decided to share.

## Revoking a share link

Share links default to 30-day expiry. To kill a link early, the user opens the dashboard, finds the run, and clicks "revoke". CLI flag also: `tester share revoke --token <shareToken>`.
