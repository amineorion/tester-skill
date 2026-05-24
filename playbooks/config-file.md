# Per-project config file

Drop `.tester.config.js` (or `.mjs`, `.cjs`, `.json`) in the root of the target's repo. Every `tester run` from anywhere in that repo picks it up automatically.

## Shape

```js
// .tester.config.js
export default {
  url: "https://your-app.example.com",
  authRefreshUrl: "https://your-app.example.com/auth/refresh",
  seedPaths: ["/admin", "/settings"],
  skip: [],
  viewport: "desktop",
  maxPages: 50,
  maxDepth: 3,
  phaseTimeout: 300000,
  freshnessDays: 7,
  notableSelectors: { "/dashboard": { newItem: 'button[data-test="new"]' } },
  knownIssues: [{ note: "POS has separate auth", route: "/pos" }],
};
```

For JSON: same shape, no `export default`, no functions.

## Precedence

CLI flags > config file > built-in defaults.

| Source | Wins when |
|---|---|
| `--max-pages 100` | always |
| config `maxPages: 50` | no `--max-pages` passed |
| built-in 30 | neither set |

The config is loaded once at `tester run`. To debug what got merged, run with `LOG_LEVEL=debug`.

## Discovery rules

Search order from the cwd:
1. `--config <path>` if passed (explicit, no search)
2. `.tester.config.js` / `.mjs` / `.cjs` / `.json` in the cwd
3. Walk up to 5 parent directories

Stop at the first hit.

## When to use config vs CLI flags

| Use case | Where to put it |
|---|---|
| Repo-wide defaults (every dev uses same crawl scope) | config file, check in |
| One-off override for this run | CLI flag |
| Auth refresh URL (rarely changes) | config file |
| Seed list of SPA routes (stable per project) | config file |
| `--share` choice | CLI flag (or sticky in `prefs.json`) |

## Pairing with sticky prefs

`tester prefs --url <url> --json` returns the user's last-chosen `depth` / `destination` / `viewport`. The skill checks both:
- `.tester.config.*` for repo-level defaults
- `~/.tester/projects/<key>/prefs.json` for user-level last-choice

If both set viewport, prefs wins (it's the most recent user signal). CLI flag beats both.

## Caveats

- `authRefresh` / `authSignin` callbacks (functions) are accepted in TS/JS configs but NOT used yet — the CLI only consumes the URL form via `--auth-refresh-url`. Wire-up is planned.
- The config file is loaded with dynamic `import()`. If the file has syntax errors, the run aborts with a useful message — it never silently falls back to defaults.
- Do **not** put secrets in this file. Auth tokens belong in `~/.tester/projects/<key>/storageState.json` (gitignored), not in the repo-checked-in config.
