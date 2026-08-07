# Context and Cache Discipline

Revision: 5 August 2026

ADR-007 states the policy: cache behavior is a control-plane invariant. This document states the **mechanism** — where the boundaries actually sit in a request, how dynamic state enters without breaking them, how a violation is detected, and what each version must ship to keep the guarantee true. It is the implementation reference for `pi-cache-contract` (V0.3-T4), the cache fields of the event stream (V0.4-T2) and the token-economy exit criteria of Stages 4 and 11.

Nothing here overrides an ADR. Where this document and an ADR disagree, the ADR wins and this file is wrong.

## 1. The single invariant

Prompt caching is a **prefix match over rendered request bytes**. Providers render a request in the order `tools → system → messages`, hash successive prefixes, and reuse a stored prefix only when the bytes are identical up to the breakpoint. One changed byte at position N invalidates every cached segment at or after N.

Three consequences follow, and the rest of this document is only their application:

1. **Order is a design decision, not a formatting detail.** Stable content must physically precede volatile content. Content that changes per request must sit after the last breakpoint or not exist.
2. **Rewriting history is worse than appending to it.** Any component that edits, prunes or reorders an earlier message invalidates everything after the edit — even when the edit "shortens" the prompt and looks like an optimization.
3. **Cache correctness is measurable, and therefore must be measured.** A prefix is either byte-identical or it is not; nothing about that is a matter of opinion (R-016).

A **cache epoch** is a maximal span of requests sharing one frozen prefix. Epochs end deliberately (session start, compaction, a declared tool-surface change) and never accidentally. An accidental epoch boundary is a defect with a specific cause, not background noise.

## 2. The four zones of a request

Every byte we send belongs to exactly one zone. Assigning a component to the wrong zone is the root cause of nearly every cache defect.

| Zone | Contents | Mutation rule | Owner |
| --- | --- | --- | --- |
| A — frozen prefix | Model/provider identity, base system prompt, ordered tool schemas, skill catalog (metadata only), policy and containment hashes | Immutable for the epoch; changing anything here is an epoch boundary and must be declared | `pi-session-control` (V0.3-T1) |
| B — session-static | Persona profile body, compiled capability set, workspace identity | Written once at session start, before the first request; never rewritten | Profile compiler |
| C — append-only tail | Task envelope, cwd/branch/changed files, retrieved facts, tool results, user answers, task-state updates | Append only; earlier entries are never edited or reordered | Executor, factory, retrieval |
| D — forbidden | Timestamps, per-request IDs, status/UI panels, changing memory dumps, re-rendered todo lists, remaining-token countdowns | Must not reach the model at all | — |

Zone D deserves its own statement because it is the zone people add to by accident: it is not "cheap because it is small." Zone D content is re-sent every turn, is usually placed early (making it maximally destructive), and its cost scales with conversation length rather than with its own size.

**Component placement** (this table is the authority for reviews; a component that cannot name its zone is not ready to install):

| Component | Zone | Note |
| --- | --- | --- |
| Base system prompt | A | No interpolated date, mode, user or session identifier |
| Tool schemas | A | Deterministic order (sort by name); serialization is stable, not incidental |
| Skill catalog | A | Name + description only; bodies load on invocation (ADR-013, V0.3-T3) |
| MCP proxy schema | A | One stable ~200-token schema; server discovery is lazy and additive (ADR-021) |
| `TaskEnvelopeV1` | C | Arrives as the final user message of the launch, never as system-prompt text |
| Retrieval / RAG results | C | Explicit, bounded, ID-first; never an automatic per-turn injection (R-023) |
| Task/todo state | C | Append-only tool results; see §6 |
| Hermes memory | C | Explicit retrieval only; never a per-turn dump |
| Status, health, cache and policy display | D | Rendered in the UI only; the model requests a bounded status tool if it genuinely needs the value (R-049) |
| Compaction summary | boundary | Sole history writer; declares a new epoch (ADR-024) |

## 3. Breakpoint placement

Breakpoints (`cache_control` markers) are how much of a prefix is retained. The provider allows a small number per request — currently four on the Anthropic API — so they are a budget, not a decoration.

- **Place them at stability boundaries, not at convenient offsets.** One at the end of zone A (covering tools + system together, since tools render first), one at the end of zone B, and the remainder tracking the growing tail.
- **Multi-turn default: automatic placement on the last cacheable block.** Hits then accrue incrementally as the conversation grows, and earlier breakpoints remain valid read points.
- **Long agentic turns need an intermediate breakpoint.** A breakpoint searches backward a bounded number of content blocks (currently 20) for a prior entry. A single turn that appends more tool_use/tool_result pairs than that window silently finds nothing and misses, with no error and no signal other than the usage counters. Any phase that can emit long tool chains — factory `implement`, subagent fan-out — places a breakpoint roughly every 15 blocks.
- **Forks must reuse the parent's exact prefix.** A summarizer, verifier or memory proposer that rebuilds `system`/`tools`/`model` with any difference misses the parent's cache entirely and pays a cold write. Fork operations copy the parent's zone A verbatim and append their own instructions to the tail (R-071).
- **Do not mark a prefix that is not actually shared.** For a fan-out where each child differs from the first token, breakpoints only buy cache-write premiums with no reads. Not caching is the correct choice there.

## 4. Cache-preserving mutation channels

The two most expensive invalidations — editing the system prompt and changing the tool set — now have append-only alternatives at the provider level. Where the pinned model supports them, they are the required mechanism; a prefix edit is a defect when a preserving channel exists (ADR-034).

| Need | Forbidden | Required channel |
| --- | --- | --- |
| Operator instruction arrives mid-session (mode change, revised constraint, runtime-fetched context) | Rebuilding the top-level system prompt | Append a `system`-role message to the tail. It carries operator authority, sits after the cached history, and is not spoofable by repository or tool content |
| A capability becomes relevant later in a session | Adding a tool to the schema list | Declare the tool up front with deferred loading and surface it with an additive tool-load message; the schema list itself never changes |
| A capability must be withdrawn | Removing a tool from the schema list | Additive removal message against the declared tool |
| A genuinely different model, policy or containment is needed | Mutating the running session | A new child session — a separate cache island with its own frozen prefix (ADR-018) |

Two constraints on this channel:

- **Model-gated.** Support differs per model and provider, and the fallback differs too. The session manifest records whether the preserving channel is available for the pinned model; when it is not, the harness either keeps a fixed surface for the whole epoch or declares an epoch boundary explicitly. It never silently edits the prefix.
- **Phrase mid-session system messages as context, not override.** State the fact and let the model act on it. Override-style phrasing ("ignore the previous instruction", "regardless of what the user said") is both less reliable and a prompt-injection shape we should not normalize on a privileged channel.

## 5. Verification — the part that makes the rest true

A frozen prefix is an assertion until something checks it. Three mechanisms, in ascending cost:

**5.1 Payload prefix hash (per request).** The observer hashes the normalized rendered prefix at each breakpoint and compares it with the epoch's recorded hash. A mismatch without a declared boundary fails the request in the evaluation profile and raises a `CACHE_EPOCH_VIOLATION` event elsewhere. This is the mechanism that turns ADR-007 from a convention into an invariant, and it is the only one that identifies *which* component moved the bytes.

**5.2 Provider usage counters (per request).** Record uncached input, cache-read and cache-write tokens as separate fields — never a single total. Two rules:

- Total prompt size is the **sum** of the three. A low uncached count on a long session means the rest was served from cache, not that context is small; reading one field in isolation has repeatedly produced wrong conclusions about context growth.
- `cache_read == 0` across repeated requests within one epoch means a silent invalidator is active. This is the alarm condition; §5.4 is the diagnosis.

**5.3 CI regression gate.** The smoke suite runs a fixed scripted session twice and asserts: identical prefix hashes across the two runs, non-zero cache reads from the second request onward, and startup token cost within the declared budget (V0.3-T5). Prefix-hash drift between commits fails CI the same way a broken test does — this is what prevents an unrelated extension from quietly costing every future session.

**5.4 Silent-invalidator audit.** When §5.2 alarms, walk this table before anything else. Every entry has been observed in practice; none of them error.

| Pattern | Effect |
| --- | --- |
| `now()` / date / uptime interpolated into the system prompt | Prefix differs on every request |
| Request ID, session ID or UUID early in content | Same, and unshareable across sessions |
| Non-deterministic serialization — unsorted map/JSON keys, an iterated set | Bytes differ while the value is "the same" |
| Conditional system-prompt sections behind a flag | Every flag combination is a distinct prefix with its own cold write |
| Per-user or per-task tool list | Tools render first, so nothing caches across users |
| An extension appending a status, memory or todo panel per turn | Tail churn; prefix survives but every request grows |
| A second component pruning or rewriting history beside compaction | Invalidation from the edit point onward (forbidden combination, `03` §"must not be active together") |
| Fork rebuilding `system`/`tools` instead of copying them | Fork misses the parent cache entirely |
| Provider serializing an "unchanged" structure differently after an upgrade | Expected hits vanish with no local change — why pins are exact and upgrades are gated (R-050) |

The diagnostic move in every case is the same: capture the normalized rendered payload for two consecutive requests and diff the bytes. Reasoning about which component "should" be stable is slower and less reliable than the diff.

## 6. Task state, memory and other mutable displays

This section exists because task state is the single most common way a well-designed prefix gets ruined, and the failure looks helpful while it happens.

The rule (ADR-017, ADR-029, R-023, R-049): **mutable state enters as append-only events, never as a re-rendered current-state blob.**

- Task state lives in the parent conversation/plan, which is append-only by construction. A todo package, if ever trialed, is parent-only and message-based; children never get independent stores (see ADR-017 for the ownership rationale).
- A todo update is an **event** ("marked T3 done"), not a **snapshot** (the full list re-serialized). Snapshots re-sent per turn grow every request for the life of the session and are the archetypal zone-D defect.
- Memory retrieval is explicit and bounded. No automatic per-turn hydration, no "relevant memories" preamble.
- Health, cost, cache and policy state render in the UI. If the model genuinely needs a value, it calls a bounded status tool and the answer lands in the tail like any other tool result.
- Remaining-context or remaining-token countdowns are not surfaced to the model. Beyond the cache cost, they measurably induce premature wrap-up behavior.

## 7. Economics and provider variance

Enough to make correct decisions; exact figures are provider- and model-specific and are re-measured per pin rather than trusted from this file (R-016).

- **Reads are roughly a tenth of base input price; writes carry a premium** (currently ~1.25× at the short TTL, ~2× at the long one). Short TTL breaks even at about two requests, long TTL at about three. The long TTL is for bursty traffic with idle gaps, not a default.
- **There is a minimum cacheable prefix**, currently between 512 and 4096 tokens depending on model, and it is not monotonic across generations. Below it, caching silently does not happen — a marker is present, the write counter reads zero, and nothing errors. Short-prefix sessions must not assume caching.
- **Concurrent fan-out stampedes the cache.** A cache entry is readable only once the first response begins streaming; N simultaneous identical-prefix requests all pay full price. Factory fan-out and subagent spawning send one request, await its first token, then release the rest.
- **Pre-warming is worth it only when first-request latency is user-visible and there is an idle moment before traffic.** Under continuous traffic the first real request warms the cache anyway and a warm call is pure extra cost.
- **Do not claim savings without traces.** Per-epoch, per-phase cache-read/write/uncached figures are recorded and reported; estimates derived from token counts alone are not evidence.

## 8. Version obligations

| Version | Obligation |
| --- | --- |
| V0.3 | `pi-session-control` freezes and hashes zone A; `pi-cache-contract` implements §5.1 with `/cache-status`; measured startup budget per §5.3; manifest records whether §4 preserving channels exist for the pinned model |
| V0.4 | Event stream carries `cache_epoch`, `prefix_hash`, `cache_read_tokens`, `cache_write_tokens`, `uncached_input_tokens` alongside the lineage IDs; Executor and factory phases respect §3 breakpoint placement and §7 fan-out ordering |
| V0.5 | MCP proxy schema is hash-stable across server discovery; the Stage 11 token-cost gate is measured against §5.2 counters; every foreign worker's prefix is measured per launch and recorded as its own event field, because that context is outside our own accounting entirely (ADR-043) |
| V0.6 | Session transfer is an explicit epoch boundary; `PortableSessionBundleV1` records the source epoch and never claims cache continuity across providers (`06` §"do not preserve the old provider's prompt cache"); the parity gate's cost threshold is computed from these counters, not estimated |
| V0.8 | Mission board and lease state are control-plane data; they reach a model only through a bounded tool result, never through per-turn injection |

## 9. Review checklist

Applied to any change that touches prompt assembly, tool registration, retrieval or history:

- [ ] Every added byte has a declared zone (§2), and nothing lands in zone D.
- [ ] Nothing in zone A changed; if it did, the epoch boundary is deliberate and declared.
- [ ] Dynamic content is appended, and no earlier message is edited, pruned or reordered.
- [ ] Serialization of anything in the prefix is deterministic.
- [ ] Any mid-session instruction or capability change uses a §4 preserving channel, or declares a boundary.
- [ ] Forks copy the parent prefix verbatim.
- [ ] Long tool chains place intermediate breakpoints (§3).
- [ ] Fan-out is sequenced per §7.
- [ ] The smoke suite still shows non-zero cache reads and an unchanged prefix hash.

## 10. Provider calibration — the current pin

§1, §2, §5 and §6 are provider-independent: prefix matching, zone assignment, verification and append-only state hold wherever we run. **§3 and §7 are not.** Breakpoint counts, lookback windows, minimum cacheable prefixes and TTLs are provider mechanics, and the numbers cited there are the shape of an explicit-breakpoint API. They must be re-derived per pin rather than inherited, which is what R-016 has always required.

### 10.1 Measured facts

From `~/.pi/agent/models-store.json` on the server (surveyed 5 August 2026 — this is on-machine catalog data, not an estimate):

| Property | `gpt-5.6-sol` via `openai-codex` | `openai/gpt-5.6-sol` via `openrouter` |
| --- | --- | --- |
| API surface | `openai-codex-responses` | OpenRouter-mediated |
| Context window | 272,000 | 1,050,000 |
| Max output | 128,000 | 128,000 |
| Input / output per Mtok | $5 / $30 | $5 / $30 |
| Cache read | $0.50 — 0.1× input | $0.50 — 0.1× input |
| Cache write | $6.25 — **1.25× input** | $6.25 — 1.25× input |
| Above 272k tokens | All prices double | No tier premium listed |
| Declared compatibility | OpenAI grammar tools, tool search | — |

Two consequences worth stating plainly:

- **Cache writes are billed at a premium on this pin, so placement is an economic decision, not a free optimization.** At 1.25× write and 0.1× read, a cached prefix pays for itself on the second request (1.25 + 0.1 < 2.0) — the same break-even as §7 states generically, so that guidance survives the provider change intact.
- **Not every model on this host behaves this way.** `gpt-5.4`, `gpt-5.5` and `gpt-5.3-codex-spark` carry `cacheWrite: 0` — writes are free, caching is automatic, and there is nothing to place. The whole `gpt-5.6` family (`sol`, `luna`, `terra`) bills writes. A conclusion measured on one of these models does not transfer to the other group, and a future model swap must re-check which group it lands in.

The two routes to the same model are materially different: 272k versus 1.05M context, with a doubling tier on the direct route that the direct route's own context window makes largely unreachable. Route choice is therefore a real decision (§10.3), not a preference.

### 10.2 What is not yet established

Unknown for `openai-codex-responses`, and not to be assumed from §3:

- whether cache segmentation is explicit (author-placed breakpoints) or automatic (provider-chosen prefix), which determines whether §3 is a set of instructions or merely a description of someone else's API;
- the minimum cacheable prefix;
- cache lifetime, and whether more than one TTL exists;
- whether a lookback window bounds reuse across long tool chains (R-082's failure mode is only reachable if it does);
- which usage fields the response exposes, since §5.2's three-field requirement depends on the provider reporting them separately.

These are answered by measurement, not by reading: run the scripted session twice and read the counters. Assigned to V0.3-T10, with the route decision at V0.1-T2. Until they are answered, §3 is documentation of a mechanism we may not have, and the honest position is that only the provider-independent sections are in force.

One asset already exists: Pi's own `showCacheMissNotices` setting is enabled on the server, so the harness surfaces cache misses without us building anything. That is the cheapest available input to V0.3-T4/T8 and should be the first signal wired in, not a bespoke probe.

### 10.3 Open route decision

The direct `openai-codex` route is the ChatGPT-subscription path; OpenRouter reaches the same model with a 3.9× larger context window. Deciding between them is not only cost and context — it determines the API surface, the usage fields available for §5.2, and whether cache mechanics are ours to control. Deferred to V0.1-T2 with this data attached, and recorded in the session manifest either way: `provider` and an **exact** model ID, never an alias, because alias drift silently changes the prefix and there is no error when it does.
