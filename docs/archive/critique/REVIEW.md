# Critique — #RD workspace review (2026-07-18)

## Overall

1. **~15,000 words of planning, zero lines of code.** OMNI-HARNESS-DESIGN.md is already the third rewrite of the same architecture (after old-pi-blueprint.md and small-example.md). The main risk here is not a bad design — it's spending all capacity on the harness instead of the work the harness is supposed to accelerate.
2. **The research inputs are unreliable.** Both "deep research" reports (multi-harness.md, harness-analysis.md) state precise internal details, scores, and product claims that are unverifiable or wrong, and those claims have propagated into later documents. OMNI's "Correct" section catches many, not all.
3. **The docs contradict each other** and no file marks which are superseded: multi-harness says cancel Copilot; OMNI says keep it for autocomplete. small-example builds on INBOX.md; OMNI rejects it. A one-line status header per file ("superseded by X") would fix this.
4. **The only empirical artifact is `quota/gcp-audit.md`** — and it's the best work in the folder. Its key finding (free Gemini Flash = 20 req/day; Gemma = 14,400/day) directly undercuts the swarm/background-agent ambitions elsewhere, but no design doc has absorbed it.

## Per document

**multi-harness.md** — Capability scores (9.5, 9.0…) with no methodology; they're presentation, not measurement. Recommends Claude Cowork's Apple Virtualization sandbox to a Linux user. Several product claims read as hallucinated or blog-grade. The latency/geography section is over-engineered for the actual problem. Marketing prose ("supreme orchestrator of an intelligence mesh") obscures the few real recommendations. Salvage: the MCP server list and the "split autocomplete from reasoning models" point.

**harness-analysis.md** — Dozens of exact implementation claims (WINDOW=100, 13 edit formats, 300KB cap, "built on Claude 3.5") backed by three citations, at least one of which is stale/wrong. Useful as a survey of harness *patterns*; untrustworthy on any specific number. Treat every uncited detail as a hypothesis.

**old-pi-blueprint.md** — Proposes account rotation and "ban evasion" (pi-antigravity-rotator): a ToS violation and the biggest liability in the folder; correctly dropped in OMNI. The "God Proxy" is a single point of failure added before any need is proven. Package names and the "98% context reduction" figure are unverified. Superseded — mark it as such.

**small-example.md** — The "memory bus" requires you to manually copy prompts between browser tabs: the human is the message queue, which is coordination overhead, not automation. INBOX.md/STATE.md as shared mutable files break with concurrent writers (OMNI already corrects this). Roles assigned by brand folklore rather than measurement.

**storage.md** — Hub-and-spoke is sound and survives into OMNI. But PICKUP.md repeats the single-shared-mutable-file mistake, and the claims about which tools honor `.cursorrules`/`.aiinstructions` are unverified.

**token-opt-brainstorm.md** — The recommended packages (pi-code-pruner, liteparse, pi-context-compressor…) are unverified and likely don't exist. "Scorched-earth" TS minification is counterproductive: it destroys prompt-cache stability, line-based evidence, and the comments that carry intent. The doc also contains an LLM-written reply speaking as you. OMNI already rejects most of this; the file has no remaining value beyond history.

**OMNI-HARNESS-DESIGN.md** — The keeper. The Retain/Correct section and the subscription-OAuth boundary handling are genuinely good. Problems: (a) scope — leases, adapters, event logs, schemas, capability-scored routing is weeks of solo work; the router formula's weights (0.30/0.20/0.15…) are invented precision with no data behind them yet; (b) the phase estimates (Phase 1 "3–5 days" for atomic store + leases + worktrees + events) are optimistic by 2–3x; (c) it still carries unverified claims inherited from the research docs. Cut the MVP to: task folder + spec + one Pi executor + verification gates. Add leases and routing only when two concurrent executors actually exist.

**quota/** — Solid, evidence-based, clearly sourced. Unactioned items are the real gap: no budget alert on `cloud-and-ai`, billing still linked to the paid Gemini project, and the plaintext-key note (the `key` file is no longer present in `#RD` — confirm it was moved, not just lost). These three are 15 minutes of work and worth more than any document here.

## What to do next (in order)

1. Create the GCP budget alert; decide on unlinking billing from `gen-lang-client-0054709975`; confirm the key's location.
2. Add a status header to every doc: `superseded-by`, `historical`, or `active`. Only OMNI and the quota audit are active.
3. Build the smallest slice of OMNI Phase 1 that produces a working task handoff — before writing any more architecture.
