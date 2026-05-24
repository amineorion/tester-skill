# Auth playbook

`tester init <url>` opens a real Chromium window, lets the user sign in, and writes the resulting `storageState` (cookies + localStorage) to `~/.tester/projects/<projectKey>/storageState.json`. Every subsequent `tester run` reuses that state automatically.

## Common situations

### Auth expired

Symptom: the run reports lots of 401s, redirects to `/login`, or finds zero authenticated routes when you know there should be more.

Fix: `tester auth <url>` — re-runs the wizard. Old `storageState` is overwritten.

### Two-factor auth / SSO

The wizard waits indefinitely for the user to press Enter. They can complete *any* auth flow — 2FA, SSO redirect to a different domain, magic links via email — before pressing Enter. Just sign in like a normal user, then return to the terminal.

### Auth requires a fresh session each time (no persistent cookies)

If the app sets short-lived (< 1h) session cookies, the crawl may outlive the session. Options (in order of preference):

1. **`--auth-refresh-url`** — pass the URL the SPA calls for token refresh (e.g. `--auth-refresh-url https://your-app/auth/refresh`). The crawler hits it before every navigation so the session stays warm. This is the canonical fix.
2. Reduce crawl scope so the auth lasts (cut `--max-pages`).
3. Use a long-lived service account / API token instead. Save the rotation URL to learnings so future runs use it automatically.

### When all your findings are about /login (the post-mortem anti-pattern)

**Symptom:** The report has ~100 visual findings, all suspiciously similar. Screenshots all show the same login hero. CLS regression appears on every route. "7 unclickable interactive elements" repeated 60 times.

**Cause:** Mid-crawl auth loss. The session rotated, every navigation got 401 + SPA redirected to `/login`, every audit ran against the login fallback. The report is garbage.

**How to detect (v0.2+ does it automatically):**
- The crawler watches for 401 responses and final-URL matching `/login|/signin|/auth` on the redirect.
- Affected routes get a `type=auth severity=high` finding ("Auth lost while crawling /foo") and ARE NOT audited further.
- The header line should say `N auth-lost` non-zero.

**If auth was lost on every page:**
1. Re-run `tester auth <url>` to refresh `storageState.json`.
2. Pass `--auth-refresh-url` if the app uses `/auth/refresh`.
3. Re-run the audit. Compare the new run's `auth-lost` count — should be 0.
4. If still > 0: the issue is server-side. Either the token TTL is too short (lengthen it server-side) or the user agent is being blocked (whitelist `tester-bot/0.1`).

### Auth modal blocks the page on every load

Some apps wrap every route in a "click to continue" modal even when logged in. The crawler will get stuck. Fix: in the wizard, dismiss the modal first, *then* press Enter. The dismissal state should persist in localStorage if the app is well-behaved.

## storageState contents

The file at `~/.tester/projects/<projectKey>/storageState.json` looks like:

```json
{
  "cookies": [
    {
      "name": "session_id",
      "value": "...",
      "domain": ".example.com",
      "path": "/",
      "expires": 1735689600,
      "httpOnly": true,
      "secure": true,
      "sameSite": "Lax"
    }
  ],
  "origins": [
    {
      "origin": "https://example.com",
      "localStorage": [
        { "name": "auth_token", "value": "..." }
      ]
    }
  ]
}
```

## What NOT to do

- Don't ask the user for their password and try to type it in headlessly. The wizard always runs headed so the user controls the flow.
- Don't paste a `storageState.json` from another machine. Cookies are origin-bound and CSRF tokens may be tied to user-agent. Capture fresh on each machine.
- Don't commit `storageState.json` to git. It contains live session tokens. The `.gitignore` in the tester repo excludes it; preserve that exclusion in user repos too.
