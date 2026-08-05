# AI harness/provider decision

Status: **active**  
Decision date: 2026-07-18  
Review date: after 30 days or 30 scored tasks, whichever is later

## Decision

Use a **native-harness portfolio with a zero-code coordination protocol**, not a custom omni-harness:

1. **Codex is the default coding executor** for the first 30 days.
2. **Claude Code is the challenger and independent reviewer** for difficult refactors, debugging, and tasks where Codex stalls.
3. **Gemini/Google AI Pro is the research, large-input, Google-product, and visual/parallel-work surface**; use Gemini CLI or Antigravity natively rather than attempting to proxy subscription access.
4. **Pi is the programmable API laboratory**, used only when model routing, a custom tool, unattended automation, or prepaid/free capacity creates concrete value.
5. **Copilot is autocomplete/IDE convenience only.** Do not use it as another primary agent during the trial. Keep it only if measured daily completion value exceeds its price and interruption cost.
6. **OpenRouter and paid AI Studio are overflow, experiments, and batch capacity**, not defaults. Put hard spend caps on both.

This is intentionally a portfolio of execution surfaces, not a unified model gateway. Consumer subscription allowances are not interchangeable API capacity, and their official clients contain provider-specific context management, tools, authentication, and product features. The shared layer is artifacts and verification—not an OAuth proxy or a new scheduler.

The optimization target is:

> **verified developer-hours returned per marginal dollar and per minute of human coordination**

Not tokens, benchmark rank, number of models used, or percentage of every subscription consumed.

## Why this wins now

- The local machine already has Codex CLI 0.144.5, Claude Code 2.1.210, Gemini CLI 0.51.0, and Pi 0.80.10. Copilot CLI, Aider, and OpenCode are not installed. A new universal harness would add another context, configuration, and failure surface.
- ChatGPT Plus includes Codex, but current usage is compute/token-sensitive and shared with other agentic features; it should be treated as a valuable, finite allowance rather than “unlimited.” [OpenAI's current plan guidance](https://help.openai.com/en/articles/11369540-using-codex-with-your-chatgpt-plan)
- Claude Pro includes Claude Code, but Claude and Claude Code share the same allowance. Anthropic describes Pro as light coding for small repositories and estimates roughly 10–40 Claude Code prompts per five-hour window; this makes it a poor high-volume router backbone but a useful independent frontier challenger. [Anthropic's current Pro/Max guidance](https://support.anthropic.com/en/articles/11145838-using-claude-code-with-your-pro-or-max-plan)
- Google AI Pro has benefits outside coding—Gemini, Deep Research, Workspace integration, higher Antigravity/Jules limits, storage, Gemini Code Assist quotas, and monthly Google Cloud credit. Its keep/cancel decision must measure that whole bundle, not only Gemini CLI. [Google AI Pro benefits](https://support.google.com/googleone/answer/14534406?hl=en-en)
- Agent quality depends on the harness as well as the model. METR explicitly measures agents with particular scaffolds and finds success strongly related to task length; long tasks should therefore be decomposed and verified rather than handed to a “best model” monolithically. [METR methodology](https://metr.org/time-horizons/) and [its Codex/Claude Code scaffold comparison](https://metr.org/notes/2026-02-13-measuring-time-horizon-using-claude-code-and-codex/)
- The workspace quota audit is stronger evidence than generic price tables: the paid Gemini project used about $0.56 of output tokens in 30 days, while the unbilled project is hard-capped and offers high Gemma request capacity. That supports cheap API experimentation, but not building the daily developer experience around API arbitrage.

## The coordination protocol (v0.1)

For any task large enough to hand between agents, create:

```text
.harness/tasks/<date>-<slug>/
  spec.md       # objective, constraints, allowed paths, acceptance checks
  notes.md      # discoveries and decisions worth preserving
  result.md     # change summary, exact verification, unresolved risks
```

Each repository's `AGENTS.md`, `CLAUDE.md`, and relevant IDE instruction file should point to the active task folder. A task has one writer at a time. A second provider receives `spec.md`, the diff, and verification output—not the first agent's full conversation.

Use a git branch or worktree for autonomous changes. Require a human-reviewed diff before hardware access, deployment, destructive data changes, or merge. Add a lock/lease protocol only after two agents genuinely need concurrent write access.

## Routing table for the trial

| Work | Default | Challenger/fallback | Rule |
|---|---|---|---|
| Normal implementation, tests, repo maintenance | Codex | Claude Code | Stay with default unless blocked for 10 minutes or two failed repair loops |
| Ambiguous architecture or high-risk refactor | Codex plan + execute | Claude independent plan/review | Do not show Claude the first plan before it forms its own view |
| Difficult debugging / stubborn test failure | Claude Code | Codex | Give the challenger symptoms, evidence, and acceptance test—not prior speculation |
| Very large logs, datasheets, PDFs, multimodal or current-web research | Gemini app/Deep Research, then Gemini CLI | ChatGPT research/agent | Return a compact evidence artifact to the coding executor |
| Google ecosystem, Android/Firebase/Cloud tasks | Gemini/Antigravity | Codex | Prefer the native product integration, then verify in repo tooling |
| Inline completion and tiny local edits | Copilot if retained | editor + native agent | Never escalate a tiny edit into a multi-agent task |
| Repetitive classification, summarization, log reduction | Pi + free Gemma first | paid Flash-Lite/OpenRouter | Quality-gate on a saved sample; no silent fallback to expensive models |
| Novel model comparison or custom tool experiment | Pi + OpenRouter | direct provider API | Time-box; graduate only after repeated wins |
| Firmware flashing / physical actuation | Human-controlled wrapper | none | Agent may prepare and test code; human confirms device and command |

Do not route merely because one subscription is near its reset. Finish coherent tasks in one harness when possible; context transfer and re-verification frequently cost more than unused allowance.

## Evaluation method

### Trial design

Run at least 30 real tasks across the actual work mix, including at least three paired benchmark tasks:

- full-stack multi-file change;
- firmware or hardware-adjacent change;
- log/datasheet/research extraction.

For paired tasks, prepare one frozen spec and clean starting commit, then run contenders in separate worktrees. Alternate which harness runs first. Do not reveal the other output. Use identical acceptance checks and stop conditions. Repeat important task classes at least three times; a single win is anecdote.

For everyday tasks, use Codex by default and sample Claude on roughly one in five medium/high-value tasks. Use Gemini for its assigned work rather than forcing every provider through every task. This combines controlled comparisons with ecological validity.

### Hard gates

An attempt scores zero on outcome quality if any required gate fails:

- acceptance tests or explicit acceptance criteria;
- build/typecheck/lint appropriate to the repository;
- no unauthorized file or dependency changes;
- no invented source, silent test deletion, destructive command, or unsafe hardware action;
- diff is reviewable and the repository is left in a known state.

### Scorecard

Record raw measurements first; compute the score afterward. This prevents made-up precision from steering the observations.

| Dimension | Weight | Measurement |
|---|---:|---|
| Verified outcome | 40 | 0 failed, 3 partial, 5 all acceptance gates pass |
| Human time returned | 20 | Baseline estimate minus active prompting, review, repair, and handoff minutes |
| First-pass correctness | 10 | 5 accepted directly; subtract for each repair loop; 0 after two failed loops |
| Change quality | 10 | Blind review of simplicity, maintainability, scope discipline, and tests, 0–5 |
| Reliability | 8 | Completion without crash, quota interruption, context loss, or unrecoverable tool failure |
| Developer experience | 7 | Flow interruption, observability, steerability, and ease of reviewing, 0–5 |
| Marginal cost | 5 | 5 included/free; 4 under $0.10; 3 under $0.50; 2 under $2; 0 at/over $2 |

Normalize each 0–5 rating and calculate:

```text
quality_score = sum(weight * rating / 5)
switching_penalty = min(15, 3 * handoffs + min(6, handoff_minutes / 5))
risk_penalty = 25 for a safety/security violation, otherwise 0
final_score = quality_score - switching_penalty - risk_penalty
```

Keep **human minutes**, **wall-clock minutes**, **subscription surface**, **estimated API cost**, **repair loops**, and **accepted/rejected** as separate columns. Do not convert a monthly subscription into a fictional per-call cost. At review time calculate utilization and accepted outcomes per subscription.

For decision confidence, report medians and the observed range by task class. Do not crown a universal winner from a pooled average if one tool wins firmware and another wins web research. A provider earns a route when it wins by at least 10 points on three comparable tasks or provides a capability the default cannot substitute.

### Minimal log row

```markdown
| date | task | class | surface/model | verified 0-5 | human min | wall min |
| repair loops | handoffs/min | DX 0-5 | marginal $ | accepted | note |
```

## Keep/cancel rules after 30 days

Evaluate bundles, not model reputations.

- **Keep ChatGPT Plus** if Codex is the default/near-default coding surface or ChatGPT's non-code features independently justify it.
- **Keep Claude Pro** if Claude wins a named task class, catches meaningful defects as reviewer, or is the preferred daily harness enough to justify $20. Cancel if it is merely an occasional second opinion reproducible through prepaid API spend for materially less.
- **Keep Google AI Pro** if the combined value of storage, Workspace/Gemini/NotebookLM/Deep Research, Cloud credit, and Google developer tools exceeds its fee. Do not cancel it solely because Codex wins coding.
- **Keep Copilot Pro** only if inline completion/IDE integration saves at least 30–45 active minutes per month or its GitHub-native agent/review workflow is regularly used. Current Copilot plans and accounting are changing; verify the account's actual entitlement before relying on old “300 premium requests” claims. [Current GitHub plan documentation](https://docs.github.com/en/copilot/get-started/plans)
- **Keep prepaid balances capped**, with API use justified by automation or marginal workload—not as insurance against every hypothetical outage.

If two coding subscriptions are statistically and experientially tied, choose the simpler one with the broader non-coding value and cancel the other. If one first-party harness clearly dominates, the recommended steady state is **that single frontier subscription + Google AI Pro if its bundle pays for itself + capped API overflow**.

## When custom harness code becomes justified

Build only the smallest response to observed repeated friction:

1. Add `new-task`/`close-task` helpers after manual folder creation causes errors or avoidance.
2. Add a bounded output reducer after verbose logs repeatedly waste context.
3. Add a scripted Pi executor after the same automatable job occurs at least weekly.
4. Add adapters only after two executors are repeatedly launched by script.
5. Add leases only when two writers genuinely overlap.
6. Add automatic routing only after at least 30 labeled outcomes and only if consulting the table itself is a recurring cost.

No daemon, event-sourced control plane, vector memory, provider proxy, swarm, or weighted capability router is warranted by current evidence.

## Immediate actions

1. Add a budget alert to the `cloud-and-ai` billing account and decide whether the Pi Gemini project should remain paid-tier.
2. Confirm the previously noted plaintext Gemini key is outside the repository and ignored by git.
3. Start the log with the next real task; do not spend the trial building trial infrastructure.
4. At day 15, inspect only for obvious losers and safety problems. Make cancellation decisions at day 30/30 tasks.

