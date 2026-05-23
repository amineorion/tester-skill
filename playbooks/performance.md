# Performance playbook

The performance audit captures Core Web Vitals via a real browser (Playwright + Chromium), per route. The numbers are *lab* measurements — they're a useful early signal but field RUM data is the source of truth for shipped sites.

## Metrics + thresholds

| Metric | Good | Needs improvement | Poor | Notes |
|---|---|---|---|---|
| **LCP** (Largest Contentful Paint) | ≤ 2500ms | 2500–4000ms | ≥ 4000ms | Time until the largest above-the-fold element renders. Usually a hero image or h1. |
| **INP** (Interaction to Next Paint) | ≤ 200ms | 200–500ms | ≥ 500ms | Replaces FID in 2024. Measures responsiveness across the *entire* session, not just first input. |
| **CLS** (Cumulative Layout Shift) | ≤ 0.1 | 0.1–0.25 | ≥ 0.25 | Unitless. Sums up layout shifts after page load. |
| **TTFB** (Time to First Byte) | ≤ 800ms | 800–1800ms | ≥ 1800ms | Pure server-side latency. |

A finding is emitted when a metric is in the "needs improvement" or "poor" band.

## Regression detection

For each metric, the run compares to the most recent baseline stored in MongoDB. If the new value is **>20% worse** than baseline, a regression finding is emitted at:

- **medium** severity for +20–50% regression
- **high** severity for +50%+ regression

The first run for a project establishes baselines without emitting regression findings. Every subsequent run compares against the *latest* stored baseline.

## How to read evidence

The finding includes `diff: { before, after, deltaPct, metric }`. If you see `LCP regression on /pricing: +85%`, the user shipped something that meaningfully slowed down that page.

## Fix recipes

- **LCP regression**: usually a new image without `fetchpriority="high"`, an unoptimized font, or a render-blocking script added in the head. Check the new commits since the previous run.
- **INP regression**: a new event handler that's doing too much synchronously. Look for `useEffect` chains that fire on every interaction, heavy `JSON.parse`, or unmemoized React re-renders.
- **CLS regression**: an element without explicit width/height. Hero images, embedded videos, and late-loading ads are the top culprits. Set `aspect-ratio` or width/height.
- **TTFB regression**: backend issue — DB query, cold start, or missing cache. The tester can't fix this directly; surface it to the user.

## Caveats — lab vs field

The 2025 Web Almanac found 52% of mobile sites that pass Lighthouse in the lab fail real Core Web Vitals in the field. INP is the biggest blind spot. The tester emulates desktop Chrome on a fast network — it will under-report problems users on slow phones experience. If the user cares about field data:

1. Suggest they wire up `web-vitals` to send to their analytics.
2. The tester's perf findings are still useful as an early-warning signal — they catch the *catastrophic* regressions before users do.
