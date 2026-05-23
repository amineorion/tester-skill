# Visual / UX playbook

The visual audit runs lightweight DOM heuristics — it's not a pixel-diff and it's not full a11y. It catches the things that look like obvious mistakes or AI-slop.

## Findings emitted

| Finding | Trigger | Default severity |
|---|---|---|
| Horizontal overflow | document scrollWidth > viewport + 8px | medium |
| N elements overflow their container | per-element rect.right > document width | low |
| N images missing alt text | `<img>` with no/empty `alt` | low |
| N text elements below 11px | computed font-size < 11px with > 4 chars | low |
| Excessive font families | > 4 distinct primary fontFamily values | low |
| Unclickable interactive elements | button/link with width or height < 4px | medium |
| Overlapping fixed/sticky elements | two `position:fixed` rects overlap by > 100px² | low |
| Low-contrast text | sampled element with WCAG contrast ratio < 4.5:1 | low |

## What this is *not*

- Not a full WCAG audit. Use a real axe-core run for that (planned for v2).
- Not a design-system check. Won't flag inconsistent spacing, off-grid alignment, or off-brand colors.
- Not a visual regression test. There's no pixel diff against a baseline screenshot.

## Severity overrides

- **Horizontal overflow on a marketing page**: keep as medium — first impressions.
- **Horizontal overflow inside an admin panel**: lower to low — power users adapt.
- **Tiny text in a footer**: low → info. Tiny text in a settings form: medium.
- **Low contrast on disabled controls**: legitimately needs to be low contrast (visual signal). Suppress these.
- **Missing alt on decorative icons**: if the codebase uses `aria-hidden="true"` instead, that's correct. Lower to info.

## Fix recipes

- **Horizontal overflow**: find the element with `rect.right > documentWidth` in DevTools. Common causes: a long unbroken string (`word-break: break-word`), a fixed-width child inside a percentage-width parent, or a missing `overflow-x: hidden` on the body for a transform animation.
- **Missing alt**: if the image is decorative, use `alt=""` (empty, not missing). Otherwise write a real description.
- **Tiny text**: bump to ≥12px or remove if it's dead content.
- **Low contrast**: bump the darker color until contrast ≥ 4.5:1 for body text or ≥ 3:1 for large text (24px+).
- **Overlapping fixed elements**: usually a sticky header AND a modal both fixed at top:0. Increase z-index on the modal, or use `position: absolute` once the modal is open.

## AI-slop indicators

The "excessive font families" finding is a soft AI-slop tell. Other things that signal slop (manually look for):

- Generic placeholder text ("Lorem ipsum", "Your text here")
- Gradient backgrounds on every section
- Stock photo aesthetic clash (mixing flat illustrations with photorealistic images)
- "Section / Section / Section" layouts with no clear hierarchy

These aren't auto-detected. If you spot them while inspecting the screenshots, mention them — but as observations, not findings.
