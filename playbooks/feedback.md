# Feedback loop playbook

The skill gets better by reading what users say after their runs. Every successful run ends with the same prompt; the answers go to the admin who triages and patches tester.

## When to ask

**Always**, after Phase 8 (Persist learnings) and before Phase 10 (Offer next step). Exception: if the user has already typed something equivalent to "no feedback / skip / nothing to add" in the same conversation, don't re-ask.

## The exact wording (verbatim)

> "Quick one — to help improve tester itself (not project-specific):
>
>   create report of problems that tester did not catch, problems tester itself has, and how we can enhance tester. How can we make it go directly deep and not encounter those issues?
>
> Helpful angles: what tester missed that you caught yourself, false positives that wasted your time, friction in the workflow, what would have made the run go deep from the start. Skip if you have nothing — but if anything is fresh in your head, please dump it."

The wording matters because it forces project-agnostic answers. "What was wrong with this scan?" tends to surface project-specific complaints. The current wording shifts focus to **the tool itself**.

## What to do with the response

| User response | Action |
|---|---|
| Substantive text (≥ ~40 chars) | Send through `tester feedback --source skill --message "<verbatim>"` |
| "no", "skip", "nothing", "all good" | Don't send anything. Move on. |
| "actually I noticed X also" (extending earlier comments) | Concatenate with what they said earlier, send once at the end. |
| Long mixed message (some project-specific, some about tester) | Send the whole thing — server auto-tags topics; admin sees both. Don't try to filter. |

## What NOT to do

- **Don't invent feedback.** Never send a "the skill worked great!" message just to keep the channel warm.
- **Don't editorialize.** Send the user's words verbatim. They're the signal — your summary isn't.
- **Don't ask twice in one session.** One ask per run.
- **Don't bug them after a `--quick` run.** Quick runs are smoke tests; the user knows it's shallow. Save the prompt for `standard` and `deep`.

## Auto-tagging on the server

The server runs simple regex topic detectors on every feedback entry:

| Topic | Triggers |
|---|---|
| `auth` | "auth", "session", "token", "login", "cookie", "jwt" |
| `false-positive` | "false positive", "noise", "wrong", "misleading" |
| `missed` | "missed", "didn't catch", "should have caught", "skipped" |
| `performance` | "slow", "timeout", "hung", "stuck", "crashed", "oom" |
| `visual` | "contrast", "overflow", "tiny text", "gradient", "hidden" |
| `crawl` | "crawl", "seed", "route", "SPA", "navigation" |
| `depth` | "too shallow", "deeper", "missing routes" |
| `report` | "report", "html", "share link", "screenshot" |
| `config` | "config", ".tester.config", "seedpath" |
| `ux` | "prompt", "wizard", "asked again", "friction" |

You don't manually tag — let the server do it. If the regex misses, the admin sees the raw text anyway.

## How the admin reads feedback

- Live inbox: dashboard's "Feedback" tab.
- API: `GET /v1/feedback` with `x-admin-token`. Filters: `?topic=missed&triaged=false`.
- 7-day digest: `GET /v1/feedback/digest` returns counts per topic + 3 example excerpts each.

## The improvement loop in practice

1. User says "tester missed a 500 on /api/foo because it never crawled it"
2. Auto-tagged as `crawl + missed`
3. Admin sees pattern: 3 different users said the same thing this week
4. Admin patches the BFS to also try `/api/*` for sites with `api` subdomain
5. Next release notes: "Fix from feedback: API routes now auto-seeded"

The point of the loop is YOUR (Claude's) wording captures the user's complaint accurately enough that the admin can act on it. Verbatim quotes always.
