# Better approaches — constructive follow-up to REVIEW.md

The critique's core finding was: too much architecture, too little evidence. Every recommendation below follows one rule — **build only what removes friction you have already observed, and let evidence, not documents, grow the system.**

## 1. Invert the process: task-first, harness-second

All three architecture rewrites designed coordination machinery before doing any coordinated work. Invert it:

- Pick the three benchmark tasks OMNI Phase 0 already names (full-stack refactor, datasheet/log extraction, firmware change) and **do them now, manually**, using whichever surfaces feel right.
- Keep a running `friction.md`: every time you copy-paste between tools, lose context, redo work, or wonder "which model should do this" — one line.
- After the three tasks, sort the log by frequency. The top item is the first thing the harness automates. Everything else waits.

This replaces speculation about what a harness needs with a measured backlog. Expect the real pain points to be mundane (context re-explanation, result handoff) rather than the exotic ones the docs solve (leases, routing formulas, event sourcing).

## 2. Harness v0.1: a folder convention, not a control plane

The minimum protocol that delivers most of OMNI's value:

```text
.harness/
  tasks/
    2026-07-18-gyro-driver/
      spec.md       # goal, acceptance criteria, allowed paths
      notes.md      # running context: decisions, findings, current state
      result.md     # what was done, how verified, what's unresolved
  architecture/     # durable project knowledge (keep from OMNI §6)
```

Plus thin pointers: `AGENTS.md`, `CLAUDE.md`, `.github/copilot-instructions.md`, each ~5 lines, saying "read the active task folder in `.harness/tasks/` before acting."

What this deliberately omits, and when to add it back:

| Omitted | Add when |
|---|---|
| Leases, locking | Two agents actually write concurrently (as a solo dev driving one autonomous task at a time, this may be never) |
| `events.jsonl`, SQLite index | You can't answer "what happened on task X" from the task folder itself |
| Adapter interface | A second executor is scripted (not just used interactively) |
| JSON schemas, `harness` CLI | Hand-editing the folder demonstrably causes errors |
| Daemon, VS Code panel | Never, until the CLI is a proven bottleneck |

v0.1 is zero lines of code — it's a convention. v0.2 is a ~200-line script (`new-task`, `list-tasks`, `close-task`). If you enjoy building the full Deno control plane later, fine — but it should be earned by v0.1's failures, not by a document.

## 3. Routing: a lookup table plus a decision log

Replace the weighted scoring formula (which needs data that doesn't exist) with:

1. A static table in `.harness/routing.md` — task type → default surface, one alternative. Seed it from OMNI §8.3, which is already sensible.
2. An append-only log: date, task, surface chosen, accepted/rejected, one-line note. Ten seconds per task.

After 30 days the log *is* the measured-quality data OMNI's router wants. Most likely outcome: the table stabilizes at 4–5 rows and you never need automated routing at all. If a pattern emerges ("Codex keeps losing on firmware"), edit the table. Automate routing only if you find yourself consulting the table so often it hurts — which is the evidence the formula lacked.

The same log answers the subscription question. The 30-day keep/cancel evaluation in OMNI §13 needs no infrastructure — just this log. **Cancelling one $19–20 subscription saves more than any token optimization in these documents.**

## 4. Research hygiene: claims must be verified before they're load-bearing

The workspace got polluted because LLM research output was treated as fact. Cheap fix, three rules:

1. **Status header on every doc**: `status: active | superseded-by: <file> | historical`. Move superseded docs (old-pi-blueprint, small-example, token-opt-brainstorm, multi-harness) to an `archive/` folder. Keeps history, removes ambiguity about what's current.
2. **Verification ladder for claims**: anything you will act on (a package name, an API limit, a product capability) gets checked against the primary source first — install it, call it, read the vendor doc. Everything else stays labeled hypothesis. The quota audit is the model here: every number in it was pulled from live systems, which is exactly why it's the only doc that survived review intact.
3. **One claim, one place.** When a fact is verified (e.g., "free Gemini Flash = 20 req/day"), it lives in one file others link to — not restated with drift in four documents.

## 5. Spend the quota findings — they're the real asset

The audit's findings are actionable today and change the design:

- **Gemma free tier (14,400 req/day)** is the correct backbone for every high-volume/low-stakes job the docs assign to "cheap OpenRouter models": classification, log summarization, commit-message drafts, notes compaction. Quality-check it on your actual tasks first (the audit already flags this), but it's free and enormous.
- **Search grounding, 1,500 req/day free** — that's a free web-search tool for Pi. Register it as a provider tool; it likely replaces a paid search dependency.
- **Never build scheduled automation on free Gemini Flash** (20 req/day) — any nightly job exhausts it instantly. Paid Flash-Lite at ~$0.40/M output is the fallback where Gemma's quality fails.
- **Do the hygiene now**: budget alert on `cloud-and-ai`, decide the billing unlink for `gen-lang-client-0054709975`, confirm where the plaintext key went. Fifteen minutes, closes every open item in the audit.

## 6. Token economics: optimize the big levers, ignore the small ones

The token-opt doc optimized in the wrong order. The actual hierarchy:

1. **Scope** — a task folder with a tight spec means the model reads three files, not the repo. This is 10–100x, and v0.1 already provides it.
2. **Prompt caching** — stable system/context prefix, dynamic content last. Requires *not* minifying, because cache hits need byte-identical prefixes.
3. **Bounded outputs** — truncate/reduce noisy tool output (test logs, builds). Pi supports this natively; a reducer keeping exit code + failures + tail is ~50 lines.
4. **Model choice** — cheap model for mechanical work beats any compression of an expensive model's input.
5. Comment stripping, minification, "prompt compression" — negative value. Deletes intent, breaks caching, corrupts line-based evidence. Already correctly rejected by OMNI; don't revisit.

## 7. Safety: OS-level boundaries instead of a policy engine

For the hardware risk the docs worry about, deterministic beats declarative:

- Serial/flash access via a **wrapper script** that prints device, port, and command, then requires interactive confirmation — agents get the wrapper, never raw `avrdude`/`esptool`/`openocd`.
- Autonomous runs happen in a **git worktree** (`git worktree add .worktrees/<task>` — a 20-line helper, adopt immediately) and, if desired, a container without device access. USB/serial simply isn't reachable from the autonomous context; no policy DSL needed.
- Review the diff before merging. That single human gate covers most of OMNI's verification pipeline until real gates (tests, lint) are wired into a `verify` script per project.

## 8. A concrete two-week plan

| When | What |
|---|---|
| Day 1 | GCP hygiene (§5). Archive superseded docs, add status headers (§4). |
| Day 2 | Write `.harness/` convention + pointer files in one real project (§2). Seed `routing.md` (§3). |
| Days 3–10 | Do the three benchmark tasks through the convention. Keep `friction.md` and the routing log. No harness code beyond the worktree helper and one output reducer. |
| Days 11–12 | Try Gemma via the unbilled project on the mechanical subtasks that came up; note quality. |
| Day 13 | Review logs. Build the single most-demanded automation (likely `new-task`/`close-task` scripting). |
| Day 14 | First pass on subscription keep/cancel from the routing log. |

End state: the same goals as OMNI-HARNESS-DESIGN, reached by shipping a convention in days and letting two weeks of real usage decide what deserves engineering — instead of estimating five phases up front.
