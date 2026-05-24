// .tester.config.js — drop this in the root of your repo and check it in.
// Every `tester run` from this directory (or any subdirectory up to 5 levels
// deep) picks it up automatically.
//
// CLI flags always override config values. Use this for repo-level defaults.

export default {
  // Required when you want `tester run` to work without --url.
  url: "https://your-app.example.com",

  // Auth setup. The crawler hits authRefreshUrl before EVERY navigation,
  // keeping short-lived tokens warm. Same-origin only.
  authRefreshUrl: "https://your-app.example.com/auth/refresh",

  // SPA routes the BFS crawler can't discover (client-side routing).
  // Paths are auto-normalized to absolute URLs.
  seedPaths: [
    "/dashboard",
    "/admin",
    "/settings/billing",
    "/reports",
  ],

  // Default audits — comment out to enable.
  // skip: ["performance"],

  // Default viewport. Use "all" + --deep to loop desktop/tablet/mobile.
  viewport: "desktop",

  // Default caps. Override with --max-pages / --max-depth.
  maxPages: 50,
  maxDepth: 3,

  // Phase timeouts (ms). Default 5 min; lower for fast smoke tests, higher
  // for slow SPAs.
  phaseTimeout: 300_000,

  // How long a route stays "fresh" for --stable-only mode.
  freshnessDays: 7,

  // Notable selectors — keyed by route path. Just stored as metadata for now;
  // future versions of the codegen will weight these in generated specs.
  notableSelectors: {
    "/dashboard": {
      newItem: 'button[data-test="new-item"]',
      filters: 'div[role="combobox"]',
    },
  },

  // Known issues — surfaced in the report's preamble for context.
  knownIssues: [
    { note: "POS terminal on /checkout has its own auth — covered by separate run", route: "/checkout" },
  ],
};
