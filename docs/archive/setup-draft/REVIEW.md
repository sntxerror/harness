# REVIEW — MCP Layer and Skills Setup

Review date: 5 August 2026
Scope: verification that the draft bundle defines (a) the MCP layer and its configuration, including lazy discovery, and (b) the skills setup, including context economy and layering — each checked against recent empirical community experience. No documents were modified; this file records findings only.

---

## 1. Concept and goals (context for this review)

The bundle is the implementation authority for a clean, high-capability Pi agent environment, later server-hosted with Hermes coordination. The concept evolved (per `docs/04-brainstorm-evolution.md`) from a broad package brainstorm toward a small set of non-negotiables: one owner per capability, immutable frozen session profiles (`pi-session-control`), one permission/containment boundary, `project_check` as sole validation authority, `pi-factory` as deterministic outer workflow, and strict prompt-prefix/cache stability. MCP and skills both landed on the same design instinct: **advertise cheap metadata, load expensive bodies on demand, and never duplicate a capability through two surfaces.**

---

## 2. MCP layer — is it defined, and how?

### 2.1 Verdict: yes, defined clearly and consistently

The MCP layer is one of the better-specified parts of the bundle. It is covered by a dedicated ADR, a dedicated install stage, cache invariants, risk entries and a deployment gate.

**Topology — one proxy, not direct servers.** ADR-021 (`docs/02-architecture-decisions.md:195`) is explicit: *"MCP is one lazy proxy plus per-task exports."* Pi talks to a single stable lazy proxy (`pi-mcp-adapter`, Stage 11 of `docs/01-ordered-implementation-plan.md:1416`); a canonical registry generates role/task-specific subsets for foreign harnesses (Claude Code via temporary allowlisted `.mcp.json`, Codex via `[mcp_servers.*]`, Antigravity only after version verification — `01:1483`). Direct exposure is not the default anywhere; `directTools` exists as a deliberate promotion mechanism for "frequently used, decision-critical tools" only (`01:1452`).

**Scope discipline.** MCP is restricted to genuinely remote/stateful services (APIs, databases, browser services, an existing RAG). Explicit non-combinations forbid: direct tools plus the same tools behind the proxy, MCP mirrors of Pi Lens/CodeGraph/local CLIs/filesystem/shell, and native/MCP duplicates (README "Important non-combinations", `docs/00-documentation-index.md:52`, ADR-021 rejections).

### 2.2 Lazy discovery — mentioned and reasonably concrete

Yes, a context-cheap lazy discovery mechanism is specified, with an actual implementation pinned:

- The proxy presents **one stable tool schema (~200 tokens)**; server/tool discovery is "lazy and additive; no eager per-server schema dump" (cache invariant table, `01:177`).
- The Stage 11 config template shows the mechanism concretely: `"lifecycle": "lazy"`, `idleTimeout`, `directTools: false`, `requestTimeoutMs`, bounded structured output, semantic-operation permission gating (read = allow, mutate = ask) (`01:1428–1462`).
- Risk R-042 (`docs/03-risks-gaps-overlaps.md:95`) anticipates the failure mode where the proxy itself becomes a giant meta-tool, and prescribes: small stable proxy schema, brief service listing, fetch schemas only on activation, capped results, prefer parent retrieval for one-off needs.
- A clean **parent-vs-child decision rule** exists (`01:1476–1481`): 1–2 lookups → parent retrieves and passes references; repeated exploration → child gets a scoped server; stateful index → one shared service; mutating/expensive → parent broker or scoped token.
- The MCP allowlist, export identity and proxy schema are hashed into the frozen session manifest (`pi-session-control`, `01:148`, `06:140`).

**Implementation authority is a single pin:** [pi-mcp-adapter](https://github.com/nicobailon/pi-mcp-adapter). The bundle correctly flags pins as research-time pins requiring evaluation-profile verification before promotion.

### 2.3 How this compares with recent empirical experience (web, 2025–2026)

The spec's direction matches the field consensus almost exactly:

- **The problem is real and measured.** Community measurements show 10 MCP servers consuming 40k+ tokens before any work starts; GitHub's MCP server alone ~94 tools / ~17.6k tokens; one dev measured ~55k tokens of pure tool metadata at session start. Industry commentary in 2026 converges on ~5–7 directly connected servers as the practical ceiling before degradation.
- **Lazy/deferred discovery is the winning pattern.** Anthropic's protocol-level answer (Tool Search / `defer_loading`, adopted by Claude Code in early 2026) reports ~85–95% reduction in tool-definition token cost; users report e.g. 12k → ~600 tokens at session start. Claude Code has since deferred even built-in tools behind ToolSearch (~14–16k → ~1k tokens). This validates the bundle's "one small stable proxy schema + fetch on activation" design — it is effectively a harness-independent implementation of the same idea.
- **Empirical caveat worth adopting:** deferral implementations have real bugs — e.g. a reported Claude Code issue where HTTP/streamable-HTTP MCP tools were *not* deferred and 120k tokens loaded upfront anyway. Lesson for the bundle: the exit condition for Stage 11 should include a **measured** startup-context assertion (token count of the tool surface), not just "servers start lazily." The bundle already has the observability hooks for this (`05-sssf` §: context occupancy metrics) but does not tie them to the Stage 11 gate explicitly.
- **Alternative/complementary patterns in the wild:** (a) *code-execution-as-MCP* — presenting servers as code APIs the agent calls from scripts (Anthropic engineering, glama.ai) — the bundle's CLI-over-Bash preference for local tools is the same philosophy; (b) *schema compression/remixing* (Atlassian, StackOne); (c) *selective per-task connection* — exactly the bundle's per-task exports. Nothing in the field contradicts the bundle's choices.
- **Gateway/aggregator landscape** (if `pi-mcp-adapter` fails evaluation, candidates exist): **MetaMCP** is the most feature-complete self-hosted aggregator (namespaces, tool remixing, middleware, OIDC, UI); **MCPJungle** is a lighter registry/gateway good for 10–20 servers with per-developer tool visibility but basic RBAC; **1mcp** and **mcp-hub** are smaller single-entry-point options. The bundle's requirement (one canonical registry generating per-client configs, hashed exports, fail-closed on unsupported fields — R-041) is *stronger* than what most off-the-shelf gateways provide; the canonical-registry exporter is rightly listed as custom-build item 7, gated on trace evidence.

### 2.4 Gaps found (MCP)

1. **No measured token budget in the Stage 11 exit condition.** "~200 schema tokens" is asserted; nothing requires verifying the actual startup context cost or alerting on regression. Recommend adding a startup tool-surface token assertion to the Stage 11 exit condition and `/cache-status`.
2. **`pi-mcp-adapter` is a single-maintainer pin with no fallback named in the docs.** The evaluation-profile procedure covers verification, but the docs never name a contingency (MetaMCP/MCPJungle class of gateway, or Tool-Search-native deferral if Pi gains it). One sentence in Stage 11 would close this.
3. **Discovery vs. permission interplay under-specified.** The proxy gates at semantic operation, but it is not stated whether *listing/discovering* a server's tools is itself permission-gated or free (discovery output also costs context; R-042 caps results but no numeric bound is given anywhere).
4. **No promotion/demotion procedure for `directTools`.** Promoting a tool to direct exposure changes the tool surface and hence the cache/compatibility hash mid-project lifecycle; the docs say promotion happens "only after measurement" but do not state that it requires a new session/epoch (it must, per the bundle's own invariants). Should be stated explicitly.

---

## 3. Skills setup — is it defined, with clean context economy?

### 3.1 Verdict: defined, and the context-economy story is clean; layering is partially addressed

**Core mechanism (ADR-022, `02:203`):** canonical project skills in `.agents/skills/`; the model initially receives *only* precise name/description metadata; full procedure bodies load on demand; skill metadata declares required profiles/commands/files/tools/MCP; incompatible skills are excluded before launch by `skill-capability-filter` (component 3 of `pi-session-control`, `01:547`). Foreign harnesses receive only task-relevant mirrored skills.

**Context/token economy:** the design is exactly the progressive-disclosure pattern:

- name/description catalog compiled **once** at session start and hashed (`skillCatalogHash` in the session manifest) — cheap, stable, cache-friendly;
- full `SKILL.md` read only on invocation (`01:572`), an append-only tool/user message, so it never breaks the cached prefix;
- changed skills apply only next session; `/reload` disabled for automation (cache invariant `01:171`) — no mid-session catalog churn;
- capability filtering shrinks the catalog *before* the model ever sees it — a specialist "never sees a skill it cannot execute" (Phase 9, `04:139`);
- operational skills (`factory-run`, `factory-observe`, `commit-finalization`, `memory-review`, …) explicitly use the same lazy pattern (`05:218–229`), with the `commit-finalization` skill as the worked example: precise description so it loads "only immediately before a commit," withheld entirely from ordinary editing agents (`01:1539`).

This matches the empirically validated model precisely: community write-ups on Claude/agent skills report ~30–100 tokens per skill at startup and only the invoked body (~2–5k tokens) loaded when matched — "dozens of skills installed with no impact on sessions where they don't apply." The bundle's design is state of the art here, and adds two things the mainstream implementations lack: **capability-truth filtering** (a skill referencing an absent command is excluded pre-launch, addressing R-030) and **catalog hashing into the frozen manifest** for reproducibility.

One empirical caution transfers directly: a reported Claude Code bug where skills consumed their *full* token count at startup instead of frontmatter-only shows that progressive disclosure is a property of the harness implementation, not the file format. The bundle should verify (Stage 4 exit condition) that Pi actually defers bodies — currently the exit condition tests capability filtering and cache stability but not "catalog cost ≈ metadata only."

### 3.2 Layering — do mechanisms exist, are they possible, do we need them?

**What the bundle has (implicit layering):**

1. **Disclosure layering** — metadata → body → (implicitly) referenced files. Two levels are explicit; the third level (body references loading supporting files on demand, as SSSF's "lazy cookbooks" do) is endorsed via the SSSF comparison (`05:61`, `05:220`) but not stated as a rule for authoring project skills.
2. **Audience layering** — parent-only skills vs. specialist skills vs. foreign-harness-exported skills (ADR-022/023). This is a genuine layering mechanism most public setups lack.
3. **Trust layering** — production skills are control-plane (read-only to agents, R-004); Hermes may only *propose* candidate skills through review/replay/promotion (ADR-025, `07:391`). Clean.

**What is explicitly unresolved (the bundle admits this, `04:378`):**

- canonical metadata extension format;
- **conflict resolution between repository / user / global skill scopes** — i.e. precedence layering, unaddressed;
- whether a selected skill may add a tool schema without starting a new cache epoch (the invariants imply: no — additive-only dynamic tools, else new epoch — but the skills section doesn't say it).

**Does the field say hierarchical layering is needed?** Recent research (arXiv 2603.02176, discussed by O'Reilly Radar, July 2026) shows flat skill catalogs degrade as libraries grow — similar-sounding descriptions collide in one-pass scanning — and that a **capability-tree hierarchy** (domain → branch → leaf, recursive categorization) consistently outperforms flat invocation, with the gap widening with library size. Red Hat's best-practices work adds "less is more": comprehensive whole-domain skills degrade performance; prefer narrow skills with scripts for the mechanical layer and SKILL.md for the reasoning layer.

**Assessment for this bundle:** hierarchical discovery is *possible* (it composes cleanly with the frozen-catalog design: the tree is just structured metadata, compiled and hashed at session start) but is **not needed at current scale**. The capability filter already shrinks each specialist's visible catalog to a handful of entries, which is the same collision-avoidance the hierarchy buys. It becomes worth adopting only if the *parent* profile's catalog grows past a few dozen skills. Recommend recording it as a conditional experiment (same pattern as E-011) rather than building it now.

### 3.3 Gaps found (skills)

1. **Three-level disclosure not stated as an authoring rule.** Add: skill bodies should reference supporting files that load on demand, and bodies should stay small (field guidance: description ≤ ~100 tokens, body ≤ ~5k tokens). No numeric budgets exist anywhere in the bundle.
2. **Scope precedence unresolved** (repo vs. user vs. global skills) — flagged in `04:378` but no owning ADR or experiment; also interacts with R-004 (untrusted repository skills must not auto-load — `01:92` says this, but the precedence/trust rule isn't in ADR-022).
3. **No verification that the harness actually defers bodies** — add a measured "startup skill-catalog token cost = metadata only" check to the Stage 4 exit condition (empirical precedent: harnesses have shipped this broken).
4. **Skill-adds-tool question left open** — should be closed by pointing at the existing dynamic-tool invariant (`01:169`): additive-only, otherwise new epoch/session.
5. **No layering/hierarchy plan for catalog growth** — not needed now (capability filtering substitutes), but worth a one-line trigger condition ("if any compiled catalog exceeds N skills, evaluate capability-tree discovery").

---

## 4. Summary

| Question | Answer |
| --- | --- |
| MCP layer defined? | Yes — ADR-021, Stage 11, cache invariants, risks R-039–R-042 |
| One proxy or direct? | One lazy proxy (`pi-mcp-adapter`); direct only via deliberate `directTools` promotion; per-task generated exports for foreign harnesses |
| Lazy discovery specified + implemented? | Yes — ~200-token stable proxy schema, lazy lifecycle, idle shutdown, on-activation schema fetch; pinned implementation exists |
| Matches empirical best practice? | Yes — mirrors the Tool-Search/deferred-loading consensus (85–95% measured savings); stricter than most gateways on registry/hashing. Gaps: no measured token gate, no named fallback, `directTools` epoch rule implicit |
| Skills setup defined? | Yes — ADR-022, `pi-session-control` filter, Stage 4, lazy operational skills |
| Clean context economy? | Yes — metadata-only frozen catalog, on-demand bodies, capability filtering, cache-safe append-only loading; needs a measured verification gate and size budgets |
| Layering mechanisms? | Disclosure/audience/trust layering present; hierarchical (capability-tree) discovery absent — possible, not currently needed; scope-precedence layering explicitly unresolved and should get an ADR |

## Sources

- [Anthropic — Code execution with MCP](https://www.anthropic.com/engineering/code-execution-with-mcp)
- [Claude Platform Docs — Tool search tool](https://platform.claude.com/docs/en/agents-and-tools/tool-use/tool-search-tool)
- [MCP Tool Search in Claude Code — context pollution guide](https://www.atcyrus.com/stories/mcp-tool-search-claude-code-context-pollution-guide)
- [MCP Tool Search: Save 95% Context](https://claudefa.st/blog/tools/mcp-extensions/mcp-tool-search)
- [Claude Code issue #40314 — HTTP MCP tools not deferred, 120K tokens upfront](https://github.com/anthropics/claude-code/issues/40314)
- [Claude Code issue #31002 — built-in tools deferred behind ToolSearch](https://github.com/anthropics/claude-code/issues/31002)
- [Claude Code issue #14882 — skills consumed full token count at startup](https://github.com/anthropics/claude-code/issues/14882)
- [MCP spec issue #2808 — tool schema token overhead](https://github.com/modelcontextprotocol/modelcontextprotocol/issues/2808)
- [DEV — MCP servers eat 55,000 tokens before your agent says a word](https://dev.to/kenimo49/your-mcp-server-eats-55000-tokens-before-your-agent-says-a-word-19l8)
- [Atlassian — MCP compression: preventing tool bloat](https://www.atlassian.com/blog/development/mcp-compression-preventing-tool-bloat-in-ai-agents)
- [The New Stack — 10 strategies to reduce MCP token bloat](https://thenewstack.io/how-to-reduce-mcp-token-bloat/)
- [StackOne — MCP token optimization: 4 approaches compared](https://www.stackone.com/blog/mcp-token-optimization/)
- [Albato — How too many MCPs break your AI agent in 2026](https://albato.com/blog/publications/embedded-mcp-context-bloat-hallucinations)
- [Composio — 10 best MCP gateways for developers in 2026](https://composio.dev/content/best-mcp-gateway-for-developers)
- [Lunar.dev — Best open source MCP gateways 2026](https://www.lunar.dev/post/the-best-open-source-mcp-gateways-in-2026)
- [e2b — awesome-mcp-gateways](https://github.com/e2b-dev/awesome-mcp-gateways)
- [O'Reilly Radar — Agent skills work but most teams build them wrong](https://www.oreilly.com/radar/agent-skills-work-but-the-research-shows-most-teams-are-building-them-wrong/)
- [arXiv 2603.02176 — hierarchical skill discovery](https://arxiv.org/html/2603.02176v1)
- [Red Hat Emerging Tech — Building skills for AI agents: pitfalls and best practices](https://next.redhat.com/2026/07/28/building-skills-for-ai-agents-pitfalls-and-best-practices/)
- [Quinton Wall — Token-efficient Claude Code skills](https://www.quintonwall.com/writing/best-practices-to-make-claude-code-skills-token-efficient)
- [Claude Skills: the 98% token savings architecture](https://chrisduffyigniteai.substack.com/p/claude-skills-the-98-token-savings)
