# Functional audit playbook

The functional audit walks every discovered route and flags things a real user would experience as broken. It does **not** try to verify business logic — it verifies that the surface area responds.

## Findings emitted

| Title prefix | Trigger | Default severity | When to override |
|---|---|---|---|
| `Server error: HTTP 5xx` | Page returns 500–599 | critical | Never lower — 5xx is always production-visible. |
| `Client error: HTTP 4xx` (not 404) | Page returns 4xx and isn't 404 | high | Lower to medium if the route is a known opt-in admin page the crawler accidentally hit. |
| `Broken link: 404` | Internal link → 404 | medium | Raise to high if the broken link is in the global nav or footer (every user hits it). |
| `N console error(s)` | JS console errors during load | low/medium/high (by volume) | Raise if any error mentions `TypeError` on a render path. |
| `N failed API request(s)` | 5xx or unexpected 403 during page load | high | Lower to medium if it's a third-party widget known to be flaky. |
| `Form with no action` | `<form>` missing `action` | low | Usually intentional (client-side handler). Suppress unless it's on a critical conversion page. |
| `Failed to load <path>` (crawl) | Navigation timeout or net::ERR | medium | Raise to high if the path is in the site nav. |

## How to read evidence

- `screenshotPath` — what the user saw when the page loaded. Always inspect before suggesting a fix.
- `consoleLogs` — first 10 errors. If you see a stack trace pointing into the user's bundle, that's a real bug. If it's a `chrome-extension://` error, ignore.
- `networkErrors` — list of `{method, url, status}`. Group by `url` to see if it's one endpoint or many.

## Fix recipes

- **5xx**: read the server-side log for the request. The CLI doesn't have it — ask the user.
- **404 on internal link**: grep the codebase for the broken path. It's usually a typo in a link or a renamed route that left an old reference.
- **Console errors**: open the file at the top of the stack. Usually a null-deref or a missing prop.
- **Failed API requests**: look for an auth issue (storageState may have expired — run `tester auth <url>`) before assuming the endpoint is broken.

## What NOT to do

- Don't suggest disabling the rule. If something is genuinely intentional (e.g. an admin route that 401s to anonymous), add it to the user's monitoring exclusions outside this skill — there is no exclusion list in the tester itself.
- Don't bundle multiple findings into one fix. Each finding has its own evidence; reasoning across them risks missing a separate root cause.
