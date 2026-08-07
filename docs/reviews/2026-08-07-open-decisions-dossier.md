# Open Decisions Dossier — 7 August 2026

Point-in-time findings. This document records evidence and options; it decides nothing and changes nothing. When a decision here is taken it moves to `docs/02-architecture-decisions.md` as an ADR, the plan is updated to match, and the entry below is struck through with a pointer to the ADR.

Its purpose is to make each decision cheap to take later: every entry states what is actually undecided, what was found on 7 August 2026, what the options cost, and the single observation or test that would settle it. Entries are ordered by when they must be decided, not by importance.

Deadline column: the version whose work cannot start or cannot be accepted without the decision. Versions refer to the re-sequenced `ROADMAP.md` (execution layer V0.1–V0.6, agentic layer V0.7–V1.0).

## Summary

| ID | Decision | Deadline | Blocking? |
| --- | --- | --- | --- |
| D1 | Provider route for the parent model | V0.1 | Yes — the pin is part of the frozen prefix |
| D2 | Parent model class: cheap-fast or strong | V0.1 | Yes |
| D3 | `UserQuestionV1` adapter placement and schema extent | V0.1 | Yes |
| D4 | Uninspected acceptance of `@juicesharp/rpiv-config` / `rpiv-i18n` | V0.1 | Yes |
| D5 | CodeGraph's actual integration surface | V0.2 | **Decided — ADR-045**; residual choice of Pi-native surface is measured at V0.2 |
| D6 | RAG engine | V0.2 | Yes |
| D7 | Editing-safety owner (hashline) | V0.2 | No — trial |
| D8 | Deferred tool loading availability on the pinned model | V0.3 | Yes |
| D9 | Shell-output compression: RTK, LeanCTX narrow, or neither | V0.4 | No |
| D10 | Web search and fetch owner | V0.6 | Yes — parity gap |
| D11 | Image and screenshot input | V0.6 | Yes — parity gap |
| D12 | Editor integration: ACP agent, VS Code Remote, or terminal-only | V0.6 | Yes — parity gap |
| D13 | ACP client for foreign workers | V0.5 | No |
| D14 | MCP proxy implementation | V0.5 | Yes |
| D15 | Broker frontend: `pi-interactive-shell` or tmux | V0.5 | Yes |
| D16 | Credential class per foreign profile | V0.5 | Yes |
| D17 | Containment engine, and whether isolation precedes the switch | V0.7 | No |
| D18 | Todo tool trial | V0.4 | No |
| D19 | ADR numbering defects in `docs/02` | Any | No |

## A. Decisions blocking the baseline harness

### D1 — Provider route for the parent model

**Undecided:** whether the parent Pi session reaches its model through the direct `openai-codex` provider or through `openrouter`.

**Found:** both are authenticated on the host, along with `gemini`. The direct route was verified end to end (`pi --model openai-codex/gpt-5.6-luna:medium`). The host's own `models-store.json` records for `gpt-5.6-luna`: context 272,000, max output 128,000, $0.20/$1.20 per Mtok, cache read 0.1×, cache write 1.25×, with a doubling tier above 272k. OpenRouter reaches the same models with a 1.05M context window. Published list pricing for Luna was $1/$6 before an announced 80% reduction; the host catalog's $0.20/$1.20 is consistent with the reduction having landed.

**Costs:** the route determines which usage fields exist, and cache verification (`10` §10.3, ADR-035) requires separate uncached / cache-read / cache-write counters. A route that reports one combined number cannot satisfy the V0.3 cache regression gate. The larger OpenRouter window is worth little if the parent is kept below the compaction threshold by design, and adds a second party to the request path.

**Settles it:** one scripted two-request session per route, reading the raw usage object, asserting three distinguishable token fields and a non-zero cache read on request two.

### D2 — Parent model class

**Undecided:** whether the parent runs the cheap-fast tier (`gpt-5.6-luna`, as currently requested) or a stronger model, with the cheap tier reserved for children.

**Found:** the design gives the parent unusual responsibilities — it owns task state, commit finalization, delegation decisions and the interpretation of every gate report — while children are bounded, schema-constrained and re-runnable. The economics run the other way from the intuition: the parent's prefix is cached and its turns are few relative to children's, so the parent is the cheapest place in the system to buy quality.

**Costs:** a weak parent produces bad envelopes, and bad envelopes are paid for by every child that consumes them. A strong parent raises a per-turn cost that caching already suppresses.

**Settles it:** run the V0.4 bootstrap task with each parent class and compare accepted-first-time rate and total run cost, not parent cost.

### D3 — `UserQuestionV1` adapter placement and extent

**Undecided:** where the adapter between our `UserQuestionV1` contract and `@juicesharp/rpiv-ask-user-question` lives, and whether `description` and `preview` extend the schema.

**Found (V0.1-T4 review):** upstream is a synchronous batch of 1–4 questions with no `sensitivity`, no `status` and no deadline. The rule that a `credential`-class question must never reach a questionnaire that echoes typed text can only be enforced in our adapter, since upstream has no concept of it.

**Costs:** placing the adapter in `pi-session-control` couples question policy to session compilation but gives it the frozen manifest; placing it in its own package keeps it reusable by the broker and the future IM gateway, which will need the identical relay. Extending the schema adds fields the current upstream cannot render.

**Settles it:** decide the second consumer first. If the broker's question relay (V0.5) and the gateway's (V0.9) use the same contract, the adapter is its own package.

### D4 — Uninspected RPIV dependencies

**Undecided:** whether `@juicesharp/rpiv-config` and `@juicesharp/rpiv-i18n` are accepted without inspection.

**Found:** `@juicesharp/rpiv-ask-user-question` is at 2.4.0. The RPIV monorepo is actively maintained, young, single-maintainer, and has previously had dependency-layout problems. The extension-trust rule is unambiguous: a Pi package executes with the privileges of the Pi process, so accepting a transitive dependency uninspected is accepting executable code uninspected.

**Costs:** inspection is two tarball reads on the same terms as the V0.1-T4 review. Acceptance without inspection saves an hour and is the only entry in the current stack that would breach the stated trust rule.

**Settles it:** read the two tarballs. This is cheaper than deciding.

## B. Decisions blocking code intelligence and validation

### D5 — CodeGraph's actual integration surface — **DECIDED, ADR-045**

**Was undecided:** whether CodeGraph is consumed through the `@vndv/pi-codegraph` bridge, through its own MCP server, or both — and whether the rule "never duplicate CodeGraph through MCP" survives contact with how CodeGraph ships.

**Found, and it settled the question:** the engine (`@colbymchenry/codegraph` v1.1.0, 23 June 2026, ~54k stars) keeps a per-project SQLite/FTS5/WAL index at `.codegraph/codegraph.db` and **shares one background server across sessions over a local socket**, with one debounced OS-level watcher; concurrent clients attach through it and WAL keeps readers off the writer's back. `@vndv/pi-codegraph` 0.1.10 is a **thin proxy** — eight named Pi tools (`codegraph_search`, `_node`, `_files`, `_callers`, `_callees`, `_impact`, `_explore`, `_status`), each forwarding one request to `codegraph serve --mcp`, starting no watcher and no index, requiring the project to be pre-indexed with `codegraph init -i`. The engine's own MCP surface defaults to a single `codegraph_explore` tool with the rest opt-in via `CODEGRAPH_MCP_TOOLS`.

So the duplicate-index and duplicate-watcher harm the rule protected against **does not arise from a second consumer** — only from a second engine. ADR-045 splits the rule into one index and one daemon per repository, one graph surface per session, and one authority for graph questions, and makes graph access a declared profile grant. Foreign workers receive the MCP server when their phase needs the graph, exactly as the plan already permitted for the Pi Lens mirror.

**One smaller question remains open, deliberately:** which Pi-native surface to register — the bridge's eight named tools or the engine's single `codegraph_explore`. Eight schemas in the frozen prefix against one is a real cost; eight operations mapping onto the routing policy is a real benefit. The capability compiler decides from measured prefix cost and routing traces at V0.2, not from preference. The bridge's youth is R-103, with a pre-decided zero-code fallback.

**Rejected along the way:** restricting the graph to Pi processes and routing all code-aware work to native children. It is coherent — native children inherit the full surface and can already be routed to another vendor's model by `modelClass` — but it makes every delegated phase structurally weaker at exactly the work worth delegating, and the engine's design means it buys nothing. What it did clarify is *when* a foreign CLI is worth spawning at all, which is now `12` §4.1: for the vendor's harness, not the vendor's model.

### D6 — RAG engine

**Undecided:** which engine backs `knowledge_search` / `knowledge_get`. The plan specifies the contract, the result shape, the bounding rules and the ownership boundary against CodeGraph and Hermes — and names no engine.

**Found:** the local-first pattern has converged on SQLite with FTS5 plus `sqlite-vec`, hybrid BM25 and vector retrieval with reciprocal-rank fusion, and local GGUF embedding models. `qmd` (Hermes Agent's document indexer) implements exactly that and stores its index at `~/.cache/qmd/index.sqlite` with no cloud dependency. LanceDB and Chroma are the strongest embedded alternatives; the heavier frameworks bring orchestration this design already owns.

**Costs:** the corpus is this repository's `docs/` — currently about 5,500 lines of prose. At that size an embedding-free FTS5 index answers most queries, and the entire question is whether semantic retrieval earns its dependency. Adopting `qmd` also imports a component from Hermes, whose coordinator role is deliberately deferred; using its indexer is not adopting its agent.

**Settles it:** build the two-call broker against FTS5 first and measure retrieval failures on twenty real questions. Add vectors only against a recorded miss list — this is the same discipline applied to every other optimization here.

### D7 — Editing-safety owner

**Undecided:** whether to trial a hashline edit package in `trusted-local` at all.

**Found:** the decision is already framed (ADR-016) and gated on traces showing stale-edit failures. Nothing new was found. The relevant change is that Pi Lens now owns post-edit diagnostics, which catches a different failure than stale reads and partially reduces the motivation.

**Settles it:** the Stage 6 baseline's `failed/stale edits` counter. If it is near zero over 20–30 tasks, the trial is not run.

## C. Decisions blocking session control

### D8 — Deferred tool loading on the pinned model

**Undecided:** whether the pinned provider/model supports append-only capability change, and what the fallback is (ADR-034, tracked as V0.3-T10).

**Found:** Pi 0.84.x is current (0.84.1, published 7 August 2026). Deferred tool loading exists in Pi and is implemented per provider — v0.84.0's release notes describe Fireworks Kimi K3 using the OpenAI-compatible API with native reasoning-effort levels and deferred tools, and the documented example is Kimi-specific. That is evidence the mechanism is provider-conditional, not universal, which is precisely what ADR-034 anticipated.

**Costs:** without native deferred loading, Pi's fallback sends the complete changed tool list, invalidating the cached prefix even for an additive change. The permitted responses are a fixed tool surface for the epoch or a declared boundary — never a silent prefix edit.

**Settles it:** read the deferred-tools support matrix in the pinned Pi version's source for the provider chosen in D1, then record availability and fallback in the session manifest.

### D9 — Shell-output compression

**Undecided:** RTK, the narrow LeanCTX profile, or neither.

**Found:** RTK (`rtk-ai/rtk`) is an MIT Rust binary, ~39.5k stars, v0.38.0 in late April 2026 with 141 releases, claiming 60–90% compression across 50+ commands at <10ms overhead, installed by platform method and wired through a `PreToolUse`-style hook that rewrites `git status` to `rtk git status`. LeanCTX is a single Rust binary with 76 MCP tools claiming 60–90% fewer tokens; a third-party field report on 26 July 2026 measured 64.1% less context overall — but attributes 89.7% of the saving to MCP traffic compression and only 10.3% to shell integration, and an independent Pi benchmark previously reported a configuration where LeanCTX produced *higher* billed input.

**Costs:** the field-report breakdown is the material finding. Our shell output is already bounded by Pi truncation and by `project_check` preferring JSON/SARIF/JUnit over text, and our MCP surface is deliberately one lazy proxy — so both of the places LeanCTX saves are places this design has already minimized. The honest prior is that measured savings here will be far below the advertised range.

**Settles it:** the Stage 6 baseline's counters for results over 5 KB and 50 KB. If the tail is thin, neither is installed, and both stay in the post-1.0 backlog.

## D. Parity gaps — no owner exists

These three are the substantive gaps found while writing `11` §4.1. Each is used daily in the current environment and none has an owner in the plan.

### D10 — Web search and fetch

**Undecided:** which component owns web search and page fetch, and under what permission class.

**Found:** no owner exists in the Outcome table. `docs/01` mentions "one read-only web surface" for the researcher role and browser services as MCP candidates, but assigns neither. The Pi ecosystem has several candidates: `pi-web-access` (search, fetch, GitHub, PDF, YouTube), `pi-web-tools` (multi-provider search and extract), `@counterposition/pi-web-search` (Brave/Tavily/Exa behind one interface), and headless-Chrome extractors such as `pi-web-fetch`. All are young and community-maintained.

**Costs:** this is the capability with the worst context behaviour in the whole stack — a fetched page is unbounded text arriving as a tool result — so it needs the pre-insertion bounding rule (ADR-013) more than anything else does. It is also an egress path, which makes it a permission question and not only a tool question: read-only fetch of a public URL is `allow`; anything that transmits repository content is `ask`.

**Settles it:** decide the class first (a Pi-native extension versus an MCP server behind the lazy proxy), then pin one candidate and measure result sizes. Evidence-critical retrievals must persist query, result ordering, passages, timestamps, URLs and hashes locally per ADR-028's evidence rule.

### D11 — Image and screenshot input

**Undecided:** whether the harness accepts images, and if so through what path.

**Found:** unverified in the pinned Pi version. Used routinely in the current environment for screenshots of failing UI and pasted diagrams.

**Costs:** if Pi has no image path, the parity matrix has a row that cannot be filled, and the honest response is to record it as an accepted loss at the switch rather than to pretend it does not matter. A foreign worker with vision could cover specific tasks.

**Settles it:** check the pinned Pi version's message content types and TUI paste handling. One test.

### D12 — Editor integration

**Undecided:** whether the harness is driven from an editor after the switch, and how.

**Found:** three shapes exist. `pi-acp` (0.0.33) exposes Pi as an ACP agent over stdio, and ACP clients now include Zed, JetBrains natively, and community plugins for VS Code, Neovim and Emacs; the ACP Agent Registry launched 28 January 2026. VS Code Remote-SSH plus tmux attach is the "buy, don't build" option already recorded in `docs/09` §4. Terminal-only is the third.

**Costs:** the version number on `pi-acp` is the whole risk — 0.0.33 is pre-alpha for a component that would sit between the editor and every session. VS Code Remote costs nothing to keep and provides diffs and file navigation but no session integration. Terminal-only is honest and loses the diff view, which is the single most-used IDE affordance in the current workflow.

**Settles it:** try `pi-acp` against one ACP client for one real task before V0.6. If it holds, it also answers how the harness is reached from a phone or another machine later, which no other option does.

## E. Decisions blocking delegation

### D13 — ACP client for foreign workers

**Undecided:** whether the broker speaks ACP to foreign CLIs where a maintained adapter exists, in addition to the preferred headless-structured path.

**Found:** ADR-044 fixes the preference order; what is open is whether to build the second rank at all in V0.5. Codex's `--json` plus `--output-schema` already satisfies the typed-envelope contract without ACP, and Claude Code's ACP support is a Zed-maintained bridge rather than a first-party channel.

**Costs:** building ACP for a provider whose headless path already suffices is duplicated work. Not building it means Antigravity — the weakest headless surface of the three — stays on a pty.

**Settles it:** measure the Antigravity pty adapter's reliability over ten runs. ACP is justified only if scraping proves unreliable there.

### D14 — MCP proxy implementation

**Undecided:** `pi-mcp-adapter` versus the named fallback class (a self-hosted gateway/registry such as MetaMCP or MCPJungle) behind the same contract.

**Found:** `pi-mcp-adapter` is at 2.21.0 — considerably more mature than when it was pinned as a "single-maintainer research-time pin". The contract is unchanged either way: one lazy proxy, `directTools: false`, bounded discovery, measured surface ≈200 tokens.

**Costs:** the adapter is Pi-native and cheap; the gateway class is a service to run and is what a multi-runner topology would need anyway. Choosing the gateway now buys a V1.0 property at V0.5 cost.

**Settles it:** the measured startup token cost of the proxy schema and whether lazy discovery actually defers. Both are already exit criteria.

### D15 — Broker frontend

**Undecided:** whether `pi-interactive-shell` remains the attach/focus surface over a tmux-backed broker, or the broker ships its own compact attach view.

**Found:** unchanged from the existing analysis — interactive-shell has its own PTY rather than tmux, which makes it excellent for trusted-local sudo and short supervised runs and unsuitable as the durable supervisor. The V0.1-T4 review additionally found it has no secret-awareness of any kind, and that `handoffSnapshotEnabled` writes un-redacted terminal tails to disk.

**Costs:** an integration that attaches interactive-shell to a broker-owned tmux pane preserves a good UI; a compact custom view is less pleasant and has one owner.

**Settles it:** whether interactive-shell can attach to an externally-created tmux pane at the pinned version. If it cannot, the question closes itself.

### D16 — Credential class per foreign profile

**Undecided:** which foreign profiles run on subscription authentication and which require an API key.

**Found:** Anthropic's February 2026 terms restrict OAuth to Claude Code and Claude.ai and require an API key for the Agent SDK; local scripted invocation of the official CLI remains within the consumer terms. A programmatic/subscription split announced for 15 June 2026 was cancelled on that date. Technical automatability has never established provider-policy permission for unattended high-volume use.

**Costs:** attended profiles on subscription auth are the cheap and intended path. Unattended, high-volume profiles on subscription auth are the arrangement most likely to be revisited by a provider, and the one that would fail silently in the agentic layer where nobody is watching.

**Settles it:** rule of construction rather than measurement — attended profiles use subscription auth, and any profile dispatched by the orchestrator without a human present uses an API key. Record the credential class in the profile so the event stream shows which was used.

## F. Deferred, but decide before the agentic layer

### D17 — Containment engine, and whether isolation precedes the switch

**Undecided:** Gondolin audited fork, `vmpi` whole-sandbox, `@nqbao/pi-sandbox`, or rootless container — and whether any of them is needed before the switch.

**Found:** the comparison table in `docs/01` §2.5.4 stands; nothing in it changed. What changed is the sequencing: the execution layer is local, attended and operates on trusted repositories, which is exactly the threat profile the `trusted-local` profile was designed for. Isolation becomes load-bearing when execution goes unattended (agentic layer) or touches unfamiliar code — neither of which happens before the switch.

**Costs:** deferring isolation means the third switch workload class (unfamiliar or risky code) stays on the current environment longer. That is a small and explicit loss. Building isolation now costs QEMU, image work and ten acceptance tests for a threat that is not yet present.

**Settles it:** it is a scheduling decision, not a technical one. It is recorded here so that deferring it is a choice rather than an oversight.

### D18 — Todo tool trial

**Undecided:** whether `@juicesharp/rpiv-todo` is trialled in the parent.

**Found:** unchanged (ADR-017). The trigger conditions are stated: tasks repeatedly crossing compaction, four or more independently verifiable steps, or durable dependency tracking.

**Settles it:** the Stage 6 baseline's compaction-crossing counter.

## G. Repository defects

### D19 — ADR numbering in `docs/02`

**Undecided:** how to repair two known defects without breaking cross-references.

**Found:** ADR-028 and ADR-029 each appear twice (lines 245/253 and 379/395), carrying different decisions under the same identifiers; and the prose following ADR-036 belongs to a factory/workflow ADR rather than to ADR-036. Renumbering would break references from `docs/01`, `08`, `09`, the roadmap and the task files.

**Options:** (a) leave as is and rely on readers disambiguating by content; (b) add an errata table at the head of `docs/02` mapping each duplicated identifier to its two decisions and giving the second one a new number used going forward; (c) renumber fully and fix every reference in one commit, which is mechanical but touches a dozen files.

**Settles it:** operator preference. Option (b) is the cheapest thing that stops the defect from misleading anyone, and it is reversible into (c) later.
