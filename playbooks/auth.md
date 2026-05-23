# Auth playbook

`tester init <url>` opens a real Chromium window, lets the user sign in, and writes the resulting `storageState` (cookies + localStorage) to `~/.tester/projects/<projectKey>/storageState.json`. Every subsequent `tester run` reuses that state automatically.

## Common situations

### Auth expired

Symptom: the run reports lots of 401s, redirects to `/login`, or finds zero authenticated routes when you know there should be more.

Fix: `tester auth <url>` — re-runs the wizard. Old `storageState` is overwritten.

### Two-factor auth / SSO

The wizard waits indefinitely for the user to press Enter. They can complete *any* auth flow — 2FA, SSO redirect to a different domain, magic links via email — before pressing Enter. Just sign in like a normal user, then return to the terminal.

### Auth requires a fresh session each time (no persistent cookies)

If the app sets short-lived (< 1h) session cookies with no refresh mechanism, baseline auth won't survive a 10-minute crawl. Options:

1. Increase the crawl scope so the auth lasts (cut `--max-pages`).
2. Use a long-lived service account / API token instead. Tell the user — there is no programmatic option in the tester for "auth headers per request" yet.

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
